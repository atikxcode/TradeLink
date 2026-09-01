import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../../core/config/api_config.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _dcPrimaryTeal = Color(0xFF0F766E);
const Color _dcScreenBg = Color(0xFFF8FAFC);
const Color _dcDarkText = Color(0xFF0F172A);
const Color _dcMutedText = Color(0xFF64748B);
const Color _dcBorderGray = Color(0xFFE2E8F0);

/// Group chat for an Order connecting Shop Owner, Supplier, and Delivery Rider
class OrderChatScreen extends StatefulWidget {
  final String orderId;
  const OrderChatScreen({super.key, required this.orderId});

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  Map<String, dynamic>? _chat;
  List<Map<String, dynamic>> _messages = [];
  String? _error;
  bool _sending = false;
  String _myRole = '';
  String _myUserId = '';
  Map<String, String> _userNames = {};
  StreamSubscription? _messagesSubscription;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMyContext();
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyContext() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _myRole = prefs.getString('user_role') ?? '';
      _myUserId = prefs.getString('user_id') ?? '';
    });
  }

  bool _isMine(Map<String, dynamic> m) {
    return (m['senderId']?.toString() == _myUserId);
  }

  Future<void> _initializeChat() async {
    try {
      final order = await SupabaseConfig.client
          .from(SupabaseConfig.tableOrders)
          .select('shop_owner_id, supplier_id')
          .eq('id', widget.orderId)
          .maybeSingle();
      
      if (order != null) {
        String? orderChatId;
        try {
          final existingChat = await SupabaseConfig.client
              .from('order_chats')
              .select('id')
              .eq('order_id', widget.orderId)
              .maybeSingle();

          if (existingChat != null) {
            orderChatId = existingChat['id'];
          } else {
            final newChat = await SupabaseConfig.client
                .from('order_chats')
                .insert({
                  'order_id': widget.orderId,
                  'last_message': 'Chat started',
                })
                .select('id')
                .single();
            orderChatId = newChat['id'];
          }
        } catch (e) {
          print('Error initializing order chat: $e');
          if (mounted) setState(() => _error = 'Failed to init chat DB: $e');
        }

        if (orderChatId != null) {
          _messagesSubscription = SupabaseConfig.client
              .from('order_messages')
              .stream(primaryKey: ['id'])
              .eq('order_chat_id', orderChatId)
              .order('created_at', ascending: true)
              .listen((List<Map<String, dynamic>> rawMessages) async {
              List<Map<String, dynamic>> parsedMessages = [];
              
              for (var m in rawMessages) {
                final mData = Map<String, dynamic>.from(m);
                final sId = mData['sender_id']?.toString();
                if (sId != null && !_userNames.containsKey(sId)) {
                  final u = await SupabaseConfig.client.from(SupabaseConfig.tableUsers).select('full_name, business_name').eq('id', sId).maybeSingle();
                  if (u != null) {
                    _userNames[sId] = u['business_name']?.toString().isNotEmpty == true ? u['business_name']! : u['full_name'] ?? 'User';
                  } else {
                    _userNames[sId] = 'User';
                  }
                }
                mData['senderName'] = sId != null ? _userNames[sId] : 'User';
                mData['senderId'] = mData['sender_id'];
                mData['senderType'] = mData['sender_type'];
                mData['textContent'] = mData['text_content'];
                mData['imageUrl'] = mData['image_url'];
                mData['lastActiveAt'] = mData['created_at'];
                parsedMessages.add(mData);
              }
              
              if (!mounted) return;
              setState(() {
                _messages = parsedMessages;
                _error = null;
              });
              _scrollToBottom();
            });
        } else {
          if (mounted && _error == null) setState(() => _error = 'Failed to initialize chat');
        }
      } else {
        if (mounted) setState(() => _error = 'Order not found');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load conversation: $e');
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    
    try {
      final orderChatRes = await SupabaseConfig.client
          .from('order_chats')
          .select('id')
          .eq('order_id', widget.orderId)
          .maybeSingle();
          
      if (orderChatRes != null) {
        await SupabaseConfig.client.from('order_messages').insert({
          'order_chat_id': orderChatRes['id'],
          'sender_id': _myUserId,
          'sender_type': _myRole.toUpperCase() == 'DELIVERY_MAN' ? 'DELIVERY_RIDER' : _myRole.toUpperCase(),
          'text_content': text,
        });
        if (mounted) {
          _inputController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800, maxHeight: 800);
    if (picked == null) return;
    
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      final orderChatRes = await SupabaseConfig.client
          .from('order_chats')
          .select('id')
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (orderChatRes != null) {
        await SupabaseConfig.client.from('order_messages').insert({
          'order_chat_id': orderChatRes['id'],
          'sender_id': _myUserId,
          'sender_type': _myRole.toUpperCase() == 'DELIVERY_MAN' ? 'DELIVERY_RIDER' : _myRole.toUpperCase(),
          'image_url': base64String,
          'text_content': ' ', // Adding space to pass any text_content constraints if they require non-empty even with image_url in some older schema
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getRoleLabel(String senderType) {
    switch (senderType) {
      case 'SHOP_OWNER':
        return 'Shop Owner';
      case 'SUPPLIER':
        return 'Supplier';
      case 'DELIVERY_RIDER':
        return 'Delivery Rider';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dcScreenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _dcPrimaryTeal.withValues(alpha: 0.12),
              child: const Icon(Icons.group, size: 20, color: _dcPrimaryTeal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Chat',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dcDarkText),
                      overflow: TextOverflow.ellipsis),
                  const Text('Live Update Group',
                      style: TextStyle(
                          fontSize: 11, color: _dcMutedText)),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF374151)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _error != null && _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style:
                                const TextStyle(color: _dcMutedText)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _initializeChat,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _dcPrimaryTeal,
                              foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> m) {
    final mine = _isMine(m);
    final senderName = m['senderName']?.toString() ?? 'User';
    final roleLabel = _getRoleLabel(m['senderType']?.toString() ?? '');
    
    bool isOnline = false;
    final lastActiveStr = m['lastActiveAt'];
    if (lastActiveStr != null && lastActiveStr.toString().isNotEmpty) {
      try {
        final lastActive = DateTime.parse(lastActiveStr.toString()).toLocal();
        if (DateTime.now().difference(lastActive).inMinutes <= 2) {
          isOnline = true;
        }
      } catch (_) {}
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? _dcPrimaryTeal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 3),
            bottomRight: Radius.circular(mine ? 3 : 14),
          ),
          border: mine ? null : Border.all(color: _dcBorderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: isOnline ? Colors.blue : Colors.grey,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _dcDarkText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _dcScreenBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(fontSize: 9, color: _dcMutedText),
                      ),
                    ),
                  ],
                ),
              ),
            if (m['imageUrl'] != null && m['imageUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: m['imageUrl'].toString().startsWith('data:image')
                      ? Image.memory(
                          base64Decode(m['imageUrl'].toString().split(',').last),
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                        )
                      : Image.network(
                          '${ApiConfig.baseUrl}${m['imageUrl']}',
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                ),
              ),
            if (m['textContent'] != null && m['textContent'].toString().isNotEmpty)
              Text(m['textContent'].toString(),
                  style: TextStyle(
                      fontSize: 13.5,
                      color: mine ? Colors.white : _dcDarkText)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _dcBorderGray)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Attachments',
              onPressed: _sending ? null : _pickAndSendImage,
              icon: const Icon(Icons.attach_file_rounded,
                  size: 22, color: _dcMutedText),
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message\u2026',
                  hintStyle: const TextStyle(
                      fontSize: 13.5, color: Color(0xFF9CA3AF)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: _dcPrimaryTeal, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _dcPrimaryTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        size: 19, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
