import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/api_service.dart';
import 'orders_screen.dart';

const Color _primaryTeal = Color(0xFF0F766E);
const Color _softSlateBg = Color(0xFFF8FAFC);
const Color _darkText = Color(0xFF0F172A);
const Color _mutedLabel = Color(0xFF64748B);
const Color _borderGray = Color(0xFFE2E8F0);
const Color _dangerRed = Color(0xFFDC2626);
const Color _cardShadow = Color(0x0A0F172A);

class IncomingOrderScreen extends StatefulWidget {
  final String demandId;
  final String productName;
  final String quantity;
  final String unit;
  final String category;
  final String notes;
  final dynamic targetPrice;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic deliveryAddress;

  const IncomingOrderScreen({
    super.key,
    required this.demandId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.notes = '',
    this.targetPrice,
    this.latitude,
    this.longitude,
    this.deliveryAddress,
  });

  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  String? _resolvedAddress;

  double? get _lat => widget.latitude is num
      ? (widget.latitude as num).toDouble()
      : double.tryParse(widget.latitude?.toString() ?? '');
  double? get _lng => widget.longitude is num
      ? (widget.longitude as num).toDouble()
      : double.tryParse(widget.longitude?.toString() ?? '');

  bool get _hasPin => _lat != null && _lng != null;

  String get _addressText {
    final addr = (widget.deliveryAddress ?? '').toString().trim();
    if (addr.isNotEmpty) return addr;
    if (_resolvedAddress != null) return _resolvedAddress!;
    return _hasPin ? '$_lat, $_lng' : 'No location provided';
  }

  @override
  void initState() {
    super.initState();
    if ((widget.deliveryAddress ?? '').toString().trim().isEmpty && _hasPin) {
      _reverseGeocode();
    }
  }

  Future<void> _reverseGeocode() async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&zoom=16&lat=$_lat&lon=$_lng',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'TradeLinkApp/1.0'});
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final name = body['display_name']?.toString();
        if (name != null && name.isNotEmpty) {
          setState(() => _resolvedAddress = name);
        }
      }
    } catch (_) {}
  }

  String get _totalPriceLabel {
    if (widget.targetPrice == null) return 'No budget set';
    final t = widget.targetPrice is num
        ? (widget.targetPrice as num).toDouble()
        : double.tryParse(widget.targetPrice.toString());
    if (t == null) return 'No budget set';
    
    final qty = double.tryParse(widget.quantity) ?? 0;
    final total = t * qty;
    final totalStr = total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(2);
    final unitStr = t == t.roundToDouble() ? t.toInt().toString() : t.toStringAsFixed(2);
    
    return '৳$totalStr (৳$unitStr/unit)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softSlateBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsCard(),
                  const SizedBox(height: 20),
                  _buildMapCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _softSlateBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _darkText),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demand Details',
              style: TextStyle(
                color: _darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Review order requirements',
              style: TextStyle(
                color: _mutedLabel.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _primaryTeal.withValues(alpha: 0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardShadow.withValues(alpha: 0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
        border: Border.all(color: _borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Product Name and Category
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryTeal,
                  const Color(0xFF0D5F58),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (widget.category.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Info Rows
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.scale_rounded,
                  label: 'Quantity Requested',
                  value: '${widget.quantity} ${widget.unit}',
                  iconColor: const Color(0xFF3B82F6),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: _borderGray),
                ),
                _buildInfoRow(
                  icon: Icons.payments_rounded,
                  label: 'Total Amount',
                  value: _totalPriceLabel,
                  iconColor: const Color(0xFF10B981),
                  isHighlight: true,
                ),
                if (widget.notes.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: _borderGray),
                  ),
                  _buildInfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Additional Notes',
                    value: widget.notes,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _mutedLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 18 : 16,
                  fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                  color: isHighlight ? _primaryTeal : _darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardShadow.withValues(alpha: 0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
        border: Border.all(color: _borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _addressText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _mutedLabel,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_hasPin)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_lat!, _lng!),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tradelink',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat!, _lng!),
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: _dangerRed,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _softSlateBg,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 32, color: _mutedLabel.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  const Text('No map data available', style: TextStyle(color: _mutedLabel, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await ApiService.post('/demands/${widget.demandId}/decline');
                    if (result != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order declined'), behavior: SnackBarBehavior.floating),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dangerRed,
                    side: BorderSide(color: _dangerRed.withValues(alpha: 0.3), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ApiService.post('/demands/${widget.demandId}/accept');
                    if (result != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order accepted'), behavior: SnackBarBehavior.floating),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: _primaryTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Accept Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

