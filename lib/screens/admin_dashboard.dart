import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sheets_api.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
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
    setState(() {
      _isLoading = true;
    });

    final result = await SheetsApi.getAllReports();

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && result['reports'] != null) {
      final reports = List<Map<String, dynamic>>.from(result['reports']);
      final workers = <String>{};
      for (final report in reports) {
        final workerName = report['workerName']?.toString() ?? 'Unknown';
        workers.add(workerName);
      }

      setState(() {
        _allReports = reports;
        _workerOptions = ['All Workers', ...workers.toList()..sort()];
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allReports);

    if (_selectedWorker != 'All Workers') {
      filtered = filtered
          .where((report) =>
              (report['workerName'] ?? '').toString() == _selectedWorker)
          .toList();
    }

    if (_selectedDate != null) {
      final selectedDateString =
          '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      filtered = filtered
          .where((report) => (report['date'] ?? '').toString() ==
              selectedDateString)
          .toList();
    }

    setState(() {
      _filteredReports = filtered;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedWorker = 'All Workers';
      _selectedDate = null;
    });
    _applyFilters();
  }

  String _getStatus(Map<String, dynamic> report) {
    final hasData =
        report['tasksCompleted'] != null && report['tasksCompleted'].toString().isNotEmpty;
    return hasData ? 'Present' : 'Leave';
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Report Details',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Worker', report['workerName'] ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow('Date', _formatDate(report['date']?.toString())),
              const SizedBox(height: 12),
              _buildDetailRow('Status', _getStatus(report)),
              const SizedBox(height: 24),
              _buildSection('Tasks Completed', report['tasksCompleted']),
              const SizedBox(height: 16),
              _buildSection('Tasks In Progress', report['tasksInProgress']),
              const SizedBox(height: 16),
              _buildSection('Next Steps', report['nextSteps']),
              const SizedBox(height: 16),
              _buildSection('Issues', report['issues']),
              if (report['students'] != null &&
                  (report['students'] as List).isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Students',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(report['students'] as List).map((student) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Name',
                            student['name']?.toString() ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Topic',
                            student['topic']?.toString() ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Time',
                            student['time']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (content?.toString().isNotEmpty ?? false)
                ? content.toString()
                : 'N/A',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
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
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.6),
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
                          'Admin Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Monitor daily submissions',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadReports,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReports.isEmpty
                        ? _buildEmptyState(context)
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              children: [
                                _buildFilterCard(context),
                                const SizedBox(height: 18),
                                ..._filteredReports.map(
                                  (report) =>
                                      _buildReportTile(context, report),
                                ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 68,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports match the current filters',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWorker,
              decoration: const InputDecoration(
                labelText: 'Worker',
                border: OutlineInputBorder(),
              ),
              items: _workerOptions
                  .map(
                    (worker) => DropdownMenuItem(
                      value: worker,
                      child: Text(worker),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedWorker = value;
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : _formatDate(_selectedDate!.toIso8601String()),
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _selectedDate = null);
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, Map<String, dynamic> report) {
    final status = _getStatus(report);
    final date = _formatDate(report['date']?.toString());
    final workerName = report['workerName']?.toString() ?? 'Unknown';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onTap: () => _showReportDetails(report),
        contentPadding: const EdgeInsets.all(18),
        title: Text(
          workerName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            'Date: $date',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        trailing: Chip(
          label: Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: status == 'Present'
              ? Colors.green[100]
              : Colors.orange[100],
          side: BorderSide(
            color: status == 'Present' ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }
}

