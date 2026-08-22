import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  Future<void> _fetchPendingOrders() async {
    setState(() => _isLoading = true);
    final data = await ApiService.get('/orders/pending');
    if (data != null && mounted) {
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pending Orders',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F5C4F)))
          : RefreshIndicator(
              onRefresh: _fetchPendingOrders,
              color: const Color(0xFF0F5C4F),
              child: _orders.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Text(
                              'No pending orders',
                              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _PendingOrderCard(
                          orderId: order['orderId'] ?? '',
                          productName: order['productName'] ?? 'Unknown',
                          quantity: order['quantity'] ?? 0,
                          unit: order['unit'] ?? '',
                          orderStatus: order['orderStatus'] ?? 'accepted',
                          orderTime: order['orderTime'] ?? '',
                          shopOwnerName: order['shopOwnerName'] ?? 'Shop Owner',
                          shopOwnerPhone: order['shopOwnerPhone'] ?? '',
                          deliveryLocation: order['deliveryLocation'],
                          deliveryOtp: order['deliveryOtp'],
                        );
                      },
                    ),
            ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final String orderId;
  final String productName;
  final dynamic quantity;
  final String unit;
  final String orderStatus;
  final String orderTime;
  final String shopOwnerName;
  final String shopOwnerPhone;
  final String? deliveryLocation;
  final String? deliveryOtp;

  const _PendingOrderCard({
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.orderStatus,
    required this.orderTime,
    required this.shopOwnerName,
    required this.shopOwnerPhone,
    this.deliveryLocation,
    this.deliveryOtp,
  });

  Color get _statusColor {
    switch (orderStatus) {
      case 'in_transit':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFFF59E0B);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _statusLabel {
    switch (orderStatus) {
      case 'in_transit':
        return 'In Transit';
      case 'accepted':
        return 'Accepted';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
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
            const SizedBox(height: 8),
            _InfoRow(label: 'Quantity', value: '$quantity $unit'),
            const _Divider(),
            _InfoRow(label: 'Shop Owner', value: shopOwnerName),
            const _Divider(),
            _InfoRow(label: 'Phone', value: shopOwnerPhone),
            if (deliveryLocation != null && deliveryLocation!.isNotEmpty) ...[
              const _Divider(),
              _InfoRow(label: 'Delivery', value: deliveryLocation!),
            ],
            if (deliveryOtp != null && deliveryOtp!.isNotEmpty) ...[
              const _Divider(),
              _InfoRow(
                label: 'Delivery OTP',
                value: deliveryOtp!,
                valueColor: const Color(0xFF0F5C4F),
              ),
            ],
            const _Divider(),
            _InfoRow(
              label: 'Ordered',
              value: _formatTime(orderTime),
              valueColor: const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFE2E8F0));
  }
}
