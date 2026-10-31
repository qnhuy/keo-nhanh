import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/formatters.dart';

/// Widget Chuông Thông Báo (Notification)
/// - Hiển thị icon chuông kèm badge số lượng chưa đọc
/// - Nhận dữ liệu và trạng thái từ NotificationProvider
/// - Khi bấm vào sẽ mở dialog hiển thị danh sách thông báo
class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

// Alias hỗ trợ cả 2 cách đặt tên
typedef NotificationButton = NotificationWidget;

class _NotificationWidgetState extends State<NotificationWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<NotificationProvider>().startPolling(userId);
      }
    });
  }

  /// Chọn icon tương ứng theo loại thông báo
  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'match_matched':
        return Icons.sports_soccer;
      case 'join_request':
        return Icons.person_add_alt_1;
      case 'team_invitation':
        return Icons.mail_outline;
      case 'match_result':
        return Icons.emoji_events;
      default:
        return Icons.notifications_active;
    }
  }

  /// Hiển thị Popup danh sách thông báo
  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (dialogContext, notifProvider, _) {
            final unread = notifProvider.unreadCount;
            final notifications = notifProvider.notifications;
            final userId = context.read<AuthProvider>().userId;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: 420,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header của Popup
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Thông báo',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unread mới',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              if (unread > 0)
                                TextButton(
                                  onPressed: () => notifProvider.markAllAsRead(userId),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Đọc tất cả',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.grey[600],
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                    // Danh sách thông báo
                    Flexible(
                      child: notifications.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_outlined,
                                    size: 54,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Chưa có thông báo nào',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Khi có đội nhận kèo hoặc gửi yêu cầu, thông báo sẽ hiển thị ở đây.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 8,
                                thickness: 0.5,
                                color: Color(0xFFF3F4F6),
                              ),
                              itemBuilder: (context, index) {
                                final n = notifications[index];
                                final isRead = n.isRead;
                                final notifId = n.id;
                                final title = n.title;
                                final message = n.message;
                                final type = n.type;
                                final relatedId = n.relatedId;
                                final timeStr = n.createdAt != null
                                    ? DateTimeFormatter.formatRelativeTime(n.createdAt!.toIso8601String())
                                    : '';

                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    if (!isRead && notifId.isNotEmpty) {
                                      await notifProvider.markAsRead(notifId);
                                    }

                                    // Nếu là thông báo kèo đấu và có relatedId thì chuyển tới chi tiết kèo
                                    if (type == 'match_matched' &&
                                        relatedId != null &&
                                        relatedId.isNotEmpty) {
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (context.mounted) {
                                        context.push('/matchDetail', extra: relatedId);
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isRead
                                            ? const Color(0xFFF3F4F6)
                                            : const Color(0xFFBBF7D0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Icon theo loại
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isRead
                                                ? const Color(0xFFE5E7EB)
                                                : const Color(0xFFDCFCE7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _getTypeIcon(type),
                                            size: 20,
                                            color: isRead
                                                ? Colors.grey[600]
                                                : const Color(0xFF16A34A),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Nội dung
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                        fontWeight: isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.bold,
                                                        fontSize: 14,
                                                        color: isRead
                                                            ? Colors.grey[800]
                                                            : const Color(0xFF166534),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (timeStr.isNotEmpty)
                                                    Text(
                                                      timeStr,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                message,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isRead
                                                      ? Colors.grey[600]
                                                      : Colors.black87,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isRead) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                    // Footer của Popup
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    final notifProvider = context.watch<NotificationProvider>();
    final unread = userId != null ? notifProvider.unreadCount : 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 26),
          color: Colors.grey[700],
          onPressed: () {
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng đăng nhập để xem thông báo!'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            _showNotificationPopup(context);
          },
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
