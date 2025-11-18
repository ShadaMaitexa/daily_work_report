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
  String? _workerName;
  String _statusMessage = 'Checking status...';
  bool _isStatusLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerId();
  }

  Future<void> _loadWorkerId() async {
    final workerId = await _authService.getWorkerId();
    final workerName = await _authService.getWorkerName();
    setState(() {
      _workerId = workerId;
      _workerName = workerName;
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
    final result =
        await SheetsApi.checkTodayStatus(workerId: workerId.toString());
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Work Report',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Stay on top of your progress',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Logout',
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadWorkerId,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      _buildHeroCard(context),
                      const SizedBox(height: 20),
                      _buildStatusCard(context),
                      const SizedBox(height: 20),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello ${_workerName ?? 'Worker'}',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_workerId != null)
            Text(
              'ID: ${_workerId}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          if (_workerId != null) const SizedBox(height: 4),
          Text(
            'Ready to share today’s progress?',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: theme.colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _statusMessage == 'Report Submitted'
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReportFormScreen(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusMessage == 'Report Submitted'
                    ? Icons.check_circle
                    : Icons.edit_calendar_outlined),
                const SizedBox(width: 8),
                Text(
                  _statusMessage == 'Report Submitted'
                      ? 'Already Submitted'
                      : 'Submit Report',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Status",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isStatusLoading
                      ? Row(
                          children: const [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 6),
                            Text('Updating…'),
                          ],
                        )
                      : Text(
                          _statusMessage,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _isStatusLoading
                  ? 'Fetching latest activity...'
                  : _statusMessage == 'Report Submitted'
                      ? 'Great job staying consistent today!'
                      : 'No report yet. Tap Submit to mark attendance.',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final items = [
      {
        'icon': _statusMessage == 'Report Submitted'
            ? Icons.check_circle
            : Icons.edit_note_rounded,
        'title': _statusMessage == 'Report Submitted'
            ? 'Already Submitted'
            : 'Submit Now',
        'description': _statusMessage == 'Report Submitted'
            ? 'Report submitted for today'
            : 'Share today\'s accomplishments',
        'action': _statusMessage == 'Report Submitted'
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportFormScreen(),
                  ),
                )
      },
      {
        'icon': Icons.history_rounded,
        'title': 'View History',
        'description': 'See previous submissions',
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ReportHistoryScreen(),
              ),
            )
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                child: Icon(
                  item['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item['description'] as String,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: item['action'] as VoidCallback?,
              enabled: item['action'] != null,
            ),
          ),
        ),
      ],
    );
  }
}

