import 'package:daily_work_report/services/auth_service.dart';
import 'package:daily_work_report/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ADD THIS IMPORT

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = SupabaseConfig.client;

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Admin credentials
  static const String _adminEmail = 'acadeno@gmail.com';
  static const String _adminPassword = 'acadeno123';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    print('🔐 SIMPLE Login for: $email');

    // ADMIN LOGIN
    if (email == _adminEmail && password == _adminPassword) {
      print('👑 Admin login');
      await _authService.saveAdminStatus(true);
      await _authService.saveWorkerId('admin');
      await _authService.saveWorkerName('Admin');
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
      return;
    }

    // STEP 1: Try normal login
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Auth successful: ${response.user!.id}');
        await _handleWorkerLookup(response.user!, email);
        return;
      }
    } catch (authError) {
      print('⚠️ Auth login failed: $authError');
    }

    // STEP 2: If auth fails, check if worker exists anyway
    print('🔍 Checking if worker exists in database...');
    final workerData = await supabase
        .from('workers')
        .select('id, name, email, auth_id')
        .eq('email', email)
        .maybeSingle();

    if (workerData != null) {
      print('✅ Worker found: ${workerData['id']}');
      
      // Try to create auth account for this worker
      print('🔄 Attempting to create auth account...');
      try {
        final authResponse = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        if (authResponse.user != null) {
          // Update worker with auth_id
          await supabase
              .from('workers')
              .update({'auth_id': authResponse.user!.id})
              .eq('id', workerData['id']);
          
          print('✅ Auth created and linked to worker');
        }
      } catch (e) {
        print('⚠️ Could not create auth: $e');
      }
      
      // Login with worker data even if auth creation failed
      await _completeLogin(workerData, workerData['auth_id']?.toString() ?? '');
      return;
    }

    // STEP 3: No worker found - suggest registration
    throw Exception('No account found. Please register first.');

  } catch (e) {
    print('❌ Login error: $e');
    setState(() => _isLoading = false);

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().contains('No account found') 
            ? 'Account not found. Please register first.'
            : 'Login failed. Please check credentials.'
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _handleWorkerLookup(User user, String email) async {
  // Try to find worker by auth_id
  var workerData = await supabase
      .from('workers')
      .select('id, name, email')
      .eq('auth_id', user.id)
      .maybeSingle();

  if (workerData == null) {
    // Try by email
    workerData = await supabase
        .from('workers')
        .select('id, name, email')
        .eq('email', email)
        .maybeSingle();
    
    if (workerData == null) {
      // Create worker on the fly
      print('📝 Creating worker profile on login...');
      final response = await supabase.from('workers').insert({
        'auth_id': user.id,
        'name': 'Worker',
        'email': email,
        'phone': '',
      }).select('id, name').single();
      
      workerData = response;
    } else {
      // Update existing worker with auth_id
      await supabase
          .from('workers')
          .update({'auth_id': user.id})
          .eq('id', workerData['id']);
    }
  }

  await _completeLogin(workerData, user.id);
}

Future<void> _completeLogin(Map<String, dynamic> workerData, String authId) async {
  final workerId = workerData['id'].toString();
  final workerName = workerData['name']?.toString() ?? 'Worker';

  print('🎉 Login successful! ID: $workerId, Name: $workerName');

  await _authService.saveAdminStatus(false);
  await _authService.saveWorkerId(workerId);
  await _authService.saveWorkerName(workerName);

  setState(() => _isLoading = false);

  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
  );
}
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: AcadenoTheme.heroGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Image.asset('assets/logo.png', height: 72),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ACADENO',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Where AI Builds Careers',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInputLabel('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        context,
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildInputLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(
                        context,
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'New worker? Create account',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}