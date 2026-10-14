import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;
    final trips = ref.watch(tripsProvider);
    final destinations = ref.watch(destinationsProvider);

    final upcomingTrip = trips.isNotEmpty ? trips.first : null;

    final popularDestinations = destinations.take(3).toList();
    final trendingDestinations = destinations.skip(1).take(3).toList();
    final recommendedDestinations = destinations.reversed.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context) ? 40 : 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row (Greeting, Profile, Notifications)
              _buildHeader(context, user),
              const SizedBox(height: 20),

              // 2. Destination Search Bar
              _buildSearchBar(context),
              const SizedBox(height: 24),

              // 3. AI Trip Planner CTA Banner
              _buildAiPlannerBanner(context),
              const SizedBox(height: 28),

              // 4. Upcoming Trips Section
              _buildSectionHeader(
                context,
                title: 'Upcoming Trip',
                actionText: 'View All',
                onActionTap: () => context.go('/trips'),
              ),
              const SizedBox(height: 12),
              _buildUpcomingTripCard(context, upcomingTrip),
              const SizedBox(height: 28),

              // 5. Popular Destinations Horizontal Carousel
              _buildSectionHeader(
                context,
                title: 'Popular Destinations',
                actionText: 'Explore All',
                onActionTap: () => context.go('/explore'),
              ),
              const SizedBox(height: 12),
              _buildDestinationCarousel(context, popularDestinations),
              const SizedBox(height: 28),

              // 6. Trending Destinations
              _buildSectionHeader(
                context,
                title: 'Trending Places 🔥',
                actionText: 'See Trending',
                onActionTap: () => context.go('/explore'),
              ),
              const SizedBox(height: 12),
              _buildDestinationCarousel(context, trendingDestinations),
              const SizedBox(height: 28),

              // 7. Recommended Destinations
              _buildSectionHeader(
                context,
                title: 'Recommended For You ✨',
                actionText: 'Browse',
                onActionTap: () => context.go('/explore'),
              ),
              const SizedBox(height: 12),
              _buildDestinationCarousel(context, recommendedDestinations),
              const SizedBox(height: 28),

              // 8. Saved Places Quick Access
              _buildSectionHeader(
                context,
                title: 'Saved Places',
                actionText: 'Go to Saved',
                onActionTap: () => context.go('/saved'),
              ),
              const SizedBox(height: 12),
              _buildSavedPlacesQuickList(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header Section Widget ---
  Widget _buildHeader(BuildContext context, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: (user?.photoUrl != null && user.photoUrl.isNotEmpty)
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: (user?.photoUrl == null || user.photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name ?? 'Traveler'} 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Where are we going next?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                  onPressed: () => context.push('/notifications'),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            if (user?.role == 'admin')
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 26),
                onPressed: () => context.push('/admin'),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  // --- Destination Search Bar ---
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/explore'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: AppColors.primary, size: 22),
            SizedBox(width: 12),
            Text(
              'Search places, cities, or experiences...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            Spacer(),
            Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0);
  }

  // --- AI Trip Planner Banner ---
  Widget _buildAiPlannerBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text(
                'AI Itinerary Planner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Get tailored 3-day or 7-day travel plans with budget, places, and routes in seconds.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.go('/ai-planner'),
            icon: const Icon(Icons.bolt, color: AppColors.primary),
            label: const Text('Generate Trip with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  // --- Section Header Helper ---
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // --- Upcoming Trip Card ---
  Widget _buildUpcomingTripCard(BuildContext context, dynamic upcomingTrip) {
    if (upcomingTrip == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: AppColors.primary, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No Upcoming Trips',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start planning your next adventure today!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go('/ai-planner'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Plan Now'),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/trip-detail/${upcomingTrip.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                upcomingTrip.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.flight, size: 48, color: AppColors.textMuted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        upcomingTrip.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          upcomingTrip.status.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        upcomingTrip.destination,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.formatCurrency(upcomingTrip.budget),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.1, end: 0);
  }

  // --- Destination Carousel ---
  Widget _buildDestinationCarousel(BuildContext context, List destinationsList) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: destinationsList.length,
        itemBuilder: (context, index) {
          final item = destinationsList[index];
          return GestureDetector(
            onTap: () => context.go('/explore'),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(
                          item.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.landscape, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '${item.rating}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.country,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${Formatters.formatCurrency(item.estimatedCostPerDay)} / day',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // --- Saved Places Quick List ---
  Widget _buildSavedPlacesQuickList(BuildContext context) {
    final sampleSaved = [
      {'name': 'Santorini Cliffside Villa', 'location': 'Greece', 'image': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=500'},
      {'name': 'Kyoto Bamboo Forest', 'location': 'Japan', 'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=500'},
      {'name': 'Swiss Alps Cabin', 'location': 'Switzerland', 'image': 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=500'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sampleSaved.length,
        itemBuilder: (context, index) {
          final place = sampleSaved[index];
          return GestureDetector(
            onTap: () => context.go('/saved'),
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      place['image']!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.bookmark, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place['location']!,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 650.ms);
  }
}
