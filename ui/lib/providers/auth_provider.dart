import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http.dart';

/// Provider quản lý trạng thái phiên đăng nhập & Đặc quyền thành viên trả phí (1 Tháng)
class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;

  // Thông tin user cơ bản
  String? _userId;
  String? _username;
  String? _role;
  String? _token;

  // Trạng thái thành viên trả phí (1 Tháng)
  bool _isPaid = false;
  DateTime? _paidUntil;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;
  String? get role => _role;
  String? get token => _token;
  bool get isAdmin => _role?.toLowerCase() == 'admin';

  bool get isPaid => _isPaid;
  DateTime? get paidUntil => _paidUntil;

  /// Kiểm tra xem gói trả phí 30 ngày có đang hoạt động hợp lệ không
  bool get isPaidActive =>
      _isPaid && (_paidUntil != null && _paidUntil!.isAfter(DateTime.now()));

  /// Số ngày đặc quyền còn lại
  int get daysRemaining =>
      _paidUntil != null && isPaidActive
          ? _paidUntil!.difference(DateTime.now()).inDays + 1
          : 0;

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
      _isPaid = prefs.getBool('isPaid') ?? false;

      final rawUntil = prefs.getString('paidUntil');
      if (rawUntil != null && rawUntil.isNotEmpty) {
        _paidUntil = DateTime.tryParse(rawUntil);
      }

      _isLoggedIn = _userId != null && _userId!.isNotEmpty;
      notifyListeners();

      // Nếu đã đăng nhập, tự động đồng bộ trạng thái thanh toán mới nhất từ server
      if (_isLoggedIn && _userId != null) {
        refreshSubscription();
      }
    } catch (e) {
      debugPrint('Error loading auth session: $e');
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Đăng nhập và lưu trữ cục bộ token, login state & subscription
  Future<void> login({
    String? id,
    String? name,
    String? role,
    String? token,
    bool? isPaid,
    DateTime? paidUntil,
  }) async {
    _isLoggedIn = true;
    _userId = id;
    _username = name;
    _role = role;
    _token = token;
    _isPaid = isPaid ?? false;
    _paidUntil = paidUntil;
    _isLoading = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (id != null) await prefs.setString('userId', id);
      if (name != null) await prefs.setString('username', name);
      if (role != null) await prefs.setString('role', role);
      if (token != null) await prefs.setString('token', token);
      await prefs.setBool('isPaid', _isPaid);
      if (paidUntil != null) {
        await prefs.setString('paidUntil', paidUntil.toIso8601String());
      }
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving auth session: $e');
    }
  }

  /// Cập nhật ngay trạng thái đặc quyền sau khi thanh toán thành công
  Future<void> updateSubscription({
    required bool isPaid,
    DateTime? paidUntil,
  }) async {
    _isPaid = isPaid;
    _paidUntil = paidUntil;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPaid', isPaid);
      if (paidUntil != null) {
        await prefs.setString('paidUntil', paidUntil.toIso8601String());
      } else {
        await prefs.remove('paidUntil');
      }
    } catch (e) {
      debugPrint('Error saving subscription to prefs: $e');
    }
  }

  /// Tra cứu và đồng bộ trạng thái thuê bao mới nhất từ server
  Future<void> refreshSubscription() async {
    if (_userId == null) return;
    try {
      final res = await Http.get('/api/payment/subscription/$_userId');
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final bool serverIsPaid = data['isPaid'] == true;
        DateTime? serverPaidUntil;
        if (data['paidUntil'] != null) {
          serverPaidUntil = DateTime.tryParse(data['paidUntil'].toString());
        }
        await updateSubscription(
          isPaid: serverIsPaid,
          paidUntil: serverPaidUntil,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing subscription from server: $e');
    }
  }

  /// Đăng xuất và dọn dẹp bộ nhớ SharedPreferences
  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _username = null;
    _role = null;
    _token = null;
    _isPaid = false;
    _paidUntil = null;
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
