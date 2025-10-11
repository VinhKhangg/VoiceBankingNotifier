import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập
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
        if (!docSnap.exists) {
          await docRef.set({
            "email": email,
            "name": user.displayName ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "pin": "", // mặc định chưa có PIN
          });
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapLoginError(e));
    }
  }

  // Đăng ký
  Future<User?> register(String email, String password, String displayName) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(displayName);

        // 🔥 Tạo document Firestore cho user
        await _firestore.collection('users').doc(user.uid).set({
          "email": email,
          "name": displayName,
          "createdAt": FieldValue.serverTimestamp(),
          "pin": "", // mặc định rỗng
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapRegisterError(e));
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mapping lỗi login
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
      default:
        return "❌ Lỗi đăng nhập: ${e.message}";
    }
  }

  // Mapping lỗi register
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
