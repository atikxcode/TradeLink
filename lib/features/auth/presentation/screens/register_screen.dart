import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shopowner/presentation/screens/shopowner_home_screen.dart';
import '../../../stockholder/presentation/screens/stockholder_home_screen.dart';
import '../widgets/map_location_picker_dialog.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole initialRole;

  const RegisterScreen({
    super.key,
    this.initialRole = UserRole.shopOwner,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late UserRole _selectedRole;
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  
  // Wholesaler / Stockholder Additional Controllers
  final TextEditingController _tradeLicenseController = TextEditingController();
  final TextEditingController _minOrderController = TextEditingController();
  final TextEditingController _supplyRadiusController = TextEditingController();

  String _selectedCategory = AppCategories.grocery;
  bool _obscurePassword = true;
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  String _locationStatus = 'Auto-detected — tap to adjust';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _tradeLicenseController.dispose();
    _minOrderController.dispose();
    _supplyRadiusController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_selectedRole == UserRole.shopOwner) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ShopownerHomeScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const StockholderHomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStockholder = _selectedRole == UserRole.stockholder;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mock Mobile Status Bar
                    const _MockStatusBar(),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Row with Back Button
                            Row(
                              children: [
                                Material(
                                  color: AppColors.toggleBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.pop(context),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        color: AppColors.textPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Role Switcher Segmented Control
                            _buildRoleToggle(),

                            const SizedBox(height: 20),

                            // Full Name Field
                            _buildLabel('Full name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hintText: 'Rahim Uddin',
                              keyboardType: TextInputType.name,
                            ),

                            const SizedBox(height: 16),

                            // Phone Number Field
                            _buildLabel('Phone number'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hintText: '+880 1XXX-XXXXXX',
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            _buildLabel('Password'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Create a password',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Shop Name / Warehouse Name
                            _buildLabel(
                              isStockholder ? 'Warehouse / Business name' : 'Shop name',
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _businessNameController,
                              hintText: isStockholder
                                  ? 'Rahim Wholesale Depot'
                                  : 'Rahim General Store',
                            ),

                            const SizedBox(height: 16),

                            // Category Dropdown
                            _buildLabel('Category'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.inputBorder, width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    }
                                  },
                                  items: AppCategories.allCategories
                                      .map<DropdownMenuItem<String>>((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            // Wholesaler / Stockholder Additional Fields
                            if (isStockholder) ...[
                              const SizedBox(height: 16),
                              _buildLabel('Trade License / Business Reg. No.'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _tradeLicenseController,
                                hintText: 'TRAD/DHK/2026/98765',
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Min Order Value (৳)'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                          controller: _minOrderController,
                                          hintText: '5,000 ৳',
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
                                        _buildLabel('Supply Radius'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                          controller: _supplyRadiusController,
                                          hintText: 'Within 15 km',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Location Field Map Box
                            _buildLabel(
                              isStockholder ? 'Warehouse location' : 'Shop location',
                            ),
                            const SizedBox(height: 8),
                            _buildMapLocationPicker(),

                            const SizedBox(height: 24),

                            // Create Account Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds Field Label Text
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

  /// Builds Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryTeal,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  /// Interactive Map Location Box Widget matching design
  Widget _buildMapLocationPicker() {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<LocationResult>(
          context: context,
          builder: (context) => MapLocationPickerDialog(
            initialLocation: _selectedLocation,
          ),
        );

        if (result != null) {
          setState(() {
            _selectedLocation = result.coordinates;
            _locationStatus = result.address;
          });
        }
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder, width: 1),
        ),
        child: Stack(
          children: [
            // Grid Background Simulation
            CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(),
            ),

            // Map Pin Icon in Center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primaryTeal,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // Location Badge at Bottom-Left
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _locationStatus,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds Role Switcher Toggle
  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.toggleBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTabItem(
              title: 'Shop Owner',
              isSelected: _selectedRole == UserRole.shopOwner,
              onTap: () {
                setState(() {
                  _selectedRole = UserRole.shopOwner;
                });
              },
            ),
          ),
          Expanded(
            child: _RoleTabItem(
              title: 'Stockholder',
              isSelected: _selectedRole == UserRole.stockholder,
              onTap: () {
                setState(() {
                  _selectedRole = UserRole.stockholder;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTabItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTabItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Custom Grid Painter to simulate interactive map view background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: const [
              Icon(Icons.signal_cellular_alt, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 4),
              Text(
                'Wi-Fi 100%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
