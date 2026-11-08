import 'dart:convert';
import '../models/admin_models.dart';
import '../utils/http.dart';

/// Service phục vụ các tính năng Quản trị hệ thống (Admin Portal)
class AdminService {
  /// Lấy số liệu thống kê tổng quan hệ thống
  static Future<AdminStatsModel?> getStats() async {
    try {
      final res = await Http.get('/api/admin/stats');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['stats'] != null) {
          return AdminStatsModel.fromJson(data['stats']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách toàn bộ người dùng để quản lý phân quyền
  static Future<List<AdminUserModel>> getAllUsers() async {
    try {
      final res = await Http.get('/api/admin/users');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['users'] is List) {
          return (data['users'] as List)
              .whereType<Map<String, dynamic>>()
              .map((u) => AdminUserModel.fromJson(u))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Cập nhật quyền của tài khoản (admin, captain, player)
  static Future<Map<String, dynamic>> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final res = await Http.patch(
        '/api/admin/users/$userId/role',
        body: {'role': newRole},
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Cập nhật phân quyền thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Gửi thông báo broadcast toàn hệ thống
  static Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String message,
  }) async {
    try {
      final res = await Http.post(
        '/api/admin/broadcast',
        body: {
          'title': title,
          'message': message,
        },
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Gửi thông báo thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Xóa/Hủy cưỡng chế một kèo đấu vi phạm
  static Future<Map<String, dynamic>> deleteMatch(String matchId) async {
    try {
      final res = await Http.delete('/api/admin/matches/$matchId');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã xóa kèo đấu thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Giải tán/Xóa một đội bóng vi phạm
  static Future<Map<String, dynamic>> deleteTeam(String teamId) async {
    try {
      final res = await Http.delete('/api/admin/teams/$teamId');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã giải tán đội bóng thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }
}
