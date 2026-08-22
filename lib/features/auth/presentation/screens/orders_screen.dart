import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/supabase_config.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.tableOrders)
          .select()
          .or('shop_owner_id.eq.$userId,supplier_id.eq.$userId')
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch orders: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F5C4F)))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: const Color(0xFF0F5C4F),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No orders yet',
                          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    )
                  else
                    ..._orders.map((order) => _OrderItem(
                          product: order['product_name'] ?? 'Unknown',
                          quantity: '${order['quantity'] ?? 0} ${order['unit'] ?? ''}',
                          totalAmount: order['total_amount'] ?? 0,
                          status: order['status'] ?? 'pending',
                        )),
                ],
              ),
            ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String product;
  final String quantity;
  final dynamic totalAmount;
  final String status;

  const _OrderItem({
    required this.product,
    required this.quantity,
    required this.totalAmount,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case 'accepted':
        return AppColors.accepted;
      case 'in_transit':
        return const Color(0xFF3B82F6);
      case 'delivered':
        return AppColors.delivered;
      case 'cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.pending;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$product ($quantity)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            totalAmount is num
                ? 'Total: ৳${(totalAmount as num).toStringAsFixed(2)}'
                : 'Total: ৳$totalAmount',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
