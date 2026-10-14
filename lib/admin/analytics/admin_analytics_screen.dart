import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance & Usage',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildMetricBar('Monthly Active Users (MAU)', 0.85, '12,450 / 15,000 Goal'),
            const SizedBox(height: 16),
            _buildMetricBar('AI Itineraries Generated', 0.92, '8,920 Requests'),
            const SizedBox(height: 16),
            _buildMetricBar('User Satisfaction Rate', 0.96, '4.8 / 5.0 Rating'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Top Requested Destinations',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text('1. Kyoto, Japan — 34% of total queries', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('2. Bali, Indonesia — 28% of total queries', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('3. Santorini, Greece — 22% of total queries', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('4. Paris, France — 16% of total queries', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, double value, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(detail, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: AppColors.surfaceLight,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}
