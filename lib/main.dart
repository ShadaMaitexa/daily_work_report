import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  Widget _initialScreen = const LoginScreen();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isAdmin = await _authService.isAdmin();
    final workerId = await _authService.getWorkerId();

    if (isAdmin) {
      setState(() {
        _initialScreen = const AdminDashboard();
        _isLoading = false;
      });
    } else if (workerId != null) {
      setState(() {
        _initialScreen = const HomeScreen();
        _isLoading = false;
      });
    } else {
      setState(() {
        _initialScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acadeno Daily Work Report',
      theme: AcadenoTheme.light(),
      home: _isLoading ? const SplashScreen() : _initialScreen,
    );
  }
}
