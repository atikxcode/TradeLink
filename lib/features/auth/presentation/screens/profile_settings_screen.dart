import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/services/api_service.dart';

/// Editable profile settings — persists via PATCH /profile.
class ProfileSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ProfileSettingsScreen({super.key, required this.initialData});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const Color _brand = Color(0xFF0F766E);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _border = Color(0xFFE2E8F0);

  late final bool _isSupplier;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _radiusCtrl;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    String s(String k) => d[k]?.toString() ?? '';
    _isSupplier = (d['role'] ?? '').toString() == 'supplier';
    _nameCtrl = TextEditingController(text: s('fullName'));
    _businessCtrl = TextEditingController(text: s('businessName'));
    _phoneCtrl = TextEditingController(text: s('phoneNumber'));
    _addressCtrl = TextEditingController(text: s('address'));
    _licenseCtrl = TextEditingController(text: s('tradeLicense'));
    _minOrderCtrl =
        TextEditingController(text: s('minOrderValue').replaceAll(RegExp(r'\.0+$'), ''));
    _radiusCtrl = TextEditingController(text: s('supplyRadius'));
    _category = s('category').isEmpty ? AppCategories.grocery : s('category');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _licenseCtrl.dispose();
    _minOrderCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brand, width: 1.6)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final business = _businessCtrl.text.trim();
    if (name.isEmpty || business.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name and business name are required.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'fullName': name,
      'businessName': business,
      'category': _category,
      'phoneNumber': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    };
    if (_isSupplier) {
      body['tradeLicense'] = _licenseCtrl.text.trim();
      body['minOrderValue'] =
          double.tryParse(_minOrderCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final r = double.tryParse(_radiusCtrl.text.trim());
      body['supplyRadius'] = r?.toString();
    }

    final data = await ApiService.patch('/profile', body: body);

    if (!mounted) return;
    if (data != null) {
      // Keep session cache in sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', data['fullName']?.toString() ?? name);
      await prefs.setString(
          'user_business', data['businessName']?.toString() ?? business);
      await prefs.setString('user_phone', data['phoneNumber']?.toString() ?? '');
      await prefs.setString('user_address', data['address']?.toString() ?? '');
      await prefs.setString('user_category', _category);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile Settings',
            style: TextStyle(
                color: _dark, fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Full name'),
            TextField(controller: _nameCtrl, decoration: _dec('Your name')),
            const SizedBox(height: 16),
            _label('Business name'),
            TextField(
                controller: _businessCtrl, decoration: _dec('Business name')),
            const SizedBox(height: 16),
            _label('Phone number'),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('01XXX-XXXXXX'),
            ),
            const SizedBox(height: 16),
            _label('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: AppCategories.grocery, child: Text('Grocery')),
                DropdownMenuItem(value: AppCategories.pharmacy, child: Text('Pharmacy')),
                DropdownMenuItem(value: AppCategories.hardware, child: Text('Hardware')),
              ],
              onChanged: (v) =>
                  setState(() => _category = v ?? AppCategories.grocery),
              decoration: _dec('Select category'),
            ),
            const SizedBox(height: 16),
            _label('Delivery address'),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: _dec('Shop location / delivery address'),
            ),
            if (_isSupplier) ...[
              const SizedBox(height: 16),
              _label('Trade license'),
              TextField(controller: _licenseCtrl, decoration: _dec('License no.')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Min order (৳)'),
                        TextField(
                            controller: _minOrderCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _dec('0')),
                      ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Supply radius (km)'),
                        TextField(
                            controller: _radiusCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _dec('10')),
                      ]),
                ),
              ]),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
