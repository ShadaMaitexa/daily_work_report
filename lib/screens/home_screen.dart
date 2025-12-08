import 'package:daily_work_report/services/auth_service.dart';
import 'package:daily_work_report/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/report_form_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'report_form_screen.dart';
import 'report_history_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = SupabaseConfig.client;
  final _authService = AuthService();

  int? _workerId;
  String? _workerName;

  String _statusMessage = 'Checking status...';
  bool _isStatusLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final id = await _authService.getWorkerId();
    final name = await _authService.getWorkerName();

    setState(() {
      _workerId = id;
      _workerName = name ?? 'Worker';
    });

    if (id != null) {
      _fetchTodayStatus();
    } else {
      setState(() {
        _statusMessage = 'Not Logged In';
        _isStatusLoading = false;
      });
    }
  }

  Future<void> _fetchTodayStatus() async {
    setState(() => _isStatusLoading = true);

    final today = DateTime.now().toIso8601String().split('T').first;

    final data = await supabase
        .from('reports')
        .select()
        .eq('worker_id', _workerId!)
        .eq('date', today)
        .maybeSingle();

    setState(() {
      if (data == null) {
        _statusMessage = 'Pending';
      } else {
        _statusMessage = data['status'] == 'submitted'
            ? 'Report Submitted'
            : 'Pending';
      }

      _isStatusLoading = false;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    await supabase.auth.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AcadenoTheme.auroraGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colorScheme),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchTodayStatus(),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acadeno Workspace',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                Text('Where AI builds your career',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colorScheme.primary),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  // ------------------- UI SECTIONS (unchanged) -------------------

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7E67F5),
            Color(0xFF6F96FF),
            Color(0xFF4DD4FF),
            Color(0xFFFFB982),
          ],
          stops: [0.0, 0.45, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(children: [
                  Icon(Icons.bolt, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Today', style: TextStyle(color: Colors.white))
                ]),
              ),
              const Spacer(),
              Text(
                DateTime.now().toIso8601String().split('T').first,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("Hello ${_workerName ?? 'Worker'}",
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
          if (_workerId != null)
            Text('ID: $_workerId',
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _statusMessage == 'Report Submitted'
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReportFormScreen())),
            child: Text(
              _statusMessage == 'Report Submitted'
                  ? 'Already Submitted'
                  : 'Submit Report',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.bolt_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text("Today's Status",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isStatusLoading
                  ? Row(mainAxisSize: MainAxisSize.min, children: const [
                      SizedBox(
                          height: 16,
                          width: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 6),
                      Text('Updating…'),
                    ])
                  : Text(_statusMessage,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _actionTile(
          context,
          icon: _statusMessage == 'Report Submitted'
              ? Icons.check_circle
              : Icons.edit_note_rounded,
          title: _statusMessage == 'Report Submitted'
              ? 'Already Submitted'
              : 'Submit Now',
          subtitle: 'Share today\'s accomplishments',
          enabled: _statusMessage != 'Report Submitted',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportFormScreen()),
          ),
        ),
        _actionTile(
          context,
          icon: Icons.history_rounded,
          title: 'View History',
          subtitle: 'See previous submissions',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8))
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: enabled ? onTap : null,
        enabled: enabled,
      ),
    );
  }
}
