import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../providers/user_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userListProvider);
    final trips = ref.watch(tripsProvider);
    final destinations = ref.watch(destinationsProvider);

    final totalUsers = users.length;
    final activeUsers = users.where((u) => u.isActive).length;
    final inactiveUsers = users.where((u) => !u.isActive).length;
    final totalTrips = trips.length;
    final totalDestinations = destinations.length;
    const int aiRequestsCount = 8920;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Administrator Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Manage global users, platform trips, destinations, and system metrics.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Users', '$totalUsers', Icons.people, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Active Users', '$activeUsers', Icons.check_circle, AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Inactive Users', '$inactiveUsers', Icons.pause_circle, AppColors.warning)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Trips', '$totalTrips', Icons.flight, AppColors.secondary)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Destinations', '$totalDestinations', Icons.place, Colors.amber)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('AI Queries', '$aiRequestsCount', Icons.auto_awesome, Colors.pink)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Management Modules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildAdminTile(
              icon: Icons.supervised_user_circle,
              title: 'User Management',
              subtitle: 'Search, filter, view profile, activate/deactivate, delete, change role, export JSON/CSV',
              onTap: () => context.push('/admin/users'),
            ),
            _buildAdminTile(
              icon: Icons.card_travel,
              title: 'Trips Moderation',
              subtitle: 'Monitor platform trips, filter status, and moderate itineraries',
              onTap: () => context.push('/admin/trips'),
            ),
            _buildAdminTile(
              icon: Icons.location_city,
              title: 'Destinations Catalog',
              subtitle: 'Add, update rating, or moderate top travel destinations',
              onTap: () => context.push('/admin/destinations'),
            ),
            _buildAdminTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics & Insights',
              subtitle: 'Platform growth, query volume, and active user metrics',
              onTap: () => context.push('/admin/analytics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAdminTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
