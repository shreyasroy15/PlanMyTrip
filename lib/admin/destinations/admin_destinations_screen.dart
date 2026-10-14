import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';

class AdminDestinationsScreen extends ConsumerWidget {
  const AdminDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(destinationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Destinations Catalog'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final d = destinations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(d.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text('${d.name}, ${d.country}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              subtitle: Text('Rating: ${d.rating} ⭐ • Est: \$${d.estimatedCostPerDay.toInt()}/day'),
              trailing: const Icon(Icons.edit, color: AppColors.primary),
            ),
          );
        },
      ),
    );
  }
}
