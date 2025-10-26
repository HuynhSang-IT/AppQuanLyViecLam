// screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Để lấy userId
import '../models/notification_model.dart'; // <-- Dùng model thật
import '../services/notification_service.dart'; // <-- Dùng service thật
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService(); // Để lấy userId
  late final String _userId;
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    final User? user = _authService.currentUser;
    if (user != null) {
      _userId = user.uid;
      _notificationsStream = _notificationService.getNotificationsStream(_userId);
    } else {
      _userId = '';
      _notificationsStream = Stream.value([]); // Stream rỗng nếu không có user
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông Báo')),
        body: const Center(child: Text('Không tìm thấy thông tin người dùng.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
        elevation: 1,
        // Actions sẽ được cập nhật dựa trên Stream
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Lỗi Index sẽ xuất hiện ở đây
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Lỗi: ${snapshot.error}. '
                    'Rất có thể bạn cần tạo chỉ mục (index) cho (userId, timestamp descending) '
                    'trong collection "notifications". '
                    'Kiểm tra F12/Console để lấy link.'),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center( // Hiển thị nếu không có thông báo
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có thông báo nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Đã có dữ liệu
          final List<NotificationModel> notifications = snapshot.data!;
          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Scaffold( // Dùng Scaffold con để AppBar cập nhật được nút Actions
            appBar: AppBar(
              title: const Text('Thông Báo'),
              elevation: 1,
              automaticallyImplyLeading: false, // Ẩn nút back mặc định
              actions: [
                if (unreadCount > 0)
                  IconButton(
                    icon: const Icon(Icons.mark_chat_read_outlined),
                    tooltip: 'Đánh dấu tất cả đã đọc',
                    onPressed: () async {
                      await _notificationService.markAllAsRead(_userId);
                      // StreamBuilder sẽ tự cập nhật UI
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
                        );
                      }
                    },
                  ),
              ],
            ),
            body: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead ? Colors.grey[300] : Theme.of(context).primaryColor,
                    child: Icon(
                      notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: notification.isRead ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () async {
                    // Chỉ gọi service nếu chưa đọc
                    if (!notification.isRead) {
                      await _notificationService.markAsRead(notification.id);
                      // StreamBuilder sẽ tự cập nhật UI
                    }
                    // TODO: Xử lý điều hướng dựa trên notification.targetType và notification.targetId
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Đã mở: ${notification.title}')),
                       );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Hàm helper _formatTimestamp (Giữ nguyên)
  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút';
    } else {
      return 'Vừa xong';
    }
  }
}