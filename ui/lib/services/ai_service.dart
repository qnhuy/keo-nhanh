import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/http.dart';

/// Service giao tiếp với AI Match Assistant API
class AiService {
  /// Gửi tin nhắn đến Trợ lý AI và nhận câu trả lời kèm danh sách kèo gợi ý
  static Future<AiChatResponse> sendMessage({
    required String message,
    List<AiChatMessage>? history,
  }) async {
    try {
      final historyList = (history ?? [])
          .where((m) => !m.isError)
          .map((m) => m.toHistoryMap())
          .toList();

      final response = await Http.post(
        '/ai/chat',
        body: {
          'message': message,
          'history': historyList,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AiChatResponse.fromJson(data);
        }
      }

      return AiChatResponse(
        success: false,
        reply: 'Không thể kết nối đến máy chủ AI (Mã lỗi: ${response.statusCode}). Vui lòng thử lại sau.',
        matches: [],
      );
    } catch (e) {
      debugPrint('Lỗi AiService.sendMessage: $e');
      return AiChatResponse(
        success: false,
        reply: 'Đã xảy ra lỗi khi gửi yêu cầu tới trợ lý AI. Vui lòng kiểm tra lại kết nối mạng.',
        matches: [],
      );
    }
  }
}
