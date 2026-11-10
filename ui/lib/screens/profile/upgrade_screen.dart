import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

/// Màn hình giới thiệu và đăng ký Gói Thành Viên Đặc Quyền 1 Tháng
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước khi nâng cấp gói!')),
      );
      context.push('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await PaymentService.createPaymentLink(auth.userId!, amount: 29000);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true && res['payment'] != null) {
        // Điều hướng sang Trang riêng hiển thị mã VietQR
        context.push('/payment-qr', extra: res['payment']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Không thể khởi tạo giao dịch thanh toán'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối khi tạo đơn thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPaidActive = auth.isPaidActive;
    final daysRemaining = auth.daysRemaining;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Đặc Quyền Kèo Nhanh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner trạng thái hiện tại
            if (isPaidActive)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bạn đang là Thành Viên Đặc Quyền',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thời hạn còn lại: $daysRemaining ngày',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Card Gói Dịch Vụ Duy Nhất
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'GÓI DUY NHẤT - TIẾT KIỆM',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thành Viên Trả Phí 30 Ngày',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        '29.000',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          'VNĐ / 30 ngày',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Danh sách quyền lợi
                  _buildBenefitRow(
                    icon: Icons.push_pin,
                    title: 'Ghim Kèo Lên Vị Trí Số 1 (Spotlight)',
                    subtitle: 'Kèo của bạn luôn nổi bật ở đầu trang chủ, tìm đối thủ nhanh hơn 3 lần.',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitRow(
                    icon: Icons.psychology,
                    title: 'Hỏi Trợ Lý AI Gemini Không Giới Hạn',
                    subtitle: 'Không bị giới hạn 5 câu/ngày. Tư vấn sân, ghép đội, hỏi phân tích thả ga.',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitRow(
                    icon: Icons.verified,
                    title: 'Huy Hiệu Ngôi Sao Vàng Đẳng Cấp',
                    subtitle: 'Khẳng định uy tín của Đội trưởng & Cầu thủ trên toàn hệ thống.',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitRow(
                    icon: Icons.autorenew,
                    title: 'Cộng dồn 30 ngày linh hoạt',
                    subtitle: 'Thanh toán bất cứ lúc nào để gia hạn thêm 30 ngày kể từ hạn hiện tại.',
                  ),

                  const SizedBox(height: 28),

                  // Nút bấm thanh toán
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handlePayment,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: Text(
                        _isLoading
                            ? 'Đang kết nối PayOS...'
                            : (isPaidActive ? 'Gia Hạn Thêm 30 Ngày (29.000đ)' : 'Thanh Toán Ngay (29.000đ)'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cam kết bảo mật PayOS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.security, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Thanh toán an toàn tự động qua cổng PayOS (VietQR NAPAS 247)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF16A34A), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
