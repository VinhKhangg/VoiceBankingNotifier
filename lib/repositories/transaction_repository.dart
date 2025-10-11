import '../models/transaction_model.dart';
import '../services/database_service.dart';

class TransactionRepository {
  Future<void> addTransaction(TransactionModel tx) async {
    await DatabaseService.insertTransaction(tx);
  }

  Future<List<TransactionModel>> getTransactions() async {
    return await DatabaseService.getAllTransactions();
  }

  Stream<List<TransactionModel>> listenTransactions() {
    return DatabaseService.listenTransactions();
  }
}
