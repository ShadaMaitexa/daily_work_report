import 'package:supabase_flutter/supabase_flutter.dart';

class ReportServiceSupabase {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> submitReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final date = data['date'];
      
      // Check if already submitted
      final existing = await supabase
          .from('reports')
          .select()
          .eq('worker_id', workerId)
          .eq('date', date);

      if (existing.isNotEmpty) {
        return {'success': false, 'message': 'Already submitted today'};
      }

      final response = await supabase.from('reports').insert(data).select();

      return {'success': true, 'data': response.first};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateReport({
    required String workerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final date = data['date'];

      final response = await supabase
          .from('reports')
          .update(data)
          .eq('worker_id', workerId)
          .eq('date', date)
          .select();

      return {'success': true, 'data': response.first};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> checkTodayStatus({
    required String workerId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      final report = await supabase
          .from('reports')
          .select()
          .eq('worker_id', workerId)
          .eq('date', today);

      if (report.isNotEmpty) {
        return {
          'success': true,
          'status': 'submitted',
          'report': report.first,
        };
      }

      return {'success': true, 'status': 'not-submitted'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}