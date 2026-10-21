/// Model thông báo người dùng
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) {
      try {
        created = DateTime.parse(rawCreated.toString()).toLocal();
      } catch (_) {}
    }

    final readVal = json['isRead'] ?? json['IsRead'];
    final bool readBool = readVal == true || readVal == 1 || readVal == 'true';

    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Thông báo').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? 'general').toString(),
      relatedId: json['relatedId']?.toString() ?? json['RelatedId']?.toString(),
      isRead: readBool,
      createdAt: created,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
