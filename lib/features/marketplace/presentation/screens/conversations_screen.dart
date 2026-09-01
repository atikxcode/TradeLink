import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'direct_chat_screen.dart';
import 'order_chat_screen.dart';

const Color _csPrimaryTeal = Color(0xFF0F766E);
const Color _csScreenBg = Color(0xFFF8FAFC);
const Color _csDarkText = Color(0xFF0F172A);
const Color _csMutedText = Color(0xFF64748B);
const Color _csBorderGray = Color(0xFFE2E8F0);

/// Shared "Chats" inbox for both Shop Owners and Suppliers.
/// Embedded as a bottom-nav tab: the header back chevron never pops
/// the root navigator — it delegates to [onBackTap] (switch to Home).
class ConversationsScreen extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onBackTap;

  const ConversationsScreen({super.key, this.showBack = false, this.onBackTap});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _chats = [];
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _fetchChats();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    // Initial fetch handled in initState
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _fetchChats(silent: true);
      }
    });
  }

  Future<void> _fetchChats({bool silent = false}) async {
    if (mounted && !silent) setState(() { _isLoading = true; _error = null; });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString('user_id');
      final myRole = prefs.getString('user_role');
      if (myId == null) throw Exception('User not logged in');

      final List<Map<String, dynamic>> finalChats = [];

      // 1. Fetch Direct Chats
      print("ConversationsScreen: fetching direct chats for $myId with role $myRole...");
      final directChats = await SupabaseConfig.client
          .from('chats')
          .select()
          .or('shop_owner_id.eq.$myId,stockholder_id.eq.$myId');
      print("ConversationsScreen: found ${directChats.length} direct chats.");
          
      for (var chat in directChats) {
        String counterpartName = 'Supplier';
        String partnerId = '';
        if (myRole == 'shop_owner') {
          partnerId = chat['stockholder_id']?.toString() ?? '';
        } else {
          partnerId = chat['shop_owner_id']?.toString() ?? '';
          counterpartName = 'Shop Owner';
        }
        
        if (partnerId.isNotEmpty) {
          try {
             final userReq = await SupabaseConfig.client.from('users').select('name').eq('id', partnerId).maybeSingle();
             if (userReq != null && userReq['name'] != null) counterpartName = userReq['name'];
          } catch (_) {}
        }
        
        finalChats.add({
          'isOrderChat': false,
          'id': chat['id'],
          'counterpartName': counterpartName,
          'productName': '',
          'lastMessage': chat['last_message'] ?? 'Say hello!',
          'updatedAt': chat['updated_at'] ?? chat['created_at'],
        });
      }

      // 2. Fetch Order Chats (Group Chats)
      print("ConversationsScreen: fetching order chats...");
      final orders = await SupabaseConfig.client
          .from('orders')
          .select()
          .or('shop_owner_id.eq.$myId,supplier_id.eq.$myId,delivery_man_id.eq.$myId');
      print("ConversationsScreen: found ${orders.length} orders.");

      for (var order in orders) {
        finalChats.add({
          'isOrderChat': true,
          'orderId': order['id'],
          'counterpartName': 'Group Chat',
          'productName': order['product_name'] ?? 'Order',
          'lastMessage': 'Tap to view conversation',
          'updatedAt': order['updated_at'] ?? order['created_at'],
        });
      }

      // Sort by updated_at descending
      finalChats.sort((a, b) {
        final dateA = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _chats = finalChats;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e, st) {
      if (mounted && !silent) {
        setState(() {
          _error = 'Failed to load chats. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  void _openChat(Map<String, dynamic> chat) async {
    final isOrderChat = chat['isOrderChat'] == true;
    if (isOrderChat) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderChatScreen(orderId: chat['orderId'].toString()),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(chatId: chat['id'].toString()),
        ),
      );
    }
    _fetchChats();
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _csScreenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // never pop the root stack
        title: const Text('Chats',
            style:
                TextStyle(color: _csDarkText, fontWeight: FontWeight.w700)),
        leading: (widget.showBack && widget.onBackTap != null)
            ? IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF374151)),
                onPressed: widget.onBackTap,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryTeal))
          : _error != null
              ? ListView(children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(children: [
                      const Icon(Icons.error_outline,
                          size: 32, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchChats,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _csPrimaryTeal,
                            foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                ])
              : RefreshIndicator(
                  onRefresh: () => _fetchChats(silent: false),
                  color: _csPrimaryTeal,
                  child: _chats.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 80),
                          Icon(Icons.chat_bubble_outline,
                              size: 44, color: Color(0xFF9CA3AF)),
                          SizedBox(height: 12),
                          Center(
                            child: Text('No conversations yet',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF))),
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          itemCount: _chats.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1, color: _csBorderGray),
                          itemBuilder: (context, i) =>
                              _buildTile(_chats[i]),
                        ),
                ),
    );
  }

  Widget _buildTile(Map<String, dynamic> chat) {
    final name = (chat['counterpartName'] ?? 'User').toString();
    final product = (chat['productName'] ?? '').toString();
    final lastMessage = (chat['lastMessage'] ?? '').toString();
    final time = _timeAgo((chat['updatedAt'] ?? '').toString());
    final isOrderChat = chat['isOrderChat'] == true;
    
    bool isOnline = false;
    final lastActiveStr = chat['lastActiveAt'];
    if (lastActiveStr != null && lastActiveStr.toString().isNotEmpty) {
      try {
        final lastActive = DateTime.parse(lastActiveStr.toString()).toLocal();
        if (DateTime.now().difference(lastActive).inMinutes <= 2) {
          isOnline = true;
        }
      } catch (_) {}
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isOrderChat ? Colors.orange.withValues(alpha: 0.12) : _csPrimaryTeal.withValues(alpha: 0.12),
            child: isOrderChat
                ? const Icon(Icons.group, color: Colors.orange)
                : Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _csPrimaryTeal)),
          ),
          if (!isOrderChat)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.blue : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _csDarkText)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.isNotEmpty)
            Text(product,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.primaryTeal)),
          const SizedBox(height: 2),
          Text(lastMessage.isEmpty ? 'Say hello!' : lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, color: _csMutedText)),
        ],
      ),
      trailing: Text(time,
          style:
              const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      onTap: () => _openChat(chat),
    );
  }
}
