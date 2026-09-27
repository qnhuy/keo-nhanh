/// Model thông tin cầu thủ tự do / tìm đội
class PlayerModel {
  final String id;
  final String userId;
  final String fullName;
  final String position;
  final String location;
  final String? phone;
  final String? avatar;
  final bool isLookingForTeam;

  PlayerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.position,
    required this.location,
    this.phone,
    this.avatar,
    this.isLookingForTeam = true,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? 'Cầu thủ ẩn danh').toString(),
      position: (json['position'] ?? json['Position'] ?? 'Chưa rõ').toString(),
      location: (json['location'] ?? json['Location'] ?? 'Chưa rõ').toString(),
      phone: json['phone']?.toString() ?? json['Phone']?.toString(),
      avatar: json['avatar']?.toString() ?? json['Avatar']?.toString(),
      isLookingForTeam: json['isLookingForTeam'] == true ||
          json['isLookingForTeam'] == 1 ||
          json['IsLookingForTeam'] == true ||
          json['IsLookingForTeam'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'fullName': fullName,
      'position': position,
      'location': location,
      'phone': phone,
      'avatar': avatar,
      'isLookingForTeam': isLookingForTeam,
    };
  }
}
