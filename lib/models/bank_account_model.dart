class BankAccountModel {
  final String id; // Document ID từ Firestore
  final String bankName;
  final String accountHolder;
  final String accountNumber;  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountHolder: json['accountHolder'] as String,
      accountNumber: json['accountNumber'] as String,
    );
  }
}
