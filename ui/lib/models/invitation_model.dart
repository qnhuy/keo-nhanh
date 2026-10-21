/// Model Lời mời gia nhập đội bóng
class InvitationModel {
  final String id;
  final String status;
  final DateTime? createdAt;
  final String teamId;
  final String teamName;
  final String? teamLogo;
  final String? teamLocation;
  final String captainName;

  InvitationModel({
    required this.id,
    required this.status,
    this.createdAt,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.teamLocation,
    required this.captainName,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    String tId = '';
    String tName = 'Đội bóng';
    String? tLogo;
    String? tLoc;

    final rawTeam = json['teamId'] ?? json['TeamId'];
    if (rawTeam is Map) {
      tId = (rawTeam['_id'] ?? rawTeam['id'] ?? '').toString();
      tName = (rawTeam['name'] ?? rawTeam['Name'] ?? 'Đội bóng').toString();
      tLogo = rawTeam['logo']?.toString() ?? rawTeam['Logo']?.toString();
      tLoc = rawTeam['location']?.toString() ?? rawTeam['Location']?.toString();
    } else if (rawTeam != null) {
      tId = rawTeam.toString();
    }

    String capName = 'Đội trưởng';
    final rawCap = json['captainId'] ?? json['CaptainId'];
    if (rawCap is Map) {
      capName = (rawCap['username'] ?? rawCap['Username'] ?? 'Đội trưởng').toString();
    } else if (rawCap != null) {
      capName = rawCap.toString();
    }

    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) {
      try {
        created = DateTime.parse(rawCreated.toString()).toLocal();
      } catch (_) {}
    }

    return InvitationModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'pending').toString(),
      createdAt: created,
      teamId: tId,
      teamName: tName,
      teamLogo: tLogo,
      teamLocation: tLoc,
      captainName: capName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'teamId': {
        '_id': teamId,
        'name': teamName,
        'logo': teamLogo,
        'location': teamLocation,
      },
      'captainId': {
        'username': captainName,
      },
    };
  }
}
