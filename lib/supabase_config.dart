import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://uxqrmxoocmmwwibbjsff.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4cXJteG9vY21td3dpYmJqc2ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNTk4MTksImV4cCI6MjA4MDczNTgxOX0.WDUemdy1KCCORUQVmWpH4BnijHIjdivfflfiMitCD5E',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
