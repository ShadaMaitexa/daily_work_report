import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  static const String _workerIdKey = 'workerId';
  static const String _workerNameKey = 'workerName';
  static const String _isAdminKey = 'isAdmin';

  // Get worker ID as STRING (important!)
  Future<String?> getWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workerIdKey); // Returns String, not int
  }

  Future<String?> getWorkerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workerNameKey);
  }

  Future<void> saveWorkerId(String workerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workerIdKey, workerId);
  }

  Future<void> saveWorkerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workerNameKey, name);
  }

  Future<void> saveAdminStatus(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminKey, isAdmin);
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}