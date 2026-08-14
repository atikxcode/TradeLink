import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order $orderId',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildOtpCard(),
            const SizedBox(height: 16),
            _buildSupplierCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Rice — Basmati, 50kg',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.outForDeliveryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Out for delivery',
                  style: TextStyle(
                    color: AppColors.outForDeliveryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStepper(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepItem(
          title: 'Pending',
          state: StepState.completed,
        ),
        _buildStepLine(isActive: true),
        _buildStepItem(
          title: 'Accepted',
          state: StepState.completed,
        ),
        _buildStepLine(isActive: true),
        _buildStepItem(
          title: 'Out for\ndelivery',
          state: StepState.active,
        ),
        _buildStepLine(isActive: false),
        _buildStepItem(
          title: 'Delivered',
          state: StepState.inactive,
        ),
      ],
    );
  }

  Widget _buildStepItem({required String title, required StepState state}) {
    Color iconColor;
    Color bgColor;
    Widget icon;

    switch (state) {
      case StepState.completed:
        iconColor = Colors.white;
        bgColor = AppColors.primaryTeal;
        icon = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case StepState.active:
        iconColor = Colors.transparent;
        bgColor = AppColors.primaryTeal;
        icon = const SizedBox(width: 16, height: 16);
        break;
      case StepState.inactive:
        iconColor = Colors.transparent;
        bgColor = const Color(0xFFE2E8F0); // Light gray
        icon = const SizedBox(width: 16, height: 16);
        break;
    }

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: state == StepState.active ? FontWeight.bold : FontWeight.w600,
              color: state == StepState.inactive ? AppColors.textHint : (state == StepState.active ? AppColors.primaryTeal : AppColors.textPrimary),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(top: 13),
        height: 2,
        color: isActive ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Share this OTP with the rider on arrival',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOtpDigit('4'),
              _buildOtpDigit('8'),
              _buildOtpDigit('1'),
              _buildOtpDigit('0'),
              _buildOtpDigit('2'),
              _buildOtpDigit('6'),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Expires in 12:41 — do not share before delivery',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDigit(String digit) {
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryTeal),
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE6C7), // Light orange
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'MK',
                style: TextStyle(
                  color: Color(0xFFD97706), // Dark orange
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manik Wholesale',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rider: Jamal · ETA 18 min',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

enum StepState { completed, active, inactive }
