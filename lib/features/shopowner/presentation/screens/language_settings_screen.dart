import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Language (English)'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                _buildLanguageOption(
                  title: 'English',
                  subtitle: 'Default language',
                  value: 'en',
                  groupValue: 'en',
                  isLast: false,
                ),
                const Divider(height: 1, color: AppColors.inputBorder),
                _buildLanguageOption(
                  title: 'বাংলা (Bangla)',
                  subtitle: 'Bengali language',
                  value: 'bn',
                  groupValue: 'en',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required bool isLast,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: (val) {},
      activeColor: AppColors.primaryTeal,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: isLast
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            )
          : null,
    );
  }
}
