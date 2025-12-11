import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/otp_verification_screen.dart';

enum ForgotPasswordStep {
  enterEmail, // Bước nhập email
  enterNewPassword, // Bước nhập mật khẩu mới
}

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final String _backendUrl = 'http://10.0.2.2:3000';

  // Controller cho các bước
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;

  // Biến để lưu token sau khi xác thực OTP thành công
  String? _verificationToken;

  // State cho UI nhập mật khẩu
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC CHO CÁC HÀNH ĐỘNG ---

  // Bước 1: Gửi OTP và chờ kết quả từ OtpVerificationScreen
  Future<void> _handleSendOtpAndNavigate() async {
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

      // Điều hướng đến OtpVerificationScreen và chờ kết quả (token) trả về
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            purpose: OtpPurpose.passwordReset,
          ),
        ),
      );

      // Nếu người dùng xác thực OTP thành công, `result` sẽ là `verificationToken`
      if (result != null && result.isNotEmpty) {
        setState(() {
          _verificationToken = result;
          _currentStep = ForgotPasswordStep.enterNewPassword;
        });
      }

    } catch (e) {
      _showError("Lỗi kết nối đến máy chủ.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bước 2: Đặt lại mật khẩu (được gọi từ bước nhập mật khẩu mới)
  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showError("Mật khẩu mới phải có ít nhất 6 ký tự."); return;
    }
    if (newPassword != confirmPassword) {
      _showError("Mật khẩu nhập lại không khớp."); return;
    }
    if (_passwordStrengthValue < 0.6) {
      _showError("Mật khẩu quá yếu, vui lòng cải thiện."); return;
    }
    if (_verificationToken == null) {
      _showError("Token không hợp lệ. Vui lòng thử lại.");
      setState(() => _currentStep = ForgotPasswordStep.enterEmail);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/reset-password-with-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'verificationToken': _verificationToken,
          'newPassword': newPassword,
        }),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSuccess(body['message']);
        Navigator.of(context).popUntil((route) => route.isFirst); // Về màn hình đăng nhập
      } else {
        _showError(body['message']);
        setState(() => _currentStep = ForgotPasswordStep.enterEmail);
      }
    } catch (e) {
      _showError("Lỗi kết nối đến máy chủ.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic đo độ mạnh mật khẩu (giữ nguyên)
  void _checkPasswordStrength(String password) {
    // ... (code y hệt như cũ)
    String strength; double value;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~%^(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;
    int score = [hasUppercase, hasLowercase, hasDigits, hasSpecial, hasMinLength].where((e) => e).length;

    if (password.isEmpty) { strength = ""; value = 0;}
    else if (score <= 2) { strength = "Yếu"; value = 0.25; }
    else if (score <= 4) { strength = "Trung bình"; value = 0.6; }
    else { strength = "Mạnh"; value = 1.0; }
    setState(() { _passwordStrengthText = strength; _passwordStrengthValue = value; });
  }

  void _showError(String message) { /* ... giữ nguyên ... */ }
  void _showSuccess(String message) { /* ... giữ nguyên ... */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == ForgotPasswordStep.enterEmail
            ? "Đặt lại mật khẩu"
            : "Tạo mật khẩu mới"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () {
            if (_currentStep == ForgotPasswordStep.enterNewPassword) {
              setState(() => _currentStep = ForgotPasswordStep.enterEmail);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  // Widget để hiển thị nội dung tùy theo bước hiện tại
  Widget _buildStepContent() {
    if (_currentStep == ForgotPasswordStep.enterEmail) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Nhập email của bạn để nhận mã OTP đặt lại mật khẩu.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, autofocus: true),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _handleSendOtpAndNavigate, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Gửi mã"))),
        ],
      );
    } else { // enterNewPassword
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Xác thực thành công! Vui lòng tạo mật khẩu mới.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextField(controller: _newPasswordController, obscureText: _obscureNewPassword, onChanged: _checkPasswordStrength, decoration: InputDecoration(labelText: "Mật khẩu mới", prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword)))),
          if (_passwordStrengthText.isNotEmpty) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _passwordStrengthValue, backgroundColor: Colors.grey[300], color: _passwordStrengthValue <= 0.25 ? Colors.red : _passwordStrengthValue < 0.75 ? Colors.orange : Colors.green),
            const SizedBox(height: 4),
            Text("Độ mạnh: $_passwordStrengthText", style: TextStyle(color: _passwordStrengthValue <= 0.25 ? Colors.red : _passwordStrengthValue < 0.75 ? Colors.orange : Colors.green)),
          ],
          const SizedBox(height: 16),
          TextField(controller: _confirmPasswordController, obscureText: _obscureConfirmPassword, decoration: InputDecoration(labelText: "Xác nhận mật khẩu", prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _handleResetPassword, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Xác nhận"))),
        ],
      );
    }
  }
}

