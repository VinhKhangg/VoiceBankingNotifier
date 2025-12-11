// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/transaction/view/transaction_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../core/widgets/bank_logo.dart'; // ✅ THÊM IMPORT CHO BANK LOGO

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  // ✅ WIDGET HELPER MỚI: Dùng ListTile để hiển thị thông tin đẹp hơn
  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
      title: Text(title, style: TextStyle(color: Colors.grey.shade600)),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      trailing: trailing,
    );
  }

  // ✅ WIDGET HELPER MỚI: Để tạo tiêu đề cho các nhóm thông tin
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;
    final amountFormatted = NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(transaction.amount);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias, // Giúp các widget con bo góc theo Card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PHẦN HEADER CỦA CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    // Logo ngân hàng nhận tiền (của bạn)
                    BankLogo(bankName: transaction.destinationBankName, size: 50),
                    const SizedBox(height: 12),
                    // Số tiền
                    Text(
                      '${isIncome ? '+' : '-'} $amountFormatted',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                    // Tên ngân hàng nhận
                    Text(
                      'vào tài khoản ${transaction.destinationBankName}',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  ],
                ),
              ),

              // --- PHẦN THÔNG TIN CHI TIẾT ---
              _buildSectionHeader("Thông tin giao dịch"),
              _buildInfoTile(
                context: context,
                icon: Icons.category_outlined,
                title: 'Loại giao dịch',
                subtitle: isIncome ? 'Nhận tiền' : 'Trừ tiền',
              ),
              _buildInfoTile(
                context: context,
                icon: Icons.schedule,
                title: 'Thời gian',
                subtitle: DateFormat('HH:mm - dd/MM/yyyy').format(transaction.time),
              ),
              _buildInfoTile(
                context: context,
                icon: Icons.notes_rounded,
                title: 'Nội dung',
                subtitle: transaction.description,
              ),

              const Divider(indent: 16, endIndent: 16),

              _buildSectionHeader("Chi tiết bên gửi"),
              _buildInfoTile(
                context: context,
                icon: Icons.account_balance,
                title: 'Từ ngân hàng',
                subtitle: transaction.bankName,
                // Hiển thị logo ngân hàng gửi ở cuối
                trailing: BankLogo(bankName: transaction.bankName, size: 30),
              ),
              _buildInfoTile(
                context: context,
                icon: Icons.person_search_rounded,
                title: 'Tên người gửi',
                subtitle: transaction.partnerAccountName,
              ),

              const Divider(indent: 16, endIndent: 16),

              _buildSectionHeader("Số dư"),
              _buildInfoTile(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Số dư cuối',
                subtitle: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(transaction.balanceAfter),
              ),
              const SizedBox(height: 10), // Thêm khoảng trống ở cuối
            ],
          ),
        ),
      ),
    );
  }
}
