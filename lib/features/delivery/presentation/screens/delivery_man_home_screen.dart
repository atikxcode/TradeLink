import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class DeliveryManHomeScreen extends StatefulWidget {
  const DeliveryManHomeScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryManHomeScreen> createState() => _DeliveryManHomeScreenState();
}

class _DeliveryManHomeScreenState extends State<DeliveryManHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  Timer? _locationTimer;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    await _fetchOrders();
    _startLocationUpdates();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final data = await ApiService.get('/delivery/orders');
    if (mounted) {
      setState(() {
        _orders = data ?? [];
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_userId == null) return;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }

        if (permission == LocationPermission.deniedForever) return;

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        
        await SupabaseConfig.client.from(SupabaseConfig.tableUsers).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }).eq('id', _userId!);
      } catch (e) {
        debugPrint('Location update error: $e');
      }
    });
  }

  Future<void> _markDelivered(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Mark this order as successfully delivered?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Confirm', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final res = await ApiService.patch('/delivery/orders/$orderId/status', body: {});
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as delivered!'), backgroundColor: AppColors.primaryTeal));
      _fetchOrders();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status.'), backgroundColor: AppColors.cancelled));
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Maps')));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Deliveries'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _orders.isEmpty
              ? const Center(child: Text('No assigned deliveries found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final isCompleted = order['status'] == 'delivered';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    order['product_name'] ?? 'Item',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Delivered' : 'Active',
                                    style: TextStyle(
                                      color: isCompleted ? Colors.green.shade800 : Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Quantity: ${order['quantity']}'),
                            Text('Total Amount: ৳${order['total_amount']}'),
                            const Divider(height: 24),
                            const Text('Shop Owner:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(order['shop_owner_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(order['shop_owner_phone'] ?? ''),
                            const SizedBox(height: 8),
                            const Text('Delivery Address:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(order['delivery_address'] ?? 'Not provided', style: const TextStyle(fontWeight: FontWeight.w500)),
                            
                            const SizedBox(height: 16),
                            if (!isCompleted)
                              Row(
                                children: [
                                  if (order['dropoff_lat'] != null && order['dropoff_lng'] != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openMap(order['dropoff_lat'], order['dropoff_lng']),
                                        icon: const Icon(Icons.map, size: 18),
                                        label: const Text('View Map'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue.shade700,
                                          side: BorderSide(color: Colors.blue.shade700),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  if (order['dropoff_lat'] != null && order['dropoff_lng'] != null)
                                    const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markDelivered(order['id']),
                                      icon: const Icon(Icons.check_circle, size: 18),
                                      label: const Text('Delivered'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
