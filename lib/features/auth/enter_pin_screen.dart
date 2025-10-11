// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/features/auth/enter_pin_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../layout/main_layout.dart';
import 'reset_pin_screen.dart'; // 👈 THÊM IMPORT NÀY

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

  // ✅ Khi người dùng nhập số
  void _onKeyTap(String value) async {
    if (isLoading) return; // Không cho nhập khi đang xác thực
    if (pin.length < 6) {
      setState(() => pin += value);
      // Khi đủ 6 số => tự xác thực
      if (pin.length == 6) {
        await _verify();
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
      if (isError) setState(() => isError = false); // Xóa trạng thái lỗi khi người dùng sửa
    }
  }

  void _onReset() {
    setState(() {
      pin = "";
      isError = false;
    });
  }

  Future<void> _verify() async {
    setState(() => isLoading = true);
    final ok = await DatabaseService.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
      );
    } else {
      setState(() {
        isError = true;
        pin = ""; // Xóa PIN sai
      });
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Mã PIN không chính xác. Vui lòng thử lại."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  // 🔹 Hiển thị các chấm PIN
  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        // tạo hiệu ứng rung trái-phải khi nhập sai
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

  // 🔹 Nút bàn phím
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

                // 🔴 THÊM MỚI TẠI ĐÂY 🔴
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
                // 🔴 KẾT THÚC PHẦN THÊM MỚI 🔴

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
