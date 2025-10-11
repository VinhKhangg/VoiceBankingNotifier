import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'create_pin_screen.dart';
import '../../layout/main_layout.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({Key? key}) : super(key: key);

  @override
  _ResetPinScreenState createState() => _ResetPinScreenState();
}

enum ResetPinStep { initial, otp, finished }

class _ResetPinScreenState extends State<ResetPinScreen> {
  final String _backendUrl = 'http://10.0.2.2:3000';
  bool _isLoading = false;
  ResetPinStep _currentStep = ResetPinStep.initial;

  final _otpController = TextEditingController();

  // ✅ HÀM GỬI OTP ĐÃ ĐƯỢC TÁI CẤU TRÚC ĐỂ AN TOÀN HƠN
  Future<void> _startPinResetFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showError("Không tìm thấy thông tin người dùng.");
      return;
    }

    setState(() => _isLoading = true);

    String? errorMessage;
    bool success = false;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/send-pin-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        success = true;
      } else {
        errorMessage = "Lỗi: ${body['message']}";
      }
    } catch (e) {
      errorMessage = "Lỗi kết nối: $e";
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _showSuccess("Đã gửi mã OTP đến email của bạn.");
        _currentStep = ResetPinStep.otp;
      } else {
        _showError(errorMessage ?? "Đã có lỗi xảy ra.");
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _showError("Phiên đăng nhập đã hết hạn, vui lòng thử lại.");
      return;
    }
    if (otp.length != 6) {
      _showError("Mã OTP phải có 6 chữ số.");
      return;
    }

    setState(() => _isLoading = true);

    String? errorMessage;
    bool isOtpVerified = false;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email!, 'otp': otp}),
      );
      if (response.statusCode == 200) {
        isOtpVerified = true;
      } else {
        final body = jsonDecode(response.body);
        errorMessage = "Lỗi: ${body['message']}";
      }
    } catch (e) {
      errorMessage = "Lỗi kết nối: $e";
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (isOtpVerified) {
      _showSuccess("Xác thực thành công! Vui lòng tạo mã PIN mới.");

      // ✅ SỬA LOGIC Ở ĐÂY: Dùng push và chờ kết quả
      final bool? pinChangedSuccessfully = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const CreatePinScreen(isChangingPin: true),
        ),
      );

      // Sau khi màn hình CreatePinScreen đóng và trả về kết quả
      if (pinChangedSuccessfully == true && mounted) {
        // Nếu là từ màn hình "Quên PIN", ta cần điều hướng vào app
        // Chúng ta có thể pop về màn hình trước (EnterPinScreen) rồi push vào MainLayout
        int count = 0;
        Navigator.of(context).popUntil((route) {
          // Nếu đang ở màn hình EnterPinScreen hoặc AccountScreen, pop nó đi
          if (route.settings.name == '/EnterPinScreen' || route.settings.name == '/AccountScreen') {
            return true;
          }
          count++;
          // Pop an toàn, tránh pop quá đà
          return count >= 2;
        });
        // Hoặc đơn giản là điều hướng thẳng vào app và xóa hết stack cũ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
              (route) => false,
        );
      }
    } else {
      _showError(errorMessage ?? "Đã có lỗi xảy ra.");
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
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi mã PIN")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    switch (_currentStep) {
      case ResetPinStep.initial:
        return _buildInitialStep();
      case ResetPinStep.otp:
        return _buildOtpStep();
      case ResetPinStep.finished:
        return const Text("Đổi PIN thành công!");
    }
  }

  Widget _buildInitialStep() {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "email của bạn";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pin_invoke_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          "Xác nhận đổi mã PIN",
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
          child: const Text("Gửi mã OTP"),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Text("Nhập mã OTP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(labelText: "OTP", counterText: ""),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Xác nhận và Tạo PIN mới"),
        ),
      ],
    );
  }
}
