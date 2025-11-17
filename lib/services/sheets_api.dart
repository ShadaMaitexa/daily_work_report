import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsApi {
  // TODO: Replace with your Google Apps Script Web App URL
  static const String _scriptUrl = 'YOUR_GOOGLE_APPS_SCRIPT_WEB_APP_URL';

  static Future<Map<String, dynamic>> _callScript({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': action,
          'data': data ?? <String, dynamic>{},
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String email,
    required String password,
  }) {
    return _callScript(
      action: 'registerWorker',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> loginWorker({
    required String email,
    required String password,
  }) {
    return _callScript(
      action: 'loginWorker',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> submitReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) {
    return _callScript(
      action: 'submitReport',
      data: {
        'workerId': workerId,
        ...data,
      },
    );
  }

  static Future<Map<String, dynamic>> getWorkerReports({
    required String workerId,
  }) {
    return _callScript(
      action: 'getWorkerReports',
      data: {'workerId': workerId},
    );
  }

  static Future<Map<String, dynamic>> getAllReports() {
    return _callScript(action: 'getAllReports');
  }

  static Future<Map<String, dynamic>> checkTodayStatus({
    required String workerId,
  }) {
    return _callScript(
      action: 'checkTodayStatus',
      data: {'workerId': workerId},
    );
  }
}

