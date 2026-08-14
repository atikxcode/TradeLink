import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildNotificationSwitch(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications for new demands and matches.',
            value: true,
          ),
          const SizedBox(height: 16),
          _buildNotificationSwitch(
            title: 'Email Notifications',
            subtitle: 'Receive daily summary and promotional emails.',
            value: false,
          ),
          const SizedBox(height: 16),
          _buildNotificationSwitch(
            title: 'Order Updates',
            subtitle: 'Get notified when an order status changes.',
            value: true,
          ),
          const SizedBox(height: 16),
          _buildNotificationSwitch(
            title: 'Marketing & Offers',
            subtitle: 'Receive notifications about new features and offers.',
            value: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (val) {},
            activeColor: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }
}
