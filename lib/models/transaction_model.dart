// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final double amount;
  final DateTime time;
  final TransactionType type;
  final String accountNumber;
  final String description;
  final String bankName;
  final double balanceAfter;
  final String partnerAccountName;
  final String destinationBankName;
  final String destinationAccountNumber;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.time,
    required this.type,
    required this.accountNumber,
    required this.description,
    required this.bankName,
    required this.balanceAfter,
    required this.partnerAccountName,
    required this.destinationBankName,
    required this.destinationAccountNumber,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accountNumber: data['accountNumber'] ?? '', // STK của partner
      type: data['type'] == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      description: data['description'] ?? 'Không có nội dung',
      bankName: data['bankName'] ?? 'Ngân hàng không rõ',
      balanceAfter: (data['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      partnerAccountName: data['partnerAccountName'] ?? '',
      destinationBankName: data['destinationBankName'] ?? 'Không rõ',
      destinationAccountNumber: data['destinationAccountNumber'] ?? '', // ✅ Đọc trường mới
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'time': Timestamp.fromDate(time),
      'accountNumber': accountNumber,
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'description': description,
      'bankName': bankName,
      'balanceAfter': balanceAfter,
      'partnerAccountName': partnerAccountName,
      'destinationBankName': destinationBankName,
      'destinationAccountNumber': destinationAccountNumber, // ✅ Ghi trường mới
    };
  }
}
