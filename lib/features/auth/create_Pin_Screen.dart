import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../../services/api_service.dart';


// ✅ Enum để quản lý các bước tạo PIN
enum CreatePinStep { create, confirm }

class CreatePinScreen extends StatefulWidget {
  final bool isChangingPin;

  const CreatePinScreen({
    Key? key,
    this.isChangingPin = false,
  }) : super(key: key);

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> with SingleTickerProviderStateMixin {
  CreatePinStep _currentStep = CreatePinStep.create;
  String _firstPin = ""; // Lưu mã PIN bước 1
  String _secondPin = ""; // Lưu mã PIN bước 2 (xác nhận)
  bool _isLoading = false;
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

  // ✅ Xử lý khi người dùng nhấn phím số
  void _onKeyTap(String value) async {
    if (_isLoading) return;

    if (_currentStep == CreatePinStep.create) {
      if (_firstPin.length < 6) {
        setState(() => _firstPin += value);
        if (_firstPin.length == 6) {
          // Tự động chuyển sang bước xác nhận
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) setState(() => _currentStep = CreatePinStep.confirm);
          });
        }
      }
    } else {
      if (_secondPin.length < 6) {
        setState(() => _secondPin += value);
        if (_secondPin.length == 6) {
          await _savePin();
        }
      }
    }
  }

  // ✅ Xử lý khi nhấn nút xóa
  void _onDelete() {
    if (_isLoading) return;

    if (_currentStep == CreatePinStep.create) {
      if (_firstPin.isNotEmpty) {
        setState(() => _firstPin = _firstPin.substring(0, _firstPin.length - 1));
      }
    } else {
      if (_secondPin.isNotEmpty) {
        setState(() => _secondPin = _secondPin.substring(0, _secondPin.length - 1));
      }
    }
  }

  // ✅ Xử lý khi nhấn nút quay lại
  void _onBack() {
    if (_currentStep == CreatePinStep.confirm) {
      setState(() {
        _currentStep = CreatePinStep.create;
        _firstPin = "";
        _secondPin = "";
      });
    } else {
      if (widget.isChangingPin) {
        Navigator.of(context).pop();
      }
    }
  }

  // ✅✅✅ HÀM _savePin ĐÃ ĐƯỢC CẬP NHẬT LOGIC
  Future<void> _savePin() async {
    if (_firstPin != _secondPin) {
      _shakeController.forward(from: 0);
      _showError("Mã PIN không khớp. Vui lòng thử lại.");
      setState(() {
        _firstPin = "";
        _secondPin = "";
        _currentStep = CreatePinStep.create;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi API backend để thiết lập PIN
      await callBackendApi('/api/auth/set-pin', {'newPin': _firstPin});

      if (!mounted) return;

      if (widget.isChangingPin) {
        _showSuccess("Đổi mã PIN thành công!");
        Navigator.of(context).pop(true);
      } else {
        // Đây là lần tạo PIN đầu tiên
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_pin_entry_pending', true); // Đặt cờ

        _showSuccess("Tạo mã PIN thành công! Vui lòng đăng nhập lại bằng PIN.");

        // Điều hướng về AuthRouter để nó tự quyết định đưa đến EnterPinScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthRouter()),
              (route) => false,
        );
      }
    } catch (e) {
      _showError("Lỗi khi lưu PIN: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade600),
    );
  }

  // --- WIDGETS ---
  // (Toàn bộ phần Widget build... của bạn được giữ nguyên)
  Widget _buildPinDots(String pin) {
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
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  color: index < pin.length ? Colors.blue.shade700 : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadButton(
      String label, {
        VoidCallback? onTap,
        required double size,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap ?? () => _onKeyTap(label),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionalKey(
      Widget child, {
        VoidCallback? onTap,
        required double size,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<Widget> children, {double vPadding = 6}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Tính kích thước nút tự co theo màn hình để toàn cụm gọn lại
    final width = MediaQuery.of(context).size.width;
    // 24: padding hai bên, 32: khoảng trống dự phòng, chia 3 cột
    final double buttonSize = math.min(76, (width - 24 * 2 - 32) / 3);

    final keypad = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isChangingPin
              ? "Đổi mã PIN"
              : (_currentStep == CreatePinStep.create ? "Tạo mã PIN" : "Xác nhận lại mã PIN"),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        leading: widget.isChangingPin ? BackButton(onPressed: _onBack) : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            // ❗️Bỏ spaceBetween để bàn phím không bị dồn xuống đáy
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CỤM TRÊN: Tiêu đề + mô tả + chấm PIN ---
              Column(
                children: [
                  const SizedBox(height: 16), // trước 40
                  Text(
                    _currentStep == CreatePinStep.create
                        ? "Tạo mã PIN gồm 6 số"
                        : "Xác nhận lại mã PIN",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8), // trước 12
                  Text(
                    "Mã PIN này sẽ được dùng để đăng nhập\nvà xác thực.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24), // trước 40
                  _buildPinDots(_currentStep == CreatePinStep.create ? _firstPin : _secondPin),
                ],
              ),

              const SizedBox(height: 120), //khoảng cách nhỏ giữa chữ & bàn phím

              // --- CỤM DƯỚI: Bàn phím số ---
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  children: [
                    ...keypad.map((row) {
                      return _buildKeypadRow(
                        row
                            .map((key) => _buildKeypadButton(key, size: buttonSize))
                            .toList(),
                      );
                    }),

                    // Hàng cuối cùng: Back / 0 / Delete
                    _buildKeypadRow([
                      _buildFunctionalKey(
                        _currentStep == CreatePinStep.confirm
                            ? const Icon(Icons.arrow_back, color: Colors.black54)
                            : const SizedBox.shrink(),
                        onTap: _currentStep == CreatePinStep.confirm ? _onBack : null,
                        size: buttonSize,
                      ),
                      _buildKeypadButton("0", size: buttonSize),
                      _buildFunctionalKey(
                        const Icon(Icons.backspace_outlined, color: Colors.black54),
                        onTap: _onDelete,
                        size: buttonSize,
                      ),
                    ]),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
