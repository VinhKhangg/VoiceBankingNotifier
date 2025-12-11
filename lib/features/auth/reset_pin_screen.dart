import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'otp_verification_screen.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({Key? key}) : super(key: key);

  @override
  _ResetPinScreenState createState() => _ResetPinScreenState();
}

// Enum ResetPinStep sẽ không còn cần thiết nữa vì đã chuyển logic OTP sang OtpVerificationScreen
// enum ResetPinStep { initial, otp, finished }

class _ResetPinScreenState extends State<ResetPinScreen> {
  final String _backendUrl = 'http://10.0.2.2:3000';
  bool _isLoading = false;
  // ResetPinStep _currentStep = ResetPinStep.initial; // Biến này không còn cần thiết

  // Hàm _otpController cũng không còn cần thiết ở đây nữa vì đã chuyển sang OtpVerificationScreen
  // final _otpController = TextEditingController();

  // ✅ HÀM GỬI OTP ĐÃ ĐƯỢC TÁI CẤU TRÚC VÀ ĐIỀU HƯỚNG ĐẾN OTP SCREEN
  Future<void> _startPinResetFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showError("Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/send-pin-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccess("Đã gửi mã OTP đến email của bạn.");
        // Điều hướng đến màn hình nhập OTP chung
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: user.email!,
              purpose: OtpPurpose.pinReset,
            ),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        _showError("Lỗi: ${body['message']}");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm _verifyOtp() đã bị loại bỏ vì không còn dùng ở đây nữa

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
    return Scaffold(
      appBar: AppBar(title: const Text("Đặt lại mã PIN")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // Chỉ hiển thị nội dung khởi tạo, không có các bước khác
          child: _buildInitialStep(),
        ),
      ),
    );
  }

  Widget _buildInitialStep() {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "email của bạn";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pin_invoke_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          "Xác nhận đặt lại mã PIN",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Một mã OTP sẽ được gửi đến email đã đăng ký của bạn:\n$userEmail",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _startPinResetFlow,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Gửi mã OTP"),
        ),
      ],
    );
  }
}