// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  // ✅✅✅ SỬA LỖI TẠI ĐÂY ✅✅✅
  // Thêm tham số tùy chọn `bool silent = false` vào hàm `show`
  static Future<void> show(String title, String body, {bool silent = false}) async {

    // Tạo một kênh thông báo riêng cho giao dịch có âm thanh
    const AndroidNotificationDetails soundChannel = AndroidNotificationDetails(
      'transaction_channel_sound', // channel id
      'Giao dịch (có âm thanh)', // channel name
      channelDescription: 'Thông báo biến động số dư có phát ra âm thanh.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // <-- Bật âm thanh cho kênh này
      ticker: 'ticker',
    );

    // Tạo một kênh thông báo riêng cho giao dịch IM LẶNG
    const AndroidNotificationDetails silentChannel = AndroidNotificationDetails(
      'transaction_channel_silent', // channel id
      'Giao dịch (im lặng)', // channel name
      channelDescription: 'Thông báo biến động số dư không phát ra âm thanh.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // <-- Tắt âm thanh cho kênh này
      ticker: 'ticker',
    );

    // ✅ Chọn kênh thông báo phù hợp dựa vào tham số `silent`
    final NotificationDetails details = NotificationDetails(
      android: silent ? silentChannel : soundChannel,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      details,
    );
  }
}
