/// Utility hỗ trợ định dạng ngày tháng, thời gian và hiển thị trạng thái
class DateTimeFormatter {
  /// Format thời gian trận đấu (ví dụ: "18:30 - 15/11/2026")
  static String formatMatchTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    final date = dateTime.toLocal();
    final hStr = date.hour.toString().padLeft(2, '0');
    final mStr = date.minute.toString().padLeft(2, '0');
    final dStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');

    if (date.hour == 0 && date.minute == 0) {
      return '$dStr/$monthStr/${date.year}';
    }
    return '$hStr:$mStr - $dStr/$monthStr/${date.year}';
  }

  /// Parse chuỗi ngày và format
  static String formatMatchTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Chưa xác định';
    try {
      final dt = DateTime.parse(timeStr);
      return formatMatchTime(dt);
    } catch (_) {
      return timeStr;
    }
  }

  /// Format thời gian tương đối (ví dụ: "Vừa xong", "5 phút trước",...)
  static String formatRelativeTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

/// Helper hỗ trợ chuyển đổi trạng thái sang nhãn tiếng Việt
class StatusHelper {
  /// Trạng thái trận đấu
  static String getMatchStatusVN(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return 'Đang tìm đối';
      case 'matched':
        return 'Đã chốt kèo';
      case 'finished':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status ?? 'Không rõ';
    }
  }

  /// Trạng thái yêu cầu tham gia đội (join request)
  static String getJoinRequestStatusVN(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Đang chờ duyệt';
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return status ?? 'Đang xử lý';
    }
  }

  /// Trạng thái lời mời vào đội (team invitation)
  static String getInvitationStatusVN(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Đang chờ phản hồi';
      case 'accepted':
        return 'Đã đồng ý';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return status ?? 'Đang xử lý';
    }
  }
}
