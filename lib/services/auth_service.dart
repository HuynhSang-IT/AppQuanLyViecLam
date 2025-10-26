import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. ĐĂNG KÝ TÀI KHOẢN
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Tạo tài khoản Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Lưu thông tin user vào Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'avatarUrl': '',
          'cvUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Cập nhật display name
        await user.updateDisplayName(name);

        return {'success': true, 'message': 'Đăng ký thành công!'};
      }

      return {'success': false, 'message': 'Có lỗi xảy ra'};
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';

      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
          break;
        case 'email-already-in-use':
          message = 'Email đã được sử dụng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // 2. ĐĂNG NHẬP
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return {'success': true, 'message': 'Đăng nhập thành công!'};
      }

      return {'success': false, 'message': 'Đăng nhập thất bại'};
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';

      switch (e.code) {
        case 'user-not-found':
          message = 'Email chưa được đăng ký';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // 3. ĐĂNG XUẤT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. LẤY THÔNG TIN USER
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // 5. CẬP NHẬT THÔNG TIN USER 
  Future<bool> updateUserData({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
    String? cvUrl,      // <-- Thêm tham số cvUrl
    String? cvFileName, // <-- Thêm tham số cvFileName
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (cvUrl != null) data['cvUrl'] = cvUrl;           // <-- Cập nhật data
      if (cvFileName != null) data['cvFileName'] = cvFileName; // <-- Cập nhật data

      // Nếu cvUrl là chuỗi rỗng "", nghĩa là muốn xóa CV
      // Chúng ta sẽ cập nhật cả cvFileName thành rỗng luôn
      if (cvUrl == "") {
         data['cvFileName'] = "";
      }

      // Chỉ cập nhật nếu có dữ liệu thay đổi
      if (data.isNotEmpty) {
         await _firestore.collection('users').doc(uid).update(data);
      }
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }
}