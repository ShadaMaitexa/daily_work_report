import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdmin = prefs.getBool('isAdmin') ?? false;
    _loadReports();
  }

  Future<String?> _getWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('workerId');
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isAdmin) {
        // ADMIN: Get all reports from all workers
        print('👑 Admin loading ALL reports...');
        final response = await supabase
            .from('reports')
            .select()
            .order('date', ascending: false);

        if (response.isNotEmpty) {
          setState(() {
            _reports = response.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          print('✅ Admin loaded ${_reports.length} reports');
        } else {
          setState(() {
            _reports = [];
            _isLoading = false;
          });
        }
      } else {
        // WORKER: Get only their own reports
        final workerId = await _getWorkerId();
        if (workerId == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Worker ID not found. Please login again.';
          });
          return;
        }

        print('👷 Worker loading reports for ID: $workerId');
        final response = await supabase
            .from('reports')
            .select()
            .eq('worker_id', workerId)  // Changed from 'user_id' to 'worker_id'
            .order('date', ascending: false);

        if (response.isNotEmpty) {
          setState(() {
            _reports = response.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          print('✅ Worker loaded ${_reports.length} reports');
        } else {
          setState(() {
            _reports = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading reports: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reports: ${e.toString()}';
      });
    }
  }

  String _getStatus(Map<String, dynamic> report) {
    final completed = (report['completed'] ?? '').toString().trim();
    return completed.isNotEmpty ? 'Present' : 'Leave';
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      final parsed = DateTime.parse(dateValue.toString());
      return DateFormat('d MMMM yyyy').format(parsed);
    } catch (_) {
      return dateValue.toString();
    }
  }

  String _getTasksPreview(Map<String, dynamic> report) {
    final tasksCompleted = report['completed']?.toString() ?? '';
    if (tasksCompleted.isEmpty) return 'No tasks completed';
    return tasksCompleted.length > 50
        ? '${tasksCompleted.substring(0, 50)}...'
        : tasksCompleted;
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAdmin && report['worker_name'] != null)
                    Chip(
                      label: Text(
                        report['worker_name'],
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Date', _formatDate(report['date'])),
              const SizedBox(height: 16),
              _buildDetailRow('Status', _getStatus(report)),
              if (_isAdmin && report['worker_name'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow('Worker', report['worker_name'] ?? 'Unknown'),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('Tasks Completed'),
              const SizedBox(height: 8),
              _buildDetailText(report['completed']?.toString() ?? 'N/A'),
              const SizedBox(height: 24),
              _buildSectionTitle('Tasks In Progress'),
              const SizedBox(height: 8),
              _buildDetailText(report['inprogress']?.toString() ?? 'N/A'),
              const SizedBox(height: 24),
              _buildSectionTitle('Next Steps'),
              const SizedBox(height: 8),
              _buildDetailText(report['nextsteps']?.toString() ?? 'N/A'),
              const SizedBox(height: 24),
              _buildSectionTitle('Issues'),
              const SizedBox(height: 8),
              _buildDetailText(report['issues']?.toString() ?? 'N/A'),
              if (report['students'] != null &&
                  (report['students'] is List && report['students'].isNotEmpty)) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Students'),
                const SizedBox(height: 16),
                ...(report['students'] as List).map((student) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Name', student['name'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Topic', student['topic'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Time', student['time'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 32),
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
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 14))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _isAdmin ? 'All Reports' : 'My Reports',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterOptions(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AcadenoTheme.auroraGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadReports,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox, size: 80, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              _isAdmin ? 'No reports found' : 'No reports submitted yet',
                              style: GoogleFonts.poppins(fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isAdmin 
                                ? 'Workers haven\'t submitted any reports yet'
                                : 'Submit your first report from the home screen',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
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
                                onTap: () => _showReportDetails(report),
                                contentPadding: const EdgeInsets.all(20),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(report['date']),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (_isAdmin && report['worker_name'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'By: ${report['worker_name']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getTasksPreview(report),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                                trailing: Chip(
                                  backgroundColor: _getStatus(report) == 'Present'
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  label: Text(
                                    _getStatus(report),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _getStatus(report) == 'Present'
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Reports',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('All Workers'),
                onTap: () {
                  Navigator.pop(context);
                  _loadReports(); // Load all reports
                },
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Today'),
                onTap: () {
                  Navigator.pop(context);
                  _filterByDate(DateTime.now());
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('This Week'),
                onTap: () {
                  Navigator.pop(context);
                  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
                  _filterByDateRange(weekAgo, DateTime.now());
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_alt),
                title: const Text('Present Only'),
                onTap: () {
                  Navigator.pop(context);
                  _filterByStatus('Present');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _filterByDate(DateTime date) async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('date', dateStr)
          .order('date', ascending: false);
      
      setState(() {
        _reports = response.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Filter error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _filterByDateRange(DateTime start, DateTime end) async {
    setState(() => _isLoading = true);
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    
    try {
      final response = await supabase
          .from('reports')
          .select()
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: false);
      
      setState(() {
        _reports = response.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Filter error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _filterByStatus(String status) async {
    setState(() => _isLoading = true);
    
    try {
      // Get all reports and filter locally
      final response = await supabase
          .from('reports')
          .select()
          .order('date', ascending: false);
      
      final filtered = response.where((report) {
        final completed = (report['completed'] ?? '').toString().trim();
        final reportStatus = completed.isNotEmpty ? 'Present' : 'Leave';
        return reportStatus == status;
      }).toList();
      
      setState(() {
        _reports = filtered.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Filter error: $e';
        _isLoading = false;
      });
    }
  }
}