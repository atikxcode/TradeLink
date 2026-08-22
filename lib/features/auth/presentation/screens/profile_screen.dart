import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _initials = 'U';
  String _role = '';
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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.tableUsers)
          .select()
          .eq('id', userId)
          .single();
          
      final lang = response['preferred_language']?.toString() ?? 'English';
      final roleStr = response['role']?.toString() ?? '';
      
      final displayName = (response['business_name']?.toString().isNotEmpty == true) 
          ? response['business_name'].toString() 
          : (response['full_name']?.toString() ?? 'User');

      String initials = 'U';
      if (displayName.isNotEmpty) {
        final words = displayName.trim().split(RegExp(r'\s+'));
        initials = words.length >= 2
            ? '${words[0][0]}${words[1][0]}'.toUpperCase()
            : displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
      }

      if (mounted) {
        setState(() {
          _userData = response;
          _currentLanguage = (lang == 'Bangla') ? 'Bangla' : 'English';
          _role = roleStr == 'supplier' ? 'Supplier / Wholesaler' : 'Shop Owner';
          _initials = initials;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLanguage(String newLang) async {
    setState(() {
      _currentLanguage = newLang;
    });
    
    try {
      if (_userData != null && _userData!['id'] != null) {
        await SupabaseConfig.client
            .from(SupabaseConfig.tableUsers)
            .update({'preferred_language': newLang})
            .eq('id', _userData!['id']);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_language', newLang);
    } catch (e) {
      // Ignored for now
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    }

    if (_userData == null) {
      return Center(child: Text(_t("Failed to load profile")));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              _t('Profile'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            
            _buildSectionTile(
              icon: Icons.person_outline,
              title: _t('Personal Details'),
              children: [
                _ProfileListTile(icon: Icons.person_outline, label: _t('Full Name'), value: _userData!['full_name'] ?? _t('Not set')),
                _ProfileListTile(icon: Icons.phone_outlined, label: _t('Phone'), value: _userData!['phone_number'] ?? _t('Not set')),
                _ProfileListTile(icon: Icons.email_outlined, label: _t('Email'), value: _userData!['email'] ?? _t('Not set')),
              ],
            ),
            
            _buildSectionTile(
              icon: Icons.store_outlined,
              title: _t('Shop Details'),
              children: [
                _ProfileListTile(icon: Icons.store_outlined, label: _t('Business Name'), value: _userData!['business_name'] ?? _t('Not set')),
                _ProfileListTile(icon: Icons.category_outlined, label: _t('Category'), value: _userData!['category'] ?? _t('Not set')),
                _ProfileListTile(icon: Icons.location_on_outlined, label: _t('Address'), value: _userData!['address'] ?? _t('Not set')),
                if (_userData!['opening_time'] != null || _userData!['closing_time'] != null)
                  _ProfileListTile(
                    icon: Icons.access_time, 
                    label: _t('Business Hours'), 
                    value: '${_userData!['opening_time'] ?? '--'} - ${_userData!['closing_time'] ?? '--'}'
                  ),
                if (_userData!['tax_id'] != null && _userData!['tax_id'].toString().isNotEmpty)
                  _ProfileListTile(icon: Icons.receipt_long_outlined, label: _t('Tax ID'), value: _userData!['tax_id']),
              ],
            ),
            
            _buildSectionTile(
              icon: Icons.settings_outlined,
              title: _t('Settings'),
              children: [
                _ActionListTile(icon: Icons.notifications_none, label: _t('Notifications'), onTap: () {}),
                _ActionListTile(
                  icon: Icons.language_outlined, 
                  label: _t('Language'), 
                  trailingText: _currentLanguage == 'Bangla' ? 'বাংলা' : 'English',
                  onTap: _showLanguageDialog,
                ),
              ],
            ),
            
            _buildSectionTile(
              icon: Icons.help_outline,
              title: _t('Support'),
              children: [
                _ActionListTile(icon: Icons.help_outline, label: _t('Help Center'), onTap: () {}),
                _ActionListTile(icon: Icons.privacy_tip_outlined, label: _t('Privacy Policy'), onTap: () {}),
              ],
            ),

            const SizedBox(height: 32),
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
                label: Text(
                  _t('Log out'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cancelled,
                  side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final displayName = (_userData!['business_name']?.toString().isNotEmpty == true) 
        ? _userData!['business_name'] 
        : (_userData!['full_name']?.toString().isNotEmpty == true ? _userData!['full_name'] : 'User');

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF0C896),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t(_role),
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  initialData: _userData!, 
                  currentLanguage: _currentLanguage,
                ),
              ),
            );
            if (result == true) {
              _fetchProfile();
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal, size: 20),
          ),
        )
      ],
    );
  }

  Widget _buildSectionTile({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _SectionDetailScreen(
                title: title,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionDetailScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionDetailScreen({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 56),
                ]
              ],
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
