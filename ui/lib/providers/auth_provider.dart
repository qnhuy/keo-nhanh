import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider quản lý trạng thái phiên đăng nhập của người dùng & Lưu trữ cục bộ SharedPreferences
class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;

  // Thông tin user cơ bản
  String? _userId;
  String? _username;
  String? _role;
  String? _token;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;
  String? get role => _role;
  String? get token => _token;
  bool get isAdmin => _role?.toLowerCase() == 'admin';

  AuthProvider() {
    loadSession();
  }

  /// Khôi phục phiên đăng nhập từ SharedPreferences
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
      _role = prefs.getString('role');
      _isLoggedIn = _userId != null && _userId!.isNotEmpty;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading auth session: $e');
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Đăng nhập và lưu trữ cục bộ token & login state
  Future<void> login({String? id, String? name, String? role, String? token}) async {
    _isLoggedIn = true;
    _userId = id;
    _username = name;
    _role = role;
    _token = token;
    _isLoading = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (id != null) await prefs.setString('userId', id);
      if (name != null) await prefs.setString('username', name);
      if (role != null) await prefs.setString('role', role);
      if (token != null) await prefs.setString('token', token);
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving auth session: $e');
    }
  }

  /// Đăng xuất và dọn dẹp bộ nhớ SharedPreferences
  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _username = null;
    _role = null;
    _token = null;
    _isLoading = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    }
  }
}
