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
    String? userId,
  }) async {
    try {
      final historyList = (history ?? [])
          .where((m) => !m.isError)
          .map((m) => m.toHistoryMap())
          .toList();

      final bodyData = {
        'message': message,
        'history': historyList,
      };
      if (userId != null && userId.isNotEmpty) {
        bodyData['userId'] = userId;
      }

      final response = await Http.post(
        '/api/ai/chat',
        body: bodyData,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AiChatResponse.fromJson(data);
        }
      }

      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return AiChatResponse(
          success: false,
          reply: data['message']?.toString() ??
              'Bạn đã dùng hết 5 câu hỏi miễn phí hôm nay. Hãy nâng cấp Gói Đặc Quyền 29.000đ/tháng để hỏi AI không giới hạn!',
          matches: [],
        );
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

  /// Tra cứu số lượt hỏi AI còn lại trong ngày đối với tài khoản Miễn phí
  static Future<Map<String, dynamic>> checkUsage(String userId) async {
    try {
      final res = await Http.get('/api/ai/usage/$userId');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'remainingQuestions': 5};
    }
  }
}
