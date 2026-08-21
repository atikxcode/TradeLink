import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'add_stock_screen.dart';

class StockScreen extends StatefulWidget {
  final bool showAddButton;

  const StockScreen({super.key, this.showAddButton = true});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _stocks = [];

  @override
  void initState() {
    super.initState();
    _fetchStocks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    debugPrint('[StockScreen] _fetchStocks called');
    final data = await ApiService.get('/suppliers/stock');
    debugPrint('[StockScreen] data=$data');
    if (data != null && mounted) {
      setState(() {
        _stocks = (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _stocks = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F5C4F)))
          : RefreshIndicator(
              onRefresh: _fetchStocks,
              color: const Color(0xFF0F5C4F),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Stock',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.showAddButton)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddStockScreen(),
                              ),
                            );
                            _fetchStocks();
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add stock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_stocks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No stock items yet. Tap "Add stock" to get started.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    )
                  else
                    ..._stocks.map((stock) => _StockItem(
                          name: stock['customProductName'] ?? stock['name'] ?? 'Unknown',
                          quantity: '${stock['quantityAvailable'] ?? stock['quantity'] ?? 0} ${stock['unit'] ?? ''}',
                          price: '৳${stock['pricePerUnit'] ?? stock['price_per_unit'] ?? 0} / ${stock['unit'] ?? ''}',
                          category: stock['category'] ?? '',
                        )),
                ],
              ),
            ),
    );
  }
}

class _StockItem extends StatelessWidget {
  final String name;
  final String quantity;
  final String price;
  final String category;

  const _StockItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  IconData get _icon {
    switch (category.toLowerCase()) {
      case 'grocery':
        return Icons.rice_bowl;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'hardware':
        return Icons.hardware;
      case 'stationery':
        return Icons.edit_note;
      default:
        return Icons.inventory_2;
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryTealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppColors.primaryTeal, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quantity,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}
