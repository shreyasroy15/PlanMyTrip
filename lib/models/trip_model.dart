import 'itinerary_model.dart';

class TripModel {
  final String id;
  final String userId;
  final String destination;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String status; // 'planned', 'ongoing', 'completed'
  final List<String> companions;
  final List<ItineraryItem> itinerary;
  final String imageUrl;

  TripModel({
    required this.id,
    required this.userId,
    required this.destination,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.budget = 0.0,
    this.status = 'planned',
    this.companions = const [],
    this.itinerary = const [],
    this.imageUrl = '',
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      destination: map['destination'] ?? '',
      title: map['title'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : DateTime.now().add(const Duration(days: 3)),
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'planned',
      companions: List<String>.from(map['companions'] ?? []),
      itinerary: (map['itinerary'] as List<dynamic>?)
              ?.map((item) => ItineraryItem.fromMap(item, ''))
              .toList() ??
          [],
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'destination': destination,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'status': status,
      'companions': companions,
      'itinerary': itinerary.map((item) => item.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }
}
