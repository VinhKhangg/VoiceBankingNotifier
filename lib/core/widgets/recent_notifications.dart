// lib/core/widgets/recent_notifications.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

class RecentNotifications extends StatefulWidget {
  final List<TransactionModel> transactions;

  const RecentNotifications({Key? key, required this.transactions}) : super(key: key);

  @override
  State<RecentNotifications> createState() => _RecentNotificationsState();
}

class _RecentNotificationsState extends State<RecentNotifications> {
  late List<TransactionModel> _notificationsToShow;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateNotifications();
    _startTimer();
  }

  // ✅ HÀM MỚI: Tách logic cập nhật danh sách thông báo
  void _updateNotifications() {
    // Lấy 3 giao dịch mới nhất và đảo ngược lại để chạy từ dưới lên (cũ nhất -> mới nhất)
    _notificationsToShow = widget.transactions.take(3).toList().reversed.toList();
  }

  void _startTimer() {
    if (_notificationsToShow.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) { // Tăng thời gian hiển thị lên 4 giây
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        // Vòng lặp chỉ số, khi đến cuối sẽ quay về đầu
        _currentIndex = (_currentIndex + 1) % _notificationsToShow.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RecentNotifications oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi có giao dịch mới, cập nhật lại danh sách và reset vòng lặp
    _updateNotifications();
    _timer?.cancel();
    setState(() => _currentIndex = 0);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsToShow.isEmpty) {
      return const SizedBox.shrink(); // Widget trống nếu không có thông báo
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // ✅ SỬ DỤNG ANIMATEDSWITCHER ĐỂ TẠO HIỆU ỨNG CHO CẢ KHỐI
    return AnimatedSwitcher(
      // Thời gian chuyển đổi
      duration: const Duration(milliseconds: 500),
      // Hiệu ứng chuyển tiếp: Widget mới sẽ trượt từ dưới lên và hiện ra
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0), // Bắt đầu từ dưới
            end: Offset.zero,              // Kết thúc ở vị trí bình thường
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildNotificationCard(
        // ✅ Key là RẤT QUAN TRỌNG, nó giúp AnimatedSwitcher biết khi nào widget đã thay đổi
        key: ValueKey<int>(_currentIndex),
        transaction: _notificationsToShow[_currentIndex],
        theme: theme,
        isDarkMode: isDarkMode,
      ),
    );
  }

  // ✅ TÁCH UI CỦA CARD RA MỘT HÀM RIÊNG CHO SẠCH SẼ
  Widget _buildNotificationCard({
    required Key key,
    required TransactionModel transaction,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    final voiceMessage = "Bạn vừa nhận được ${NumberFormat("#,###", "vi_VN").format(transaction.amount.toInt())} đồng";

    return Padding(
      key: key, // Gán key cho widget gốc
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkMode
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.blue[50],
        child: ListTile(
          leading: Icon(Icons.notifications_active, color: theme.colorScheme.primary),
          title: const Text('Thông báo gần nhất:', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(voiceMessage),
        ),
      ),
    );
  }
}
