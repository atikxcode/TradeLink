import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'order_tracking_screen.dart';
import 'rate_supplier_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'My Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.inputBorder),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: AppColors.primaryTeal,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryTeal,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: [
                      Tab(text: 'Active'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildActiveOrders(context),
                        _buildCompletedOrders(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrders(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildOrderCard(
          id: '#TL-10482',
          item: 'Rice — Basmati, 50kg',
          supplier: 'Manik Wholesale',
          status: 'Out for delivery',
          statusColor: AppColors.outForDeliveryText,
          statusBgColor: AppColors.outForDeliveryBg,
          price: '৳3,400',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderTrackingScreen(orderId: '#TL-10482'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompletedOrders(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildOrderCard(
          id: '#ORD-0905',
          item: 'Detergent Powder, 30 units',
          supplier: 'Bismillah Traders',
          status: 'Completed',
          statusColor: AppColors.delivered,
          statusBgColor: AppColors.delivered.withOpacity(0.1),
          price: '৳2,100',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RateSupplierScreen(supplierName: 'Bismillah Traders'),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildOrderCard(
          id: '#ORD-0899',
          item: 'Refined Oil, 10 Liters',
          supplier: 'Hazi Rice House',
          status: 'Completed',
          statusColor: AppColors.delivered,
          statusBgColor: AppColors.delivered.withOpacity(0.1),
          price: '৳1,650',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RateSupplierScreen(supplierName: 'Hazi Rice House'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required String id,
    required String item,
    required String supplier,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String price,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supplier: $supplier',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
