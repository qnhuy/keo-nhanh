import 'dart:convert';
import '../models/match_model.dart';
import '../utils/http.dart';

class MatchService {
  /// Lấy toàn bộ danh sách trận đấu / kèo mở
  static Future<List<MatchModel>> getAllMatches() async {
    try {
      final res = await Http.get('/api/matches');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((m) => MatchModel.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy chi tiết một trận đấu theo ID
  static Future<MatchModel?> getMatchDetail(String matchId) async {
    try {
      final res = await Http.get('/api/matches/$matchId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final matchData = data['data'] ?? data;
        if (matchData is Map<String, dynamic>) {
          return MatchModel.fromJson(matchData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách trận đấu liên quan đến đội bóng của tôi
  static Future<List<MatchModel>> getMyMatches(String teamId) async {
    try {
      final res = await Http.get('/api/matches/my-matches/$teamId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((m) => MatchModel.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Tạo một kèo đấu mới
  static Future<Map<String, dynamic>> createMatch({
    required String userId,
    required DateTime playTime,
    required String fieldName,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await Http.post(
        '/api/matches',
        body: {
          'userId': userId,
          'playTime': playTime.toIso8601String(),
          'fieldName': fieldName,
          'location': location ?? '',
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final data = jsonDecode(res.body);
      final isOk = (res.statusCode == 200 || res.statusCode == 201) && data['success'] == true;
      return {
        'success': isOk,
        'message': data['message']?.toString() ?? (isOk ? 'Đăng kèo thành công!' : 'Không thể tạo kèo.'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server: $e',
      };
    }
  }

  /// Nhận kèo (bắt đối với một kèo đấu đang mở)
  static Future<bool> acceptMatch({
    required String matchId,
    required String matchedWithTeamId,
    required String userId,
  }) async {
    try {
      final res = await Http.patch(
        '/api/matches/$matchId/match',
        body: {
          'matchedWithTeamId': matchedWithTeamId,
          'userId': userId,
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

  /// Cập nhật trạng thái trận đấu (hoàn thành, kết thúc...)
  static Future<bool> updateMatchStatus({
    required String matchId,
    required String status,
    required String userId,
  }) async {
    try {
      final res = await Http.patch(
        '/api/matches/$matchId/status',
        body: {
          'status': status,
          'userId': userId,
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

  /// Hủy bắt kèo (đưa kèo về lại trạng thái đang mở open)
  static Future<bool> cancelMatch({
    required String matchId,
    required String userId,
  }) async {
    try {
      final res = await Http.patch(
        '/api/matches/$matchId/cancel',
        body: {'userId': userId},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Xóa vĩnh viễn trận đấu
  static Future<bool> deleteMatch({
    required String matchId,
    required String userId,
  }) async {
    try {
      final res = await Http.delete(
        '/api/matches/$matchId',
        body: {'userId': userId},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
