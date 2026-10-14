import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateTripModal() {
    final titleController = TextEditingController();
    final destController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedStatus = 'upcoming';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Trip',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Trip Title',
              hint: 'e.g. Summer Beach Escape',
              controller: titleController,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Destination',
              hint: 'e.g. Tokyo, Paris, Bali',
              controller: destController,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Budget (\$)',
              hint: '2000',
              controller: budgetController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Save Trip',
              onPressed: () {
                if (destController.text.trim().isEmpty) return;
                final user = ref.read(authProvider).userModel;
                final newTrip = TripModel(
                  id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
                  userId: user?.uid ?? 'usr_001',
                  destination: destController.text.trim(),
                  title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : destController.text.trim(),
                  startDate: DateTime.now().add(const Duration(days: 7)),
                  endDate: DateTime.now().add(const Duration(days: 14)),
                  budget: double.tryParse(budgetController.text) ?? 1500.0,
                  status: selectedStatus,
                  imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600',
                );

                ref.read(tripsProvider.notifier).addTrip(newTrip);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);

    final upcomingTrips = trips.where((t) => t.status == 'upcoming' && _matchesSearch(t)).toList();
    final ongoingTrips = trips.where((t) => t.status == 'ongoing' && _matchesSearch(t)).toList();
    final completedTrips = trips.where((t) => t.status == 'completed' && _matchesSearch(t)).toList();
    final draftTrips = trips.where((t) => t.status == 'draft' && _matchesSearch(t)).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Drafts'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                label: '',
                hint: 'Search trips by title or destination...',
                controller: _searchController,
                prefixIcon: Icons.search,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTripList(context, upcomingTrips, 'No upcoming trips planned yet.'),
                  _buildTripList(context, ongoingTrips, 'No ongoing trips right now.'),
                  _buildTripList(context, completedTrips, 'No completed trips in your history.'),
                  _buildTripList(context, draftTrips, 'No draft trips saved.'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _showCreateTripModal,
        ),
      ),
    );
  }

  bool _matchesSearch(TripModel trip) {
    if (_searchQuery.isEmpty) return true;
    return trip.title.toLowerCase().contains(_searchQuery) || trip.destination.toLowerCase().contains(_searchQuery);
  }

  Widget _buildTripList(BuildContext context, List<TripModel> tripsList, String emptyMessage) {
    if (tripsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_travel, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.read(tripsProvider.notifier).fetchUserTrips('usr_active'),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: const Text('Refresh Trips'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tripsList.length,
      itemBuilder: (context, index) {
        final trip = tripsList[index];
        return Dismissible(
          key: Key(trip.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            ref.read(tripsProvider.notifier).deleteTrip(trip.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${trip.title} deleted')),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/trip-detail/${trip.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      trip.imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.flight, size: 40, color: AppColors.textMuted),
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
                            Expanded(
                              child: Text(
                                trip.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                trip.status.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${Formatters.formatDate(trip.startDate)} - ${Formatters.formatDate(trip.endDate)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.formatCurrency(trip.budget),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
        );
      },
    );
  }
}
