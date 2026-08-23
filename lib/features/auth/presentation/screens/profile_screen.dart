import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';

/// Modern profile screen that adapts to Shop Owner vs Supplier.
///
/// The "Switch Mode" tile flips a LOCAL presentation override so users can
/// preview the other workspace; it never mutates the server-side role.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _brand = Color(0xFF0F766E);
  static const Color _bgTop = Color(0xFFFFF7ED);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  bool _isLoading = true;
  String _actualRole = 'shop_owner'; // from server/prefs
  String _fullName = '';
  String _businessName = '';
  String _phone = '';
  String _address = '';
  double _rating = 0;
  int _activeOrders = 0;
  int _totalDemands = 0;
  int _totalFulfilled = 0;


  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.get('/profile');
    if (!mounted) return;
    if (data != null) {
      final m = Map<String, dynamic>.from(data);
      // Null-safe string helper — never render "null"
      String s(String k) => m[k]?.toString() ?? '';
      setState(() {
        _actualRole = s('role').isNotEmpty ? s('role') : _actualRole;
        _fullName = s('fullName');
        _businessName = s('businessName');
        _phone = s('phoneNumber');
        _address = s('address');
        _rating = double.tryParse(s('rating')) ?? 5.0;
        _activeOrders = int.tryParse(s('activeOrders')) ?? 0;
        _totalDemands = int.tryParse(s('totalDemands')) ?? 0;
        _totalFulfilled = int.tryParse(s('totalFulfilled')) ?? 0;
        _isLoading = false;
      });
    } else if (mounted) {
      await _loadFromPrefs();
    }
  }

  bool get _isSupplier => _actualRole == 'supplier';

  /// Offline fallback when /profile is unreachable.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String pretty(String? raw, String fb) {
      final n = (raw ?? '').trim();
      if (n.isEmpty || RegExp(r'^\d+$').hasMatch(n)) return fb;
      return n;
    }

    if (!mounted) return;
    setState(() {
      _actualRole = prefs.getString('user_role') ?? _actualRole;
      _fullName = pretty(prefs.getString('user_name'), '');
      _businessName = pretty(prefs.getString('user_business'), 'My Shop');
      _phone = prefs.getString('user_phone') ?? '';
      _address = prefs.getString('user_address') ?? '';
      _isLoading = false;
    });
  }

  String get _displayName {
    final n = _businessName.trim().isNotEmpty
        ? _businessName
        : _fullName.trim();
    if (n.isEmpty || RegExp(r'^\d+$').hasMatch(n)) {
      return _isSupplier ? 'My Store' : 'My Shop';
    }
    return n;
  }

  String get _avatarInitials {
    final parts = _displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
    }
    return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
  }

  String get _locationLabel {
    final a = _address.trim();
    if (a.isEmpty || a.toLowerCase().startsWith('selected location')) {
      return 'Dhaka, Bangladesh';
    }
    return a.split(',').take(2).join(',').trim();
  }

  String get _rankLabel {
    if (_rating >= 4.8) return 'Top 5%';
    if (_rating >= 4.5) return 'Top 10%';
    if (_rating >= 4.0) return 'Top 25%';
    return '—';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, Colors.white],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(),
              _buildProfileCard(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsRow(),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSettingsList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text('Profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none_rounded,
                      size: 22, color: Color(0xFF374151)),
                  onPressed: () {}, // notifications live in their own tab/screen
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating profile card ──
  Widget _buildProfileCard() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: _brand,
            child: Text(_avatarInitials,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Text(_displayName,
            style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _textDark)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded,
                size: 15, color: _brand),
            const SizedBox(width: 4),
            Flexible(
              child: Text(_locationLabel,
                  style: const TextStyle(
                      fontSize: 13.5, color: _textMuted),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _isSupplier
                ? const Color(0xFFEEF8F6)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _isSupplier ? 'SUPPLIER' : 'SHOP OWNER',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _isSupplier ? _brand : const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  // ── Stats row ──
  Widget _buildStatsRow() {
    final List<({IconData icon, String value, String label})> stats =
        _isSupplier
            ? [
                (icon: Icons.star_rounded, value: _rating.toStringAsFixed(1), label: 'AVG. Rating'),
                (icon: Icons.emoji_events_rounded, value: _rankLabel, label: 'Current Rank'),
                (icon: Icons.inventory_2_outlined, value: '$_totalFulfilled', label: 'Total Fulfilled'),
              ]
            : [
                (icon: Icons.star_rounded, value: _rating.toStringAsFixed(1), label: 'AVG. Rating'),
                (icon: Icons.local_shipping_outlined, value: '$_activeOrders', label: 'Active Orders'),
                (icon: Icons.request_quote_outlined, value: '$_totalDemands', label: 'Total Demands'),
              ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          return Expanded(
            child: Column(
              children: [
                Icon(s.icon, size: 18, color: _brand),
                const SizedBox(height: 4),
                Text(s.value,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _textDark)),
                const SizedBox(height: 2),
                Text(s.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10.5, color: _textMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Settings list ──
  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _tile(Icons.person_outline_rounded, 'Profile Settings',
              subtitle: 'Name, phone, business details',
              onTap: _openEditor),
          _divider(),
          _tile(Icons.location_on_outlined, 'Location & Delivery Address',
              subtitle: _address.isEmpty ? 'Not set' : _address,
              onTap: _openEditor),
          _divider(),
          if (!_isSupplier)
            _tile(Icons.receipt_long_outlined, 'Order History',
                onTap: () => _push(const OrdersScreen()))
          else
            _tile(Icons.account_balance_wallet_outlined,
                'Manage Withdrawals / Earnings',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Withdrawals coming soon — earnings ledger in progress.'),
                        behavior: SnackBarBehavior.floating))),
          _divider(),
          _tile(Icons.settings_outlined, 'Account Settings & Security',
              onTap: () => _push(const SettingsScreen())),
          _divider(),
          _tile(Icons.logout_rounded, 'Log Out',
              iconColor: Colors.red,
              textColor: Colors.red,
              showChevron: false,
              onTap: _logout),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9));

  Widget _tile(IconData icon, String title,
      {String? subtitle,
      VoidCallback? onTap,
      Color iconColor = _brand,
      Color textColor = _textDark,
      bool showChevron = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  if (subtitle != null &&
                      subtitle.isNotEmpty &&
                      subtitle.length < 60)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: _textMuted)),
                    ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialData: {
            'fullName': _fullName,
            'businessName': _businessName,
            'phoneNumber': _phone,
            'address': _address,
            'category': '',
          },
        ),
      ),
    );
    if (mounted) {
      setState(() => _isLoading = true);
      await _loadProfile();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
  }
}
