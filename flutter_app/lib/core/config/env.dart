import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase connection info from `.env` (gitignored — see
/// `.env.example`). Only the anon key ever ships in this client; the
/// service role key must never appear here (SECURITY_PLAN.md).
abstract class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon-key');
}
