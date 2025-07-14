import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientInstance {
  static const String _supabaseUrl = 'https://fyqgzbgyqaxicjzbckfp.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5cWd6Ymd5cWF4aWNqemJja2ZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNDcxMDksImV4cCI6MjA2NjkyMzEwOX0.MYMbPSRbBd8sFY60ZS5Q4iCsV-xwx2zUmrMd-JDJrbk';

  static final SupabaseClient client = SupabaseClient(
    _supabaseUrl,
    _supabaseAnonKey,
  );
}
