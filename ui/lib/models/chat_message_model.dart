/// Model Tin nhắn nhóm chat
class ChatMessageModel {
  final String id;
  final String content;
  final DateTime? createdAt;
  final String senderId;
  final String senderName;
  final String? senderAvatar;

  ChatMessageModel({
    required this.id,
    required this.content,
    this.createdAt,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) {
      try {
        created = DateTime.parse(rawCreated.toString()).toLocal();
      } catch (_) {}
    }

    String sId = '';
    String sName = 'Thành viên';
    String? sAvatar;

    final rawSender = json['senderId'] ?? json['SenderId'];
    if (rawSender is Map) {
      sId = (rawSender['_id'] ?? rawSender['id'] ?? rawSender['Id'] ?? '').toString();
      sName = (rawSender['fullName'] ?? rawSender['name'] ?? rawSender['username'] ?? 'Thành viên').toString();
      sAvatar = rawSender['avatar']?.toString();
    } else if (rawSender != null) {
      sId = rawSender.toString();
    }

    return ChatMessageModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      content: (json['content'] ?? json['Content'] ?? '').toString(),
      createdAt: created,
      senderId: sId,
      senderName: sName,
      senderAvatar: sAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'senderId': {
        '_id': senderId,
        'fullName': senderName,
        'avatar': senderAvatar,
      },
    };
  }
}
