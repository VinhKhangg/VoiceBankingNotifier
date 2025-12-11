// lib/repositories/profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // Import model của chúng ta

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy document reference của người dùng hiện tại
  DocumentReference<Map<String, dynamic>>? _getUserDocRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// Lấy thông tin đầy đủ của người dùng từ Firestore.
  /// Trả về một đối tượng UserProfileModel.
  Future<UserProfileModel?> getUserProfile() async {
    final docRef = _getUserDocRef();
    if (docRef == null) return null;

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      return UserProfileModel.fromFirestore(docSnap);
    }
    return null;
  }

  /// Cập nhật thông tin người dùng.
  /// Nhận vào một UserProfileModel đã được chỉnh sửa.
  Future<void> updateUserProfile(UserProfileModel updatedProfile) async {
    final user = _auth.currentUser;
    final docRef = _getUserDocRef();

    if (user == null || docRef == null) {
      throw Exception("Người dùng không tồn tại hoặc chưa đăng nhập.");
    }

    // Tạo một transaction để đảm bảo cả hai cập nhật cùng thành công hoặc cùng thất bại.
    await _firestore.runTransaction((transaction) async {
      // 1. Cập nhật các trường cơ bản trong Firebase Authentication
      if (user.displayName != updatedProfile.name) {
        await user.updateDisplayName(updatedProfile.name);
      }
      if (user.photoURL != updatedProfile.photoURL) {
        await user.updatePhotoURL(updatedProfile.photoURL);
      }

      // 2. Cập nhật dữ liệu trong Firestore Document bằng model
      transaction.update(docRef, updatedProfile.toFirestore());
    });
  }
}
