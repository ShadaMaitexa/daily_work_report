import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      // Query the reports table with proper column names
      final response = await supabase
          .from('reports')
          .select('''
            id,
            worker_id,
            worker_name,
            completed,
            inprogress,
            nextsteps,
            issues,
            students,
            date,
            created_at,
            status
          ''')
          .order('date', ascending: false);

      // Convert to List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }
}