import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/create_pin_screen.dart';
import 'features/auth/enter_pin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/splash_screen.dart';
import 'services/notification_handler_service.dart';

// import 'services/database_service.dart'; // <-- Không còn cần thiết ở đây

// ✅ HÀM BACKGROUND ĐÃ ĐƯỢC NÂNG CẤP
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // BƯỚC 1: Khởi tạo các service cần thiết
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  print("Handling a background message with data-only payload: ${message.messageId}");
  print("Background Message data: ${message.data}");

  // ✅ BƯỚC 2: KHÔNG CẦN TRUY VẤN DATABASE NỮA
  // Kiểm tra xem đây có phải là thông báo giao dịch không
  if (message.data['type'] == 'transaction') {
    // Gọi thẳng handler với message.data
    await NotificationHandlerService.handleTransactionFromData(message.data);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cấu hình Firebase Messaging với handler đã nâng cấp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Yêu cầu quyền gửi thông báo
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Khởi tạo NotificationService một lần ở main
  await NotificationService.initialize();
  await Permission.notification.request();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BankingNotifierApp(),
    ),
  );
}

class BankingNotifierApp extends StatefulWidget {
  const BankingNotifierApp({Key? key}) : super(key: key);

  @override
  State<BankingNotifierApp> createState() => _BankingNotifierAppState();
}

class _BankingNotifierAppState extends State<BankingNotifierApp> {
  @override
  void initState() {
    super.initState();
    // ✅ Lắng nghe thông báo khi ứng dụng đang mở (foreground) - ĐÃ ĐƯỢC NÂNG CẤP
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground with data: ${message.data}');

      // ✅ KHÔNG CẦN TRUY VẤN DATABASE NỮA
      // Kiểm tra xem đây có phải là thông báo giao dịch không
      if (message.data['type'] == 'transaction') {
        // Gọi thẳng handler với message.data
        await NotificationHandlerService.handleTransactionFromData(message.data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Voice Banking Notifier',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF212121),
        cardColor: const Color(0xFF303030),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF303030),
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
          fillColor: Color(0xFF424242),
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
      home: const SplashScreen(),
    );
  }
}

// Các phần AuthRouter, _buildLoadingIndicator giữ nguyên
Widget _buildLoadingIndicator() {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.asset('assets/images/gif-loading.gif'),
      ),
    ),
  );
}

class AuthRouter extends StatelessWidget {
  const AuthRouter({Key? key}) : super(key: key);

  Future<Widget> _decideScreen(User user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return const CreatePinScreen();
      }

      final data = doc.data();
      final pin = data?["pin"] as String?;

      if (pin == null || pin.isEmpty) {
        return const CreatePinScreen();
      } else {
        return const EnterPinScreen();
      }
    } catch (e) {
      print("Lỗi khi kiểm tra PIN từ Firestore: $e");
      return const CreatePinScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        final user = snapshot.data!;
        return FutureBuilder<Widget>(
          future: _decideScreen(user),
          builder: (context, futureSnap) {
            if (futureSnap.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (futureSnap.hasError) {
              return Scaffold(body: Center(child: Text("Lỗi khởi tạo: ${futureSnap.error}")));
            }
            return futureSnap.data ?? const LoginScreen();
          },
        );
      },
    );
  }
}
