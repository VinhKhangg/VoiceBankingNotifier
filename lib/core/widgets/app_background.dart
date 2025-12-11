import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  // Widget này sẽ nhận một widget con, thường là Scaffold
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dùng decoration để đặt ảnh nền
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/nen_ung_dung.jpg'),
          fit: BoxFit.cover, // Đảm bảo ảnh nền lấp đầy màn hình
        ),
      ),
      // Đặt widget con (nội dung màn hình) lên trên ảnh nền
      child: child,
    );
  }
}
