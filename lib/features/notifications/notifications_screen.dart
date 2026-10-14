import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> _notifications = const [
    {
      'title': 'Flight Reminder',
      'message': 'Your flight to Bali departs in 10 days. Don\'t forget your passport!',
      'time': '2 hours ago',
    },
    {
      'title': 'AI Itinerary Ready',
      'message': 'Your 3-day Kyoto culture tour plan was generated successfully.',
      'time': 'Yesterday',
    },
    {
      'title': 'Budget Update',
      'message': 'You have allocated \$2,500 for the Swiss Alps trip.',
      'time': '3 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.notifications, color: Colors.white, size: 20),
              ),
              title: Text(
                item['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              subtitle: Text(item['message']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: Text(item['time']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }
}
