class ItineraryItem {
  final String id;
  final int dayNumber;
  final String timeSlot;
  final String title;
  final String description;
  final String location;
  final double cost;
  final bool isCompleted;

  ItineraryItem({
    required this.id,
    required this.dayNumber,
    required this.timeSlot,
    required this.title,
    required this.description,
    required this.location,
    this.cost = 0.0,
    this.isCompleted = false,
  });

  ItineraryItem copyWith({
    String? id,
    int? dayNumber,
    String? timeSlot,
    String? title,
    String? description,
    String? location,
    double? cost,
    bool? isCompleted,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      timeSlot: timeSlot ?? this.timeSlot,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      cost: cost ?? this.cost,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map, String id) {
    return ItineraryItem(
      id: map['id'] ?? id,
      dayNumber: map['dayNumber'] ?? 1,
      timeSlot: map['timeSlot'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'timeSlot': timeSlot,
      'title': title,
      'description': description,
      'location': location,
      'cost': cost,
      'isCompleted': isCompleted,
    };
  }
}
