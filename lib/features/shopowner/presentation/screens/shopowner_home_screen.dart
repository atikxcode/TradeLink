import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'post_demand_screen.dart';
import 'matching_suppliers_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class ShopownerHomeScreen extends StatefulWidget {
  const ShopownerHomeScreen({super.key});

  @override
  State<ShopownerHomeScreen> createState() => _ShopownerHomeScreenState();
}

class _ShopownerHomeScreenState extends State<ShopownerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.inputBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostDemandScreen(),
                ),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryTeal,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.inventory_2_outlined),
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.add_outlined),
              ),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_outline),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const OrdersScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.inputBorder),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildPostDemandButton(),
                  const SizedBox(height: 32),
                  _buildActiveDemandsHeader(),
                  const SizedBox(height: 16),
                  _buildDemandCard(
                    title: 'Rice — Basmati, 50kg',
                    location: 'Mirpur-10',
                    time: 'Posted 2h ago',
                    status: 'Matching',
                    statusColor: AppColors.matchingText,
                    statusBgColor: AppColors.matchingBg,
                    icon: Icons.location_on_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MatchingSuppliersScreen(
                            demandTitle: 'Rice — Basmati, 50kg',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDemandCard(
                    title: 'Detergent Powder, 30 units',
                    location: null,
                    time: 'ETA 20–30 min',
                    status: 'Out for delivery',
                    statusColor: AppColors.outForDeliveryText,
                    statusBgColor: AppColors.outForDeliveryBg,
                    icon: Icons.subdirectory_arrow_right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryTealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'RU',
                style: TextStyle(
                  color: AppColors.primaryTealDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Rahim General Store',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.toggleBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.textPrimary,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('3', 'Open\ndemands'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('1', 'Out for\ndelivery'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('12', 'Completed'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostDemandButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostDemandScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Post a new demand',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActiveDemandsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Active demands',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandCard({
    required String title,
    required String? location,
    required String time,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location != null ? '$location · $time' : time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
