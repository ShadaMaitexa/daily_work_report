import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/sheets_api.dart';
import '../theme/app_theme.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
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
    return prefs.getInt('workerId')?.toString();
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
      final result = await SheetsApi.getWorkerReports(
        workerId: workerId.toString(),
      );

      print('Report History - API Result: $result');

      if (result['success'] == true) {
        final reportsList = result['reports'];
        print('Reports list: $reportsList');
        print('Reports list type: ${reportsList.runtimeType}');

        if (reportsList != null) {
          if (reportsList is List) {
            setState(() {
              _reports = reportsList
                  .whereType<Map<String, dynamic>>()
                  .map((r) => Map<String, dynamic>.from(r))
                  .toList();
              _isLoading = false;
              _errorMessage = null;
            });
            print('Loaded ${_reports.length} reports');
          } else {
            print('Reports is not a List, it is: ${reportsList.runtimeType}');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Unexpected data format received from server.';
            });
          }
        } else {
          print('Reports list is null');
          setState(() {
            _isLoading = false;
            _reports = [];
          });
        }
      } else {
        print('API call was not successful: ${result['message']}');
        setState(() {
          _isLoading = false;
          _errorMessage =
              result['message']?.toString() ??
              'Failed to load reports. Please try again.';
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reports: $e';
      });
    }
  }

  String _getStatus(Map<String, dynamic> report) {
    final status = (report['status'] ?? '').toString().toLowerCase();
    return status == 'submitted' ? 'Present' : 'Leave';
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      final dateStr = dateValue.toString().trim();

      // Extract date parts from string (handles "2025-11-17" format)
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          try {
            // Extract just the date part (YYYY-MM-DD) before any time or other data
            final dateOnly =
                parts[0] +
                '-' +
                parts[1] +
                '-' +
                parts[2].split('T').first.split(' ').first;
            final dateParts = dateOnly.split('-');

            if (dateParts.length == 3) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);

              // Create DateTime in local timezone (not UTC) to avoid day shift
              final dateTime = DateTime(year, month, day);

              // Format as "17 November 2025"
              return DateFormat('d MMMM yyyy').format(dateTime);
            }
          } catch (e) {
            print('Error parsing date parts: $e');
          }
        }
      }

      // Try parsing ISO format with timezone (2025-11-17T18:30:00.000Z)
      if (dateStr.contains('T')) {
        try {
          final parsed = DateTime.parse(dateStr);
          // Use the date components directly to avoid timezone issues
          return DateFormat(
            'd MMMM yyyy',
          ).format(DateTime(parsed.year, parsed.month, parsed.day));
        } catch (e) {
          print('Error parsing ISO date: $e');
        }
      }

      // Try parsing as timestamp
      final timestamp = int.tryParse(dateStr);
      if (timestamp != null) {
        try {
          // Check if it's milliseconds or seconds
          final dateTime = timestamp > 1000000000000
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          // Use date components to avoid timezone shift
          return DateFormat(
            'd MMMM yyyy',
          ).format(DateTime(dateTime.year, dateTime.month, dateTime.day));
        } catch (e) {
          print('Error parsing timestamp: $e');
        }
      }

      // Fallback: return as-is
      return dateStr;
    } catch (e) {
      print('Error in _formatDate: $e, value: $dateValue');
      return dateValue.toString();
    }
  }

  String _getTasksPreview(Map<String, dynamic> report) {
    final tasksCompleted =
        report['completed']?.toString() ??
        report['tasksCompleted']?.toString() ??
        '';
    if (tasksCompleted.isEmpty) {
      return 'No tasks completed';
    }
    // Show first 50 characters as preview
    if (tasksCompleted.length > 50) {
      return '${tasksCompleted.substring(0, 50)}...';
    }
    return tasksCompleted;
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
                  (report['students'] as List).isNotEmpty) ...[
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AcadenoTheme.heroGradient,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Reports',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadReports,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.6),
                      ),
                      child: Icon(
                        Icons.inbox,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reports found',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your submitted reports will appear here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadReports,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final status = _getStatus(report);
                    final tasksPreview = _getTasksPreview(report);

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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        onTap: () => _showReportDetails(report),
                        title: Text(
                          _formatDate(report['date']),
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
                              tasksPreview,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                              ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                          side: BorderSide(
                            color: status == 'Present'
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.secondary,
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
