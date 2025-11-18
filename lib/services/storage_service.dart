// services/storage_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // UPLOAD ẢNH – HỖ TRỢ WEB & MOBILE + XÓA ẢNH CŨ
  Future<String?> uploadAvatar({
    File? file,
    Uint8List? webImage,
    required String userId,
    String? oldAvatarUrl,
  }) async {
    try {
      // XÓA ẢNH CŨ
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        try {
          final oldRef = _storage.refFromURL(oldAvatarUrl);
          await oldRef.delete();
          print('Đã xóa ảnh cũ');
        } catch (e) {
          print('Không thể xóa ảnh cũ: $e');
        }
      }

      // UPLOAD ẢNH MỚI
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final ref = _storage.ref('avatars/$userId/$fileName');

      UploadTask task;
      if (webImage != null) {
        task = ref.putData(webImage, SettableMetadata(contentType: 'image/jpeg'));
      } else if (file != null) {
        task = ref.putFile(file);
      } else {
        return null;
      }

      final snapshot = await task.whenComplete(() => null);
      final url = await snapshot.ref.getDownloadURL();
      print('Upload ảnh thành công: $url');
      return url;
    } catch (e) {
      print('uploadAvatar error: $e');
      return null;
    }
  }

  // UPLOAD CV
  Future<Map<String, String>?> uploadCvFile(File file, String userId) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_cv_$timestamp.$ext';
      final ref = _storage.ref('cvs/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return {'url': url, 'fileName': fileName};
    } catch (e) {
      print('uploadCvFile error: $e');
      return null;
    }
  }
}