import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/repositories/trip_repository.dart';
import '../models/trip_model.dart';
import '../models/destination_model.dart';
import '../models/itinerary_model.dart';

final tripRepositoryProvider = Provider<ITripRepository>((ref) => TripRepository());

class TripsNotifier extends Notifier<List<TripModel>> {
  late final ITripRepository _repository;

  @override
  List<TripModel> build() {
    _repository = ref.watch(tripRepositoryProvider);
    return [
      TripModel(
        id: 'trip_001',
        userId: 'usr_001',
        destination: 'Bali, Indonesia',
        title: 'Tropical Beach & Culture Getaway',
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 17)),
        budget: 2500,
        status: 'upcoming',
        companions: ['Alice', 'Bob'],
        imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
        itinerary: [
          ItineraryItem(
            id: 'itin_001',
            dayNumber: 1,
            timeSlot: '09:00 AM',
            title: 'Arrival & Hotel Check-in',
            description: 'Land at Denpasar International Airport, take private transfer to Seminyak Resort.',
            location: 'Seminyak Beach Resort',
            cost: 150,
            isCompleted: true,
          ),
          ItineraryItem(
            id: 'itin_002',
            dayNumber: 1,
            timeSlot: '04:30 PM',
            title: 'Sunset at Tanah Lot Temple',
            description: 'Visit the sea temple and enjoy traditional Balinese dinner by the ocean.',
            location: 'Tanah Lot',
            cost: 65,
            isCompleted: false,
          ),
          ItineraryItem(
            id: 'itin_003',
            dayNumber: 2,
            timeSlot: '08:00 AM',
            title: 'Ubud Sacred Monkey Forest & Terraces',
            description: 'Explore Tegallalang rice terraces, coffee tasting, and jungle swings.',
            location: 'Ubud',
            cost: 120,
            isCompleted: false,
          ),
        ],
      ),
      TripModel(
        id: 'trip_002',
        userId: 'usr_001',
        destination: 'Kyoto, Japan',
        title: 'Autumn Leaves & Ancient Shrines',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 52)),
        budget: 3200,
        status: 'completed',
        companions: ['Self'],
        imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600',
        itinerary: [
          ItineraryItem(
            id: 'itin_101',
            dayNumber: 1,
            timeSlot: '08:00 AM',
            title: 'Fushimi Inari Torii Gate Walk',
            description: 'Early morning hike up Mount Inari through thousands of vermilion torii gates.',
            location: 'Fushimi Inari',
            cost: 20,
            isCompleted: true,
          ),
        ],
      ),
      TripModel(
        id: 'trip_003',
        userId: 'usr_001',
        destination: 'Santorini, Greece',
        title: 'Aegean Sunset & Villa Escape',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        budget: 1800,
        status: 'ongoing',
        companions: ['Emma'],
        imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600',
        itinerary: [],
      ),
      TripModel(
        id: 'trip_004',
        userId: 'usr_001',
        destination: 'Swiss Alps',
        title: 'Mountain Hiking & Chalet Draft',
        startDate: DateTime.now().add(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 95)),
        budget: 2200,
        status: 'draft',
        companions: ['Self'],
        imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=600',
        itinerary: [],
      ),
    ];
  }

  Future<void> fetchUserTrips(String userId) async {
    final trips = await _repository.getUserTrips(userId);
    if (trips.isNotEmpty) {
      state = trips;
    }
  }

  Future<void> addTrip(TripModel trip) async {
    state = [trip, ...state];
    await _repository.createTrip(trip);
  }

  Future<void> updateTrip(TripModel trip) async {
    state = state.map((t) => t.id == trip.id ? trip : t).toList();
    await _repository.updateTrip(trip);
  }

  Future<void> deleteTrip(String tripId) async {
    state = state.where((t) => t.id != tripId).toList();
    await _repository.deleteTrip(tripId);
  }

  Future<void> addActivity(String tripId, ItineraryItem activity) async {
    state = state.map((trip) {
      if (trip.id == tripId) {
        final updatedItinerary = [...trip.itinerary, activity];
        return TripModel(
          id: trip.id,
          userId: trip.userId,
          destination: trip.destination,
          title: trip.title,
          startDate: trip.startDate,
          endDate: trip.endDate,
          budget: trip.budget,
          status: trip.status,
          companions: trip.companions,
          imageUrl: trip.imageUrl,
          itinerary: updatedItinerary,
        );
      }
      return trip;
    }).toList();

    await _repository.addActivity(tripId, activity);
  }

  Future<void> toggleActivityCompleted(String tripId, String activityId) async {
    state = state.map((trip) {
      if (trip.id == tripId) {
        final updatedItinerary = trip.itinerary.map((item) {
          if (item.id == activityId) {
            return item.copyWith(isCompleted: !item.isCompleted);
          }
          return item;
        }).toList();

        return TripModel(
          id: trip.id,
          userId: trip.userId,
          destination: trip.destination,
          title: trip.title,
          startDate: trip.startDate,
          endDate: trip.endDate,
          budget: trip.budget,
          status: trip.status,
          companions: trip.companions,
          imageUrl: trip.imageUrl,
          itinerary: updatedItinerary,
        );
      }
      return trip;
    }).toList();

    await _repository.toggleActivityCompleted(tripId, activityId);
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, List<TripModel>>(TripsNotifier.new);

final destinationsProvider = Provider<List<DestinationModel>>((ref) {
  return [
    DestinationModel(
      id: 'dest_001',
      name: 'Kyoto',
      country: 'Japan',
      description: 'Historical capital famous for classical Buddhist temples, gardens, imperial palaces, and wooden houses.',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600',
      rating: 4.9,
      tags: ['Culture', 'Art', 'Nature'],
      estimatedCostPerDay: 180,
    ),
    DestinationModel(
      id: 'dest_002',
      name: 'Bali',
      country: 'Indonesia',
      description: 'Indonesian island known for its forested volcanic mountains, iconic rice paddies, beaches and coral reefs.',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
      rating: 4.8,
      tags: ['Beaches', 'Nature', 'Adventure'],
      estimatedCostPerDay: 120,
    ),
    DestinationModel(
      id: 'dest_003',
      name: 'Santorini',
      country: 'Greece',
      description: 'Cyclades island in the Aegean Sea, defined by cubiform houses perched on dramatic cliffs.',
      imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600',
      rating: 4.9,
      tags: ['Beaches', 'Luxury'],
      estimatedCostPerDay: 250,
    ),
    DestinationModel(
      id: 'dest_004',
      name: 'Paris',
      country: 'France',
      description: 'Global center for art, fashion, gastronomy and culture with landmark Eiffel Tower and cafes.',
      imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600',
      rating: 4.7,
      tags: ['Culture', 'Art', 'Luxury'],
      estimatedCostPerDay: 220,
    ),
  ];
});
