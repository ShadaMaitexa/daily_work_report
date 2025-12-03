import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsApi {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzMQcz8oVMANGKnc3-wFUpS9142QsSLB6cRcvX0Wmtn0tO38Vhv_iFNUfFMCc0y-gaudg/exec';

  // ---------------------- PRIVATE ----------------------
  static Future<Map<String, dynamic>> _send(Map<String, dynamic> data) async {
    try {
      print("📤 Sending → $data");

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              "Content-Type": "application/json",
              "User-Agent": "FlutterApp",
              "Cache-Control": "no-cache",
              "Accept": "application/json",
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      print("📥 Response Code → ${response.statusCode}");
      print("📥 Response Body → ${response.body}");

      if (response.statusCode != 200) {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}",
        };
      }

      // Decode JSON safely
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ---------------------- PUBLIC API ----------------------

  static Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _send({
      "action": "register",
      "name": name.trim(),
      "email": email.trim().toLowerCase(),
      "phone": phone.trim(),
      "password": password.trim(),
    });
  }

  static Future<Map<String, dynamic>> loginWorker({
    required String email,
    required String password,
  }) {
    return _send({
      "action": "login",
      "email": email.trim().toLowerCase(),
      "password": password.trim(),
    });
  }

  static Future<Map<String, dynamic>> submitReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) {
    return _send({"action": "submitReport", "workerId": workerId, ...data});
  }

  static Future<Map<String, dynamic>> updateReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) {
    return _send({"action": "updateReport", "workerId": workerId, ...data});
  }

  static Future<Map<String, dynamic>> getWorkerReports(String workerId) {
    return _send({"action": "getWorkerReports", "workerId": workerId});
  }

  static Future<Map<String, dynamic>> getAllReports() {
    return _send({"action": "getAllReports"});
  }

  static Future<Map<String, dynamic>> checkTodayStatus(String workerId) async {
    final reportsResponse = await getWorkerReports(workerId);

    if (reportsResponse["success"] == true &&
        reportsResponse["reports"] is List) {
      final today = DateTime.now().toIso8601String().split("T").first;
      final List reports = reportsResponse["reports"];

      final todayEntry = reports.cast<Map<String, dynamic>>().firstWhere((
        item,
      ) {
        final date = item["date"]?.toString().split("T").first ?? "";
        return date == today;
      }, orElse: () => {});

      return {
        "success": true,
        "status": todayEntry.isEmpty ? "leave" : todayEntry["status"],
        "report": todayEntry.isEmpty ? null : todayEntry,
      };
    }

    return reportsResponse;
  }
}
