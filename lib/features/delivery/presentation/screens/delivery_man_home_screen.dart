import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'delivery_request_details_screen.dart';
import 'qr_scanner_screen.dart';

class DeliveryManHomeScreen extends StatefulWidget {
  const DeliveryManHomeScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryManHomeScreen> createState() => _DeliveryManHomeScreenState();
}

class _DeliveryManHomeScreenState extends State<DeliveryManHomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLoading = false;
  List<dynamic> _nearbyRequests = [];
  List<dynamic> _myDeliveries = [];
  Timer? _locationTimer;
  String? _userId;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _performLocationUpdate();
    }
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _fetchData();
    _startLocationUpdates();
  }

  Future<void> _fetchData() async {
    if (_currentIndex == 0) {
      await _fetchNearbyRequests();
    } else {
      await _fetchMyDeliveries();
    }
  }

  Future<void> _fetchNearbyRequests() async {
    setState(() => _isLoading = true);
    final data = await ApiService.get('/delivery/requests');
    if (mounted) {
      setState(() {
        _nearbyRequests = data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMyDeliveries() async {
    setState(() => _isLoading = true);
    final data = await ApiService.get('/delivery/orders');
    if (mounted) {
      setState(() {
        _myDeliveries = data ?? [];
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() {
    _performLocationUpdate(); // Initial call
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performLocationUpdate();
    });
  }

  Future<void> _performLocationUpdate() async {
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
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }

      await SupabaseConfig.client.from(SupabaseConfig.tableUsers).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('id', _userId!);

      _checkProximityToDropoff(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  final Set<String> _notifiedArrivalOrders = {};

  Future<void> _checkProximityToDropoff(double lat, double lng) async {
    if (_myDeliveries.isEmpty) return;
    final currentLoc = LatLng(lat, lng);
    const distance = Distance();

    for (var order in _myDeliveries) {
      if (order['status'] == 'out_for_delivery') {
        final orderId = order['id'];
        if (_notifiedArrivalOrders.contains(orderId)) continue; // Already notified

        if (order['delivery_lat'] != null && order['delivery_lng'] != null) {
          final deliveryLat = double.tryParse(order['delivery_lat'].toString());
          final deliveryLng = double.tryParse(order['delivery_lng'].toString());
          if (deliveryLat != null && deliveryLng != null) {
            final dropoffLoc = LatLng(deliveryLat, deliveryLng);
            final distInMeters = distance.as(LengthUnit.Meter, currentLoc, dropoffLoc);
            
            if (distInMeters < 1000) { // Less than 1km
              _notifiedArrivalOrders.add(orderId);
              // Notify backend
              ApiService.post('/orders/$orderId/notify-arrival', body: {});
            }
          }
        }
      }
    }
  }

  Future<void> _acceptRequest(String orderId) async {
    setState(() => _isLoading = true);
    final res = await ApiService.patch('/delivery/requests/$orderId/accept', body: {});
    
    if (res != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully assigned to you!'),
        backgroundColor: AppColors.primaryTeal,
      ));
      // Switch to deliveries tab
      setState(() {
        _currentIndex = 1;
      });
      _fetchMyDeliveries();
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to accept. It might have been taken by another rider.'),
        backgroundColor: AppColors.cancelled,
      ));
      _fetchNearbyRequests();
    }
  }

  Future<void> _showDeliveryCompletionOptions(String orderId) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete Delivery',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _sendOtpAndVerify(orderId);
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send OTP to Shop Owner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final scannedOtp = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
                if (scannedOtp != null && scannedOtp.isNotEmpty) {
                  _processOtp(orderId, scannedOtp, isQrScan: true);
                }
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtpAndVerify(String orderId) async {
    setState(() => _isLoading = true);
    final res = await ApiService.post('/orders/$orderId/send-otp', body: {});
    setState(() => _isLoading = false);

    if (res != null) {
      if (!mounted) return;
      
      final otpController = TextEditingController();
      final otp = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Enter OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'An OTP has been sent to the shop owner. Please enter it below to confirm delivery.',
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
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, otpController.text),
              child: const Text('Verify'),
            ),
          ],
        ),
      );

      if (otp != null && otp.trim().isNotEmpty) {
        _processOtp(orderId, otp);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to send OTP.'),
        backgroundColor: AppColors.cancelled,
      ));
    }
  }

  Future<void> _processOtp(String orderId, String otp, {bool isQrScan = false}) async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiService.patch('/delivery/orders/$orderId/status', body: {
        'otp': otp,
        'isQrScan': isQrScan,
      });

      if (res != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order delivered successfully!'),
          backgroundColor: AppColors.primaryTeal,
        ));
        _fetchMyDeliveries();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to confirm delivery. Invalid OTP or server error.'),
          backgroundColor: AppColors.cancelled,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.cancelled,
      ));
    }
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
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

  Widget _buildRequestsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    if (_nearbyRequests.isEmpty) {
      return const Center(child: Text('No new requests in your area.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyRequests.length,
      itemBuilder: (context, index) {
        final order = _nearbyRequests[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryRequestDetailsScreen(
                  request: order,
                  riderLocation: _currentLocation,
                  onAccept: () => _acceptRequest(order['id']),
                ),
              ),
            );
          },
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.inputBorder),
            ),
            margin: const EdgeInsets.only(bottom: 16),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(Icons.location_on, color: AppColors.primaryTeal, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Qty: ${order['quantity']} ${order['unit']}   •   Total: ৳${order['total_amount']}', 
                       style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Pickup: ${order['supplier_name']}', style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Dropoff: ${order['delivery_address'] ?? 'Customer Address'}', style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveriesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    if (_myDeliveries.isEmpty) {
      return const Center(child: Text('You have no active deliveries.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myDeliveries.length,
      itemBuilder: (context, index) {
        final order = _myDeliveries[index];
        final isCompleted = order['status'] == 'delivered';
        
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.inputBorder),
          ),
          margin: const EdgeInsets.only(bottom: 16),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Active',
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Qty: ${order['quantity']} ${order['unit']}   •   Total: ৳${order['total_amount']}', 
                     style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const Divider(height: 24),
                const Text('Supplier (Pickup)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${order['supplier_name']} - ${order['supplier_phone']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Customer (Dropoff)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${order['shop_owner_name']} - ${order['shop_owner_phone']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(order['delivery_address'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                
                if (!isCompleted) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (order['delivery_lat'] != null && order['delivery_lng'] != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openMap(
                              double.tryParse(order['delivery_lat'].toString()), 
                              double.tryParse(order['delivery_lng'].toString())
                            ),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (order['delivery_lat'] != null && order['delivery_lng'] != null)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeliveryCompletionOptions(order['id']),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Nearby Requests' : 'My Deliveries', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildRequestsTab() : _buildDeliveriesTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _fetchData();
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryTeal,
          unselectedItemColor: AppColors.textHint,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.electric_bike_outlined),
              activeIcon: Icon(Icons.electric_bike_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'My Deliveries',
            ),
          ],
        ),
      ),
    );
  }
}
