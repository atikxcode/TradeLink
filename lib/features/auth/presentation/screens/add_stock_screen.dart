import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/api_service.dart';
import '../widgets/map_location_picker_dialog.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  static const Color _primaryTeal = Color(0xFF0F766E);
  static const Color _softTeal = Color(0xFFEEF8F6);
  static const Color _slateDark = Color(0xFF0F172A);
  static const Color _slateLabel = Color(0xFF334155);
  static const Color _slateMuted = Color(0xFF64748B);
  static const Color _slateBorder = Color(0xFFE2E8F0);
  static const Color _slateLightBg = Color(0xFFF1F5F9);
  static const Color _screenBackground = Color(0xFFF8FAFC);

  static const List<String> _categories = ['Grocery', 'Pharmacy', 'Stationery', 'Hardware'];
  static const List<String> _units = ['kg', 'litre', 'pcs'];

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Grocery';
  String _selectedUnit = 'kg';
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _openMapPicker() async {
    final initial = _selectedLocation ?? const LatLng(23.8103, 90.4125);
    final result = await showDialog<LocationResult>(
      context: context,
      builder: (_) => MapLocationPickerDialog(initialLocation: initial),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result.coordinates;
        _selectedAddress = result.address;
      });
    }
  }

  Future<void> _handlePublish() async {
    final productName = _productNameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final priceText = _priceController.text.trim();

    if (productName.isEmpty) {
      _showError('Please enter a product name');
      return;
    }
    if (quantityText.isEmpty) {
      _showError('Please enter a quantity');
      return;
    }
    if (priceText.isEmpty) {
      _showError('Please enter a price');
      return;
    }

    final quantity = double.tryParse(quantityText);
    final price = double.tryParse(priceText);
    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }
    if (price == null || price < 0) {
      _showError('Please enter a valid price');
      return;
    }

    setState(() => _isSaving = true);

    final body = {
      'customProductName': productName,
      'category': _selectedCategory,
      'quantity': quantity,
      'unit': _selectedUnit,
      'pricePerUnit': price,
    };

    final result = await ApiService.post('/suppliers/stock', body: body);

    setState(() => _isSaving = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Published: $productName'),
          backgroundColor: _primaryTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      _showError('Failed to publish stock. Try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: _buildAppBar(),
      body: _buildFormBody(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _slateBorder)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildBackButton(),
            const SizedBox(width: 12),
            const Text(
              'Add stock',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _slateDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _slateLightBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _slateLabel,
        ),
      ),
    );
  }

  Widget _buildFormBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            label: 'Category',
            value: _selectedCategory,
            options: _categories,
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          _buildTextFieldField(
            label: 'Product name',
            hintText: 'e.g. Rice - Basmati',
            controller: _productNameController,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildTextFieldField(
                  label: 'Quantity available',
                  hintText: '500',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdownField(
                  label: 'Unit',
                  value: _selectedUnit,
                  options: _units,
                  onChanged: (value) => setState(() => _selectedUnit = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextFieldField(
            label: 'Price per unit (\u09F3)',
            hintText: '68',
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildLabel('Warehouse location'),
          const SizedBox(height: 8),
          _buildMapBox(),
          const SizedBox(height: 8),
          Text(
            _selectedAddress.isNotEmpty
                ? _selectedAddress
                : 'Tap the map to select warehouse location',
            style: const TextStyle(
              fontSize: 13,
              color: _slateMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _slateLabel,
      ),
    );
  }

  Widget _buildTextFieldField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: _slateDark),
          decoration: _inputDecoration(hintText),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _slateBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateMuted),
              style: const TextStyle(fontSize: 15, color: _slateDark),
              items: options
                  .map((option) => DropdownMenuItem<String>(value: option, child: Text(option)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 15, color: _slateMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _slateBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryTeal, width: 1.5),
      ),
    );
  }

  Widget _buildMapBox() {
    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _slateBorder),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_softTeal, _slateLightBg],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.location_on_rounded, size: 36, color: _primaryTeal),
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap to pick location',
                  style: TextStyle(fontSize: 11, color: _slateMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _slateBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handlePublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Publish stock listing',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
