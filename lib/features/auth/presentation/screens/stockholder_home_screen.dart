import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import 'incoming_order_screen.dart';
import 'notifications_screen.dart';
import 'stock_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class StockholderHomeScreen extends StatefulWidget {
  const StockholderHomeScreen({super.key});

  @override
  State<StockholderHomeScreen> createState() => _StockholderHomeScreenState();
}

class _StockholderHomeScreenState extends State<StockholderHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _StockholderHeader(),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    _StockholderDashboard(),
                    StockScreen(),
                    OrdersScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0F5C4F),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StockholderHeader extends StatefulWidget {
  @override
  State<_StockholderHeader> createState() => _StockholderHeaderState();
}

class _StockholderHeaderState extends State<_StockholderHeader> {
  String _businessName = '';
  String _initials = 'S';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_business') ?? prefs.getString('user_name') ?? '';
    setState(() {
      _businessName = name;
      if (name.isNotEmpty) {
        final words = name.trim().split(RegExp(r'\s+'));
        _initials = words.length >= 2
            ? '${words[0][0]}${words[1][0]}'.toUpperCase()
            : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0C896),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  _businessName.isNotEmpty ? _businessName : 'Supplier',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF374151)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockholderDashboard extends StatefulWidget {
  const _StockholderDashboard();

  @override
  State<_StockholderDashboard> createState() => _StockholderDashboardState();
}

class _StockholderDashboardState extends State<_StockholderDashboard> {
  bool _isLoading = true;
  int _newDemandsCount = 0;
  int _pendingOrdersCount = 0;
  int _stockItemsCount = 0;
  List<Map<String, dynamic>> _demands = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeStats();
  }

  Future<void> _fetchHomeStats() async {
    final data = await ApiService.get('/suppliers/home-stats');
    if (data != null && mounted) {
      final demandsList = (data['nearbyDemands'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      setState(() {
        _newDemandsCount = data['newDemandsCount'] ?? 0;
        _pendingOrdersCount = data['pendingOrdersCount'] ?? 0;
        _stockItemsCount = data['stockItemsCount'] ?? 0;
        _demands = demandsList;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptDemand(String demandId, String productName) async {
    final result = await ApiService.post('/demands/$demandId/accept');
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accepted: $productName'),
          backgroundColor: const Color(0xFF0F5C4F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchHomeStats();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept demand. Try again.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _declineDemand(String demandId, String productName) async {
    final result = await ApiService.post('/demands/$demandId/decline');
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined: $productName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchHomeStats();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline demand. Try again.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F5C4F)));
    }

    return RefreshIndicator(
      onRefresh: _fetchHomeStats,
      color: const Color(0xFF0F5C4F),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('$_newDemandsCount', 'New demands'),
              const SizedBox(width: 12),
              _buildStatCard('$_pendingOrdersCount', 'Pending orders'),
              const SizedBox(width: 12),
              _buildStatCard('$_stockItemsCount', 'Stock items'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Nearby demands', '$_newDemandsCount new'),
          const SizedBox(height: 8),
          if (_demands.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Text(
                  'No pending demands nearby',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ..._demands.map((demand) => DemandCard(
                  title: demand['product_name'] ?? 'Unknown',
                  distance: demand['category'] ?? '',
                  subtitle: 'Qty: ${demand['quantity'] ?? 0} ${demand['unit'] ?? ''}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IncomingOrderScreen(
                          demandId: demand['id'] ?? '',
                          productName: demand['product_name'] ?? '',
                          quantity: (demand['quantity'] ?? 0).toString(),
                          unit: demand['unit'] ?? '',
                          category: demand['category'] ?? '',
                          notes: demand['notes'] ?? '',
                        ),
                      ),
                    );
                  },
                  onAccept: () => _acceptDemand(
                    demand['id'] ?? '',
                    demand['product_name'] ?? '',
                  ),
                  onDecline: () => _declineDemand(
                    demand['id'] ?? '',
                    demand['product_name'] ?? '',
                  ),
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 26,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badgeLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class DemandCard extends StatelessWidget {
  final String title;
  final String distance;
  final String subtitle;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onTap;

  const DemandCard({
    super.key,
    required this.title,
    required this.distance,
    required this.subtitle,
    required this.onAccept,
    required this.onDecline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Decline',
                          backgroundColor: const Color(0xFFEAECF5),
                          textColor: const Color(0xFF374151),
                          onPressed: onDecline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Accept',
                          backgroundColor: const Color(0xFF0F5C4F),
                          textColor: Colors.white,
                          onPressed: onAccept,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
