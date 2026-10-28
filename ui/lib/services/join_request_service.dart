import 'dart:convert';
import '../models/join_request_model.dart';
import '../utils/http.dart';

class JoinRequestService {
  /// Gửi yêu cầu gia nhập một đội bóng
  static Future<bool> sendJoinRequest({
    required String teamId,
    required String requesterProfileId,
  }) async {
    try {
      final res = await Http.post(
        '/api/join-requests',
        body: {
          'teamId': teamId,
          'requesterId': requesterProfileId,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Lấy danh sách yêu cầu xin gia nhập gửi tới Đội trưởng
  static Future<List<JoinRequestModel>> getCaptainRequests(String userId) async {
    try {
      final res = await Http.get('/api/join-requests/captain/$userId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((r) => JoinRequestModel.fromJson(r))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy danh sách các yêu cầu mà cầu thủ tự mình đã gửi đi
  static Future<List<JoinRequestModel>> getPlayerRequests(String profileId) async {
    try {
      final res = await Http.get('/api/join-requests/player/$profileId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((r) => JoinRequestModel.fromJson(r))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Duyệt (chấp nhận) yêu cầu xin gia nhập
  static Future<Map<String, dynamic>> approveRequest(String requestId) async {
    try {
      final res = await Http.patch('/api/join-requests/$requestId/approve');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Duyệt yêu cầu thành công',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Từ chối yêu cầu xin gia nhập
  static Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    try {
      final res = await Http.patch('/api/join-requests/$requestId/reject');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? 'Đã từ chối yêu cầu',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
