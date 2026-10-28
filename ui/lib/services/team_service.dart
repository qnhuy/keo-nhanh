import 'dart:convert';
import '../models/team_model.dart';
import '../utils/http.dart';

class TeamService {
  /// Lấy toàn bộ danh sách các đội bóng
  static Future<List<TeamModel>> getAllTeams() async {
    try {
      final res = await Http.get('/api/teams');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((t) => TeamModel.fromJson(t))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy danh sách các đội bóng mà một cầu thủ (profileId) đang tham gia
  static Future<List<TeamModel>> getMyTeams(String profileId) async {
    try {
      final res = await Http.get('/api/teams/my-team/$profileId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((t) => TeamModel.fromJson(t))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Tạo đội bóng mới
  static Future<bool> createTeam({
    required String name,
    required String captainId,
    required String location,
    String? logo,
    String? skillLevel,
    bool isRecruiting = true,
  }) async {
    try {
      final res = await Http.post(
        '/api/teams',
        body: {
          'name': name,
          'captainId': captainId,
          'location': location,
          'logo': logo ?? '',
          'skillLevel': skillLevel ?? 'Sơ cấp',
          'isRecruiting': isRecruiting,
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

  /// Bật/Tắt tuyển quân của đội bóng
  static Future<Map<String, dynamic>> toggleRecruiting({
    required String teamId,
    required String captainUserId,
  }) async {
    try {
      final res = await Http.patch(
        '/api/teams/$teamId/toggle-recruiting',
        body: {'captainUserId': captainUserId},
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'isRecruiting': data['isRecruiting'] == true,
        'message': data['message']?.toString() ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối tới máy chủ: $e'};
    }
  }

  /// Xóa (kick) một cầu thủ khỏi đội bóng
  static Future<Map<String, dynamic>> kickMember({
    required String teamId,
    required String playerProfileId,
  }) async {
    try {
      final res = await Http.patch('/api/teams/$teamId/kick/$playerProfileId');
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && data['success'] == true,
        'message': data['message']?.toString() ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối tới máy chủ: $e'};
    }
  }
}
