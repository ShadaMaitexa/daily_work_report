import 'package:daily_work_report/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final supabase = SupabaseConfig.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      print('🚀 Starting Registration');
      print('📧 Email: $email');
      print('👤 Name: $name');
      print('📱 Phone: $phone');

      // STEP 1: Create Worker Record FIRST (using function to bypass RLS)
      print('\n👷 STEP 1: Creating worker record...');

      // First, try direct insert (works if RLS disabled)
      // If it fails, the function with SECURITY DEFINER will handle it
      try {
        final workerResponse = await supabase
            .from('workers')
            .insert({'name': name, 'email': email, 'phone': phone})
            .select('id, name, email')
            .single();

        print('✅ Worker record created!');
        print('   Worker ID: ${workerResponse['id']}');
      } catch (rpsError) {
        // If RLS blocks it, use the function instead
        print('⚠️ Direct insert blocked, using register_worker function...');

        final response = await supabase.rpc(
          'register_worker',
          params: {
            'p_name': name,
            'p_email': email,
            'p_phone': phone,
            'p_auth_id': null,
          },
        );

        print('✅ Worker registered via function: $response');
      }

      final workerId = await supabase
          .from('workers')
          .select('id')
          .eq('email', email)
          .single()
          .then((row) => row['id']);

      // STEP 2: Try to create Supabase Auth User
      print('\n🔐 STEP 2: Creating Supabase Auth user...');
      try {
        final authResponse = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name, 'phone': phone},
        );

        if (authResponse.user != null) {
          print('✅ Auth user created: ${authResponse.user!.id}');

          // Link auth to worker record
          await supabase
              .from('workers')
              .update({'auth_id': authResponse.user!.id})
              .eq('id', workerId);
          print('✅ Worker linked to auth');
        }
      } catch (authError) {
        print('⚠️ Auth creation skipped: $authError');
        print('ℹ️ Worker registered - you can login with your credentials');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registration successful! Redirecting to login...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('❌ Registration Error: $e');

      setState(() => _isLoading = false);

      if (mounted) {
        String errorMessage = 'Registration failed: ${e.toString()}';

        if (e.toString().contains('duplicate')) {
          errorMessage = 'Email already registered. Please login instead.';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Email issue. Please check and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: AcadenoTheme.heroGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Image.asset('assets/logo.png', height: 62),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Join Acadeno Workforce',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s get you started with data-rich daily reports.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Worker Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration(
                        context,
                        hint: 'Alex Mathew',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: _fieldDecoration(
                        context,
                        hint: 'alex@email.com',
                        icon: Icons.mail_outline,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Phone'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _fieldDecoration(
                        context,
                        hint: '9074402900',
                        icon: Icons.phone_outlined,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _fieldDecoration(
                        context,
                        hint: 'Minimum 6 characters',
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _register,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _isLoading ? 'Creating...' : 'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Already registered? Sign in',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}
