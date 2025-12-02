import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsApi {
  // TODO: Replace with your Google Apps Script Web App URL
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbyPTe9xQc2KA2V-jcT1xxyrB27AZdi_aGg0Zoy7WzaB_LHOhdAptRMOw3VZSYHrOE9zNg/exec';

  static Future<Map<String, dynamic>> _postAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final body = <String, dynamic>{'action': action};
      if (data != null) {
        body.addAll(data);
      }

      print('POST request - Action: $action');
      print('POST request - Body: $body');

      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('POST response status: ${response.statusCode}');
      print('POST response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          print('POST decoded response type: ${decoded.runtimeType}');
          print('POST decoded response: $decoded');

          if (decoded is Map<String, dynamic>) {
            // Handle different response formats
            if (!decoded.containsKey('success')) {
              // Check for status field
              if (decoded.containsKey('status')) {
                final status = decoded['status']?.toString().toLowerCase();
                // If status is 'error', success should be false
                if (status == 'error') {
                  decoded['success'] = false;
                } else {
                  decoded['success'] =
                      status == 'success' ||
                      status == 'submitted' ||
                      status == 'logged in' ||
                      status == 'login successful';
                }
              }
              // Check if workerId exists (indicates successful login)
              else if (decoded.containsKey('workerId') ||
                  decoded.containsKey('id') ||
                  decoded.containsKey('userId')) {
                decoded['success'] = true;
                // Normalize workerId field
                if (decoded.containsKey('id') &&
                    !decoded.containsKey('workerId')) {
                  decoded['workerId'] = decoded['id'];
                }
                if (decoded.containsKey('userId') &&
                    !decoded.containsKey('workerId')) {
                  decoded['workerId'] = decoded['userId'];
                }
              }
              // If no success indicator, default to false
              else {
                decoded['success'] = false;
              }
            }
            return decoded;
          }

          // If decoded is not a Map, wrap it
          return {'success': true, 'data': decoded};
        } catch (e) {
          print('Error decoding POST response: $e');
          return {
            'success': false,
            'message': 'Failed to parse server response: $e',
            'rawBody': response.body,
          };
        }
      }

      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('POST action error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _getAction(
    Map<String, String> params,
  ) async {
    try {
      // Try GET request first
      final uri = Uri.parse(_scriptUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      print('GET request status: ${response.statusCode}');
      print('GET request body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML (error page from Google Apps Script)
        final body = response.body.trim();
        if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
          print('GET returned HTML error page, falling back to POST');
          return await _postAction(
            action: params['action'] ?? '',
            data: Map<String, dynamic>.from(params),
          );
        }

        try {
          final decoded = jsonDecode(response.body);
          print('Decoded response type: ${decoded.runtimeType}');

          if (decoded is Map<String, dynamic>) {
            if (!decoded.containsKey('success')) {
              decoded['success'] = true;
            }
            return decoded;
          }

          // If decoded is a List, wrap it
          if (decoded is List) {
            return {'success': true, 'reports': decoded, 'data': decoded};
          }

          return {'success': true, 'reports': decoded, 'data': decoded};
        } catch (e) {
          print('Error decoding JSON: $e');
          // If JSON decode fails and it looks like HTML, try POST fallback
          if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
            print(
              'JSON decode failed due to HTML response, falling back to POST',
            );
            return await _postAction(
              action: params['action'] ?? '',
              data: Map<String, dynamic>.from(params),
            );
          }
          // If JSON decode fails, try to return the raw body as string
          return {
            'success': false,
            'message': 'Failed to parse response: $e',
            'rawBody': response.body,
          };
        }
      }

      // If GET fails, try POST as fallback (some Google Apps Scripts require POST)
      print('GET failed, trying POST as fallback');
      return await _postAction(
        action: params['action'] ?? '',
        data: Map<String, dynamic>.from(params),
      );
    } catch (e) {
      print('GET action error: $e');
      // Try POST as fallback
      try {
        return await _postAction(
          action: params['action'] ?? '',
          data: Map<String, dynamic>.from(params),
        );
      } catch (postError) {
        return {
          'success': false,
          'message': 'Error: $e (POST fallback also failed: $postError)',
        };
      }
    }
  }

  static Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _postAction(
      action: 'register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> loginWorker({
    required String email,
    required String password,
  }) async {
    // Ensure email is trimmed and lowercase, password is trimmed
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    print(
      'Login attempt - Email: "$normalizedEmail", Password length: ${normalizedPassword.length}',
    );

    final result = await _postAction(
      action: 'login',
      data: {'email': normalizedEmail, 'password': normalizedPassword},
    );

    print('Login result: $result');

    // The Google Apps Script returns { status: 'success' } or { status: 'error' }
    // Update success based on status field
    if (result.containsKey('status')) {
      final status = result['status']?.toString().toLowerCase();
      result['success'] = status == 'success';

      if (status == 'error') {
        result['message'] = result['message'] ?? 'Invalid login credentials';
      }
    }

    // Additional validation for login response
    if (result['success'] == true) {
      // Ensure workerId exists in the response
      if (result['workerId'] == null &&
          result['id'] == null &&
          result['userId'] == null) {
        print('Warning: Login successful but no workerId found in response');
        // Try to extract from nested data
        if (result['data'] is Map) {
          final data = result['data'] as Map<String, dynamic>;
          if (data['workerId'] != null) {
            result['workerId'] = data['workerId'];
          } else if (data['id'] != null) {
            result['workerId'] = data['id'];
          }
        }
      }
    }

    return result;
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

  static Future<Map<String, dynamic>> updateReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) {
    return _postAction(
      action: 'updateReport',
      data: {'workerId': workerId, ...data},
    );
  }

  static Future<Map<String, dynamic>> getWorkerReports({
    required String workerId,
  }) async {
    // Use POST directly since Google Apps Script only has doPost function
    final response = await _postAction(
      action: 'getWorkerReports',
      data: {'workerId': workerId},
    );

    // Debug: Print response to understand structure
    print('getWorkerReports response: $response');

    if (response['success'] == true) {
      // Try multiple possible response formats
      dynamic raw =
          response['reports'] ??
          response['data'] ??
          response['result'] ??
          response;

      // If raw is the entire response map, try to extract reports
      if (raw is Map && raw.containsKey('reports')) {
        raw = raw['reports'];
      } else if (raw is Map && raw.containsKey('data')) {
        raw = raw['data'];
      }

      final normalized = _normalizeWorkerReports(raw);
      print('Normalized reports count: ${normalized.length}');
      return {'success': true, 'reports': normalized};
    }

    // If success is false or not present, still try to extract reports
    dynamic raw = response['reports'] ?? response['data'] ?? response['result'];

    if (raw != null) {
      final normalized = _normalizeWorkerReports(raw);
      if (normalized.isNotEmpty) {
        return {'success': true, 'reports': normalized};
      }
    }

    return response;
  }

  static Future<Map<String, dynamic>> getAllReports() async {
    // Use POST directly since Google Apps Script only has doPost function
    final response = await _postAction(action: 'getAllReports', data: {});

    print('getAllReports response: $response');

    if (response['success'] == true) {
      final raw = response['reports'] ?? response['data'];
      if (raw != null) {
        // Normalize reports if needed
        if (raw is List) {
          return {'success': true, 'reports': raw};
        }
      }
    }

    return response;
  }

  static Future<Map<String, dynamic>> checkTodayStatus({
    required String workerId,
  }) async {
    final reportsResponse = await getWorkerReports(workerId: workerId);
    if (reportsResponse['success'] == true) {
      final reports =
          (reportsResponse['reports'] as List<Map<String, dynamic>>?) ?? [];
      final today = DateTime.now().toIso8601String().split('T').first;

      // Find report for today - normalize dates for comparison
      Map<String, dynamic>? entry;
      for (var report in reports) {
        final reportDate = report['date']?.toString() ?? '';
        // Normalize date (extract just YYYY-MM-DD part)
        final normalizedReportDate = reportDate.split('T')[0].split(' ')[0];
        if (normalizedReportDate == today) {
          entry = report;
          break;
        }
      }

      final status = entry == null
          ? 'leave'
          : (entry['status']?.toString() ?? 'leave');
      return {'success': true, 'status': status, 'report': entry};
    }
    return reportsResponse;
  }

  static List<Map<String, dynamic>> _normalizeWorkerReports(dynamic raw) {
    print('_normalizeWorkerReports input type: ${raw.runtimeType}');
    print('_normalizeWorkerReports input: $raw');

    if (raw == null) {
      print('Raw data is null');
      return [];
    }

    // Handle List response
    if (raw is List) {
      print('Raw is List with ${raw.length} items');
      final reports = raw
          .whereType<Map>()
          .map((item) {
            try {
              final map = Map<String, dynamic>.from(item);
              Map<String, dynamic> data = {};

              // Check if data is nested in 'data' field
              if (map['data'] is Map) {
                data = Map<String, dynamic>.from(map['data']);
              } else {
                // Data might be at the root level
                data = map;
              }

              // Extract date - try multiple possible field names
              final date =
                  map['date']?.toString() ??
                  data['date']?.toString() ??
                  map['Date']?.toString() ??
                  '';

              // Extract status - try multiple possible field names
              final statusStr =
                  (map['status'] ?? data['status'] ?? map['Status'] ?? 'leave')
                      .toString()
                      .toLowerCase();

              final normalized = {
                'date': date,
                'status': statusStr,
                'completed':
                    data['completed'] ??
                    data['tasksCompleted'] ??
                    data['Completed'] ??
                    map['completed'] ??
                    '',
                'inprogress':
                    data['inprogress'] ??
                    data['tasksInProgress'] ??
                    data['InProgress'] ??
                    map['inprogress'] ??
                    '',
                'nextsteps':
                    data['nextsteps'] ??
                    data['nextSteps'] ??
                    data['NextSteps'] ??
                    map['nextsteps'] ??
                    '',
                'issues':
                    data['issues'] ?? data['Issues'] ?? map['issues'] ?? '',
                'students': _decodeStudents(
                  data['students'] ?? data['Students'] ?? map['students'],
                ),
                'timestamp': map['timestamp'] ?? data['timestamp'] ?? '',
              };

              print('Normalized report: $normalized');
              return normalized;
            } catch (e) {
              print('Error normalizing report item: $e');
              print('Item was: $item');
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      reports.sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateB.compareTo(dateA); // Sort descending (newest first)
      });

      print('Returning ${reports.length} normalized reports');
      return reports;
    }

    // Handle Map response (single report or wrapped response)
    if (raw is Map) {
      print('Raw is Map, attempting to extract reports');
      // Check if it's a single report
      if (raw.containsKey('date') || raw.containsKey('Date')) {
        return _normalizeWorkerReports([raw]);
      }
      // Check if reports are nested
      if (raw.containsKey('reports') && raw['reports'] is List) {
        return _normalizeWorkerReports(raw['reports']);
      }
      if (raw.containsKey('data') && raw['data'] is List) {
        return _normalizeWorkerReports(raw['data']);
      }
    }

    print('Could not normalize raw data, returning empty list');
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
