import 'match_model.dart';

/// Đại diện cho một tin nhắn trong đoạn hội thoại với Trợ lý AI
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<MatchModel> suggestedMatches;
  final bool isError;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedMatches = const [],
    this.isError = false,
  });

  Map<String, dynamic> toHistoryMap() {
    return {
      'role': isUser ? 'user' : 'model',
      'text': text,
    };
  }
}

/// Dữ liệu phản hồi từ API Trợ lý AI (/api/ai/chat)
class AiChatResponse {
  final bool success;
  final String reply;
  final List<MatchModel> matches;
  final String? source;

  AiChatResponse({
    required this.success,
    required this.reply,
    this.matches = const [],
    this.source,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final matchesList = <MatchModel>[];
    if (json['matches'] is List) {
      for (final item in json['matches']) {
        try {
          matchesList.add(MatchModel.fromJson(item));
        } catch (_) {}
      }
    }

    return AiChatResponse(
      success: json['success'] == true,
      reply: (json['reply'] ?? '').toString(),
      matches: matchesList,
      source: json['source']?.toString(),
    );
  }
}
