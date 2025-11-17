import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  static const String _workerIdKey = 'workerId';
  static const String _workerNameKey = 'workerName';
  static const String _isAdminKey = 'isAdmin';

  Future<void> saveWorkerId(int workerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workerIdKey, workerId);
  }

  Future<void> saveWorkerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workerNameKey, name);
  }

  Future<int?> getWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workerIdKey);
  }

  Future<String?> getWorkerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workerNameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workerIdKey);
    await prefs.remove(_workerNameKey);
    await prefs.remove(_isAdminKey);
  }
}

