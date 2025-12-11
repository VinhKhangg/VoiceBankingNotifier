import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _backendUrl = 'http://10.0.2.2:3000';

  /// Gửi OTP để đăng ký (gọi API backend)
  Future<void> sendRegistrationOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Lỗi không xác định từ server.');
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('Failed host lookup') || errorMessage.contains('Connection refused')) {
        throw Exception('Lỗi kết nối đến server. Vui lòng kiểm tra lại.');
      }
      throw Exception(e);
    }
  }

  /// Đăng nhập bằng Email và Password
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 Đảm bảo user doc tồn tại khi login
      final user = result.user;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        // Nếu document chưa tồn tại (cho người dùng cũ), tạo mới với đầy đủ các trường
        if (!docSnap.exists) {
          await docRef.set({
            "email": email,
            "name": user.displayName ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "pin": "",
            "photoURL": user.photoURL ?? "",
            "phoneNumber": user.phoneNumber ?? "",
          });
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapLoginError(e));
    }
  }

  /// Đăng ký tài khoản (được gọi từ backend sau khi xác thực OTP)
  /// Hàm này không cần thay đổi nhiều vì backend đã xử lý việc tạo document
  Future<User?> register(String email, String password, String displayName, String phoneNumber) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(displayName);

        // 🔥 Tạo document Firestore cho user với đầy đủ các trường
        await _firestore.collection('users').doc(user.uid).set({
          "email": email,
          "name": displayName,
          // ✅ Bổ sung các trường còn thiếu
          "phoneNumber": phoneNumber,
          "photoURL": "", // Mặc định rỗng khi mới đăng ký
          "createdAt": FieldValue.serverTimestamp(),
          "pin": "", // mặc định rỗng
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapRegisterError(e));
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Mapping lỗi đăng nhập
  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "❌ Không tìm thấy tài khoản này";
      case 'wrong-password':
        return "❌ Sai mật khẩu";
      case 'invalid-email':
        return "❌ Email không hợp lệ";
      case 'network-request-failed':
        return "❌ Lỗi mạng, vui lòng kiểm tra kết nối";
      case 'invalid-credential':
        return "❌ Sai thông tin đăng nhập.";
      default:
        return "❌ Lỗi đăng nhập: ${e.message}";
    }
  }

  /// Mapping lỗi đăng ký
  String _mapRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "❌ Email không hợp lệ";
      case 'email-already-in-use':
        return "❌ Email này đã được sử dụng";
      case 'weak-password':
        return "❌ Mật khẩu quá yếu (tối thiểu 6 ký tự)";
      default:
        return "❌ Lỗi đăng ký: ${e.message}";
    }
  }
}
