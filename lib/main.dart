import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'controllers/DashboardController.dart';
import 'controllers/auth/login_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/paymentcontroller.dart';
import 'controllers/socket_controller.dart';
import 'controllers/wallet_controller.dart';
import 'controllers/withdrawal_controller.dart';
import 'services/NotificationService.dart';
import 'splash_screen.dart';
import '../models/order_model.dart';
import 'views/order_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔹 Background FCM handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.init();
  NotificationService.showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  MyApp.configLoading();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..backgroundColor = Colors.black.withOpacity(0.7)
      ..indicatorColor = Colors.white
      ..maskColor = Colors.black.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  SocketController? _socketController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFCM();
  }

  /// 🔹 Initialize Firebase Cloud Messaging (FCM)
  Future<void> _initializeFCM() async {
    try {
      await NotificationService.init();

      // Request permission for notifications
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("🔑 FCM Token: $fcmToken");

      if (fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', fcmToken);
        print("✅ FCM Token saved in SharedPreferences");
      }

      // 🔹 Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📲 Foreground FCM: ${message.notification?.title}");
        NotificationService.showNotification(message);
      });


    } catch (e) {
      print("❌ FCM Initialization Error: $e");
    }
  }

  // 🔹 Lifecycle socket handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_socketController == null) return;

    if (state == AppLifecycleState.resumed) {
      print("📱 App resumed → reconnecting socket...");
      _socketController!.reconnectSocket();
    } else if (state == AppLifecycleState.paused) {
      print("⏸️ App paused → disconnecting socket...");
      _socketController!.disconnectSocket();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocketController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => WithdrawalController()),
        ChangeNotifierProvider(create: (_) => WalletController()),
        ChangeNotifierProvider(create: (_) => PaymentController()),
      ],
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _socketController = Provider.of<SocketController>(context, listen: false);
          _socketController!.connectSocket();

          final isLoggedIn = await LoginController.isLoggedIn();
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('employeeId') ?? '';
          print('👤 App Started | LoggedIn: $isLoggedIn | UserID: $userId');
        });

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),

          home: const SplashScreen(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
