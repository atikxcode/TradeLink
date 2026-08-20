import 'package:flutter/material.dart';

const Color _primaryTeal = Color(0xFF0F766E);
const Color _screenBg = Color(0xFFF8FAFC);
const Color _darkText = Color(0xFF0F172A);
const Color _mutedText = Color(0xFF64748B);
const Color _borderGray = Color(0xFFE2E8F0);
const Color _iconButtonBg = Color(0xFFF1F5F9);

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          _NotificationItem(
            icon: Icons.check_rounded,
            iconColor: Color(0xFF0F766E),
            bgColor: Color(0xFFEEF8F6),
            title: 'Order accepted by Manik Wholesale',
            subtitle: 'Your rice demand is now pending delivery · 5m ago',
          ),
          _NotificationItem(
            icon: Icons.lock_outline_rounded,
            iconColor: Color(0xFFC2660A),
            bgColor: Color(0xFFFEF6EA),
            title: 'Delivery OTP: 481026',
            subtitle: 'Share this with the rider only on arrival · 1h ago',
          ),
          _NotificationItem(
            icon: Icons.location_on_outlined,
            iconColor: Color(0xFF64748B),
            bgColor: Color(0xFFF1F5F9),
            title: '3 new suppliers match your demand',
            subtitle: 'Rice — Basmati, 50kg · 2h ago',
          ),
          _NotificationItem(
            icon: Icons.star_outline_rounded,
            iconColor: Color(0xFF15803D),
            bgColor: Color(0xFFF0FDF4),
            title: 'Thanks for rating Manik Wholesale',
            subtitle: 'You gave 4 stars · Yesterday',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  // ---------- AppBar ----------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _borderGray)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildBackButton(context),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                  fontFamily: 'Sora',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),
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
          color: _iconButtonBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _mutedText,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool showDivider;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _mutedText,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: _borderGray),
      ],
    );
  }
}