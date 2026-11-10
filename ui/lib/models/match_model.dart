/// Thông tin đội bóng tóm tắt trong kèo đấu
class MatchTeamSummary {
  final String id;
  final String name;
  final String? logo;

  MatchTeamSummary({
    required this.id,
    required this.name,
    this.logo,
  });

  factory MatchTeamSummary.fromJson(dynamic json) {
    if (json == null) {
      return MatchTeamSummary(id: '', name: 'Đội ẩn danh');
    }
    if (json is String) {
      return MatchTeamSummary(id: json, name: 'Đội bóng');
    }
    if (json is Map) {
      return MatchTeamSummary(
        id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
        name: (json['name'] ?? json['Name'] ?? 'Đội ẩn danh').toString(),
        logo: json['logo']?.toString() ?? json['Logo']?.toString(),
      );
    }
    return MatchTeamSummary(id: '', name: 'Đội ẩn danh');
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'logo': logo,
    };
  }
}

/// Model trận đấu bóng đá / kèo đấu
class MatchModel {
  final String id;
  final String status;
  final DateTime? playTime;
  final String fieldName;
  final String? fieldAddress;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isPinned;
  final MatchTeamSummary creatorTeam;
  final MatchTeamSummary? matchedWithTeam;

  MatchModel({
    required this.id,
    required this.status,
    this.playTime,
    required this.fieldName,
    this.fieldAddress,
    this.location,
    this.latitude,
    this.longitude,
    this.isPinned = false,
    required this.creatorTeam,
    this.matchedWithTeam,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTime = json['playTime'] ?? json['PlayTime'];
    if (rawTime != null) {
      try {
        parsedTime = DateTime.parse(rawTime.toString()).toLocal();
      } catch (_) {}
    }

    double? parseCoord(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return MatchModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'open').toString(),
      playTime: parsedTime,
      fieldName: (json['fieldName'] ?? json['FieldName'] ?? 'Sân chưa xác định').toString(),
      fieldAddress: json['fieldAddress']?.toString() ?? json['location']?.toString() ?? json['Location']?.toString(),
      location: json['location']?.toString() ?? json['fieldAddress']?.toString() ?? json['Location']?.toString(),
      latitude: parseCoord(json['latitude'] ?? json['Latitude']),
      longitude: parseCoord(json['longitude'] ?? json['Longitude']),
      isPinned: json['isPinned'] == true ||
          json['isPinned'] == 1 ||
          json['IsPinned'] == true ||
          json['IsPinned'] == 1,
      creatorTeam: MatchTeamSummary.fromJson(json['creatorTeamId']),
      matchedWithTeam: json['matchedWithTeamId'] != null
          ? MatchTeamSummary.fromJson(json['matchedWithTeamId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'playTime': playTime?.toIso8601String(),
      'fieldName': fieldName,
      'fieldAddress': fieldAddress,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isPinned': isPinned,
      'creatorTeamId': creatorTeam.toJson(),
      'matchedWithTeamId': matchedWithTeam?.toJson(),
    };
  }
}
