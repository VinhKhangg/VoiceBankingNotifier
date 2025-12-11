import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../layout/main_layout.dart';
import 'reset_pin_screen.dart';
import '../../../services/logout_service.dart';
import '../../../services/api_service.dart';
import '../add_bank/manage_linked_accounts_screen.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({Key? key}) : super(key: key);

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen>
    with SingleTickerProviderStateMixin {
  String pin = "";
  bool isLoading = false;
  bool isError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) async {
    if (isLoading) return;
    if (pin.length < 6) {
      setState(() => pin += value);
      if (pin.length == 6) {
        await _verify();
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
      if (isError) setState(() => isError = false);
    }
  }

  void _onReset() {
    setState(() {
      pin = "";
      isError = false;
    });
  }

  // HÀM NÀY ĐÃ ĐƯỢC CẬP NHẬT LOGIC HOÀN CHỈNH
  Future<void> _verify() async {
    setState(() => isLoading = true);
    try {
      final response = await callBackendApi('/api/auth/verify-pin', {'pinAttempt': pin});
      final bool verified = response['verified'] ?? false;

      if (!mounted) return;

      if (verified) {
        final prefs = await SharedPreferences.getInstance();
        // Kiểm tra xem có phải là lần thiết lập đầu tiên không
        final bool isInitialSetup = prefs.getBool('first_pin_entry_pending') ?? false;

        if (isInitialSetup) {
          // Nếu đúng là lần đầu, xóa cờ đi để lần sau không vào đây nữa
          await prefs.remove('first_pin_entry_pending');
          // Và điều hướng đến màn hình liên kết tài khoản ngân hàng
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ManageLinkedAccountsScreen(isInitialSetup: true),
            ),
                (route) => false,
          );
        } else {
          // Nếu không phải lần đầu, vào thẳng màn hình chính
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
                (route) => false,
          );
        }

      } else {
        // Xử lý khi PIN sai
        setState(() {
          isError = true;
          pin = "";
        });
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Mã PIN không chính xác. Vui lòng thử lại."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isError = true;
          pin = "";
        });
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Lỗi xác thực PIN: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  // --- WIDGETS ---
  // (Phần còn lại của file không thay đổi, bạn có thể giữ nguyên)
  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset = math.sin(_shakeController.value * math.pi * 6) * 10;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isError ? Colors.red.shade700 : Colors.grey.shade400),
                  color: index < pin.length
                      ? (isError ? Colors.red : Colors.blue.shade700)
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, {VoidCallback? onTap, double size = 80}) {
    final bool isAction = label == "Reset" || label == "⌫";
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: !isAction
              ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == "Reset" ? 16 : 28,
              fontWeight: isAction ? FontWeight.w500 : FontWeight.bold,
              color: label == "Reset"
                  ? Colors.grey[600]
                  : label == "⌫"
                  ? Colors.grey[800]
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keypad = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["Reset", "0", "⌫"],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Vui lòng nhập PIN",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildPinDots(),
                const SizedBox(height: 50),
                Column(
                  children: keypad.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((key) {
                          if (key == "Reset") {
                            return _buildButton(key, onTap: _onReset, size: 70);
                          } else if (key == "⌫") {
                            return _buildButton(key, onTap: _onDelete, size: 70);
                          } else {
                            return _buildButton(key, onTap: () => _onKeyTap(key));
                          }
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  )
                else
                  const SizedBox(height: 24 + 16.0), // Giữ khoảng trống tương đương

                TextButton(
                  onPressed: () => LogoutService.logout(context),
                  child: const Text(
                    "Quay về đăng nhập",
                    style: TextStyle(
                      color: Colors.grey, // Dùng màu xám cho đỡ nổi bật
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPinScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Quên mã PIN?",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
