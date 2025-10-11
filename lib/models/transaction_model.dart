import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String senderName;
  final String accountNumber;
  final String bankName;
  final double amount;
  final DateTime time;

  TransactionModel({
    this.id = "",
    required this.senderName,
    required this.accountNumber,
    required this.bankName,
    required this.amount,
    required this.time,
  });

  /// Parse Firestore document → Model
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final timeField = data['time'];

    return TransactionModel(
      id: doc.id,  // 👈 lấy luôn doc.id
      senderName: data['senderName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      bankName: data['bankName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      time: timeField is Timestamp
          ? timeField.toDate()
          : DateTime.tryParse(timeField.toString()) ?? DateTime.now(),
    );
  }

  /// Model → Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'amount': amount,
      'time': Timestamp.fromDate(time),
    };
  }

  @override
  String toString() {
    return "Transaction(id: $id, sender: $senderName, amount: $amount, bank: $bankName, time: $time)";
  }
}
