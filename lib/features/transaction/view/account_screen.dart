import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/logout_service.dart';
import '../../auth/reset_pin_screen.dart';
import '../../../layout/app_bar_common.dart';
import '../../settings/settings_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../add_bank/manage_linked_accounts_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _profileRepo.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải thông tin: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CommonAppBar(title: "Tài khoản"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: (_userProfile?.photoURL != null && _userProfile!.photoURL!.isNotEmpty)
                      ? NetworkImage(_userProfile!.photoURL!)
                      : null,
                  child: (_userProfile?.photoURL == null || _userProfile!.photoURL!.isEmpty)
                      ? Text(
                    _userProfile?.name?.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(fontSize: 40, color: theme.colorScheme.primary),
                  )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _userProfile?.name ?? "Chưa có tên",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?.email ?? "Chưa có email",
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildListTile(
              context,
              icon: Icons.person_outline,
              title: "Thông tin cá nhân",
              subtitle: "Thay đổi tên, ảnh đại diện, SĐT",
              onTap: () async {
                if (_userProfile == null) return;
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _userProfile!)),
                );
                if (result == true) {
                  await _loadUserProfile();
                }
              },
            ),
            _buildListTile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: "Quản lý tài khoản ngân hàng",
              subtitle: "Thêm hoặc xóa các liên kết",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageLinkedAccountsScreen()),
                );
              },
            ),
            _buildListTile(
              context,
              icon: Icons.pin_outlined,
              title: "Đổi mã PIN",
              subtitle: "Tăng cường bảo mật cho tài khoản",
              // ✅ 2. Sửa lại logic onTap cho đúng luồng bảo mật
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Điều hướng đến ResetPinScreen để bắt đầu luồng xác thực OTP
                      builder: (_) => const ResetPinScreen()),
                );
              },
            ),
            _buildListTile(
              context,
              icon: Icons.settings_outlined,
              title: "Cài đặt",
              subtitle: "Giao diện và giọng nói thông báo",
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
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Hủy")),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Đăng xuất")),
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
      ),
    );
  }
}
