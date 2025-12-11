import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/transaction/view/transaction_screen.dart';
import '../features/transaction/view/transaction_stats_screen.dart';
import '../features/transaction/view/account_screen.dart';
import '../core/widgets/app_background.dart'; // ✅ 1. THÊM IMPORT CHO AppBackground

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  DateTime? _lastPressed;

  final GlobalKey<TransactionStatsScreenState> _statsKey = GlobalKey();

  late final List<Widget> _screens = [
    const TransactionNotifierScreen(),
    TransactionStatsScreen(key: _statsKey),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _saveDeviceTokenAfterLogin();
  }

  Future<void> _saveDeviceTokenAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Không tìm thấy người dùng để lưu token.");
      return;
    }

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final userTokensRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token);

        await userTokensRef.set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
        });
        print('✅ Device token saved successfully after PIN verification: $token');
      }
    } catch (e) {
      print('❌ Error saving device token in MainLayout: $e');
    }
  }


  void _onTabTapped(int index) {
    if (_currentIndex != index && index == 1) {
      _statsKey.currentState?.loadStats();
    }
    setState(() => _currentIndex = index);
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastPressed == null ||
        now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bấm Back thêm lần nữa để thoát"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // ✅ 2. BỌC TOÀN BỘ WIDGET BẰNG AppBackground
    return AppBackground(
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          // ✅ 3. ĐẶT MÀU NỀN CỦA SCAFFOLD THÀNH TRONG SUỐT
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            // Để BottomNavigationBar có nền riêng, không bị trong suốt
            backgroundColor: theme.cardColor,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            items: [
              _buildNavItem(Icons.swap_horiz_rounded, "Giao dịch"),
              _buildNavItem(Icons.pie_chart_rounded, "Thống kê"),
              _buildNavItem(Icons.person_rounded, "Tài khoản"),
            ],
          ),
        ),
      ),
    );
  }
}
