class SavedPlaceModel {
  final String id;
  final String userId;
  final String destinationId;
  final String placeName;
  final String imageUrl;
  final double rating;
  final DateTime savedAt;

  SavedPlaceModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.placeName,
    required this.imageUrl,
    this.rating = 4.5,
    required this.savedAt,
  });

  factory SavedPlaceModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedPlaceModel(
      id: id,
      userId: map['userId'] ?? '',
      destinationId: map['destinationId'] ?? '',
      placeName: map['placeName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      savedAt: map['savedAt'] != null
          ? DateTime.parse(map['savedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'destinationId': destinationId,
      'placeName': placeName,
      'imageUrl': imageUrl,
      'rating': rating,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
