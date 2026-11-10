/// Model đại diện cho thông tin tài khoản người dùng
class UserModel {
  final String id;
  final String username;
  final String? role;
  final bool isPaid;
  final DateTime? paidUntil;

  UserModel({
    required this.id,
    required this.username,
    this.role,
    this.isPaid = false,
    this.paidUntil,
  });

  bool get isPaidActive =>
      isPaid && (paidUntil != null && paidUntil!.isAfter(DateTime.now()));

  int get daysRemaining =>
      paidUntil != null ? paidUntil!.difference(DateTime.now()).inDays : 0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedUntil;
    if (json['paidUntil'] != null) {
      parsedUntil = DateTime.tryParse(json['paidUntil'].toString());
    } else if (json['PaidUntil'] != null) {
      parsedUntil = DateTime.tryParse(json['PaidUntil'].toString());
    }

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['Id'] ?? '').toString(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      role: json['role']?.toString(),
      isPaid: json['isPaid'] == true ||
          json['isPaid'] == 1 ||
          json['IsPaid'] == true ||
          json['IsPaid'] == 1,
      paidUntil: parsedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'isPaid': isPaid,
      'paidUntil': paidUntil?.toIso8601String(),
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
