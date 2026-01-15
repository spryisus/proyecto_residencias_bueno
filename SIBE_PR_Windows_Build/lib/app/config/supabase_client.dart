import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseConfig {
  static const String supabaseUrl = 'https://eulpljyplqyjuyuvvnwm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bHBsanlwbHF5anV5dXZ2bndtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MjA3MjEsImV4cCI6MjA3NDM5NjcyMX0.uQ7AXQAgXNSCGhJk5JFChHCGufJTs4aH1MNMb8WY0CQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

SupabaseClient get supabaseClient => Supabase.instance.client;

