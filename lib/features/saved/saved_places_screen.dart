import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  final List<Map<String, dynamic>> _saved = const [
    {
      'name': 'Fushimi Inari Taisha',
      'location': 'Kyoto, Japan',
      'imageUrl': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400',
      'rating': 4.9,
    },
    {
      'name': 'Oia Sunset Point',
      'location': 'Santorini, Greece',
      'imageUrl': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400',
      'rating': 4.8,
    },
    {
      'name': 'Eiffel Tower Deck',
      'location': 'Paris, France',
      'imageUrl': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
      'rating': 4.7,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _saved.length,
        itemBuilder: (context, index) {
          final item = _saved[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['location'],
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item['rating']}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove, color: AppColors.accent),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
