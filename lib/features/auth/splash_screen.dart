import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthRouter(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bỏ màu nền ở đây để ảnh nền hiển thị
      // backgroundColor: Colors.white,
      body: Container(
        // ✅ BƯỚC 1: DÙNG DECORATION ĐỂ THÊM ẢNH NỀN
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Giả sử ảnh nền của bạn tên là 'background.jpg'
            image: AssetImage('assets/images/nen_ung_dung.jpg'),
            // `BoxFit.cover` sẽ đảm bảo ảnh nền lấp đầy màn hình
            fit: BoxFit.cover,
          ),
        ),
        // ✅ BƯỚC 2: CÁC WIDGET CON VẪN GIỮ NGUYÊN
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo của bạn
              Image.asset(
                'assets/logo.png',
                width: 150,
              ),
              const SizedBox(height: 2),

              // 2. GIF loading
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/gif-loading.gif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
