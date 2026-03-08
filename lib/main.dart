// lib/main.dart
// BikeValue Flutter App — Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/app_theme.dart';
import 'services/session_service.dart';
import 'models/app_models.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
  ));
  runApp(const BikeValueApp());
}

class BikeValueApp extends StatelessWidget {
  const BikeValueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeValue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});
  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _loading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await SessionService.getUser();
    await Future.delayed(const Duration(milliseconds: 1500)); // splash delay
    setState(() { _user = user; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();
    if (_user == null) return const LoginScreen();
    if (_user!.role == 'admin') return AdminScreen(user: _user!);
    return HomeScreen(user: _user!);
  }
}
