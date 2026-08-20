import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'add_stock_screen.dart';

class StockScreen extends StatelessWidget {
  final bool showAddButton;

  const StockScreen({super.key, this.showAddButton = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              if (showAddButton)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStockScreen(),
                      ),
                    );
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
          _StockItem(
            name: 'Basmati Rice',
            quantity: '50 kg',
            price: '৳ 1,450 / 50kg',
            icon: Icons.rice_bowl,
          ),
          _StockItem(
            name: 'Soybean Oil',
            quantity: '20 L',
            price: '৳ 1,800 / 20L',
            icon: Icons.local_drink,
          ),
          _StockItem(
            name: 'Sugar',
            quantity: '30 kg',
            price: '৳ 780 / 30kg',
            icon: Icons.cookie,
          ),
          _StockItem(
            name: 'Flour (Maida)',
            quantity: '40 kg',
            price: '৳ 620 / 40kg',
            icon: Icons.cake,
          ),
        ],
      ),
    );
  }
}

class _StockItem extends StatelessWidget {
  final String name;
  final String quantity;
  final String price;
  final IconData icon;

  const _StockItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.icon,
  });

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
            child: Icon(icon, color: AppColors.primaryTeal, size: 24),
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
