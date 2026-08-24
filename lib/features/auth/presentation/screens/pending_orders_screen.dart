import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import 'track_rider_screen.dart';
import '../../../../core/config/api_config.dart';

class PendingOrdersScreen extends StatefulWidget {
  final bool embedded;
  const PendingOrdersScreen({super.key, this.embedded = false});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  bool _isActionInProgress = false;

  bool _isLoadingCompleted = true;
  String? _errorCompleted;
  List<Map<String, dynamic>> _completedOrders = [];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPendingOrders();
    _fetchCompletedOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _fetchCompletedOrders() async {
    if (mounted) setState(() { _isLoadingCompleted = true; _errorCompleted = null; });
    final data = await ApiService.get('/orders/completed');
    if (data != null && mounted) {
      setState(() {
        _completedOrders = List<Map<String, dynamic>>.from(data);
        _isLoadingCompleted = false;
      });
    } else if (mounted) {
      setState(() {
        _errorCompleted = 'Failed to load completed orders. Pull to refresh.';
        _isLoadingCompleted = false;
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


  Future<void> _requestRider(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final role = prefs.getString('user_role');

    if (userId == null || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isActionInProgress = true);
    try {
      final patchRes = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/request-rider'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': '$userId::$role',
        },
      );

      setState(() => _isActionInProgress = false);
      final patchBody = jsonDecode(patchRes.body);
      if (patchRes.statusCode == 200 && patchBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Looking for nearby riders...'),
          backgroundColor: Color(0xFF10B981),
        ));
        _fetchPendingOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(patchBody['error'] ?? 'Failed to request rider'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } catch (e) {
      setState(() => _isActionInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
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
      if (!isError) _fetchCompletedOrders();
    }
  }

  Future<String?> _postActionWithBody(String path, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final role = prefs.getString('user_role') ?? 'supplier';
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');

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
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              if (!widget.embedded) ...[
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
              ] else
                const SizedBox(width: 20),
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0F5C4F),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0F5C4F),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(),
            _buildCompletedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    return _isLoading
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
                                'No active orders',
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
                            onAccept: () => _acceptOrder(order['orderId'] ?? ''),
                            onDecline: () => _declineOrder(order['orderId'] ?? ''),
                            onOutForDelivery: () => _markOutOfDelivery(order['orderId'] ?? ''),
                            onAssignDelivery: () => _requestRider(order['orderId'] ?? ''),
                            onTrackRider: order['delivery_man_id'] != null 
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrackRiderScreen(
                                        deliveryManId: order['delivery_man_id'],
                                        orderId: order['orderId'] ?? '',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          );
                        },
                      ),
              );
  }

  Widget _buildCompletedTab() {
    Widget body;
    if (_isLoadingCompleted) {
      body = const Center(child: CircularProgressIndicator(color: Color(0xFF0F5C4F)));
    } else if (_errorCompleted != null) {
      body = ListView(
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
                  _errorCompleted!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchCompletedOrders,
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
      );
    } else if (_completedOrders.isEmpty) {
      body = ListView(
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
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline, size: 32, color: Color(0xFF10B981)),
                SizedBox(height: 12),
                Text(
                  'No completed orders yet',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _fetchCompletedOrders,
        color: const Color(0xFF0F5C4F),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _completedOrders.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
          itemBuilder: (context, index) {
            final order = _completedOrders[index];
            final qty = order['quantity'];
            final displayQty = qty is num ? qty.toInt().toString() : qty?.toString() ?? '0';
            return _CompletedOrderCard(
              productName: order['productName'] ?? 'Unknown',
              quantity: displayQty,
              unit: order['unit'] ?? '',
              totalAmount: order['totalAmount'] ?? 0,
              deliveredAt: order['deliveredAt'] ?? '',
              shopOwnerName: order['shopOwnerName'] ?? 'Shop Owner',
              shopOwnerPhone: order['shopOwnerPhone'] ?? '',
              givenRating: order['givenRating'],
              givenComment: order['givenComment'],
            );
          },
        ),
      );
    }
    return body;
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
  final VoidCallback? onAssignDelivery; // "Request Rider"
  final VoidCallback? onTrackRider;

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
    this.onAssignDelivery,
    this.onTrackRider,
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
      case 'searching_for_rider':
        return const Color(0xFFD97706);
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
      case 'searching_for_rider':
        return 'Searching Rider';
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

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required Color textColor, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
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
              if (onTrackRider != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isActionInProgress ? null : onTrackRider,
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Track Rider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isActionInProgress ? null : onAssignDelivery,
                  icon: const Icon(Icons.electric_bike_rounded, size: 18),
                  label: const Text('Request Rider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ] else if (orderStatus == 'searching_for_rider') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706))),
                    SizedBox(width: 8),
                    Text(
                      'Looking for nearby riders...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (orderStatus == 'out_for_delivery') ...[
              if (onTrackRider != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isActionInProgress ? null : onTrackRider,
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Track Rider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
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

// ==================== Completed Order Card ====================

class _CompletedOrderCard extends StatelessWidget {
  final String productName;
  final String quantity;
  final String unit;
  final num totalAmount;
  final String deliveredAt;
  final String shopOwnerName;
  final String shopOwnerPhone;
  final dynamic givenRating;
  final String? givenComment;

  const _CompletedOrderCard({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.deliveredAt,
    required this.shopOwnerName,
    required this.shopOwnerPhone,
    this.givenRating,
    this.givenComment,
  });

  String get _deliveredLabel {
    try {
      final dt = DateTime.parse(deliveredAt);
      final local = dt.toLocal();
      return '${local.day}/${local.month}/${local.year}';
    } catch (_) {
      return '';
    }
  }

  int get _rating {
    if (givenRating is num) return givenRating.toInt();
    return int.tryParse(givenRating?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Delivered',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$quantity $unit',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 3),
              Text(
                _deliveredLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shopOwnerName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '৳${_fmtAmount(totalAmount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F5C4F),
                ),
              ),
            ],
          ),
          if (_rating > 0 || (givenComment ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 15,
                          color: i < _rating ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        'Customer review',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  if ((givenComment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      givenComment!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'No review left yet',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF9CA3AF)),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtAmount(num amount) {
    final d = amount.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
  }
}
