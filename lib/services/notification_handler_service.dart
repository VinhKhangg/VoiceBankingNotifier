// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/services/notification_handler_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationHandlerService {
  static Future<void> handleTransactionFromData(Map<String, dynamic> data) async {
    try {
      // --- Parse dữ liệu từ map ---
      final double amount = double.tryParse(data['amount'] ?? '0') ?? 0;
      final double balanceAfter = double.tryParse(data['balanceAfter'] ?? '0') ?? 0;
      //final String partnerName = data['partnerName'] ?? 'Không rõ';
      final String transactionTypeStr = data['transactionType'] ?? 'income';
      final bool isIncome = transactionTypeStr == 'income';
      final String destinationBankName = data['destinationBankName'] ?? 'Không rõ';

      // --- Tạo nội dung thông báo ---
      final formattedAmount = NumberFormat("#,###", "vi_VN").format(amount.toInt());
      final formattedBalance = NumberFormat("#,###", "vi_VN").format(balanceAfter.toInt());

      final String notificationTitle = "Thông báo Voice Banking";
      final String notificationBody;

      if (isIncome) {
        notificationBody = "Phát hiện biến động số dư +${formattedAmount}đ từ tài khoản liên kết ${destinationBankName}. Số dư cuối: ${formattedBalance}đ.";
      } else {
        notificationBody = "Phát hiện biến động số dư -${formattedAmount}đ từ tài khoản liên kết ${destinationBankName}. Số dư cuối: ${formattedBalance}đ.";
      }

      // --- LOGIC XỬ LÝ MỚI ---
      if (isIncome) {
        // --- VỚI GIAO DỊCH NHẬN TIỀN: HIỂN THỊ VÀ NÓI ---

        // ✅✅✅ THAY ĐỔI TẠI ĐÂY: Dùng `destinationBankName` thay cho `partnerName` trong câu nói ✅✅✅
        final String voiceMessage = "Bạn vừa nhận được $formattedAmount đồng từ tài khoản liên kết ${destinationBankName}";

        // 2. Hiển thị thông báo (với âm thanh mặc định của kênh)
        await NotificationService.show(notificationTitle, notificationBody);

        // 3. Phát âm thanh và giọng nói tùy chỉnh
        await _speak(voiceMessage);

      } else {
        // --- VỚI GIAO DỊCH TRỪ TIỀN: CHỈ HIỂN THỊ IM LẶNG ---
        await NotificationService.show(notificationTitle, notificationBody, silent: true);
      }

    } catch (e) {
      print("Lỗi trong NotificationHandlerService.handleTransactionFromData: $e");
    }
  }

  /// Hàm private để phát âm thanh và giọng nói (giữ nguyên).
  static Future<void> _speak(String text) async {
    final flutterTts = FlutterTts();
    final player = AudioPlayer();

    try {
      final prefs = await SharedPreferences.getInstance();
      final speechRate = prefs.getDouble('speechRate') ?? 0.4;
      final pitch = prefs.getDouble('pitch') ?? 1.0;

      await flutterTts.stop();
      await flutterTts.setLanguage("vi-VN");
      await flutterTts.setPitch(pitch);
      await flutterTts.setSpeechRate(speechRate);

      await player.play(AssetSource('sounds/tingting.mp3'));
      await Future.delayed(const Duration(milliseconds: 500));
      await flutterTts.speak(text);

    } catch (e) {
      print("Lỗi trong quá trình phát âm thanh/giọng nói: $e");
    }
  }
}
