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

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<String?> _getWorkerId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('workerId'); // Changed from getInt to getString
}

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final workerId = await _getWorkerId();
    if (workerId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Worker ID not found. Please login again.';
      });
      return;
    }

    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('user_id', workerId)
          .order('date', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          _reports = response.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reports: $e';
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
      return DateFormat(
        'd MMMM yyyy',
      ).format(DateTime(parsed.year, parsed.month, parsed.day));
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
              Text(
                'Report Details',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Date', _formatDate(report['date'])),
              const SizedBox(height: 16),
              _buildDetailRow('Status', _getStatus(report)),
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
                  (report['students'] is List &&
                      report['students'].isNotEmpty)) ...[
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
                          _buildDetailRow('Name', student['name']),
                          const SizedBox(height: 8),
                          _buildDetailRow('Topic', student['topic']),
                          const SizedBox(height: 8),
                          _buildDetailRow('Time', student['time']),
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
          'Report History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AcadenoTheme.auroraGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              )
            : _reports.isEmpty
            ? Center(
                child: Text(
                  'No reports found',
                  style: GoogleFonts.poppins(fontSize: 16),
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
                        title: Text(
                          _formatDate(report['date']),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                          label: Text(
                            _getStatus(report),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
}
