import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';

import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

/// Trang Riêng Biệt Hiển Thị Mã VietQR Thanh Toán PayOS (29.000 VNĐ)
class PaymentQrScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentQrScreen({
    super.key,
    required this.paymentData,
  });

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 15 * 60; // 15 phút
  bool _isSavingImage = false;
  bool _isSuccess = false;
  bool _isChecking = false;

  late final int _orderCode;
  late final int _amount;
  late final String _description;
  late final String _accountNumber;
  late final String _accountName;
  late final String _bankName;
  late final String _qrCodeUrl;
  late final String _checkoutUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.paymentData;
    _orderCode = int.tryParse(data['orderCode']?.toString() ?? '0') ?? 0;
    _amount = int.tryParse(data['amount']?.toString() ?? '29000') ?? 29000;
    _description = data['description']?.toString() ?? 'KEO NHANH 1 THANG';
    _accountNumber = data['accountNumber']?.toString() ?? '0333888999';
    _accountName = data['accountName']?.toString() ?? 'KEONHANH PLATFORM';
    _bankName = data['bankName']?.toString() ?? 'MBBank (Ngân Hàng Quân Đội)';
    _qrCodeUrl = data['qrCode']?.toString() ?? '';
    _checkoutUrl = data['checkoutUrl']?.toString() ?? '';

    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  /// Tự động polling kiểm tra trạng thái đơn hàng mỗi 3 giây
  void _startPolling() {
    if (_orderCode == 0) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isSuccess) {
        timer.cancel();
        return;
      }
      try {
        final res = await PaymentService.checkStatus(_orderCode);
        if (res['success'] == true && res['status'] == 'PAID') {
          timer.cancel();
          _onPaymentSuccess();
        }
      } catch (_) {}
    });
  }

  Future<void> _checkManualStatus() async {
    if (_orderCode == 0 || _isChecking) return;
    setState(() => _isChecking = true);
    try {
      final res = await PaymentService.checkStatus(_orderCode);
      if (!mounted) return;
      setState(() => _isChecking = false);

      if (res['success'] == true && res['status'] == 'PAID') {
        _onPaymentSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hệ thống chưa nhận được tiền. Vui lòng kiểm tra lại giao dịch chuyển khoản!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kiểm tra: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onPaymentSuccess() {
    if (!mounted) return;
    setState(() => _isSuccess = true);
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    // Cập nhật trạng thái thuê bao trong AuthProvider
    context.read<AuthProvider>().refreshSubscription();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Thanh Toán Thành Công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chúc mừng bạn đã kích hoạt thành công 30 ngày Đặc Quyền Kèo Nhanh (Ghim kèo ưu tiên, hỏi AI không giới hạn).',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Bắt Đầu Trải Nghiệm',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tính năng Lưu ảnh mã VietQR vào máy
  Future<void> _saveQrImage() async {
    if (_qrCodeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đường dẫn ảnh mã QR!')),
      );
      return;
    }

    setState(() => _isSavingImage = true);

    try {
      final res = await http.get(Uri.parse(_qrCodeUrl));
      if (res.statusCode == 200) {
        // Lưu ảnh bằng thư viện gal
        await Gal.putImageBytes(res.bodyBytes, name: 'vietqr_keonhanh_$_orderCode.png');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Đã lưu ảnh mã QR vào thư viện ảnh của thiết bị!')),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        throw Exception('Mã phản hồi HTTP: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu ảnh (Hệ thống sẽ mở mã trên trình duyệt): $e'),
          backgroundColor: Colors.orange,
        ),
      );
      // Fallback mở qua trình duyệt
      if (_checkoutUrl.isNotEmpty) {
        launchUrl(Uri.parse(_checkoutUrl), mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  /// Giả lập thanh toán tức thì phục vụ Demo/Chấm điểm đồ án
  Future<void> _simulatePayment() async {
    try {
      final res = await PaymentService.simulateSuccess(_orderCode);
      if (!mounted) return;
      if (res['success'] == true) {
        _onPaymentSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Lỗi giả lập'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatAmount(int amt) {
    return amt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thanh Toán VietQR',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bộ đếm thời gian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đơn hàng hết hạn sau: ${_formatTimer(_secondsRemaining)}',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Thẻ Hiển Thị Mã VietQR
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Logo VietQR Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VietQR',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NAPAS 247',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Ảnh QR Code
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _qrCodeUrl.isNotEmpty
                        ? Image.network(
                            _qrCodeUrl,
                            height: 250,
                            width: 250,
                            fit: BoxFit.contain,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 250,
                                width: 250,
                                child: Center(
                                  child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                                ),
                              );
                            },
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 250,
                              width: 250,
                              color: Colors.grey[100],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 80, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Không thể tải ảnh QR', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(height: 250, child: Center(child: Text('Đang tải mã QR...'))),
                  ),

                  const SizedBox(height: 16),

                  // Nút "Lưu ảnh QR vào máy"
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _isSavingImage ? null : _saveQrImage,
                      icon: _isSavingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 20),
                      label: Text(
                        _isSavingImage ? 'Đang lưu ảnh...' : 'Lưu Ảnh QR Vào Máy',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bảng Thông Tin Chuyển Khoản Chi Tiết
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông Tin Chuyển Khoản Chính Xác',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),
                  _buildCopyRow(
                    label: 'Số tiền thanh toán',
                    value: '${_formatAmount(_amount)} VNĐ',
                    copyText: _amount.toString(),
                    isHighlight: true,
                  ),
                  const Divider(height: 20),
                  _buildCopyRow(
                    label: 'Ngân hàng thụ hưởng',
                    value: _bankName,
                    copyText: _bankName,
                  ),
                  const Divider(height: 20),
                  _buildCopyRow(
                    label: 'Số tài khoản',
                    value: _accountNumber,
                    copyText: _accountNumber,
                  ),
                  const Divider(height: 20),
                  _buildCopyRow(
                    label: 'Tên chủ tài khoản',
                    value: _accountName,
                    copyText: _accountName,
                  ),
                  const Divider(height: 20),
                  _buildCopyRow(
                    label: 'Nội dung chuyển khoản (bắt buộc)',
                    value: _description,
                    copyText: _description,
                    isImportant: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nút Kiểm tra thủ công
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkManualStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Tôi Đã Chuyển Khoản Xong',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút Giả lập thanh toán (Dành riêng cho Demo / Báo cáo)
            TextButton.icon(
              onPressed: _simulatePayment,
              icon: const Icon(Icons.flash_on, color: Color(0xFFEAB308), size: 18),
              label: const Text(
                'Giả Lập Thanh Toán Thành Công (Dành Cho Demo)',
                style: TextStyle(color: Color(0xFFB45309), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    required String copyText,
    bool isHighlight = false,
    bool isImportant = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 17 : 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? const Color(0xFF16A34A)
                      : (isImportant ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(copyText, label),
          icon: const Icon(Icons.copy, size: 18, color: Color(0xFF64748B)),
          tooltip: 'Sao chép',
        ),
      ],
    );
  }
}
