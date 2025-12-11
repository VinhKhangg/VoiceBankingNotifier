// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/add_bank/manage_linked_accounts_screen.dart

import 'package:flutter/material.dart';
import '../../../models/bank_account_model.dart';
import '../../../services/api_service.dart';
import '../../../core/widgets/bank_logo.dart';
import 'select_bank_for_linking_screen.dart';
import '../../../layout/main_layout.dart';

class ManageLinkedAccountsScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ManageLinkedAccountsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<ManageLinkedAccountsScreen> createState() =>
      _ManageLinkedAccountsScreenState();
}

class _ManageLinkedAccountsScreenState extends State<ManageLinkedAccountsScreen> {
  List<BankAccountModel> _linkedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinkedAccounts();
  }

  Future<void> _fetchLinkedAccounts() async {
    // ... (Hàm này giữ nguyên)
    setState(() => _isLoading = true);
    try {
      final responseData = await callBackendApi('/api/auth/bank-accounts', {}, method: 'GET');
      if (!mounted) return;
      final List<dynamic> accountsJson = responseData as List<dynamic>;
      setState(() {
        _linkedAccounts = accountsJson.map((json) => BankAccountModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Lỗi khi tải danh sách tài khoản: ${e.toString()}");
      }
    }
  }

  Future<void> _navigateAndRefresh() async {
    // ... (Hàm này giữ nguyên)
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SelectBankForLinkingScreen(
        linkedBankNames: _linkedAccounts.map((e) => e.bankName).toList(),
      )),
    );
    if (result == true) {
      await _fetchLinkedAccounts();
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    // ... (Hàm này giữ nguyên)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa liên kết tài khoản này?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await callBackendApi('/api/auth/bank-accounts/$accountId', {}, method: 'DELETE');
      _showSuccess('Xóa liên kết thành công!');
      await _fetchLinkedAccounts();
    } catch (e) {
      _showError("Lỗi khi xóa tài khoản: ${e.toString()}");
    }
  }

  void _showError(String message) { /* ... giữ nguyên ... */
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
  void _showSuccess(String message) { /* ... giữ nguyên ... */
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý liên kết'),
        automaticallyImplyLeading: !widget.isInitialSetup,
        actions: [
          if (widget.isInitialSetup)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainLayout()),
                      (route) => false,
                );
              },
              child: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.bold)),
            )
        ],
      ),
      // ✅ BƯỚC 1: XÓA HOÀN TOÀN 'floatingActionButton'
      // floatingActionButton: FloatingActionButton.extended( ... ),

      //...
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchLinkedAccounts,
        // ✅ SỬ DỤNG ListView hoặc SingleChildScrollView để chứa các widget con
        child: ListView(
          padding: const EdgeInsets.all(8.0), // Thêm padding chung cho toàn bộ trang
          children: [
            // --- DANH SÁCH TÀI KHOẢN ĐÃ LIÊN KẾT ---
            if (_linkedAccounts.isEmpty)
              Padding(
                // Thêm padding trên để không bị dính vào AppBar
                padding: const EdgeInsets.only(top: 100.0, bottom: 20.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Bạn chưa liên kết tài khoản nào.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      if(widget.isInitialSetup) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Bấm nút ở dưới để bắt đầu thêm liên kết.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ]
                    ],
                  ),
                ),
              )
            else
            // Dùng Column vì nó đã nằm trong ListView có thể cuộn
              Column(
                children: _linkedAccounts.map((account) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: BankLogo(bankName: account.bankName, size: 40),
                      title: Text(account.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('**** **** ${account.accountNumber.length > 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: "Xóa liên kết",
                        onPressed: () => _deleteAccount(account.id),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // --- NÚT THÊM LIÊN KẾT MỚI ---
            Padding(
              // Thêm một chút padding trên để tạo khoảng cách với danh sách
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateAndRefresh,
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm liên kết ngân hàng mới"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
