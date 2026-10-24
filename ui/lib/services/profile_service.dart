import 'dart:convert';
import '../models/user_model.dart';
import '../utils/http.dart';

class ProfileService {
  /// Lấy hồ sơ cá nhân của người dùng theo userId
  static Future<UserProfileModel?> getProfile(String userId) async {
    try {
      final res = await Http.get('/api/user-profiles/$userId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['profile'] != null) {
          return UserProfileModel.fromJson(data['profile']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Tạo mới hoặc cập nhật hồ sơ cá nhân
  static Future<bool> saveProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String position,
    required String location,
    String? avatar,
    bool isLookingForTeam = true,
  }) async {
    try {
      final res = await Http.post(
        '/api/user-profiles',
        body: {
          'userId': userId,
          'fullName': fullName,
          'phone': phone,
          'position': position,
          'location': location,
          'avatar': avatar ?? '',
          'isLookingForTeam': isLookingForTeam,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
