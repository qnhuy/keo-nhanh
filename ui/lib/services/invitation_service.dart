import 'dart:convert';
import '../models/invitation_model.dart';
import '../utils/http.dart';

class InvitationService {
  /// Lấy danh sách lời mời gia nhập đội bóng gửi tới user
  static Future<List<InvitationModel>> getUserInvitations(String userId) async {
    try {
      final res = await Http.get('/api/invitations/user/$userId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((i) => InvitationModel.fromJson(i))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Gửi lời mời một cầu thủ vào đội bóng
  static Future<Map<String, dynamic>> sendInvitation({
    required String teamId,
    required String playerProfileId,
    required String captainUserId,
  }) async {
    try {
      final res = await Http.post(
        '/api/invitations',
        body: {
          'teamId': teamId,
          'playerProfileId': playerProfileId,
          'captainUserId': captainUserId,
        },
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã gửi lời mời thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  /// Chấp nhận lời mời gia nhập đội
  static Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    try {
      final res = await Http.patch('/api/invitations/$invitationId/accept');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã tham gia đội bóng thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Từ chối lời mời gia nhập đội
  static Future<Map<String, dynamic>> rejectInvitation(String invitationId) async {
    try {
      final res = await Http.patch('/api/invitations/$invitationId/reject');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã từ chối lời mời',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
