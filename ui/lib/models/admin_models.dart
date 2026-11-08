/// Model thống kê các chỉ số tổng quan hệ thống cho Admin
class AdminStatsModel {
  final int totalUsers;
  final int totalTeams;
  final int totalMatches;
  final int openMatches;
  final int matchedMatches;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalTeams,
    required this.totalMatches,
    required this.openMatches,
    required this.matchedMatches,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return AdminStatsModel(
      totalUsers: parseInt(json['totalUsers']),
      totalTeams: parseInt(json['totalTeams']),
      totalMatches: parseInt(json['totalMatches']),
      openMatches: parseInt(json['openMatches']),
      matchedMatches: parseInt(json['matchedMatches']),
    );
  }
}

/// Model tài khoản người dùng trong danh sách quản trị
class AdminUserModel {
  final String id;
  final String username;
  final String role;
  final String fullName;
  final String phone;
  final String location;
  final String position;

  AdminUserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.location,
    required this.position,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'player').toString(),
      fullName: (json['fullName'] ?? 'Chưa cập nhật').toString(),
      phone: (json['phone'] ?? 'Chưa cập nhật').toString(),
      location: (json['location'] ?? 'Chưa cập nhật').toString(),
      position: (json['position'] ?? 'Chưa rõ').toString(),
    );
  }
}
