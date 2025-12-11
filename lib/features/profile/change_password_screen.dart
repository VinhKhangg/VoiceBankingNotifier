// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/profile/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/logout_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _passwordStrengthText = "";
  double _passwordStrengthValue = 0;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    // ... (Hàm này giữ nguyên)
    String strength;
    double value;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~%^(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    int score =
        [hasUppercase, hasLowercase, hasDigits, hasSpecial].where((e) => e).length;

    if (password.isEmpty) {
      strength = "";
      value = 0;
    } else if (!hasMinLength) {
      strength = "Yếu (chưa đủ 8 ký tự)";
      value = 0.25;
    } else {
      if (score <= 1) {
        strength = "Yếu";
        value = 0.4;
      } else if (score == 2 || score == 3) {
        strength = "Trung bình";
        value = 0.7;
      } else {
        strength = "Mạnh";
        value = 1.0;
      }
    }

    setState(() {
      _passwordStrengthText = strength;
      _passwordStrengthValue = value;
    });
  }

  Future<void> _changePassword() async {
    // ... (Hàm này giữ nguyên)
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_passwordStrengthValue < 0.6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Mật khẩu mới quá yếu, vui lòng cải thiện."),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw Exception("Không tìm thấy người dùng.");
      }
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text("✅ Đổi mật khẩu thành công! Vui lòng đăng nhập lại."),
              backgroundColor: Colors.green),
        );
        LogoutService.logout(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Đã xảy ra lỗi.";
      if (e.code == 'invalid-credential') {
        errorMessage = "Mật khẩu hiện tại không chính xác.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Mật khẩu mới quá yếu.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Ô MẬT KHẨU HIỆN TẠI ĐÃ NÂNG CẤP
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
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
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 16),

              // ✅ Ô MẬT KHẨU MỚI ĐÃ NÂNG CẤP
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: _checkPasswordStrength,
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới",
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
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
                validator: (v) {
                  if (v!.isEmpty) return "Không được để trống";
                  if (v.length < 8) return "Mật khẩu phải có ít nhất 8 ký tự";
                  return null;
                },
              ),

              if (_passwordStrengthText.isNotEmpty) ...[
                //... (widget độ mạnh mật khẩu giữ nguyên)
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _passwordStrengthValue,
                  backgroundColor: Colors.grey[300],
                  color: _passwordStrengthValue <= 0.4
                      ? Colors.red
                      : _passwordStrengthValue < 0.7
                      ? Colors.orange
                      : Colors.green,
                  minHeight: 5,
                ),
                const SizedBox(height: 4),
                Text(
                  "Độ mạnh: $_passwordStrengthText",
                  style: TextStyle(
                    fontSize: 14,
                    color: _passwordStrengthValue <= 0.4
                        ? Colors.red
                        : _passwordStrengthValue < 0.7
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ✅ Ô XÁC NHẬN MẬT KHẨU ĐÃ NÂNG CẤP
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu mới",
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
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
                validator: (v) {
                  if (v!.isEmpty) return "Không được để trống";
                  if (v != _newPasswordController.text)
                    return "Mật khẩu xác nhận không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text("Xác nhận đổi mật khẩu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
