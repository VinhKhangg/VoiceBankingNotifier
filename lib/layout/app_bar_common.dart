import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CommonAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 2,
      // ✅ Giữ lại màu nền như cũ
      backgroundColor: Colors.blue[50],
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 70,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                // ✅ Giữ lại màu chữ đen như cũ
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      // ✅ Đã xóa toàn bộ thuộc tính 'actions' (nút tài khoản)
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
