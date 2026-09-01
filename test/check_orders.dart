import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Check orders table', () async {
    await dotenv.load(fileName: ".env");
    final supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_ANON_KEY']!,
    );

    try {
      final response = await supabase.from('orders').select().limit(1);
      print("Orders table data: $response");
    } catch (e) {
      print("Error fetching orders: $e");
    }
    
    try {
      final response = await supabase.from('chats').select().limit(1);
      print("Chats table data: $response");
    } catch (e) {
      print("Error fetching chats: $e");
    }
  });
}
