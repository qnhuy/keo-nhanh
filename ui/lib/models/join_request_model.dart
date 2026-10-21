import 'player_model.dart';

/// Yêu cầu gia nhập đội bóng
class JoinRequestModel {
  final String id;
  final String status;
  final String teamId;
  final String? teamName;
  final String? teamLocation;
  final String? captainName;
  final PlayerModel? requester;

  JoinRequestModel({
    required this.id,
    required this.status,
    required this.teamId,
    this.teamName,
    this.teamLocation,
    this.captainName,
    this.requester,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    String tId = '';
    String? tName;
    String? tLoc;
    String? capName;

    final rawTeam = json['teamId'] ?? json['TeamId'];
    if (rawTeam is Map) {
      tId = (rawTeam['_id'] ?? rawTeam['id'] ?? '').toString();
      tName = rawTeam['name']?.toString() ?? rawTeam['Name']?.toString();
      tLoc = rawTeam['location']?.toString() ?? rawTeam['Location']?.toString();
      if (rawTeam['captainId'] is Map) {
        capName = rawTeam['captainId']['username']?.toString();
      }
    } else if (rawTeam != null) {
      tId = rawTeam.toString();
    }

    PlayerModel? reqPlayer;
    final rawReq = json['requesterId'] ?? json['RequesterId'];
    if (rawReq is Map) {
      reqPlayer = PlayerModel.fromJson(Map<String, dynamic>.from(rawReq));
    }

    return JoinRequestModel(
      id: (json['_id'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'pending').toString(),
      teamId: tId,
      teamName: tName,
      teamLocation: tLoc,
      captainName: capName,
      requester: reqPlayer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'teamId': teamId,
      'teamName': teamName,
      'teamLocation': teamLocation,
      'captainName': captainName,
      'requester': requester?.toJson(),
    };
  }
}
