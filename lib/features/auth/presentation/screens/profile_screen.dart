import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _role = '';
  String _fullName = '';
  String _businessName = '';
  String _phone = '';
  String _category = '';
  String _tradeLicense = '';
  String _minOrderValue = '0';
  String _supplyRadius = '';
  String _address = '';
  String _createdAt = '';
  String _initials = 'U';
  String _currentLanguage = 'English';

  final Map<String, Map<String, String>> _localizedStrings = {
    'English': {
      'Profile': 'Profile',
      'Personal Details': 'Personal Details',
      'Full Name': 'Full Name',
      'Phone': 'Phone',
      'Email': 'Email',
      'Not set': 'Not set',
      'Shop Details': 'Shop Details',
      'Business Name': 'Business Name',
      'Category': 'Category',
      'Address': 'Address',
      'Business Hours': 'Business Hours',
      'Tax ID': 'Tax ID',
      'Settings': 'Settings',
      'Notifications': 'Notifications',
      'Language': 'Language',
      'Support': 'Support',
      'Help Center': 'Help Center',
      'Privacy Policy': 'Privacy Policy',
      'Log out': 'Log out',
      'Supplier / Wholesaler': 'Supplier / Wholesaler',
      'Shop Owner': 'Shop Owner',
      'Failed to load profile': 'Failed to load profile',
    },
    'Bangla': {
      'Profile': 'প্রোফাইল',
      'Personal Details': 'ব্যক্তিগত বিবরণ',
      'Full Name': 'পুরো নাম',
      'Phone': 'ফোন',
      'Email': 'ইমেইল',
      'Not set': 'সেট করা নেই',
      'Shop Details': 'দোকানের বিবরণ',
      'Business Name': 'ব্যবসার নাম',
      'Category': 'বিভাগ',
      'Address': 'ঠিকানা',
      'Business Hours': 'ব্যবসার সময়',
      'Tax ID': 'ট্যাক্স আইডি',
      'Settings': 'সেটিংস',
      'Notifications': 'নোটিফিকেশন',
      'Language': 'ভাষা',
      'Support': 'সাপোর্ট',
      'Help Center': 'হেল্প সেন্টার',
      'Privacy Policy': 'গোপনীয়তা নীতি',
      'Log out': 'লগ আউট',
      'Supplier / Wholesaler': 'সরবরাহকারী / পাইকারি বিক্রেতা',
      'Shop Owner': 'দোকান মালিক',
      'Failed to load profile': 'প্রোফাইল লোড করতে ব্যর্থ হয়েছে',
    }
  };

  String _t(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? key;
  }

  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _licenseController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _radiusController = TextEditingController();
  String _editCategory = AppCategories.grocery;

  bool get _isSupplier => _role == 'supplier';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _licenseController.dispose();
    _minOrderController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.get('/profile');
    if (data != null && mounted) {
      final m = Map<String, dynamic>.from(data);
      _applyData(m);
    } else if (mounted) {
      await _loadFromPrefs();
    }
  }

  void _applyData(Map<String, dynamic> m) {
    final display = (m['businessName'] ?? '').toString().isNotEmpty
        ? m['businessName'].toString()
        : (m['fullName'] ?? '').toString();
    final initials = _computeInitials(display);

    final raw = m['createdAt'] ?? '';
    String memberSince = '';
    if (raw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(raw.toString());
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        memberSince = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        memberSince = raw.toString().substring(0, 10.clamp(0, raw.toString().length));
      }
    }

    setState(() {
      _role = m['role']?.toString() ?? '';
      _fullName = m['fullName']?.toString() ?? '';
      _businessName = m['businessName']?.toString() ?? '';
      _phone = m['phoneNumber']?.toString() ?? '';
      _category = m['category']?.toString() ?? '';
      _tradeLicense = m['tradeLicense']?.toString() ?? '';
      _minOrderValue = m['minOrderValue']?.toString() ?? '0';
      _supplyRadius = m['supplyRadius']?.toString() ?? '';
      _address = m['address']?.toString() ?? '';
      _createdAt = memberSince;
      _initials = initials;
      _isLoading = false;
    });
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final business = prefs.getString('user_business') ?? '';
    final role = prefs.getString('user_role') ?? '';
    final phone = prefs.getString('user_phone') ?? '';
    final address = prefs.getString('user_address') ?? '';
    final category = prefs.getString('user_category') ?? '';

    setState(() {
      _role = role;
      _fullName = name;
      _businessName = business;
      _phone = phone;
      _address = address;
      _category = category;
      _initials = _computeInitials(business.isNotEmpty ? business : name);
      _isLoading = false;
    });
  }

  Future<void> _updateLanguage(String newLang) async {
    setState(() => _currentLanguage = newLang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', newLang);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t('Language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _currentLanguage,
                onChanged: (val) {
                  if (val != null) {
                    _updateLanguage(val);
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close details screen to refresh UI
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('বাংলা (Bangla)'),
                value: 'Bangla',
                groupValue: _currentLanguage,
                onChanged: (val) {
                  if (val != null) {
                    _updateLanguage(val);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _computeInitials(String displayName) {
    if (displayName.isEmpty) return 'U';
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
  }

  void _enterEditMode() {
    _nameController.text = _fullName;
    _businessController.text = _businessName;
    _licenseController.text = _tradeLicense;
    _minOrderController.text = _minOrderValue == '0' ? '' : _minOrderValue;
    _radiusController.text = _supplyRadius;
    _editCategory = _category.isNotEmpty ? _category : AppCategories.grocery;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() => setState(() => _isEditing = false);

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final business = _businessController.text.trim();

    if (name.isEmpty || business.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and business name are required.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'fullName': name,
      'businessName': business,
      'category': _editCategory,
    };

    if (_isSupplier) {
      body['tradeLicense'] = _licenseController.text.trim();
      body['minOrderValue'] =
          double.tryParse(_minOrderController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      body['supplyRadius'] = _radiusController.text.trim();
    }

    final data = await ApiService.patch('/profile', body: body);

    if (data != null && mounted) {
      final m = Map<String, dynamic>.from(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', m['fullName']?.toString() ?? name);
      await prefs.setString('user_business', m['businessName']?.toString() ?? business);
      await prefs.setString('user_category', m['category']?.toString() ?? _editCategory);

      _applyData(m);
      setState(() => _isEditing = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    } else if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!_isEditing)
                IconButton(
                  onPressed: _enterEditMode,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal, size: 22),
                  tooltip: 'Edit profile',
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAvatar(),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _businessName.isNotEmpty ? _businessName : (_fullName.isNotEmpty ? _fullName : 'User'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isSupplier
                    ? const Color(0xFFE6F4F1)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isSupplier ? 'Supplier / Wholesaler' : 'Shop Owner',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isSupplier
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF4338CA),
                ),
              ),
            ),
          ),
          if (_createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Member since $_createdAt',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_isEditing) ..._buildEditForm() else ..._buildViewTiles(),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Log out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cancelled,
                side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFF0C896),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildViewTiles() {
    return [
      _ProfileListTile(icon: Icons.person_outline, label: 'Full Name', value: _fullName.isNotEmpty ? _fullName : 'Not set'),
      _ProfileListTile(icon: Icons.store_outlined, label: 'Business Name', value: _businessName.isNotEmpty ? _businessName : 'Not set'),
      _ProfileListTile(icon: Icons.phone_outlined, label: 'Phone', value: _phone.isNotEmpty ? _phone : 'Not set'),
      _ProfileListTile(icon: Icons.category_outlined, label: 'Category', value: _category.isNotEmpty ? _category : 'Not set'),
      if (_address.isNotEmpty)
        _ProfileListTile(icon: Icons.location_on_outlined, label: 'Address', value: _address),
      if (_isSupplier) ...[
        _ProfileListTile(
          icon: Icons.badge_outlined,
          label: 'Trade License',
          value: _tradeLicense.isNotEmpty ? _tradeLicense : 'Not provided',
        ),
        _ProfileListTile(
          icon: Icons.shopping_cart_outlined,
          label: 'Min Order Value',
          value: '৳${double.tryParse(_minOrderValue) ?? 0}',
        ),
        _ProfileListTile(
          icon: Icons.social_distance_outlined,
          label: 'Supply Radius',
          value: _supplyRadius.isNotEmpty ? _supplyRadius : 'Not set',
        ),
      ],
    ];
  }

  List<Widget> _buildEditForm() {
    return [
      _buildEditField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline),
      const SizedBox(height: 4),
      _buildEditField(label: 'Business Name', controller: _businessController, icon: Icons.store_outlined),
      const SizedBox(height: 12),
      _buildEditCategoryDropdown(),
      if (_isSupplier) ...[
        const SizedBox(height: 4),
        _buildEditField(label: 'Trade License', controller: _licenseController, icon: Icons.badge_outlined),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildEditField(
                label: 'Min Order (৳)',
                controller: _minOrderController,
                icon: Icons.shopping_cart_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEditField(
                label: 'Supply Radius',
                controller: _radiusController,
                icon: Icons.social_distance_outlined,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _cancelEdit,
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
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
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
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 20),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEditCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: AppColors.primaryTeal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _editCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                onChanged: (v) {
                  if (v != null) setState(() => _editCategory = v);
                },
                items: AppCategories.allCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileListTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryTealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  const _ActionListTile({required this.icon, required this.label, required this.onTap, this.trailingText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }
}
