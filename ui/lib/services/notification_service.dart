import 'dart:convert';
import '../models/notification_model.dart';
import '../utils/http.dart';

class NotificationService {
  /// Lấy danh sách thông báo của người dùng
  static Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final res = await Http.get(
        '/api/notification',
        queryParams: {'userId': userId},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((n) => NotificationModel.fromJson(n))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Đánh dấu một thông báo đã đọc
  static Future<bool> markAsRead(String notifId) async {
    try {
      final res = await Http.patch('/api/notification/$notifId/read');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Đánh dấu toàn bộ thông báo đã đọc
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final res = await Http.patch('/api/notification/read-all/$userId');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
