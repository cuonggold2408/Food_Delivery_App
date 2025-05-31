import 'package:flutter/material.dart';
import 'package:frontend/views/cart/draft_screen.dart';
import 'package:frontend/views/settings/menu.dart';
import 'package:frontend/views/auth/login_screen.dart';
import 'package:frontend/views/auth/register_screen.dart';
import 'package:frontend/views/home/product_details_screen.dart';
import 'package:frontend/views/auth/otp_verification_screen.dart';
import 'package:frontend/views/home/home_screen.dart';

import 'package:frontend/views/settings/location_permission_screen.dart';
import 'package:frontend/views/search/search_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: '/location',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/draft': (context) => const DraftPage(),
        '/search': (context) => const SearchScreen(),
        '/location': (context) => const LocationPermissionScreen(),
      },
    );
  }
}