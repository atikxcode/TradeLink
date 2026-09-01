import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Debug conversations query', () async {
    await dotenv.load(fileName: ".env");
    final supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_ANON_KEY']!,
    );

    try {
      // Find a user ID to test with
      final userResp = await supabase.from('users').select().limit(5);
      print("Found users: ${userResp.map((u) => u['id']).toList()}");
      
      for (var u in userResp) {
        String myId = u['id'];
        print("Testing for user: $myId");
        
        final directChats = await supabase
          .from('chats')
          .select()
          .or('shop_owner_id.eq.$myId,stockholder_id.eq.$myId');
        print("  Direct Chats: ${directChats.length}");
        
        final orders = await supabase
          .from('orders')
          .select()
          .or('shop_owner_id.eq.$myId,supplier_id.eq.$myId,delivery_man_id.eq.$myId');
        print("  Orders: ${orders.length}");
      }
    } catch (e) {
      print("Error: $e");
    }
  });
}
