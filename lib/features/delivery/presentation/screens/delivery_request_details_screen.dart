import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class DeliveryRequestDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> request;
  final LatLng? riderLocation;
  final VoidCallback onAccept;

  const DeliveryRequestDetailsScreen({
    super.key,
    required this.request,
    required this.riderLocation,
    required this.onAccept,
  });

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  double? _calculateDistance(LatLng? p1, LatLng? p2) {
    if (p1 == null || p2 == null) return null;
    const distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2) / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final supplierLat = request['supplier_lat'] != null ? double.tryParse(request['supplier_lat'].toString()) : null;
    final supplierLng = request['supplier_lng'] != null ? double.tryParse(request['supplier_lng'].toString()) : null;
    final deliveryLat = request['delivery_lat'] != null ? double.tryParse(request['delivery_lat'].toString()) : null;
    final deliveryLng = request['delivery_lng'] != null ? double.tryParse(request['delivery_lng'].toString()) : null;

    LatLng? supplierLoc;
    if (supplierLat != null && supplierLng != null) supplierLoc = LatLng(supplierLat, supplierLng);
    
    LatLng? deliveryLoc;
    if (deliveryLat != null && deliveryLng != null) deliveryLoc = LatLng(deliveryLat, deliveryLng);

    final distToSupplier = _calculateDistance(riderLocation, supplierLoc);
    final distSupplierToShop = _calculateDistance(supplierLoc, deliveryLoc);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Order Summary',
              icon: Icons.receipt_long,
              children: [
                _buildInfoRow('Product', request['product_name'] ?? 'N/A', isBold: true),
                _buildInfoRow('Quantity', '${request['quantity']} ${request['unit']}'),
                _buildInfoRow('Total Amount', '৳${request['total_amount']}'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Pickup (Supplier)',
              icon: Icons.store,
              distance: distToSupplier != null ? '${distToSupplier.toStringAsFixed(1)} km from you' : null,
              onMapTap: supplierLoc != null ? () => _openMap(supplierLoc!.latitude, supplierLoc.longitude) : null,
              children: [
                _buildInfoRow('Name', request['supplier_name'] ?? 'N/A'),
                _buildInfoRow('Phone', request['supplier_phone'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Dropoff (Shop Owner)',
              icon: Icons.location_on,
              distance: distSupplierToShop != null ? '${distSupplierToShop.toStringAsFixed(1)} km from pickup' : null,
              onMapTap: deliveryLoc != null ? () => _openMap(deliveryLoc!.latitude, deliveryLoc.longitude) : null,
              children: [
                _buildInfoRow('Name', request['shop_owner_name'] ?? 'N/A'),
                _buildInfoRow('Phone', request['shop_owner_phone'] ?? 'N/A'),
                _buildInfoRow('Address', request['delivery_address'] ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? distance,
    VoidCallback? onMapTap,
    required List<Widget> children,
  }) {
    return Container(
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
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (onMapTap != null)
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: onMapTap,
                  tooltip: 'View on map',
                ),
            ],
          ),
          if (distance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(distance, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
