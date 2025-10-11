import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final _firestore = FirebaseFirestore.instance;

  /// 🔹 Lấy collection transactions theo userId
  static CollectionReference<Map<String, dynamic>>? _collection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; //
    return _firestore.collection('users').doc(user.uid).collection('transactions');
  }

  /// 🔹 Thêm giao dịch mới
  static Future<void> insertTransaction(TransactionModel transaction) async {
    final col = _collection();
    if (col == null) return;

    await col.add({
      'senderName': transaction.senderName,
      'accountNumber': transaction.accountNumber,
      'bankName': transaction.bankName,
      'amount': transaction.amount,
      'time': Timestamp.fromDate(transaction.time),
    });
  }

  /// 🔹 Lấy tất cả giao dịch (mới nhất trước)
  static Future<List<TransactionModel>> getAllTransactions() async {
    final col = _collection();
    if (col == null) return [];

    final snapshot = await col.orderBy('time', descending: true).get();
    return snapshot.docs.map(TransactionModel.fromFirestore).toList();
  }

  /// 🔹 Lắng nghe giao dịch realtime
  static Stream<List<TransactionModel>> listenTransactions() {
    final col = _collection();
    if (col == null) return Stream.value([]);

    return col
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map(TransactionModel.fromFirestore).toList());
  }

  // ========================================================================
  // 🟢 QUẢN LÝ MÃ PIN
  // ========================================================================

  static Future<void> savePin(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(
      {
        "pin": pin,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<bool> verifyPin(String pinInput) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;

    final data = doc.data();
    final storedPin = data?["pin"] as String?;
    if (storedPin == null) return false;

    return storedPin == pinInput;
  }

  static Future<String?> getPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      // Nếu chưa có document cho user → tạo luôn doc trống với pin = null
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          "pin": null,
          "createdAt": FieldValue.serverTimestamp(),
        });
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      final pin = data["pin"];
      if (pin == null || (pin is String && pin.isEmpty)) {
        return null; // chưa đặt pin
      }

      return pin as String;
    } catch (e) {
      print("Lỗi khi getPin: $e");
      return null; // fallback an toàn
    }
  }
}
