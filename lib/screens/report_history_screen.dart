import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/sheets_api.dart';

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
      final result =
          await SheetsApi.getWorkerReports(workerId: workerId.toString());

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
          _errorMessage = result['message']?.toString() ?? 
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
      DateTime dateTime;
      final dateStr = dateValue.toString().trim();
      
      // Try parsing ISO format (2025-11-17T18:30:00.000Z)
      if (dateStr.contains('T')) {
        dateTime = DateTime.parse(dateStr);
      }
      // Try parsing simple date format (2025-11-17)
      else if (dateStr.contains('-') && dateStr.length >= 10) {
        dateTime = DateTime.parse(dateStr.split(' ').first);
      }
      // Try parsing as timestamp
      else {
        final timestamp = int.tryParse(dateStr);
        if (timestamp != null) {
          // Check if it's milliseconds or seconds
          dateTime = timestamp > 1000000000000
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else {
          return dateStr; // Return as-is if can't parse
        }
      }
      
      // Format as "17 November 2025" or "17 Nov 2025"
      return DateFormat('d MMMM yyyy').format(dateTime);
    } catch (e) {
      // If parsing fails, try to extract just the date part
      final dateStr = dateValue.toString();
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2].split('T').first.split(' ').first);
            final dateTime = DateTime(year, month, day);
            return DateFormat('d MMMM yyyy').format(dateTime);
          } catch (_) {
            return dateStr;
          }
        }
      }
      return dateStr;
    }
  }

  String _getTasksPreview(Map<String, dynamic> report) {
    final tasksCompleted =
        report['completed']?.toString() ?? report['tasksCompleted']?.toString() ?? '';
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
              _buildDetailRow(
                'Status',
                _getStatus(report),
              ),
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
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Reports',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                          const SizedBox(height: 8),
                          Text(
                            'Your submitted reports will appear here',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
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
                                  color: Colors.grey[700],
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
                                ? Colors.green[100]
                                : Colors.orange[100],
                            side: BorderSide(
                              color: status == 'Present'
                                  ? Colors.green
                                  : Colors.orange,
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
