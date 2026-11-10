import 'dart:convert';
import '../utils/http.dart';

/// Dịch vụ kết nối API thanh toán PayOS (VietQR) và quản lý gói đặc quyền
class PaymentService {
  /// Khởi tạo liên kết thanh toán PayOS (Cố định 29.000 VNĐ)
  static Future<Map<String, dynamic>> createPaymentLink(String userId, {int amount = 29000}) async {
    try {
      final res = await Http.post('/api/payment/create-payment-link', body: {
        'userId': userId,
        'amount': amount,
      });
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  /// Tra cứu trạng thái đơn hàng (Polling từ màn hình PaymentQrScreen)
  static Future<Map<String, dynamic>> checkStatus(int orderCode) async {
    try {
      final res = await Http.get('/api/payment/check-status/$orderCode');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  /// Giả lập thanh toán thành công tức thì phục vụ Demo/Báo cáo
  static Future<Map<String, dynamic>> simulateSuccess(int orderCode) async {
    try {
      final res = await Http.post('/api/payment/simulate-success/$orderCode');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  /// Lấy thông tin thời hạn đặc quyền của người dùng
  static Future<Map<String, dynamic>> getSubscription(String userId) async {
    try {
      final res = await Http.get('/api/payment/subscription/$userId');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }
}
