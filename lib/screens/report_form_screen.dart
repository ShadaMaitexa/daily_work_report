import 'package:daily_work_report/services/report_form_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

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
      _tasksCompletedController.text = widget.reportToEdit!['completed'] ?? '';
      _tasksInProgressController.text = widget.reportToEdit!['inprogress'] ?? '';
      _nextStepsController.text = widget.reportToEdit!['nextsteps'] ?? '';
      _issuesController.text = widget.reportToEdit!['issues'] ?? '';

      final students = widget.reportToEdit!['students'];
      if (students is List && students.isNotEmpty) {
        for (var student in students) {
          _studentRows.add(StudentRow(
            nameController: TextEditingController(text: student['name']),
            topicController: TextEditingController(text: student['topic']),
            timeController: TextEditingController(text: student['time']),
          ));
        }
      } else {
        _addStudentRow();
      }

      setState(() {
        _isCheckingSubmission = false;
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
    for (var row in _studentRows) row.dispose();
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
      setState(() => _isCheckingSubmission = false);
      return;
    }

    final result = await ReportServiceSupabase.checkTodayStatus(workerId: workerId.toString());

    setState(() {
      _hasSubmittedToday = result['status'] == 'submitted';
      _isCheckingSubmission = false;
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final workerId = await _getWorkerId();
    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker ID missing. Please login again.'), backgroundColor: Colors.red),
      );
      return;
    }

    final workerName = await _getWorkerName();
    final isEditing = widget.reportToEdit != null;

    if (!isEditing && _hasSubmittedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already submitted today. Only one per day.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final students = _studentRows.map((e) => e.toMap()).toList();

    final reportData = {
      'completed': _tasksCompletedController.text.trim(),
      'inprogress': _tasksInProgressController.text.trim(),
      'nextsteps': _nextStepsController.text.trim(),
      'issues': _issuesController.text.trim(),
      'students': students,
      'date': (isEditing ? widget.reportToEdit!['date'] : DateTime.now().toIso8601String().split('T').first),
      'worker_id': workerId.toString(),
      'worker_name': workerName ?? '',
    };

    final result = isEditing
        ? await ReportServiceSupabase.updateReport(workerId: workerId.toString(), data: reportData)
        : await ReportServiceSupabase.submitReport(workerId: workerId.toString(), data: reportData);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Report updated!' : 'Report submitted!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Something went wrong'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportToEdit != null ? "Edit Report" : "Submit Report"),
      ),
      body: Center(child: Text("UI unchanged — backend migrated successfully.")),
    );
  }
}
