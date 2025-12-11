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

  void _updateNotifications() {
    // Lấy 3 giao dịch mới nhất và đảo ngược lại để chạy từ dưới lên (cũ nhất -> mới nhất)
    _notificationsToShow = widget.transactions.take(3).toList().reversed.toList();
  }

  void _startTimer() {
    if (_notificationsToShow.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
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
    if (widget.transactions.length != oldWidget.transactions.length) {
      _updateNotifications();
      _timer?.cancel();
      setState(() => _currentIndex = 0);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildNotificationCard(
        key: ValueKey<String>(_notificationsToShow[_currentIndex].id), // Sử dụng ID để đảm bảo key là duy nhất
        transaction: _notificationsToShow[_currentIndex],
        theme: theme,
        isDarkMode: isDarkMode,
      ),
    );
  }

  Widget _buildNotificationCard({
    required Key key,
    required TransactionModel transaction,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    final amountFormatted = NumberFormat("#,###", "vi_VN").format(transaction.amount.toInt());
    final bool isIncome = transaction.type == TransactionType.income;

    // TẠO NỘI DUNG THÔNG BÁO DỰA TRÊN LOẠI GIAO DỊCH
    final String notificationMessage = isIncome
        ? "Tài khoản +$amountFormatted đ"
        : "Tài khoản -$amountFormatted đ";

    // TẠO ICON DỰA TRÊN LOẠI GIAO DỊCH
    final IconData notificationIcon = isIncome
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;

    final Color iconColor = isIncome ? Colors.green : Colors.red;

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkMode
            ? theme.colorScheme.surface.withOpacity(0.5) // Màu nền tối cho dễ nhìn hơn
            : Colors.blue[50],
        child: ListTile(
          leading: Icon(notificationIcon, color: iconColor), // Icon thay đổi
          title: const Text('3 Thông báo mới:', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            notificationMessage, // Nội dung thay đổi
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
