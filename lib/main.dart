// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/create_pin_screen.dart';
import 'features/auth/enter_pin_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();
  await Permission.notification.request();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BankingNotifierApp(),
    ),
  );
}

class BankingNotifierApp extends StatelessWidget {
  const BankingNotifierApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Voice Banking Notifier',
      debugShowCheckedModeBanner: false,

      themeMode: themeProvider.themeMode,

      // --- THEME SÁNG (Giữ nguyên) ---
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.black87,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),

      // --- THEME TỐI (✅ ĐIỀU CHỈNH LẠI MÀU SẮC) ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,

        // ✅ SỬA Ở ĐÂY: Dùng màu xám đậm thay vì đen tuyền
        scaffoldBackgroundColor: const Color(0xFF212121), // Xám đậm (Material Grey 900)
        cardColor: const Color(0xFF303030),              // Xám đậm hơn một chút
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF303030), // Đồng bộ với màu card
          foregroundColor: Colors.white,
        ),

        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.blue[300],
          secondary: Colors.blueAccent[100],
        ),

        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF424242), // Màu nền cho TextField
        ),
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      home: const AuthRouter(),
    );
  }
}

// ... (Lớp AuthRouter giữ nguyên)
class AuthRouter extends StatelessWidget {
  const AuthRouter({Key? key}) : super(key: key);

  Future<Widget> _decideScreen(User user) async {
    final pin = await DatabaseService.getPin();
    if (pin == null || pin.isEmpty) {
      return const CreatePinScreen();
    } else {
      return const EnterPinScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        final user = snapshot.data!;
        return FutureBuilder<Widget>(
          future: _decideScreen(user),
          builder: (context, futureSnap) {
            if (futureSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (futureSnap.hasError) {
              return Scaffold(body: Center(child: Text("Lỗi: ${futureSnap.error}")));
            }
            return futureSnap.data ?? const LoginScreen();
          },
        );
      },
    );
  }
}
