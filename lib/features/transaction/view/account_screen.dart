// lib/features/transaction/view/account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/logout_service.dart';
import '../../auth/reset_pin_screen.dart';
import '../../../layout/app_bar_common.dart';
import '../../settings/settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Widget _buildListTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.withOpacity(0.7)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy theme hiện tại
    final theme = Theme.of(context);

    return Scaffold(
      // ✅ Sử dụng màu từ theme
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: "Tài khoản"),
      body: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(fontSize: 40, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                currentUser?.displayName ?? "Không có tên",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                currentUser?.email ?? "Không có email",
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildListTile(
            context,
            icon: Icons.pin_outlined,
            title: "Đổi mã PIN",
            subtitle: "Tăng cường bảo mật cho tài khoản",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResetPinScreen()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.settings_outlined,
            title: "Cài đặt",
            subtitle: "Giao diện và các thiết lập khác",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.logout,
            title: "Đăng xuất",
            subtitle: "Kết thúc phiên làm việc hiện tại",
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Xác nhận đăng xuất"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Hủy"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Đăng xuất"),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                LogoutService.logout(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

