import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllReports() async {
    final response = await supabase.from('reports').select('*').order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
