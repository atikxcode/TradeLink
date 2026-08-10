import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration helper for Supabase (PostgreSQL) initialization & access
class SupabaseConfig {
  // Replace these with your actual Supabase URL and Anon Key from Supabase Dashboard
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Initialize Supabase Flutter SDK
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }

  /// Helper to obtain Supabase Client
  static SupabaseClient get client => Supabase.instance.client;

  // Supabase Database Table Names matching PDF Class Diagram
  static const String tableUsers = 'users';
  static const String tableProducts = 'products';
  static const String tableDemands = 'demands';
  static const String tableStocks = 'stocks';
  static const String tableOrders = 'orders';
  static const String tableOtps = 'otps';
  static const String tableRatings = 'ratings';
  static const String tableNotifications = 'notifications';
}
