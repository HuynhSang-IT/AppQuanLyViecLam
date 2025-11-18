// services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ĐĂNG KÝ
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'avatarUrl': '',
          'cvUrl': '',
          'cvFileName': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await user.updateDisplayName(name);
        return {'success': true, 'message': 'Đăng ký thành công!'};
      }
      return {'success': false, 'message': 'Lỗi tạo tài khoản'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ĐĂNG NHẬP
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return {'success': true, 'message': 'Đăng nhập thành công!'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ĐĂNG XUẤT
  Future<void> signOut() async => await _auth.signOut();

  // LẤY DỮ LIỆU USER
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('getUserData error: $e');
      return null;
    }
  }

  // CẬP NHẬT USER – CHỈ GHI FIELD CÓ GIÁ TRỊ
  Future<bool> updateUserData({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
    String? cvUrl,
    String? cvFileName,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (name != null && name.isNotEmpty) data['name'] = name;
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (cvUrl != null) data['cvUrl'] = cvUrl;
      if (cvFileName != null) data['cvFileName'] = cvFileName;

      if (cvUrl == "") {
        data['cvUrl'] = "";
        data['cvFileName'] = "";
      }

      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('updateUserData error: $e');
      return false;
    }
  }

  String _getAuthError(String code) {
    switch (code) {
      case 'weak-password': return 'Mật khẩu quá yếu';
      case 'email-already-in-use': return 'Email đã được dùng';
      case 'invalid-email': return 'Email không hợp lệ';
      case 'user-not-found': return 'Email chưa đăng ký';
      case 'wrong-password': return 'Mật khẩu sai';
      default: return 'Lỗi: $code';
    }
  }
}