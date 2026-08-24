import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/widgets/map_location_picker_dialog.dart';
import 'delivery_man_home_screen.dart';

class DeliveryManRegisterScreen extends StatefulWidget {
  const DeliveryManRegisterScreen({super.key});

  @override
  State<DeliveryManRegisterScreen> createState() => _DeliveryManRegisterScreenState();
}

class _DeliveryManRegisterScreenState extends State<DeliveryManRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  String _locationStatus = 'Auto-detected — tap to adjust';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _formatPhoneNumber(String input) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880')) {
      digits = '0${digits.substring(3)}';
    } else if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    if (digits.length == 11 && digits.startsWith('01')) {
      return digits;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final phone = _formatPhoneNumber(rawPhone);

    if (name.isEmpty || rawPhone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: AppColors.cancelled),
      );
      return;
    }

    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 11-digit phone number.'), backgroundColor: AppColors.cancelled),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();

      final inserted = await SupabaseConfig.client.from(SupabaseConfig.tableUsers).insert({
        'role': 'delivery_man',
        'full_name': name,
        'phone_number': phone,
        'password_hash': hashedPassword,
        'business_name': '$name Delivery',
        'category': 'Delivery',
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'address': _locationStatus,
      }).select().single();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', inserted['id']?.toString() ?? '');
      await prefs.setString('user_name', inserted['full_name']?.toString() ?? name);
      await prefs.setString('user_role', 'delivery_man');
      await prefs.setString('user_phone', phone);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryManHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (e.toString().contains('duplicate key value violates unique constraint')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number already registered. Please login.'), backgroundColor: AppColors.cancelled),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await showDialog<LocationResult>(
      context: context,
      builder: (_) => MapLocationPickerDialog(initialLocation: _selectedLocation),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result.coordinates;
        _locationStatus = result.address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Join as a Rider 🛵',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deliver goods and earn money on your own schedule.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Form Fields
                _buildModernTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. John Doe',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '017XXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Location Picker
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: AppColors.primaryTeal, size: 20),
                          SizedBox(width: 8),
                          Text('Service Area', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _locationStatus,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickLocation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            side: const BorderSide(color: AppColors.primaryTeal),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Adjust on Map', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.cancelled, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
