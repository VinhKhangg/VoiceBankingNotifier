// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>? _collection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('transactions');
  }

  static Future<void> insertTransaction(TransactionModel transaction) async {
    final col = _collection();
    if (col == null) return;
    await col.add(transaction.toFirestore());
  }

  static Future<List<TransactionModel>> getAllTransactions() async {
    final col = _collection();
    if (col == null) return [];

    final snapshot = await col.orderBy('time', descending: true).get();
    return snapshot.docs.map(TransactionModel.fromFirestore).toList();
  }

  // 🔴 HÀM MỚI ĐỂ LẤY GIAO DỊCH GẦN NHẤT
  static Future<TransactionModel?> getLatestTransaction() async {
    final col = _collection();
    if (col == null) return null;

    final snapshot = await col
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null; // Không có giao dịch nào
    }
    return TransactionModel.fromFirestore(snapshot.docs.first);
  }


  static Stream<List<TransactionModel>> listenTransactions() {
    final col = _collection();
    if (col == null) return Stream.value([]);

    return col
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map(TransactionModel.fromFirestore).toList());
  }

}