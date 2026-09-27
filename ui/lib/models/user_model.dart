/// Model đại diện cho thông tin tài khoản người dùng
class UserModel {
  final String id;
  final String username;
  final String? role;

  UserModel({
    required this.id,
    required this.username,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['Id'] ?? '').toString(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
    };
  }
}

/// Model đại diện cho thông tin hồ sơ cầu thủ cá nhân
class UserProfileModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final String? position;
  final String? location;
  final bool isLookingForTeam;

  UserProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.avatar,
    this.position,
    this.location,
    this.isLookingForTeam = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      fullName: json['fullName']?.toString() ?? json['FullName']?.toString(),
      phone: json['phone']?.toString() ?? json['Phone']?.toString(),
      avatar: json['avatar']?.toString() ?? json['Avatar']?.toString(),
      position: json['position']?.toString() ?? json['Position']?.toString(),
      location: json['location']?.toString() ?? json['Location']?.toString(),
      isLookingForTeam: json['isLookingForTeam'] == true ||
          json['isLookingForTeam'] == 1 ||
          json['IsLookingForTeam'] == true ||
          json['IsLookingForTeam'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'position': position,
      'location': location,
      'isLookingForTeam': isLookingForTeam,
    };
  }
}
