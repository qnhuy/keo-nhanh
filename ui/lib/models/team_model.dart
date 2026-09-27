/// Thành viên của đội bóng
class TeamMemberModel {
  final String id;
  final String? fullName;
  final String? position;
  final String? location;
  final String? phone;
  final String? avatar;
  final String? userId;
  final bool isCaptain;

  TeamMemberModel({
    required this.id,
    this.fullName,
    this.position,
    this.location,
    this.phone,
    this.avatar,
    this.userId,
    this.isCaptain = false,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      fullName: json['fullName']?.toString() ?? json['FullName']?.toString(),
      position: json['position']?.toString() ?? json['Position']?.toString(),
      location: json['location']?.toString() ?? json['Location']?.toString(),
      phone: json['phone']?.toString() ?? json['Phone']?.toString(),
      avatar: json['avatar']?.toString() ?? json['Avatar']?.toString(),
      userId: json['userId']?.toString() ?? json['UserId']?.toString(),
      isCaptain: json['isCaptain'] == 1 || json['isCaptain'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'position': position,
      'location': location,
      'phone': phone,
      'avatar': avatar,
      'userId': userId,
      'isCaptain': isCaptain,
    };
  }
}

/// Model Đội bóng
class TeamModel {
  final String id;
  final String name;
  final String? logo;
  final String skillLevel;
  final String location;
  final bool isRecruiting;
  final String? desc;
  final String? captainId;
  final String captainName;
  final List<TeamMemberModel> players;

  TeamModel({
    required this.id,
    required this.name,
    this.logo,
    required this.skillLevel,
    required this.location,
    this.isRecruiting = true,
    this.desc,
    this.captainId,
    required this.captainName,
    this.players = const [],
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    String? capId;
    String capName = (json['captainName'] ?? json['CaptainName'] ?? 'Ẩn danh').toString();

    final rawCap = json['captainId'] ?? json['CaptainId'];
    if (rawCap is Map) {
      capId = (rawCap['_id'] ?? rawCap['id'] ?? rawCap['Id'])?.toString();
      if (rawCap['username'] != null) {
        capName = rawCap['username'].toString();
      }
    } else if (rawCap != null) {
      capId = rawCap.toString();
    }

    final rawPlayers = json['players'] ?? json['members'];
    List<TeamMemberModel> playerList = [];
    if (rawPlayers is List) {
      playerList = rawPlayers
          .whereType<Map<String, dynamic>>()
          .map((p) => TeamMemberModel.fromJson(p))
          .toList();
    }

    return TeamModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? 'Chưa đặt tên').toString(),
      logo: json['logo']?.toString() ?? json['Logo']?.toString(),
      skillLevel: (json['skillLevel'] ?? json['level'] ?? json['SkillLevel'] ?? 'Sơ cấp').toString(),
      location: (json['location'] ?? json['Location'] ?? '').toString(),
      isRecruiting: json['isRecruiting'] == true ||
          json['isRecruiting'] == 1 ||
          json['IsRecruiting'] == true ||
          json['IsRecruiting'] == 1,
      desc: json['desc']?.toString() ?? json['description']?.toString(),
      captainId: capId,
      captainName: capName,
      players: playerList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'logo': logo,
      'skillLevel': skillLevel,
      'location': location,
      'isRecruiting': isRecruiting,
      'desc': desc,
      'captainId': captainId,
      'captainName': captainName,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}
