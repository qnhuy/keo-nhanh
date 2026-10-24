import 'dart:convert';
import '../models/user_model.dart';
import '../utils/http.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? token;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
  });
}

class AuthService {
  /// Đăng nhập tài khoản
  static Future<AuthResult> login(String username, String password) async {
    try {
      final res = await Http.post(
        '/api/auth/login',
        body: {
          'username': username,
          'password': password,
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        UserModel? user;
        if (data['user'] != null) {
          user = UserModel.fromJson(data['user']);
        }
        return AuthResult(
          success: true,
          message: data['message']?.toString() ?? 'Đăng nhập thành công',
          user: user,
          token: data['token']?.toString(),
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message']?.toString() ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại!',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Không thể kết nối tới máy chủ: $e',
      );
    }
  }

  /// Đăng ký tài khoản mới
  static Future<AuthResult> register(String username, String password) async {
    try {
      final res = await Http.post(
        '/api/auth/register',
        body: {
          'username': username,
          'password': password,
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return AuthResult(
          success: true,
          message: data['message']?.toString() ?? 'Đăng ký thành công',
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message']?.toString() ?? 'Đăng ký thất bại',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Lỗi kết nối máy chủ: $e',
      );
    }
  }
}
