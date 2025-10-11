import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Enum để quản lý các bước trong Dialog
enum ForgotPasswordStep { enterEmail, enterOtpAndPassword }

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordDialog({Key? key, this.initialEmail}) : super(key: key);

  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  // LƯU Ý: Đổi IP này sang IP mạng LAN của bạn khi build APK cho người khác dùng thử
  final String _backendUrl = 'http://10.0.2.2:3000';

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;

  String _passwordStrengthText = "";
  double _passwordStrengthValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
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

  // --- HÀM GỬI YÊU CẦU OTP ---
  Future<void> _sendOtpRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError("Vui lòng nhập một địa chỉ email hợp lệ.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/send-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (!mounted) return;
      final body = jsonDecode(response.body);
      _showSuccess(body['message']);
      setState(() => _currentStep = ForgotPasswordStep.enterOtpAndPassword);
    } catch (e) {
      _showError("Lỗi kết nối: Không thể kết nối đến máy chủ.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM ĐẶT LẠI MẬT KHẨU ---
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (otp.length != 6) {
      _showError("Mã OTP phải có 6 chữ số.");
      return;
    }
    if (_passwordStrengthValue < 0.6) {
      _showError("Mật khẩu mới quá yếu, vui lòng cải thiện.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/reset-password-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      );
      if (!mounted) return;
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccess(body['message']);
        Navigator.of(context).pop(); // Đóng Dialog khi thành công
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      _showError("Lỗi kết nối: Không thể kết nối đến máy chủ.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CÁC HÀM TIỆN ÍCH ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $message"), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ $message"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_currentStep == ForgotPasswordStep.enterEmail ? "Đặt lại mật khẩu" : "Xác thực & Đổi mật khẩu"),
      content: SingleChildScrollView(
        child: _buildStepContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : (_currentStep == ForgotPasswordStep.enterEmail ? _sendOtpRequest : _resetPassword),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_currentStep == ForgotPasswordStep.enterEmail ? "Gửi mã" : "Xác nhận"),
        ),
      ],
    );
  }

  // --- BUILD UI CHO TỪNG BƯỚC ---
  Widget _buildStepContent() {
    if (_currentStep == ForgotPasswordStep.enterEmail) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nhập email của bạn để nhận mã OTP đặt lại mật khẩu."),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
          ),
        ],
      );
    } else { // enterOtpAndPassword
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Vui lòng kiểm tra email và nhập mã OTP cùng mật khẩu mới vào đây."),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            // ✅ ĐÃ SỬA LỖI: CHỈ GIỮ LẠI MỘT THUỘC TÍNH DECORATION
            decoration: const InputDecoration(
              labelText: "Mã OTP",
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: "", // Ẩn bộ đếm ký tự
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: "Mật khẩu mới", prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true,
            onChanged: _checkPasswordStrength,
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
        ],
      );
    }
  }
}
