import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Model cho tin nhắn
class ChatMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 1. LẤY HOẶC TẠO PHÒNG CHAT (ĐÃ FIX)
  Future<String?> getOrCreateChatRoom(String applicationId, String userId1, String userId2, String jobId) async {
    // Sắp xếp userId để đảm bảo thứ tự nhất quán
    List<String> userIds = [userId1, userId2]..sort();

    try {
      // 🔍 CÁCH 1: Tìm bằng applicationId (ƯU TIÊN - ĐÁNG TIN CẬY NHẤT)
      QuerySnapshot existingChatByApp = await _firestore
          .collection('chats')
          .where('applicationId', isEqualTo: applicationId)
          .limit(1)
          .get();

      if (existingChatByApp.docs.isNotEmpty) {
        print('✅ Tìm thấy chat room bằng applicationId: ${existingChatByApp.docs.first.id}');
        return existingChatByApp.docs.first.id;
      }

      // 🔍 CÁCH 2: Tìm bằng array 'users' (DỰ PHÒNG)
      QuerySnapshot existingChatByUsers = await _firestore
          .collection('chats')
          .where('users', isEqualTo: userIds)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (existingChatByUsers.docs.isNotEmpty) {
        print('✅ Tìm thấy chat room bằng users array: ${existingChatByUsers.docs.first.id}');
        
        // Cập nhật applicationId nếu chưa có (trường hợp cũ)
        String chatRoomId = existingChatByUsers.docs.first.id;
        Map<String, dynamic> data = existingChatByUsers.docs.first.data() as Map<String, dynamic>;
        if (data['applicationId'] == null) {
          await _firestore.collection('chats').doc(chatRoomId).update({
            'applicationId': applicationId,
          });
          print('🔄 Đã cập nhật applicationId cho chat room cũ');
        }
        
        return chatRoomId;
      }

      // ➕ CÁCH 3: Không tìm thấy -> TẠO MỚI
      print('➕ Tạo chat room mới...');
      DocumentReference newChatRef = await _firestore.collection('chats').add({
        'users': userIds,              // Mảng đã sắp xếp
        'applicationId': applicationId, // 🔑 KEY CHÍNH để tìm chat
        'jobId': jobId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
      
      print('✅ Đã tạo chat room mới: ${newChatRef.id}');
      return newChatRef.id;
      
    } catch (e) {
      print('❌ Lỗi khi lấy/tạo phòng chat: $e');
      return null;
    }
  }

  // 2. GỬI TIN NHẮN MỚI
  Future<bool> sendMessage(String chatRoomId, ChatMessage message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('chats').doc(chatRoomId).update({
        'lastMessage': {
          'text': message.text,
          'senderId': message.senderId,
          'timestamp': message.timestamp,
        },
        'updatedAt': message.timestamp,
      });
      return true;
    } catch (e) {
      print('❌ Lỗi khi gửi tin nhắn: $e');
      return false;
    }
  }

  // 3. LẤY STREAM TIN NHẮN CỦA MỘT PHÒNG CHAT
  Stream<QuerySnapshot> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Tin mới nhất ở trên
        .snapshots();
  }

  // 4. LẤY STREAM CÁC PHÒNG CHAT CỦA USER
  Stream<QuerySnapshot> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}