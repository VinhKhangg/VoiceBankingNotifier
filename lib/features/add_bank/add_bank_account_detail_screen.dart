// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/add_bank/add_bank_account_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/bank_logo.dart';
import '../../../services/api_service.dart';

class AddBankAccountDetailScreen extends StatefulWidget {
  final String selectedBankName;

  const AddBankAccountDetailScreen({super.key, required this.selectedBankName});

  @override
  State<AddBankAccountDetailScreen> createState() =>
      _AddBankAccountDetailScreenState();
}

class _AddBankAccountDetailScreenState extends State<AddBankAccountDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _bankPhoneNumberController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _bankPhoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    // ... (Hàm này giữ nguyên)
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await callBackendApi('/api/auth/bank-accounts', {
        'bankName': widget.selectedBankName,
        'accountHolder': _holderController.text.trim(),
        'accountNumber': _numberController.text.trim(),
        'bankPhoneNumber': _bankPhoneNumberController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Liên kết tài khoản thành công!"),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Lỗi: ${e.toString()}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedBankName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: BankLogo(bankName: widget.selectedBankName, size: 60)),
              const SizedBox(height: 8),
              Text(
                "Nhập thông tin cho tài khoản ${widget.selectedBankName} của bạn.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ✅ Ô TÊN CHỦ TÀI KHOẢN ĐÃ NÂNG CẤP
              TextFormField(
                controller: _holderController,
                decoration: InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              // ✅ Ô SỐ TÀI KHOẢN ĐÃ NÂNG CẤP
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: 'Số tài khoản',
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              // ✅ Ô SỐ ĐIỆN THOẠI ĐÃ NÂNG CẤP
              TextFormField(
                controller: _bankPhoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại liên kết ngân hàng',
                  helperText: "Phải khớp với SĐT đã đăng ký với ứng dụng.",
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Không được để trống';
                  if (v.length < 10 || v.length > 11) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isSaving
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Hoàn tất liên kết',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
