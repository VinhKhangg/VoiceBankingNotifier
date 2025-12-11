import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileModel {
  final String uid;
  final String? name;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;
  final Timestamp? createdAt;

  UserProfileModel({
    required this.uid,
    this.name,
    this.email,
    this.photoURL,
    this.phoneNumber,
    this.createdAt,
  });

  /// Factory constructor để tạo một [UserProfileModel] từ một [DocumentSnapshot] của Firestore.
  ///
  /// Dùng để chuyển đổi dữ liệu đọc từ collection `users` thành một đối tượng Dart.
  factory UserProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfileModel(
      uid: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Factory constructor để tạo một [UserProfileModel] từ đối tượng [User] của Firebase Auth.
  ///
  /// Dùng khi bạn chỉ có đối tượng User từ Firebase Auth nhưng chưa có dữ liệu từ Firestore.
  factory UserProfileModel.fromFirebaseAuth(User user) {
    return UserProfileModel(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      // phoneNumber và createdAt không có sẵn trong Firebase Auth User, sẽ là null
    );
  }

  /// Chuyển đổi một đối tượng [UserProfileModel] thành một Map để ghi vào Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      // Không ghi uid vào document field, vì nó đã là document id rồi.
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (photoURL != null) 'photoURL': photoURL,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      // Thường không cần cập nhật lại createdAt
    };
  }

  /// Tạo một bản sao của đối tượng với một vài trường được cập nhật.
  ///
  /// Rất hữu ích khi dùng trong state management để tạo một đối tượng mới thay vì thay đổi đối tượng cũ.
  UserProfileModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoURL,
    String? phoneNumber,
    Timestamp? createdAt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
