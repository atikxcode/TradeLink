import 'package:flutter/material.dart';
import '../../../../core/constants/app_categories.dart';
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

  Future<void> _deleteStock(Map<String, dynamic> stock) async {
    final id = stock['id']?.toString();
    final stockName = stock['customProductName'] ?? stock['name'] ?? 'Unknown';
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Stock Item?'),
        content: Text(
          "Are you sure you want to delete '$stockName'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ApiService.delete('/suppliers/stock/$id');
    if (result != null && mounted) {
      setState(() {
        _stocks.removeWhere((s) => s['id']?.toString() == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$stockName deleted successfully'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item. Please try again.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  void _editStock(Map<String, dynamic> stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditStockSheet(
        stock: stock,
        onSave: (updated) async {
          final id = stock['id']?.toString();
          if (id == null) return;

          final result = await ApiService.patch('/suppliers/stock/$id', body: updated);
          if (result != null && mounted) {
            final map = Map<String, dynamic>.from(result);
            setState(() {
              final idx = _stocks.indexWhere((s) => s['id']?.toString() == id);
              if (idx != -1) _stocks[idx] = map;
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stock item updated successfully'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update item. Please try again.'),
                backgroundColor: AppColors.cancelled,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : RefreshIndicator(
              onRefresh: _fetchStocks,
              color: const Color(0xFF0F766E),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No stock listed yet. Tap '+ Add stock' to publish your first item.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._stocks.map((stock) => _StockItem(
                          stock: stock,
                          onEdit: () => _editStock(stock),
                          onDelete: () => _deleteStock(stock),
                        )),
                ],
              ),
            ),
    );
  }
}

class _StockItem extends StatelessWidget {
  final Map<String, dynamic> stock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StockItem({
    required this.stock,
    required this.onEdit,
    required this.onDelete,
  });

  String get name => stock['customProductName'] ?? stock['name'] ?? 'Unknown';
  dynamic get quantity => stock['quantityAvailable'] ?? stock['quantity'] ?? 0;
  String get unit => stock['unit'] ?? '';
  dynamic get price => stock['pricePerUnit'] ?? stock['price_per_unit'] ?? 0;
  String get category => stock['category'] ?? '';

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

  Color get _categoryBgColor {
    switch (category.toLowerCase()) {
      case 'grocery':
        return const Color(0xFFE6F4F1);
      case 'pharmacy':
        return const Color(0xFFEDE9FE);
      case 'hardware':
        return const Color(0xFFF1F5F9);
      case 'stationery':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _categoryTextColor {
    switch (category.toLowerCase()) {
      case 'grocery':
        return const Color(0xFF0F766E);
      case 'pharmacy':
        return const Color(0xFF7C3AED);
      case 'hardware':
        return const Color(0xFF475569);
      case 'stationery':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: AppColors.primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _categoryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\u09F3$price / $unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
              Text(
                'Quantity: $quantity $unit',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditStockSheet extends StatefulWidget {
  final Map<String, dynamic> stock;
  final Future<void> Function(Map<String, dynamic> updated) onSave;

  const _EditStockSheet({required this.stock, required this.onSave});

  @override
  State<_EditStockSheet> createState() => _EditStockSheetState();
}

class _EditStockSheetState extends State<_EditStockSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late String _selectedCategory;
  late String _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.stock['customProductName']?.toString() ?? widget.stock['name']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.stock['pricePerUnit']?.toString() ?? widget.stock['price_per_unit']?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.stock['quantityAvailable']?.toString() ?? widget.stock['quantity']?.toString() ?? '',
    );
    _selectedCategory = widget.stock['category']?.toString() ?? AppCategories.grocery;
    _selectedUnit = widget.stock['unit']?.toString() ?? 'kg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final stockName = _nameController.text.trim();
    final priceVal = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final qtyVal = double.tryParse(_quantityController.text.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (stockName.isEmpty || priceVal == null || qtyVal == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields with valid values.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    await widget.onSave({
      'customProductName': stockName,
      'category': _selectedCategory,
      'pricePerUnit': priceVal,
      'quantity': qtyVal,
      'unit': _selectedUnit,
    });

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Stock Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Product Name'),
            const SizedBox(height: 8),
            _buildTextField(controller: _nameController, hintText: 'Product name'),
            const SizedBox(height: 16),
            _buildLabel('Category'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                  items: AppCategories.allCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price per unit'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _priceController,
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Unit'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
                            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedUnit = v);
                            },
                            items: ['kg', 'litre', 'pcs']
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Quantity'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _quantityController,
              hintText: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}
