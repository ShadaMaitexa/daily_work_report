import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sheets_api.dart';

class StudentRow {
  final TextEditingController nameController;
  final TextEditingController topicController;
  final TextEditingController timeController;

  StudentRow({
    required this.nameController,
    required this.topicController,
    required this.timeController,
  });

  void dispose() {
    nameController.dispose();
    topicController.dispose();
    timeController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'topic': topicController.text.trim(),
      'time': timeController.text.trim(),
    };
  }
}

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tasksCompletedController = TextEditingController();
  final _tasksInProgressController = TextEditingController();
  final _nextStepsController = TextEditingController();
  final _issuesController = TextEditingController();
  
  List<StudentRow> _studentRows = [];
  bool _isLoading = false;
  bool _hasSubmittedToday = false;
  bool _isCheckingSubmission = true;

  @override
  void initState() {
    super.initState();
    _addStudentRow();
    _checkTodaySubmission();
  }

  @override
  void dispose() {
    _tasksCompletedController.dispose();
    _tasksInProgressController.dispose();
    _nextStepsController.dispose();
    _issuesController.dispose();
    for (var row in _studentRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addStudentRow() {
    setState(() {
      _studentRows.add(StudentRow(
        nameController: TextEditingController(),
        topicController: TextEditingController(),
        timeController: TextEditingController(),
      ));
    });
  }

  void _removeStudentRow(int index) {
    if (_studentRows.length > 1) {
      setState(() {
        _studentRows[index].dispose();
        _studentRows.removeAt(index);
      });
    }
  }

  Future<int?> _getWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('workerId');
  }

  Future<String?> _getWorkerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('workerName');
  }

  Future<void> _checkTodaySubmission() async {
    final workerId = await _getWorkerId();
    if (workerId == null) {
      setState(() {
        _isCheckingSubmission = false;
      });
      return;
    }

    final hasSubmitted = await _hasSubmittedTodayCheck(workerId);
    setState(() {
      _hasSubmittedToday = hasSubmitted;
      _isCheckingSubmission = false;
    });
  }

  Future<void> _submitReport() async {
    if (_hasSubmittedToday) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted today\'s report. Only one submission per day is allowed.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workerId = await _getWorkerId();
    if (workerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker ID not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Double check before submitting
    if (await _hasSubmittedTodayCheck(workerId)) {
      setState(() {
        _hasSubmittedToday = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted today\'s report. Only one submission per day is allowed.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final workerName = await _getWorkerName();

    setState(() {
      _isLoading = true;
    });

    final students = _studentRows
        .map((row) => row.toMap())
        .where((student) =>
            student['name']!.isNotEmpty ||
            student['topic']!.isNotEmpty ||
            student['time']!.isNotEmpty)
        .toList();

    final reportData = {
      'completed': _tasksCompletedController.text.trim(),
      'inprogress': _tasksInProgressController.text.trim(),
      'nextsteps': _nextStepsController.text.trim(),
      'issues': _issuesController.text.trim(),
      'students': students,
      'date': DateTime.now().toIso8601String().split('T').first,
      'name': workerName ?? '',
    };

    final result = await SheetsApi.submitReport(
      workerId: workerId.toString(),
      data: reportData,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _hasSubmittedToday = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Today Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isCheckingSubmission
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _hasSubmittedToday
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Report Already Submitted',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You have already submitted today\'s report.\nOnly one submission per day is allowed.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Daily Work Report',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                TextFormField(
                  controller: _tasksCompletedController,
                  decoration: const InputDecoration(
                    labelText: 'Tasks Completed',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle),
                    filled: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tasks completed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tasksInProgressController,
                  decoration: const InputDecoration(
                    labelText: 'Tasks In Progress',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                    filled: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tasks in progress';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nextStepsController,
                  decoration: const InputDecoration(
                    labelText: 'Next Steps',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.arrow_forward),
                    filled: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter next steps';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _issuesController,
                  decoration: const InputDecoration(
                    labelText: 'Issues',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warning),
                    filled: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter issues';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Students',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addStudentRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Student'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(_studentRows.length, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Student ${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_studentRows.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeStudentRow(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _studentRows[index].nameController,
                            decoration: const InputDecoration(
                              labelText: 'Student Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _studentRows[index].topicController,
                            decoration: const InputDecoration(
                              labelText: 'Topic Taken',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _studentRows[index].timeController,
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                              filled: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_isLoading || _hasSubmittedToday)
                      ? null
                      : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _hasSubmittedTodayCheck(int workerId) async {
    final result =
        await SheetsApi.checkTodayStatus(workerId: workerId.toString());
    if (result['success'] == true) {
      // Check if there's a report entry for today (not just status)
      final report = result['report'];
      if (report != null) {
        // If there's a report entry for today, it means already submitted
        return true;
      }
      // Also check status as fallback
      final status = result['status']?.toString().toLowerCase();
      return status == 'submitted';
    }
    return false;
  }
}
