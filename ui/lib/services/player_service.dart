import 'dart:convert';
import '../models/player_model.dart';
import '../utils/http.dart';

class PlayerService {
  /// Lấy danh sách toàn bộ cầu thủ
  static Future<List<PlayerModel>> getAllPlayers() async {
    try {
      final res = await Http.get('/api/players');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['players'] is List) {
          return (data['players'] as List)
              .whereType<Map<String, dynamic>>()
              .map((p) => PlayerModel.fromJson(p))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
