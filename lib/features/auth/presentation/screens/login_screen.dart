import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'register_screen.dart';

enum UserRole { shopOwner, stockholder }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.shopOwner;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final roleName = _selectedRole == UserRole.shopOwner ? 'Shop Owner' : 'Stockholder';
    final phone = _phoneController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logging in as $roleName ($phone)...'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    // Mock Mobile Status Bar (Matches design header)
                    const _MockStatusBar(),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),

                          // App Logo Icon
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.layers_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title
                          const Text(
                            'Welcome to TradeLink',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle
                          const Text(
                            'Sign in to buy or sell with nearby shops',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Role Switcher Segmented Control
                          _buildRoleToggle(),

                          const SizedBox(height: 24),

                          // Phone Number Field Label
                          const Text(
                            'Phone number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Phone Input Field
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '+880 1XXX-XXXXXX',
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
                          ),

                          const SizedBox(height: 20),

                          // Password Field Label
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Password Input Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
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
                          ),

                          const SizedBox(height: 12),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Forgot Password clicked'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Log in Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Register Footer Text
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterScreen(
                                        initialRole: _selectedRole,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  /// Builds the "Shop Owner" vs "Stockholder" toggle bar
  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.toggleBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Shop Owner Option
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
          // Stockholder Option
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

/// Helper widget for the role selection tabs
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Status Bar simulation to match the provided mockup
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
