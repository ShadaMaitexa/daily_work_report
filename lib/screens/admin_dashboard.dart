import 'package:daily_work_report/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/report_form_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _reportService = ReportService();

  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  List<String> _workerOptions = ['All Workers'];
  String _selectedWorker = 'All Workers';
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final reports = await _reportService.getAllReports();

      final workers = <String>{};

      for (final report in reports) {
        final workerName =
            report['workerName']?.toString() ?? report['name']?.toString() ?? 'Unknown';

        if (workerName != 'Unknown') workers.add(workerName);
      }

      setState(() {
        _allReports = reports;
        _workerOptions = ['All Workers', ...workers.toList()..sort()];
      });

      _applyFilters();
    } catch (e) {
      debugPrint("❌ Error loading reports: $e");
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allReports);

    if (_selectedWorker != 'All Workers') {
      filtered = filtered.where((report) {
        final name = report['workerName'] ?? report['name'];
        return name == _selectedWorker;
      }).toList();
    }

    if (_selectedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      filtered = filtered.where((report) {
        final date = report['date']?.toString().split('T').first;
        return date == formattedDate;
      }).toList();
    }

    setState(() => _filteredReports = filtered);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (_) => false,
    );
  }

  String _getStatus(Map<String, dynamic> report) {
    return (report['tasksCompleted'] != null && report['tasksCompleted'].toString().isNotEmpty)
        ? 'Present'
        : 'Leave';
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    final parsed = DateTime.tryParse(date);
    return parsed != null ? DateFormat('d MMM yyyy').format(parsed) : date;
  }

  void _clearFilters() {
    setState(() {
      _selectedWorker = 'All Workers';
      _selectedDate = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AcadenoTheme.auroraGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReports.isEmpty
                        ? _buildEmptyState(context)
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 20),
                              children: [
                                _buildFilterCard(context),
                                const SizedBox(height: 14),
                                ..._filteredReports.map((r) => _buildReportTile(context, r)),
                              ],
                            ),
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔽 UI Functions remain unchanged
  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Image.asset('assets/logo.png', height: 40),
          const SizedBox(width: 10),
          Text("Admin Dashboard",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, Map<String, dynamic> report) {
    final workerName = report['workerName'] ?? report['name'] ?? 'Unknown';
    final status = _getStatus(report);
    final date = _formatDate(report['date']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        title: Text(workerName),
        subtitle: Text("Date: $date"),
        trailing: Chip(
          label: Text(status),
          backgroundColor: status == "Present" ? Colors.green[100] : Colors.orange[100],
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedWorker,
              items: _workerOptions.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (v) => setState(() {
                _selectedWorker = v!;
                _applyFilters();
              }),
              decoration: const InputDecoration(labelText: 'Filter by Worker'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _applyFilters();
                }
              },
              child: Text(
                _selectedDate == null
                    ? "Select Date"
                    : DateFormat('d MMM yyyy').format(_selectedDate!),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 200),
          Icon(Icons.inbox, size: 60),
          const SizedBox(height: 12),
          Text("No reports found"),
          TextButton(onPressed: _clearFilters, child: const Text("Reset Filters")),
        ],
      ),
    );
  }
}
