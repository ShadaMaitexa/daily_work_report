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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Filters',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedWorker,
                                decoration: const InputDecoration(
                                  labelText: 'Worker',
                                  border: OutlineInputBorder(),
                                ),
                                items: _workerOptions
                                    .map((worker) => DropdownMenuItem(
                                          value: worker,
                                          child: Text(worker),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedWorker = value;
                                  });
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _selectDate,
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        _selectedDate == null
                                            ? 'Select Date'
                                            : _formatDate(_selectedDate!
                                                .toIso8601String()),
                                      ),
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = null;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Clear Filters'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ..._filteredReports.map((report) {
                        final status = _getStatus(report);
                        final date = _formatDate(report['date']?.toString());
                        final workerName =
                            report['workerName']?.toString() ?? 'Unknown';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => _showReportDetails(report),
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              workerName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Date: $date',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                status,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: status == 'Present'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              side: BorderSide(
                                color: status == 'Present'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}

