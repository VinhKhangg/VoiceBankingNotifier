// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/auth/otp_verification_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'create_pin_screen.dart';
import '../../main.dart';

enum OtpPurpose { registration, passwordReset, pinReset }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  // Dữ liệu bổ sung cho việc đăng ký
  final Map<String, String>? registrationData;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.purpose,
    this.registrationData,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final String _backendUrl = 'http://10.0.2.2:3000';
  bool _isLoading = false;

  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _resendTimer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    //_focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _countdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) return;

    String endpoint;
    switch (widget.purpose) {
      case OtpPurpose.registration:
        endpoint = '/api/auth/send-otp';
        break;
      case OtpPurpose.passwordReset:
        endpoint = '/api/auth/send-password-reset-otp';
        break;
      case OtpPurpose.pinReset:
        endpoint = '/api/auth/send-pin-reset-otp';
        break;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSuccess("Đã gửi lại mã OTP đến email của bạn.");
        _startResendTimer();
      } else {
        _showError(
            "Lỗi khi gửi lại mã: ${jsonDecode(response.body)['message']}");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _pinController.text;
    if (otp.length != 6) {
      _showError("Vui lòng nhập đủ 6 số OTP.");
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    switch (widget.purpose) {
      case OtpPurpose.registration:
        await _handleRegistrationVerification(otp);
        break;
      case OtpPurpose.passwordReset:
        await _handlePasswordResetVerification(otp);
        break;
      case OtpPurpose.pinReset:
        await _handlePinResetVerification(otp);
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegistrationVerification(String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/verify-and-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': widget.registrationData!['password'],
          'name': widget.registrationData!['name'],
          'otp': otp,
          // ✅✅✅ SỬA LỖI: BỔ SUNG 'phoneNumber' VÀO REQUEST ✅✅✅
          'phoneNumber': widget.registrationData!['phoneNumber'],
        }),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 201) {
        _showSuccess("✅ Tạo tài khoản thành công! Vui lòng đăng nhập.");
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _handleVerificationError(body['message']);
      }
    } catch (e) {
      _handleVerificationError("Lỗi kết nối: $e");
    }
  }

  Future<void> _handlePasswordResetVerification(String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/verify-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );

      final body = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final verificationToken = body['verificationToken'];
        // Trả token về cho màn hình ForgotPasswordScreen
        Navigator.of(context).pop(verificationToken);
      } else {
        _handleVerificationError(body['message']);
      }
    } catch (e) {
      _handleVerificationError("Lỗi kết nối: $e");
    }
  }

  Future<void> _handlePinResetVerification(String otp) async {
    try {
      // Endpoint này đúng theo thiết kế của backend
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccess("Xác thực thành công! Vui lòng tạo mã PIN mới.");

        // Điều hướng đến màn hình tạo PIN mới
        final pinChanged = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => const CreatePinScreen(isChangingPin: true)),
        );

        // Sau khi đổi PIN thành công, quay về AuthRouter để kiểm tra lại
        // và điều hướng đến MainLayout hoặc EnterPinScreen nếu cần
        if (pinChanged == true && mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthRouter())
          );
        } else {
          // Nếu người dùng nhấn back trên màn hình tạo PIN, chỉ cần quay lại
          Navigator.of(context).pop();
        }

      } else {
        final body = jsonDecode(response.body);
        _handleVerificationError(body['message']);
      }
    } catch (e) {
      _handleVerificationError("Lỗi kết nối: $e");
    }
  }

  // Xóa _pinController ngay lập tức khi có lỗi
  void _handleVerificationError(String message) {
    if (mounted) {
      // Xóa OTP ngay lập tức khi có lỗi
      _pinController.clear();
      _focusNode.requestFocus();
      _showError(message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message), backgroundColor: Colors.red.shade600));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message), backgroundColor: Colors.green.shade600));
  }

  // Phần build() không cần thay đổi
  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Xác thực OTP"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Nhập mã xác thực đã được gửi đến email",
                      style:
                      TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 40),
                    Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: Colors.blue),
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                      ),
                      onCompleted: (pin) {
                        _verifyOtp();
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                            : const Text("Xác nhận", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Chưa nhận được mã? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        _canResend
                            ? GestureDetector(
                          onTap: _resendOtp,
                          child: const Text(
                            "Gửi lại",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : Text(
                          "Gửi lại sau 0:${_countdown.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
