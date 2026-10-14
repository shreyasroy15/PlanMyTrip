import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';

class AdminTripsScreen extends ConsumerWidget {
  const AdminTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Trips Moderation'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final t = trips[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(t.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              subtitle: Text('${t.destination} • \$${t.budget.toInt()} • Owner: ${t.userId}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () {
                  ref.read(tripsProvider.notifier).deleteTrip(t.id);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
