import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Provider quản lý thông báo toàn ứng dụng
class NotificationProvider with ChangeNotifier {
  Timer? _pollingTimer;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Bắt đầu chu kỳ polling tự động lấy thông báo mỗi 5s
  void startPolling(String? userId) {
    if (userId == null) return;
    if (_currentUserId == userId && _pollingTimer != null && _pollingTimer!.isActive) {
      return;
    }

    _currentUserId = userId;
    stopPolling();
    fetchNotifications(userId);

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentUserId != null) {
        fetchNotifications(_currentUserId!, silent: true);
      }
    });
  }

  /// Dừng chu kỳ polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Xóa dữ liệu khi đăng xuất
  void clear() {
    stopPolling();
    _currentUserId = null;
    _notifications = [];
    notifyListeners();
  }

  /// Lấy danh sách thông báo từ máy chủ
  Future<void> fetchNotifications(String userId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    final list = await NotificationService.getNotifications(userId);
    _notifications = list;
    _isLoading = false;
    notifyListeners();
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String notifId) async {
    final success = await NotificationService.markAsRead(notifId);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notifId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead(String? userId) async {
    if (userId == null) return;
    final success = await NotificationService.markAllAsRead(userId);
    if (success) {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
