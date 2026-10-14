import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/itinerary_model.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool _isSaved = false;

  void _showEditTripDialog(TripModel trip) {
    final titleController = TextEditingController(text: trip.title);
    final budgetController = TextEditingController(text: trip.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Trip Details', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(label: 'Title', controller: titleController),
            const SizedBox(height: 12),
            CustomTextField(label: 'Budget (\$)', controller: budgetController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = TripModel(
                id: trip.id,
                userId: trip.userId,
                destination: trip.destination,
                title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : trip.title,
                startDate: trip.startDate,
                endDate: trip.endDate,
                budget: double.tryParse(budgetController.text) ?? trip.budget,
                status: trip.status,
                companions: trip.companions,
                imageUrl: trip.imageUrl,
                itinerary: trip.itinerary,
              );
              ref.read(tripsProvider.notifier).updateTrip(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityModal(TripModel trip) {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '10:00 AM');
    final locController = TextEditingController();
    final descController = TextEditingController();
    final costController = TextEditingController(text: '0');
    int selectedDay = 1;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Activity to Itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              CustomTextField(label: 'Activity Title', hint: 'e.g. Visit Museum', controller: titleController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: 'Time Slot', hint: '10:00 AM', controller: timeController)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: 'Cost (\$)', hint: '25', controller: costController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Location', hint: 'e.g. Louvre Museum', controller: locController),
              const SizedBox(height: 12),
              CustomTextField(label: 'Description', hint: 'Notes about the activity', controller: descController, maxLines: 2),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Add to Timeline',
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  final newItem = ItineraryItem(
                    id: 'itin_${DateTime.now().millisecondsSinceEpoch}',
                    dayNumber: selectedDay,
                    timeSlot: timeController.text.trim(),
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    location: locController.text.trim(),
                    cost: double.tryParse(costController.text) ?? 0.0,
                    isCompleted: false,
                  );
                  ref.read(tripsProvider.notifier).addActivity(trip.id, newItem);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareTrip(TripModel trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing itinerary for "${trip.title}"... Link copied to clipboard!')),
    );
  }

  void _deleteTrip(TripModel trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Trip?', style: TextStyle(color: AppColors.error)),
        content: Text('Are you sure you want to delete "${trip.title}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(tripsProvider.notifier).deleteTrip(trip.id);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);
    final trip = trips.firstWhere(
      (t) => t.id == widget.tripId,
      orElse: () => TripModel(
        id: widget.tripId,
        userId: 'usr_001',
        destination: 'Destination',
        title: 'Trip Details',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? AppColors.accentGold : Colors.white),
                onPressed: () {
                  setState(() => _isSaved = !_isSaved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isSaved ? 'Trip saved to bookmarks!' : 'Trip removed from bookmarks.')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareTrip(trip),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) {
                  if (val == 'edit') _showEditTripDialog(trip);
                  if (val == 'delete') _deleteTrip(trip);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Trip', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    trip.imageUrl.isNotEmpty ? trip.imageUrl : 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceLight),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.background.withValues(alpha: 0.95)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${Formatters.formatDate(trip.startDate)} - ${Formatters.formatDate(trip.endDate)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Budget', Formatters.formatCurrency(trip.budget), Icons.attach_money)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('Activities', '${trip.itinerary.length} items', Icons.event_available)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Itinerary Timeline',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: () => _showAddActivityModal(trip),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (trip.itinerary.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.timeline, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('No activities in itinerary yet.', style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showAddActivityModal(trip),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add First Activity'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trip.itinerary.length,
                      itemBuilder: (context, index) {
                        final item = trip.itinerary[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isCompleted ? AppColors.success.withValues(alpha: 0.5) : AppColors.glassBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: AppColors.success,
                                value: item.isCompleted,
                                onChanged: (_) {
                                  ref.read(tripsProvider.notifier).toggleActivityCompleted(trip.id, item.id);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.timeSlot,
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, decoration: item.isCompleted ? TextDecoration.lineThrough : null),
                                      ),
                                    ],
                                    if (item.location.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(item.location, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.cost > 0)
                                Text(
                                  Formatters.formatCurrency(item.cost),
                                  style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/maps'),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open Interactive Map'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
