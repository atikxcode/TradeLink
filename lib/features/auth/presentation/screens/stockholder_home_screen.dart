import 'package:flutter/material.dart';
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

  static const List<Widget> _tabs = [
    _StockholderDashboard(),
    StockScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

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
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _tabs),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 4),
                Text(
                  'Manik Wholesale',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF0C896),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'MW',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
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
            const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: Color(0xFF374151),
            ),
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

class _StockholderDashboard extends StatelessWidget {
  const _StockholderDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 24),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildSectionHeader('Nearby demands', '6 new'),
        const SizedBox(height: 16),
        DemandCard(
          title: 'Rice — Basmati, 50kg',
          distance: '2.1 km',
          subtitle: 'Rahim General Store · Mirpur-10',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IncomingOrderScreen(),
              ),
            );
          },
          onAccept: () =>
              _showDemandAction(context, 'Accepted', 'Rice — Basmati, 50kg'),
          onDecline: () =>
              _showDemandAction(context, 'Declined', 'Rice — Basmati, 50kg'),
        ),
        DemandCard(
          title: 'Soybean Oil, 20L',
          distance: '3.8 km',
          subtitle: 'New Bazar Store · Kazipara',
          onAccept: () =>
              _showDemandAction(context, 'Accepted', 'Soybean Oil, 20L'),
          onDecline: () =>
              _showDemandAction(context, 'Declined', 'Soybean Oil, 20L'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDemandAction(BuildContext context, String action, String demand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: $demand'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('6', 'New demands'),
        const SizedBox(width: 12),
        _buildStatCard('2', 'Pending orders'),
        const SizedBox(width: 12),
        _buildStatCard('18', 'Stock items'),
      ],
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
