import 'package:flutter/material.dart';
import '../features/transaction/view/transaction_screen.dart';
import '../features/transaction/view/transaction_stats_screen.dart';
import '../features/transaction/view/account_screen.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  DateTime? _lastPressed;

  // ✅ 3. Xóa GlobalKey của màn hình lịch sử
  final GlobalKey<TransactionStatsScreenState> _statsKey = GlobalKey();

  // ✅ 4. Cập nhật danh sách màn hình
  late final List<Widget> _screens = [
    const TransactionNotifierScreen(), // Tab 0: Giao dịch
    TransactionStatsScreen(key: _statsKey),     // Tab 1: Thống kê
    const AccountScreen(),                      // Tab 2: Tài khoản
  ];

  void _onTabTapped(int index) {
    // ✅ 5. Cập nhật logic khi chuyển tab
    // Chỉ gọi loadStats khi chuyển đến tab Thống kê (index = 1)
    if (_currentIndex != index && index == 1) {
      _statsKey.currentState?.loadStats();
    }
    setState(() => _currentIndex = index);
  }

  Future<bool> _onWillPop() async {
    // Nếu không ở tab "Giao dịch", thì khi bấm back sẽ quay về tab "Giao dịch"
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false; // Không thoát ứng dụng
    }

    // Nếu đang ở tab "Giao dịch", xử lý bấm 2 lần để thoát
    final now = DateTime.now();
    if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bấm Back thêm lần nữa để thoát")),
      );
      return false; // Không thoát ứng dụng
    }
    return true; // Thoát ứng dụng
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index,
      {Color activeColor = Colors.blue, Color inactiveColor = Colors.black54}) {
    final bool isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: isActive ? 30 : 24,
        color: isActive ? activeColor : inactiveColor,
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.blue;
    const Color inactiveColor = Colors.black54;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            selectedFontSize: 14,
            unselectedFontSize: 13,
            showUnselectedLabels: true,
            // ✅ 6. Cập nhật các mục trong BottomNavigationBar
            items: [
              _buildNavItem(Icons.swap_horiz, "Giao dịch", 0), // Thay đổi icon cho đẹp hơn
              _buildNavItem(Icons.pie_chart, "Thống kê", 1),
              _buildNavItem(Icons.person, "Tài khoản", 2),
            ],
          ),
        ),
      ),
    );
  }
}
