import 'package:flutter/material.dart';
import 'package:frontend/services/firebase_api.dart';
import 'package:frontend/services/firebase_service.dart';
import 'package:frontend/views/cart/draft_screen.dart';
import 'package:frontend/views/settings/menu.dart';
import 'package:frontend/views/auth/login_screen.dart';
import 'package:frontend/views/auth/register_screen.dart';
import 'package:frontend/views/home/product_details_screen.dart';
import 'package:frontend/views/auth/otp_verification_screen.dart';
import 'package:frontend/views/home/home_screen.dart';
import 'package:frontend/views/settings/location_permission_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();
  await FirebaseService.initializeLocalNotifications();
  await FirebaseMessaging.instance.requestPermission();
  FirebaseService.setupForegroundNotificationListener();
  FirebaseService.setupNotificationTapListener();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery App',
      navigatorKey: navigatorKey, // Add navigatorKey here
      scaffoldMessengerKey: FirebaseService.scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/draft': (context) => DraftPage(),
      },
      home: const HomeScreen(),
    );
  }
}