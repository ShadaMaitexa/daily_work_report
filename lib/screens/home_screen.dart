import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sheets_api.dart';
import 'login_screen.dart';
import 'report_form_screen.dart';
import 'report_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  int? _workerId;
  String _statusMessage = 'Checking status...';
  bool _isStatusLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerId();
  }

  Future<void> _loadWorkerId() async {
    final workerId = await _authService.getWorkerId();
    setState(() {
      _workerId = workerId;
    });
    if (workerId != null) {
      await _fetchTodayStatus(workerId);
    } else {
      setState(() {
        _statusMessage = 'Marked as Leave';
        _isStatusLoading = false;
      });
    }
  }

  Future<void> _fetchTodayStatus(int workerId) async {
    setState(() {
      _isStatusLoading = true;
    });
    final result = await SheetsApi.checkTodayStatus(
      workerId: workerId.toString(),
    );
    String statusText = 'Marked as Leave';
    if (result['success'] == true) {
      final status = (result['status'] ?? '').toString().toLowerCase();
      if (status == 'submitted') {
        statusText = 'Report Submitted';
      }
    }
    if (!mounted) return;
    setState(() {
      _statusMessage = statusText;
      _isStatusLoading = false;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Worker Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_workerId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Worker ID: $_workerId',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Status",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isStatusLoading
                        ? const LinearProgressIndicator()
                        : Text(
                            _statusMessage,
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportFormScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Today Report'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportHistoryScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('View Report History'),
            ),
          ],
        ),
      ),
    );
  }
}

