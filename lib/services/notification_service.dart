// services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. LẤY STREAM THÔNG BÁO CỦA USER
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) // Lọc theo người nhận
        .orderBy('timestamp', descending: true) // Sắp xếp mới nhất lên trước
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
    // Lưu ý: Truy vấn này sẽ cần Index (userId, timestamp)
  }

  // 2. ĐÁNH DẤU LÀ ĐÃ ĐỌC
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Lỗi khi đánh dấu đã đọc: $e');
      // Có thể throw lỗi ra ngoài để UI xử lý
    }
  }

  // 3. ĐÁNH DẤU TẤT CẢ LÀ ĐÃ ĐỌC (Nâng cao hơn)
  Future<void> markAllAsRead(String userId) async {
    try {
      // Lấy tất cả thông báo chưa đọc của user
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Dùng WriteBatch để cập nhật nhiều document cùng lúc (hiệu quả hơn)
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Commit batch
      await batch.commit();

    } catch (e) {
      print('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }
  // 4. LẤY STREAM ĐẾM SỐ THÔNG BÁO CHƯA ĐỌC
  Stream<int> getUnreadNotificationCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false) // Chỉ đếm cái chưa đọc
        .snapshots() // Lắng nghe thay đổi realtime
        .map((snapshot) => snapshot.docs.length); // Trả về số lượng document
    // Lưu ý: Truy vấn này cũng cần Index (userId, isRead)
  }

  // (Trong tương lai có thể thêm hàm tạo thông báo mới ở đây)
  // Future<void> createNotification(...) async { ... }
}