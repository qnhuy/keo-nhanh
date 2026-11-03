import 'dart:convert';
import '../models/chat_message_model.dart';
import '../utils/http.dart';

class ChatService {
  /// Lấy danh sách tin nhắn của đội bóng
  static Future<List<ChatMessageModel>> getMessages(String teamId) async {
    try {
      final res = await Http.get('/api/messages/$teamId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((m) => ChatMessageModel.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Gửi tin nhắn mới vào phòng chat đội bóng
  static Future<bool> sendMessage({
    required String teamId,
    required String senderId,
    required String content,
  }) async {
    try {
      final res = await Http.post(
        '/api/messages',
        body: {
          'teamId': teamId,
          'senderId': senderId,
          'content': content,
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
}
