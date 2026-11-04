import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Huy hiệu hiển thị trạng thái trận đấu / yêu cầu với màu sắc tương ứng
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    final lower = status.toLowerCase();
    if (lower == 'open' || lower == 'đang tìm đối') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      border = const Color(0xFF86EFAC);
    } else if (lower == 'matched' || lower == 'đã chốt kèo' || lower == 'approved' || lower == 'đã chấp nhận') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
      border = const Color(0xFF93C5FD);
    } else if (lower == 'finished' || lower == 'đã kết thúc') {
      bg = const Color(0xFFF3F4F6);
      fg = const Color(0xFF4B5563);
      border = const Color(0xFFD1D5DB);
    } else if (lower == 'cancelled' || lower == 'đã hủy' || lower == 'rejected' || lower == 'đã từ chối') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      border = const Color(0xFFFCA5A5);
    } else {
      // Pending
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      border = const Color(0xFFFCD34D);
    }

    final displayText = StatusHelper.getMatchStatusVN(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
