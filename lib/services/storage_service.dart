// services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Hàm upload 1 file
  // Trả về URL của file sau khi upload
  Future<String?> uploadFile(File file, String destinationPath) async {
    try {
      // Tạo một tham chiếu (reference) đến vị trí lưu file
      final ref = _storage.ref(destinationPath);
      
      // Đặt file vào vị trí đó
      final UploadTask uploadTask = ref.putFile(file);
      
      // Chờ cho đến khi upload xong
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      
      // Lấy URL để tải về
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;

    } catch (e) {
      print('Lỗi khi upload file: $e');
      return null;
    }
  }
  // Hàm upload CV
  // Trả về Map chứa URL và tên file gốc
  Future<Map<String, String>?> uploadCvFile(File file, String userId) async {
    try {
      // Lấy tên file gốc
      String originalFileName = file.path.split('/').last;
      // Tạo đường dẫn file trên Storage (ví dụ: cvs/user_id/ten_file.pdf)
      // Giữ lại tên file gốc để dễ nhận biết
      final String destinationPath = 'cvs/$userId/$originalFileName';

      final ref = _storage.ref(destinationPath);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Trả về cả URL và tên file gốc
      return {
        'url': downloadUrl,
        'fileName': originalFileName,
      };

    } catch (e) {
      print('Lỗi khi upload CV: $e');
      return null;
    }
  }
  // --- KẾT THÚC THÊM HÀM ---

  // (Có thể thêm hàm xóa file sau này)
  // Future<bool> deleteFile(String fileUrl) async { ... }
}

  // (Trong tương lai bạn có thể thêm hàm upload CV, xóa file... ở đây)
