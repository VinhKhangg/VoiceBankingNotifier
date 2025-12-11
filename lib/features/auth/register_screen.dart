import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../repositories/auth_repository.dart';
import 'otp_verification_screen.dart';
import '../../core/widgets/app_background.dart';


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
  final phoneNumberController = TextEditingController();

  final AuthRepository _authRepo = AuthRepository();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _passwordStrengthText = "";
  double _passwordStrengthValue = 0;

  // Biến _backendUrl không còn cần thiết ở đây nữa

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    // ... (logic giữ nguyên)
    String strength;
    double value;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~%^(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    int score = [hasUppercase, hasLowercase, hasDigits, hasSpecial].where((e) => e).length;

    if (password.isEmpty) {
      strength = ""; value = 0;
    } else if (!hasMinLength) {
      strength = "Yếu"; value = 0.25;
    } else if (score <= 1) {
      strength = "Yếu"; value = 0.25;
    } else if (score == 2 || score == 3) {
      strength = "Trung bình"; value = 0.6;
    } else {
      strength = "Mạnh"; value = 1.0;
    }
    setState(() {
      _passwordStrengthText = strength;
      _passwordStrengthValue = value;
    });
  }

  // ✅ HÀM NÀY ĐÃ ĐƯỢC TÁI CẤU TRÚC
  Future<void> _handleRegisterFlow() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final phoneNumber = phoneNumberController.text.trim();

    // --- 1. Validate input fields (giữ nguyên) ---
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phoneNumber.isEmpty) {
      _showError("Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (password != confirmPassword) {
      _showError("Mật khẩu nhập lại không khớp");
      return;
    }
    if (password.length < 8) {
      _showError("Mật khẩu phải có ít nhất 8 ký tự");
      return;
    }
    if (_passwordStrengthValue < 0.6) {
      _showError("Mật khẩu quá yếu, vui lòng cải thiện");
      return;
    }

    setState(() => isLoading = true);

    // --- 2. Gửi OTP qua AuthRepository ---
    try {
      // Gọi hàm trong repository
      await _authRepo.sendRegistrationOtp(email);

      if (!mounted) return;

      _showSuccess("✅ Mã OTP đã được gửi đến email của bạn.");
      // Điều hướng đến màn hình OtpVerificationScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            purpose: OtpPurpose.registration,
            registrationData: {
              'name': name,
              'password': password,
              'phoneNumber': phoneNumber,
            },
          ),
        ),
      );
    } catch (e) {
      // Bắt lỗi được ném ra từ repository
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    // Toàn bộ phần build Widget của bạn giữ nguyên, không cần thay đổi gì.
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  prefixIcon: const Icon(Icons.phone_outlined),
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
      ),
    );
  }
}
