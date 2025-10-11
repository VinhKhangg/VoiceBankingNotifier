import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../layout/main_layout.dart';

class CreatePinScreen extends StatefulWidget {
  // BƯỚC 1: Đảm bảo tham số này tồn tại
  final bool isChangingPin;

  // BƯỚC 2: Đảm bảo constructor nhận tham số này
  const CreatePinScreen({
    Key? key,
    this.isChangingPin = false, // Mặc định là luồng tạo PIN lần đầu
  }) : super(key: key);

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  bool isLoading = false;

  Future<void> _savePin() async {
    // ... (phần kiểm tra pin giữ nguyên)
    final pin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();

    if (pin.length != 6 || confirm.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ PIN phải đủ 6 số")),
      );
      return;
    }
    if (pin != confirm) {
      pinController.clear();
      confirmPinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ PIN nhập lại không khớp")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await DatabaseService.savePin(pin);

      if (!mounted) return;

      if (widget.isChangingPin) {
        // ✅ NẾU LÀ LUỒNG ĐỔI PIN
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đổi mã PIN thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        // ✅ TRẢ VỀ GIÁ TRỊ `true` KHI ĐÓNG MÀN HÌNH
        Navigator.of(context).pop(true);
      } else {
        // Nếu là luồng "tạo PIN lần đầu"
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi lưu PIN: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Widget _buildPinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      obscuringCharacter: "●",
      maxLength: 6,
      autofocus: label == "PIN" && !widget.isChangingPin,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 10,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: "••••••",
        counterText: "",
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onSubmitted: (_) {
        if (label == "Nhập lại PIN") _savePin();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChangingPin ? "Tạo mã PIN mới" : "Tạo mã PIN"),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: widget.isChangingPin,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              widget.isChangingPin
                  ? "🔐 Nhập mã PIN mới gồm 6 số"
                  : "🔐 Nhập mã PIN 6 số để bảo vệ tài khoản",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildPinField(pinController, "PIN"),
            const SizedBox(height: 16),
            _buildPinField(confirmPinController, "Nhập lại PIN"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Xác nhận",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
