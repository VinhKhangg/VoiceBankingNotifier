// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/core/widgets/add_transaction_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/bank_account_model.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import 'bank_logo.dart';
import '../../features/add_bank/manage_linked_accounts_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({Key? key}) : super(key: key);

  @override
  _AddTransactionDialogState createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _type = TransactionType.income;
  final _amountController = TextEditingController();

  String? _selectedPartnerBank;
  final _partnerAccountNumberController = TextEditingController();
  final _searchBankController = TextEditingController();

  BankAccountModel? _selectedMyAccount;

  bool _isLoading = false;
  List<BankAccountModel> _linkedAccounts = [];
  bool _isCheckingAccounts = true;

  final List<String> _partnerNames = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Minh C', 'Phạm Quang D', 'Hoàng Thị E'];
  final List<String> _descriptions = ['Thanh toán tiền nhà', 'Chuyển tiền cá nhân', 'Đóng học phí', 'Mua sắm online', 'Thanh toán hóa đơn'];
  final _random = Random();

  final List<String> _vietnamBanks = [
    'ACB', 'Agribank', 'BIDV', 'Eximbank', 'HDBank',
    'MBBank', 'OCB', 'Sacombank', 'Techcombank',
    'TPBank', 'VIB', 'Vietcombank', 'VietinBank', 'VPBank'
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  Future<void> _loadLinkedAccounts() async {
    setState(() => _isCheckingAccounts = true);
    try {
      final responseData = await callBackendApi('/api/auth/bank-accounts', {}, method: 'GET');
      final List<dynamic> accountsJson = responseData as List<dynamic>;

      if (!mounted) return;

      setState(() {
        _linkedAccounts = accountsJson.map((json) => BankAccountModel.fromJson(json)).toList();
        if (_linkedAccounts.isNotEmpty) {
          // Tự động chọn tài khoản đầu tiên nếu có
          _selectedMyAccount = _linkedAccounts.first;
        }
        _isCheckingAccounts = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isCheckingAccounts = false);
      print("Lỗi khi tải tài khoản ngân hàng: $e");
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _partnerAccountNumberController.dispose();
    _searchBankController.dispose();
    super.dispose();
  }

  String _getRandomItem(List<String> list) => list[_random.nextInt(list.length)];

  // ✅✅✅ HÀM QUAN TRỌNG NHẤT - ĐÃ ĐƯỢC SỬA LỖI HOÀN CHỈNH ✅✅✅
  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));

      // --- Tính toán số dư và tạo đối tượng giao dịch ---
      final latestTx = await DatabaseService.getLatestTransaction();
      final currentBalance = latestTx?.balanceAfter ?? 0;
      final newBalance = currentBalance + (_type == TransactionType.income ? amount : -amount);

      if (_type == TransactionType.expense && newBalance < 0) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Không đủ số dư. Số dư hiện tại: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(currentBalance)}'),
            backgroundColor: Colors.red,
          ));
        }
        setState(() => _isLoading = false);
        return;
      }

      final newTransaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        time: DateTime.now(),
        type: _type,
        bankName: _selectedPartnerBank!,
        accountNumber: _partnerAccountNumberController.text.trim(),
        destinationBankName: _selectedMyAccount!.bankName,
        destinationAccountNumber: _selectedMyAccount!.accountNumber,
        description: _getRandomItem(_descriptions),
        balanceAfter: newBalance,
        partnerAccountName: _getRandomItem(_partnerNames),
      );

      // --- BƯỚC 1: LƯU GIAO DỊCH VÀO DATABASE ---
      await DatabaseService.insertTransaction(newTransaction);

      // --- BƯỚC 2: YÊU CẦU BACKEND GỬI PUSH NOTIFICATION ---
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          print("CHUẨN BỊ GỌI API: Gửi đầy đủ dữ liệu cho backend...");

          // ⭐️ SỬA LỖI TẠI ĐÂY: Gửi đầy đủ 5 trường dữ liệu mà backend yêu cầu ⭐️
          await callBackendApi(
            '/api/notifications/send-test',
            {
              'userId': currentUser.uid,
              'amount': newTransaction.amount,
              'partnerName': newTransaction.partnerAccountName,
              'balanceAfter': newTransaction.balanceAfter,
              'destinationBankName': newTransaction.destinationBankName,
              // Đảm bảo trường này được gửi đi
              'transactionType': newTransaction.type == TransactionType.income ? 'income' : 'expense',
            },
            method: 'POST',
          );
          print("✅ Đã yêu cầu backend gửi Push Notification thành công.");
        } catch (e) {
          print("❌ Lỗi khi yêu cầu backend gửi Push Notification: $e");
          // Hiển thị lỗi này cho người dùng để dễ debug
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Lỗi gọi API thông báo: ${e.toString()}"),
                backgroundColor: Colors.orange)
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {required String labelText, Widget? prefixIcon}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccounts) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(20.0), child: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Đang tải...")])));
    }

    if (_linkedAccounts.isEmpty) {
      return AlertDialog(
        title: const Text('Chưa liên kết ngân hàng'),
        content: const Text('Bạn cần thêm tài khoản ngân hàng trước khi tạo giao dịch.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
          ElevatedButton(onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ManageLinkedAccountsScreen()
            ));
          }, child: const Text('Thêm tài khoản')),
        ],
      );
    }

    return AlertDialog(
      title: const Text("Tạo giao dịch giả lập", textAlign: TextAlign.center),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),

      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Tài khoản của bạn"),
              DropdownButtonFormField<BankAccountModel>(
                value: _selectedMyAccount,
                hint: const Text('Chọn tài khoản'),
                items: _linkedAccounts.map((account) {
                  return DropdownMenuItem<BankAccountModel>(
                    value: account,
                    child: Row(
                      children: [
                        BankLogo(bankName: account.bankName, size: 24),
                        const SizedBox(width: 10),
                        Expanded(child: Text("${account.bankName} (...${account.accountNumber.substring(account.accountNumber.length - 4)})", overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedMyAccount = value),
                validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
                decoration: _inputDecoration(context, labelText: 'Tài khoản nhận/trừ tiền', prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
                isExpanded: true,
              ),

              _buildSectionHeader("Thông tin bên còn lại"),
              DropdownButtonFormField2<String>(
                value: _selectedPartnerBank,
                isExpanded: true,
                decoration: _inputDecoration(context, labelText: 'Ngân hàng đối tác', prefixIcon: const Icon(Icons.account_balance_outlined)),
                hint: const Text('Chọn ngân hàng', style: TextStyle(fontSize: 14)),
                items: _vietnamBanks.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Row(children: [
                    BankLogo(bankName: item, size: 24),
                    const SizedBox(width: 10),
                    Text(item, style: const TextStyle(fontSize: 14)),
                  ]),
                )).toList(),
                validator: (value) => value == null ? 'Vui lòng chọn ngân hàng' : null,
                onChanged: (value) => setState(() => _selectedPartnerBank = value),
                buttonStyleData: const ButtonStyleData(padding: EdgeInsets.only(right: 8)),
                iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24),
                dropdownStyleData: DropdownStyleData(maxHeight: 250, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15))),
                menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                dropdownSearchData: DropdownSearchData(
                  searchController: _searchBankController,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    child: TextFormField(
                      expands: true, maxLines: null, controller: _searchBankController,
                      decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), hintText: 'Tìm kiếm ngân hàng...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) => item.value.toString().toLowerCase().contains(searchValue.toLowerCase()),
                ),
                onMenuStateChange: (isOpen) { if (!isOpen) _searchBankController.clear(); },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partnerAccountNumberController,
                decoration: _inputDecoration(context, labelText: "Số tài khoản đối tác", prefixIcon: const Icon(Icons.confirmation_number_outlined)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập STK' : null,
              ),

              _buildSectionHeader("Thông tin giao dịch"),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TransactionType>(
                  segments: const <ButtonSegment<TransactionType>>[
                    ButtonSegment<TransactionType>(value: TransactionType.income, label: Text('Nhận tiền'), icon: Icon(Icons.add)),
                    ButtonSegment<TransactionType>(value: TransactionType.expense, label: Text('Trừ tiền'), icon: Icon(Icons.remove)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() => _type = newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: _inputDecoration(context, labelText: 'Số tiền', prefixIcon: const Icon(Icons.attach_money)),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số tiền' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text("Hủy")),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _addTransaction,
          icon: _isLoading ? Container(width: 16, height: 16, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isLoading ? 'Đang tạo...' : 'Tạo giao dịch'),
        ),
      ],
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final int selectionIndex = newValue.selection.end;
    String newText = newValue.text.replaceAll('.', '');

    // Sửa lỗi: dùng tryParse để tránh crash app nếu người dùng dán text không phải số
    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'vi_VN');
    String formattedText = formatter.format(number);

    // Tính toán lại vị trí con trỏ sau khi format
    final newSelectionOffset = formattedText.length - (newValue.text.length - selectionIndex);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newSelectionOffset > 0 ? newSelectionOffset : formattedText.length),
    );
  }
}
