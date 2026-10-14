class AiTripPlannerRequestModel {
  final String destination;
  final String startDate;
  final String endDate;
  final int travelers;
  final String travelerType;
  final double budget;
  final String currency;
  final String travelStyle;
  final List<String> interests;
  final String transportation;
  final String accommodation;

  AiTripPlannerRequestModel({
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.travelers = 1,
    this.travelerType = 'Solo',
    required this.budget,
    this.currency = 'USD',
    this.travelStyle = 'Moderate',
    required this.interests,
    this.transportation = 'Flight',
    this.accommodation = 'Hotel',
  });

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'travelers': travelers,
      'travelerType': travelerType,
      'budget': budget,
      'currency': currency,
      'travelStyle': travelStyle,
      'interests': interests,
      'transportation': transportation,
      'accommodation': accommodation,
    };
  }

  factory AiTripPlannerRequestModel.fromMap(Map<String, dynamic> map) {
    return AiTripPlannerRequestModel(
      destination: map['destination'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      travelers: map['travelers']?.toInt() ?? 1,
      travelerType: map['travelerType'] ?? 'Solo',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      travelStyle: map['travelStyle'] ?? 'Moderate',
      interests: List<String>.from(map['interests'] ?? []),
      transportation: map['transportation'] ?? 'Flight',
      accommodation: map['accommodation'] ?? 'Hotel',
    );
  }
}

class ItineraryActivityModel {
  final String time;
  final String title;
  final String description;
  final String location;
  final double cost;
  final String category;

  ItineraryActivityModel({
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    required this.cost,
    required this.category,
  });

  factory ItineraryActivityModel.fromMap(Map<String, dynamic> map) {
    return ItineraryActivityModel(
      time: map['time'] ?? map['timeSlot'] ?? '09:00 AM',
      title: map['title'] ?? 'Activity',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Sightseeing',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'description': description,
      'location': location,
      'cost': cost,
      'category': category,
    };
  }
}

class ItineraryDayModel {
  final int dayNumber;
  final String title;
  final List<ItineraryActivityModel> activities;

  ItineraryDayModel({
    required this.dayNumber,
    required this.title,
    required this.activities,
  });

  factory ItineraryDayModel.fromMap(Map<String, dynamic> map) {
    var rawActivities = map['activities'] as List? ?? [];
    List<ItineraryActivityModel> parsedActivities =
        rawActivities.map((a) => ItineraryActivityModel.fromMap(Map<String, dynamic>.from(a))).toList();

    return ItineraryDayModel(
      dayNumber: map['dayNumber']?.toInt() ?? 1,
      title: map['title'] ?? 'Day ${map['dayNumber'] ?? 1}',
      activities: parsedActivities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'activities': activities.map((a) => a.toMap()).toList(),
    };
  }
}

class AiTripPlannerResponseModel {
  final String destination;
  final String title;
  final String summary;
  final double estimatedTotalCost;
  final String currency;
  final List<ItineraryDayModel> itinerary;

  AiTripPlannerResponseModel({
    required this.destination,
    required this.title,
    required this.summary,
    required this.estimatedTotalCost,
    required this.currency,
    required this.itinerary,
  });

  factory AiTripPlannerResponseModel.fromMap(Map<String, dynamic> map) {
    var rawItinerary = map['days'] ?? map['itinerary'] ?? [];
    List<ItineraryDayModel> parsedDays = [];
    if (rawItinerary is List) {
      parsedDays = rawItinerary.map((d) => ItineraryDayModel.fromMap(Map<String, dynamic>.from(d))).toList();
    }

    final parsedTitle = map['tripTitle'] ?? map['title'] ?? 'Custom AI Travel Plan';
    final parsedCost = (map['totalEstimatedCost'] as num?)?.toDouble() ??
        (map['estimatedTotalCost'] as num?)?.toDouble() ??
        0.0;

    return AiTripPlannerResponseModel(
      destination: map['destination'] ?? 'Travel Destination',
      title: parsedTitle,
      summary: map['summary'] ?? 'An AI-curated travel itinerary generated via n8n & Gemini.',
      estimatedTotalCost: parsedCost,
      currency: map['currency'] ?? 'USD',
      itinerary: parsedDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'tripTitle': title,
      'summary': summary,
      'totalEstimatedCost': estimatedTotalCost,
      'currency': currency,
      'days': itinerary.map((d) => d.toMap()).toList(),
    };
  }
}
