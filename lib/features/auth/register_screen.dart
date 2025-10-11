// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/auth/register_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../repositories/auth_repository.dart';
import 'login_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _passwordStrengthText = "";
  double _passwordStrengthValue = 0;

  final String _backendUrl = 'http://10.0.2.2:3000';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    String strength;
    double value;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~%^(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;
    int score = [hasUppercase, hasLowercase, hasDigits, hasSpecial, hasMinLength].where((e) => e).length;

    if (password.isEmpty) {
      strength = "";
      value = 0;
    } else if (score <= 2) {
      strength = "Yếu";
      value = 0.25;
    } else if (score == 3 || score == 4) {
      strength = "Trung bình";
      value = 0.6;
    } else {
      strength = "Mạnh";
      value = 1.0;
    }

    setState(() {
      _passwordStrengthText = strength;
      _passwordStrengthValue = value;
    });
  }

  // ✅ HÀM ĐĂNG KÝ ĐÃ ĐƯỢC TÁI CẤU TRÚC ĐỂ AN TOÀN HƠN
  Future<void> _handleRegisterFlow() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // --- 1. Validate input fields (đồng bộ) ---
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("⚠️ Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (password != confirmPassword) {
      _showError("⚠️ Mật khẩu nhập lại không khớp");
      return;
    }
    if (_passwordStrengthValue < 0.6) {
      _showError("⚠️ Mật khẩu quá yếu, vui lòng cải thiện");
      return;
    }

    setState(() => isLoading = true);

    // --- 2. Gửi OTP và chờ người dùng nhập (bất đồng bộ) ---
    try {
      // 2.1. Gọi API gửi OTP (kiểm tra email tồn tại ở backend)
      final sendOtpResponse = await http.post(
        Uri.parse('$_backendUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (sendOtpResponse.statusCode != 200) {
        final errorBody = jsonDecode(sendOtpResponse.body);
        _showError("Lỗi gửi OTP: ${errorBody['message']}");
        setState(() => isLoading = false);
        return;
      }

      // 2.2. Hiển thị Dialog để người dùng nhập OTP
      final otp = await _showOtpDialog();
      if (otp == null || otp.isEmpty) {
        setState(() => isLoading = false);
        return; // Người dùng đã hủy
      }

      // 2.3. Người dùng đã nhập OTP -> Gọi API xác thực
      final verifyResponse = await http.post(
        Uri.parse('$_backendUrl/api/auth/verify-and-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'otp': otp,
        }),
      );

      if (!mounted) return;

      // --- 3. Cập nhật UI và điều hướng (đồng bộ, an toàn) ---
      setState(() {
        isLoading = false;
        final verifyBody = jsonDecode(verifyResponse.body);
        if (verifyResponse.statusCode == 201) {
          // Thành công
          _showSuccess("✅ Tạo tài khoản thành công! Vui lòng đăng nhập.");
          Navigator.pop(context); // Quay về màn hình đăng nhập
        } else {
          // Thất bại
          _showError("Lỗi: ${verifyBody['message']}");
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError("Lỗi kết nối đến server: $e");
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<String?> _showOtpDialog() {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Nhập mã OTP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Một mã OTP đã được gửi đến email của bạn. Vui lòng kiểm tra và nhập vào đây."),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "OTP",
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(otpController.text.trim());
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Image.asset('assets/logo.png', height: 140),
            const SizedBox(height: 8),
            const Text(
              "Tạo tài khoản mới",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Tên hiển thị",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              onChanged: _checkPasswordStrength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            if (_passwordStrengthText.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _passwordStrengthValue,
                backgroundColor: Colors.grey[300],
                color: _passwordStrengthValue <= 0.25 ? Colors.red : _passwordStrengthValue < 0.75 ? Colors.orange : Colors.green,
                minHeight: 5,
              ),
              const SizedBox(height: 4),
              Text(
                "Độ mạnh mật khẩu: $_passwordStrengthText",
                style: TextStyle(
                  fontSize: 14,
                  color: _passwordStrengthValue <= 0.25 ? Colors.red : _passwordStrengthValue < 0.75 ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRegisterFlow(),
              decoration: InputDecoration(
                labelText: "Nhập lại mật khẩu",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegisterFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Đăng ký", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản? "),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Đăng nhập",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
