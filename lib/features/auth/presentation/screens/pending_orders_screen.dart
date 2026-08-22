import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  Future<void> _fetchPendingOrders() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    final data = await ApiService.get('/orders/pending');
    if (data != null && mounted) {
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _error = 'Failed to load orders. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    final result = await _postAction('/orders/$orderId/accept');
    if (mounted) {
      setState(() => _isActionInProgress = false);
      final isError = result == null || result.startsWith('Invalid') || result.startsWith('Network') || result.startsWith('Failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Action failed'),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
      );
      _fetchPendingOrders();
    }
  }

  Future<void> _declineOrder(String orderId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    final result = await _postAction('/orders/$orderId/decline');
    if (mounted) {
      setState(() => _isActionInProgress = false);
      final isError = result == null || result.startsWith('Invalid') || result.startsWith('Network') || result.startsWith('Failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Action failed'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      _fetchPendingOrders();
    }
  }

  Future<void> _markOutOfDelivery(String orderId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    final result = await _postAction('/orders/$orderId/out-for-delivery');
    if (mounted) {
      setState(() => _isActionInProgress = false);
      final isError = result == null || result.startsWith('Invalid') || result.startsWith('Network') || result.startsWith('Failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Action failed'),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
        ),
      );
      _fetchPendingOrders();
    }
  }

  Future<void> _verifyDelivery(String orderId) async {
    final otpController = TextEditingController();

    final otp = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask the shop owner for the 6-digit OTP they received.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '------',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F5C4F), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, otpController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5C4F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );

    if (otp == null || otp.length != 6) return;

    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    final result = await _postActionWithBody('/orders/$orderId/verify-delivery', {'otp': otp});
    if (mounted) {
      setState(() => _isActionInProgress = false);
      final isError = result == null || result.startsWith('Invalid') || result.startsWith('Network') || result.startsWith('Failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Verification failed'),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
      );
      _fetchPendingOrders();
    }
  }

  Future<String?> _postActionWithBody(String path, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final role = prefs.getString('user_role') ?? 'supplier';
      final uri = Uri.parse('http://localhost:8081/api/v1$path');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': '$userId::$role',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200 && resBody['success'] == true) {
        return resBody['data']['message'] ?? 'Action completed';
      }
      return resBody['error'] ?? 'Action failed';
    } catch (e) {
      return 'Network error - please try again';
    }
  }

  Future<String?> _postAction(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final role = prefs.getString('user_role') ?? 'supplier';
      final uri = Uri.parse('http://localhost:8081/api/v1$path');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': '$userId::$role',
        },
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data']['message'] ?? 'Action completed';
      }
      return body['error'] ?? 'Action failed';
    } catch (e) {
      return 'Network error - please try again';
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
                'Orders',
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
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchPendingOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5C4F),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
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
                                  'No orders yet',
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
                            final qty = order['quantity'];
                            final displayQty = qty is num ? qty.toInt().toString() : qty?.toString() ?? '0';
                            return _SupplierOrderCard(
                              orderId: order['orderId'] ?? '',
                              productName: order['productName'] ?? 'Unknown',
                              quantity: displayQty,
                              unit: order['unit'] ?? '',
                              totalAmount: order['totalAmount'] ?? 0,
                              orderStatus: order['orderStatus'] ?? 'pending',
                              orderTime: order['orderTime'] ?? '',
                              shopOwnerName: order['shopOwnerName'] ?? 'Shop Owner',
                              shopOwnerPhone: order['shopOwnerPhone'] ?? '',
                              deliveryLocation: order['deliveryLocation'],
                              deliveryOtp: order['deliveryOtp'],
                              isActionInProgress: _isActionInProgress,
                              onAccept: () => _acceptOrder(order['orderId']),
                              onDecline: () => _declineOrder(order['orderId']),
                              onOutForDelivery: () => _markOutOfDelivery(order['orderId']),
                              onVerifyDelivery: () => _verifyDelivery(order['orderId']),
                            );
                          },
                        ),
                ),
    );
  }
}

class _SupplierOrderCard extends StatelessWidget {
  final String orderId;
  final String productName;
  final String quantity;
  final String unit;
  final dynamic totalAmount;
  final String orderStatus;
  final String orderTime;
  final String shopOwnerName;
  final String shopOwnerPhone;
  final String? deliveryLocation;
  final String? deliveryOtp;
  final bool isActionInProgress;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOutForDelivery;
  final VoidCallback onVerifyDelivery;

  const _SupplierOrderCard({
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.orderStatus,
    required this.orderTime,
    required this.shopOwnerName,
    required this.shopOwnerPhone,
    this.deliveryLocation,
    this.deliveryOtp,
    this.isActionInProgress = false,
    required this.onAccept,
    required this.onDecline,
    required this.onOutForDelivery,
    required this.onVerifyDelivery,
  });

  Color get _statusColor {
    switch (orderStatus) {
      case 'accepted':
        return const Color(0xFFF59E0B);
      case 'out_for_delivery':
        return const Color(0xFF3B82F6);
      case 'in_transit':
        return const Color(0xFF3B82F6);
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
      case 'accepted':
        return 'Accepted';
      case 'out_for_delivery':
        return 'Out for Delivery';
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
            _InfoRow(label: 'Total', value: '৳${(totalAmount is num ? totalAmount.toDouble() : 0).toStringAsFixed(0)}'),
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

            // Action buttons based on status
            const SizedBox(height: 12),
            if (orderStatus == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isActionInProgress ? null : onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Decline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isActionInProgress ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ] else if (orderStatus == 'accepted') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isActionInProgress ? null : onOutForDelivery,
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Mark Out for Delivery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ] else if (orderStatus == 'out_for_delivery') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Ask the shop owner for the delivery OTP.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isActionInProgress ? null : onVerifyDelivery,
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('Enter OTP & Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5C4F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
