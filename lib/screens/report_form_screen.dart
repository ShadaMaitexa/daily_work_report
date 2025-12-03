import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sheets_api.dart';
import '../theme/app_theme.dart';

class StudentRow {
  final TextEditingController nameController;
  final TextEditingController activityController;

  StudentRow({required this.nameController, required this.activityController});

  void dispose() {
    nameController.dispose();
    activityController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'activity': activityController.text.trim(),
    };
  }
}

class ReportFormScreen extends StatefulWidget {
  final Map<String, dynamic>? reportToEdit;

  const ReportFormScreen({super.key, this.reportToEdit});

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
    if (widget.reportToEdit != null) {
      // Populate form with existing report data
      _tasksCompletedController.text =
          widget.reportToEdit!['completed']?.toString() ?? '';
      _tasksInProgressController.text =
          widget.reportToEdit!['inprogress']?.toString() ?? '';
      _nextStepsController.text =
          widget.reportToEdit!['nextsteps']?.toString() ?? '';
      _issuesController.text = widget.reportToEdit!['issues']?.toString() ?? '';

      // Populate student rows
      final students = widget.reportToEdit!['students'];
      if (students is List && students.isNotEmpty) {
        for (var student in students) {
          final row = StudentRow(
            nameController: TextEditingController(
              text: student['name']?.toString() ?? '',
            ),
            activityController: TextEditingController(
              text:
                  student['activity']?.toString() ??
                  student['topic']?.toString() ??
                  '',
            ),
          );
          _studentRows.add(row);
        }
      } else {
        _addStudentRow();
      }

      // Don't check for today's submission if editing
      setState(() {
        _isCheckingSubmission = false;
        _hasSubmittedToday = false;
      });
    } else {
      _addStudentRow();
      _checkTodaySubmission();
    }
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
      _studentRows.add(
        StudentRow(
          nameController: TextEditingController(),
          activityController: TextEditingController(),
        ),
      );
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

    final workerName = await _getWorkerName();
    final isEditing = widget.reportToEdit != null;

    // Only check for today's submission if creating new report
    if (!isEditing) {
      if (_hasSubmittedToday) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already submitted today\'s report. Only one submission per day is allowed.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
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
            content: Text(
              'You have already submitted today\'s report. Only one submission per day is allowed.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final students = _studentRows
        .map((row) => row.toMap())
        .where(
          (student) =>
              student['name']!.isNotEmpty ||
              student['topic']!.isNotEmpty ||
              student['time']!.isNotEmpty,
        )
        .toList();

    final reportData = {
      'completed': _tasksCompletedController.text.trim(),
      'inprogress': _tasksInProgressController.text.trim(),
      'nextsteps': _nextStepsController.text.trim(),
      'issues': _issuesController.text.trim(),
      'students': students,
      'date': isEditing
          ? widget.reportToEdit!['date']?.toString() ??
                DateTime.now().toIso8601String().split('T').first
          : DateTime.now().toIso8601String().split('T').first,
      'name': workerName ?? '',
    };

    final result = isEditing
        ? await SheetsApi.updateReport(
            workerId: workerId.toString(),
            data: reportData,
          )
        : await SheetsApi.submitReport(
            workerId: workerId.toString(),
            data: reportData,
          );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // Check success status - handle both 'success' field and 'status' field
    final isSuccess =
        result['success'] == true ||
        (result['status']?.toString().toLowerCase() == 'submitted' &&
            result['success'] != false);

    if (isSuccess && result['status']?.toString().toLowerCase() != 'error') {
      if (!isEditing) {
        setState(() {
          _hasSubmittedToday = true;
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Report updated successfully!'
                : 'Report submitted successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Check if report already exists
      if (result['alreadyExists'] == true ||
          result['status']?.toString().toLowerCase() == 'error') {
        setState(() {
          _hasSubmittedToday = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'A report for this date already exists. Only one submission per day is allowed.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  (isEditing
                      ? 'Failed to update report'
                      : 'Failed to submit report'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reportToEdit != null ? 'Edit Report' : 'Submit Today Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AcadenoTheme.heroGradient),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AcadenoTheme.auroraGradient),
        child: SafeArea(
          child: _isCheckingSubmission
              ? const Center(child: CircularProgressIndicator())
              : _hasSubmittedToday
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
                            Icons.check_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: AcadenoTheme.heroGradient,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: 42,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.reportToEdit != null
                                          ? 'Update today\'s progress'
                                          : 'Share today’s impact',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Give us a quick look into your achievements and next moves.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _tasksCompletedController,
                          decoration: _fieldDecoration(
                            'Tasks Completed',
                            Icons.check_circle,
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
                          decoration: _fieldDecoration(
                            'Tasks In Progress',
                            Icons.work,
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
                          decoration: _fieldDecoration(
                            'Next Steps',
                            Icons.arrow_forward,
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
                          decoration: _fieldDecoration('Issues', Icons.warning),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Student ${index + 1}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_studentRows.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeStudentRow(index),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller:
                                        _studentRows[index].nameController,
                                    decoration: _fieldDecoration(
                                      'Student Name',
                                      Icons.person,
                                    ),
                                    validator: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          _studentRows[index]
                                              .activityController
                                              .text
                                              .isEmpty) {
                                        return 'Please enter activity for this student';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller:
                                        _studentRows[index].activityController,
                                    decoration: _fieldDecoration(
                                      'Activity Performed',
                                      Icons.assignment,
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          _studentRows[index]
                                              .nameController
                                              .text
                                              .isEmpty) {
                                        return 'Please enter student name for this activity';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed:
                              (_isLoading ||
                                  (widget.reportToEdit == null &&
                                      _hasSubmittedToday))
                              ? null
                              : _submitReport,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.reportToEdit != null
                                      ? 'Update Report'
                                      : 'Submit Report',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<bool> _hasSubmittedTodayCheck(int workerId) async {
    final result = await SheetsApi.checkTodayStatus(
      workerId: workerId.toString(),
    );
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

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
    );
  }
}
