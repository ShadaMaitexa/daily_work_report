import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsApi {
  // TODO: Replace with your Google Apps Script Web App URL
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbz3MlFCPCSRyhgKuRK8z4xpeBpyiMR1AUjmYMrvDiGFbuvejxSeMD9DtJIZfq_WUgA7-w/exec';

  static Future<Map<String, dynamic>> _postAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final body = <String, dynamic>{'action': action};
      if (data != null) {
        body.addAll(data);
      }

      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('status') &&
              !decoded.containsKey('success')) {
            final status = decoded['status']?.toString().toLowerCase();
            decoded['success'] = status == 'success' || status == 'submitted';
          }
          return decoded;
        }
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _getAction(
    Map<String, String> params,
  ) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (!decoded.containsKey('success')) {
            decoded['success'] = true;
          }
          return decoded;
        }
        return {'success': true, 'reports': decoded};
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String email,
    required String password,
  }) {
    return _postAction(
      action: 'register',
      data: {'name': name, 'email': email, 'password': password, 'phone': ''},
    );
  }

  static Future<Map<String, dynamic>> loginWorker({
    required String email,
    required String password,
  }) {
    return _postAction(
      action: 'login',
      data: {'email': email, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> submitReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) {
    return _postAction(
      action: 'submitReport',
      data: {'workerId': workerId, ...data},
    );
  } 

  static Future<Map<String, dynamic>> getWorkerReports({
    required String workerId,
  }) async {
    final response = await _getAction({
      'action': 'getWorkerReports',
      'workerId': workerId,
    });
    if (response['success'] == true) {
      final raw = response['reports'] ?? response['data'];
      response['reports'] = _normalizeWorkerReports(raw);
    }
    return response;
  }

  static Future<Map<String, dynamic>> getAllReports() {
    return _getAction({'action': 'getAllReports'});
  }

  static Future<Map<String, dynamic>> checkTodayStatus({
    required String workerId,
  }) async {
    final reportsResponse = await getWorkerReports(workerId: workerId);
    if (reportsResponse['success'] == true) {
      final reports =
          (reportsResponse['reports'] as List<Map<String, dynamic>>?) ?? [];
      final today = DateTime.now().toIso8601String().split('T').first;
      final entry = reports.cast<Map<String, dynamic>?>().firstWhere(
        (r) => r?['date'] == today,
        orElse: () => null,
      );
      final status = entry == null
          ? 'leave'
          : (entry['status']?.toString() ?? 'leave');
      return {'success': true, 'status': status, 'report': entry};
    }
    return reportsResponse;
  }

  static List<Map<String, dynamic>> _normalizeWorkerReports(dynamic raw) {
    if (raw is List) {
      final reports = raw.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        Map<String, dynamic> data = {};
        if (map['data'] is Map) {
          data = Map<String, dynamic>.from(map['data']);
        } else {
          data = map;
        }
        return {
          'date': map['date']?.toString() ?? '',
          'status': map['status']?.toString().toLowerCase() ?? 'leave',
          'completed': data['completed'] ?? data['tasksCompleted'] ?? '',
          'inprogress': data['inprogress'] ?? data['tasksInProgress'] ?? '',
          'nextsteps': data['nextsteps'] ?? data['nextSteps'] ?? '',
          'issues': data['issues'] ?? '',
          'students': _decodeStudents(data['students']),
        };
      }).toList();

      reports.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      return reports;
    }
    return [];
  }

  static List<dynamic> _decodeStudents(dynamic students) {
    if (students == null) return [];
    if (students is List) return students;
    if (students is String && students.isNotEmpty) {
      try {
        final decoded = jsonDecode(students);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }
}
