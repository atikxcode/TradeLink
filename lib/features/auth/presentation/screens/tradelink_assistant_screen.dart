import 'package:flutter/material.dart';
import 'models/supplier_result.dart';
import 'services/assistant_service.dart';
import 'supplier_comparison_screen.dart';

const Color _asPrimaryTeal = Color(0xFF0F766E);
const Color _asScreenBg = Color(0xFFF8FAFC);
const Color _asDarkText = Color(0xFF0F172A);
const Color _asMutedText = Color(0xFF64748B);
const Color _asBorderGray = Color(0xFFE2E8F0);
const Color _asLightGrayBox = Color(0xFFF1F5F9);
const Color _asGreen = Color(0xFF10B981);

class TradeLinkAssistantScreen extends StatefulWidget {
  const TradeLinkAssistantScreen({super.key});

  @override
  State<TradeLinkAssistantScreen> createState() =>
      _TradeLinkAssistantScreenState();
}

class _TradeLinkAssistantScreenState extends State<TradeLinkAssistantScreen> {
  final AssistantService _service = AssistantService(
    apiKey: AssistantService.configuredApiKey(),
  );
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<AssistantMessage> _messages = [
    AssistantMessage(
      text: 'Hi! I\'m TradeLink Assistant. Ask me for any product and I\'ll '
          'find the best suppliers near you.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isTyping) return;
    _inputController.clear();

    setState(() {
      _messages.add(AssistantMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    final reply = await _service.generateReply(text);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(reply);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openSupplierComparison(SupplierResult best) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierComparisonScreen(
          product: 'Rice — Basmati, 50kg',
          suppliers: SupplierResult.mockForProduct('Rice — Basmati, 50kg'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _asScreenBg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const _DateHeader(),
                ..._buildMessages(),
                if (_isTyping) const _TypingBubble(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  List<Widget> _buildMessages() {
    return _messages.map((msg) {
      if (msg.isUser) {
        return _UserBubble(text: msg.text);
      }
      if (msg.suppliers != null) {
        return _AssistantReply(
          text: msg.text,
          suppliers: msg.suppliers!,
          onSeeAll: () => _openSupplierComparison(msg.suppliers!.first),
          onSortByDistance: () => _sendMessage('sort by distance instead'),
          onRatingFilter: () => _sendMessage('only show 4.5★ and up'),
        );
      }
      return _AssistantBubble(text: msg.text);
    }).toList();
  }

  // ---------- AppBar ----------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _asBorderGray)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildBackButton(context),
            const SizedBox(width: 12),
            _buildTitleBlock(),
            const Spacer(),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _asLightGrayBox,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: _asDarkText,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _asLightGrayBox,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _asMutedText,
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _asPrimaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _asGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TradeLink Assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _asDarkText,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _asGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _asGreen,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Input Bar ----------
  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _asBorderGray)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
              Icons.attach_file_rounded,
              size: 24,
              color: _asMutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: _asDarkText,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about another product...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: _asMutedText,
                    fontFamily: 'Inter',
                  ),
                  filled: true,
                  fillColor: _asLightGrayBox,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(_inputController.text),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _asPrimaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Date Header ----------
class _DateHeader extends StatelessWidget {
  const _DateHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'TODAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- User Bubble ----------
class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '9:41 AM',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Assistant Bubble ----------
class _AssistantBubble extends StatelessWidget {
  final String text;

  const _AssistantBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssistantAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

// ---------- Assistant Reply with product cards ----------
class _AssistantReply extends StatelessWidget {
  final String text;
  final List<SupplierResult> suppliers;
  final VoidCallback onSeeAll;
  final VoidCallback onSortByDistance;
  final VoidCallback onRatingFilter;

  const _AssistantReply({
    required this.text,
    required this.suppliers,
    required this.onSeeAll,
    required this.onSortByDistance,
    required this.onRatingFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suppliers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _ProductCard(supplier: suppliers[index]),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                label: 'See all ${suppliers.length} results',
                isPrimary: true,
                onTap: onSeeAll,
              ),
              _ActionChip(
                label: 'Sort by distance instead',
                isPrimary: false,
                onTap: onSortByDistance,
              ),
              _ActionChip(
                label: 'Only show 4.5★ & up',
                isPrimary: false,
                onTap: onRatingFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Product Card ----------
class _ProductCard extends StatelessWidget {
  final SupplierResult supplier;

  const _ProductCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F766E), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BEST PRICE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            supplier.storeName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${supplier.location} · ${supplier.distance}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            supplier.priceLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F766E),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 2),
              Text(
                supplier.distance,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 2),
              Text(
                '${supplier.rating} ★',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order placed at ${supplier.storeName}'),
                    backgroundColor: const Color(0xFF0F766E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Order now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Action Chip ----------
class _ActionChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : const Color(0xFF334155),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ---------- Typing Indicator ----------
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(delay: Duration.zero),
                SizedBox(width: 4),
                _PulsingDot(delay: Duration(milliseconds: 150)),
                SizedBox(width: 4),
                _PulsingDot(delay: Duration(milliseconds: 300)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Duration delay;

  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}