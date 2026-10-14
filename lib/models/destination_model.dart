class DestinationModel {
  final String id;
  final String name;
  final String country;
  final String description;
  final String imageUrl;
  final double rating;
  final double estimatedCostPerDay;
  final List<String> tags;

  DestinationModel({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.imageUrl,
    this.rating = 4.5,
    this.estimatedCostPerDay = 150.0,
    this.tags = const [],
  });

  factory DestinationModel.fromMap(Map<String, dynamic> map, String id) {
    return DestinationModel(
      id: id,
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      estimatedCostPerDay: (map['estimatedCostPerDay'] as num?)?.toDouble() ?? 150.0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'estimatedCostPerDay': estimatedCostPerDay,
      'tags': tags,
    };
  }
}
