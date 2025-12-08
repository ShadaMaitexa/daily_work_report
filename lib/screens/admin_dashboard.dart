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
      print('📊 Loaded ${reports.length} reports');

      // Debug: Print first report structure
      if (reports.isNotEmpty) {
        print('First report keys: ${reports.first.keys}');
        print('First report data: ${reports.first}');
      }

      final workers = <String>{};

      for (final report in reports) {
        // Use correct field name: 'worker_name' from database
        final workerName = report['worker_name']?.toString() ?? 'Unknown';
        
        if (workerName != 'Unknown' && workerName.isNotEmpty) {
          workers.add(workerName);
        }
      }

      setState(() {
        _allReports = reports;
        _workerOptions = ['All Workers', ...workers.toList()..sort()];
        print('👥 Worker options: $_workerOptions');
      });

      _applyFilters();
    } catch (e) {
      debugPrint("❌ Error loading reports: $e");
      // Show error in UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allReports);

    if (_selectedWorker != 'All Workers') {
      filtered = filtered.where((report) {
        final name = report['worker_name'] ?? 'Unknown';
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
    // Check if 'completed' field has content
    final completed = report['completed']?.toString() ?? '';
    return completed.trim().isNotEmpty ? 'Present' : 'Leave';
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      final dateStr = dateValue.toString();
      // Handle different date formats
      if (dateStr.contains('T')) {
        final parsed = DateTime.parse(dateStr);
        return DateFormat('d MMM yyyy').format(parsed);
      } else {
        // Already in date format
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final month = int.tryParse(parts[1]) ?? DateTime.now().month;
          final day = int.tryParse(parts[2]) ?? DateTime.now().day;
          final date = DateTime(year, month, day);
          return DateFormat('d MMM yyyy').format(date);
        }
        return dateStr;
      }
    } catch (e) {
      return dateValue.toString();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedWorker = 'All Workers';
      _selectedDate = null;
    });
    _applyFilters();
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
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
              const SizedBox(height: 20),
              _buildDetailRow('Worker', report['worker_name'] ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow('Date', _formatDate(report['date'])),
              const SizedBox(height: 12),
              _buildDetailRow('Status', _getStatus(report)),
              const SizedBox(height: 20),
              _buildSectionTitle('Tasks Completed'),
              const SizedBox(height: 8),
              _buildDetailText(report['completed']?.toString() ?? 'No tasks completed'),
              const SizedBox(height: 16),
              _buildSectionTitle('Tasks In Progress'),
              const SizedBox(height: 8),
              _buildDetailText(report['inprogress']?.toString() ?? 'No tasks in progress'),
              const SizedBox(height: 16),
              _buildSectionTitle('Next Steps'),
              const SizedBox(height: 8),
              _buildDetailText(report['nextsteps']?.toString() ?? 'No next steps'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14)),
    );
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 50,
              height: 50,
              color: Colors.white,
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${_allReports.length} total reports',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadReports,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, Map<String, dynamic> report) {
    final workerName = report['worker_name']?.toString() ?? 'Unknown';
    final status = _getStatus(report);
    final date = _formatDate(report['date']);
    final completedTasks = report['completed']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showReportDetails(report),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: status == "Present" ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            status == "Present" ? Icons.check : Icons.pending,
            color: status == "Present" ? Colors.green[800] : Colors.orange[800],
          ),
        ),
        title: Text(
          workerName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              date,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            if (completedTasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  completedTasks.length > 40
                      ? '${completedTasks.substring(0, 40)}...'
                      : completedTasks,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            status,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: status == "Present" ? Colors.green[800] : Colors.orange[800],
            ),
          ),
          backgroundColor: status == "Present" ? Colors.green[100] : Colors.orange[100],
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_selectedWorker != 'All Workers' || _selectedDate != null)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: _selectedWorker,
              items: _workerOptions.map((w) {
                return DropdownMenuItem(
                  value: w,
                  child: Text(w),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedWorker = v!;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                labelText: 'Worker',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Theme.of(context).primaryColor,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _applyFilters();
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate == null
                        ? "Select Date"
                        : DateFormat('d MMM yyyy').format(_selectedDate!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No reports found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedWorker != 'All Workers' || _selectedDate != null
                  ? 'No reports match your filters'
                  : 'No reports have been submitted yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedWorker != 'All Workers' || _selectedDate != null)
              ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Reset Filters'),
              ),
          ],
        ),
      ),
    );
  }
}