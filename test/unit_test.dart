import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:planmytrip/core/services/location_service.dart';
import 'package:planmytrip/models/user_model.dart';
import 'package:planmytrip/models/ai_trip_planner_models.dart';
import 'package:planmytrip/models/itinerary_model.dart';
import 'package:planmytrip/models/trip_model.dart';
import 'package:planmytrip/providers/user_provider.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel creates correctly and excludes sensitive password data', () {
      final user = UserModel(
        uid: 'usr_test_123',
        name: 'Test Traveler',
        email: 'test@example.com',
        phone: '+1 555 123 4567',
        photoUrl: 'https://example.com/photo.jpg',
        role: 'user',
        isActive: true,
        createdAt: '2026-09-07T12:00:00Z',
        updatedAt: '2026-09-07T12:00:00Z',
      );

      final map = user.toMap();

      expect(map['name'], 'Test Traveler');
      expect(map['email'], 'test@example.com');
      expect(map['phone'], '+1 555 123 4567');
      expect(map['role'], 'user');
      expect(map['isActive'], isTrue);
      // Verify sensitive password keys NEVER exist in Firestore map
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('passwordHash'), isFalse);
    });

    test('UserModel.fromMap deserializes correctly', () {
      final map = {
        'name': 'Test Traveler',
        'email': 'test@example.com',
        'phone': '+1 555 123 4567',
        'photoUrl': 'https://example.com/photo.jpg',
        'role': 'admin',
        'isActive': true,
        'createdAt': '2026-09-07T12:00:00Z',
        'updatedAt': '2026-09-07T12:00:00Z',
      };

      final user = UserModel.fromMap(map, 'usr_test_456');

      expect(user.uid, 'usr_test_456');
      expect(user.role, 'admin');
      expect(user.isActive, isTrue);
    });
  });

  group('UserListNotifier Admin Operations Tests', () {
    test('UserListNotifier toggles activation, deletes user, and changes role', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial check
      expect(container.read(userListProvider).firstWhere((u) => u.uid == 'usr_001').role, 'user');

      // Change role
      container.read(userListProvider.notifier).changeUserRole('usr_001', 'admin');
      expect(container.read(userListProvider).firstWhere((u) => u.uid == 'usr_001').role, 'admin');

      // Delete user
      container.read(userListProvider.notifier).deleteUser('usr_001');
      expect(container.read(userListProvider).any((u) => u.uid == 'usr_001'), isFalse);
    });

    test('UserListNotifier exports JSON and CSV without sensitive password data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userListProvider.notifier);

      final jsonStr = notifier.exportUsersJson();
      expect(jsonStr, contains('alex@example.com'));
      expect(jsonStr, isNot(contains('password')));
      expect(jsonStr, isNot(contains('passwordHash')));

      final csvStr = notifier.exportUsersCsv();
      expect(csvStr, contains('uid,name,email,phone,role,isActive,createdAt,updatedAt'));
      expect(csvStr, contains('alex@example.com'));
    });
  });

  group('LocationService & Maps Tests', () {
    test('LocationService fallback location provides valid default LatLng coordinates', () {
      const defaultLoc = LocationService.defaultLocation;

      expect(defaultLoc.latitude, equals(-8.409518));
      expect(defaultLoc.longitude, equals(115.188919));
      expect(defaultLoc, isA<LatLng>());
    });
  });

  group('ItineraryItem & TripModel Tests', () {
    test('ItineraryItem copyWith toggles isCompleted status', () {
      final item = ItineraryItem(
        id: 'itin_001',
        dayNumber: 1,
        timeSlot: '10:00 AM',
        title: 'Baga Beach',
        description: 'Enjoy beach volleyball and water sports.',
        location: 'Goa',
        cost: 0.0,
        isCompleted: false,
      );

      expect(item.isCompleted, isFalse);

      final completedItem = item.copyWith(isCompleted: true);

      expect(completedItem.isCompleted, isTrue);
      expect(completedItem.title, 'Baga Beach');
    });

    test('TripModel serializes and deserializes user isolation metadata', () {
      final trip = TripModel(
        id: 'trip_usr_99',
        userId: 'usr_owner_123',
        destination: 'Bali',
        title: 'Balinese Sunset Tour',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 5),
        budget: 1200.0,
        status: 'upcoming',
      );

      final map = trip.toMap();

      expect(map['userId'], 'usr_owner_123');
      expect(map['destination'], 'Bali');

      final parsed = TripModel.fromMap(map, 'trip_usr_99');

      expect(parsed.userId, 'usr_owner_123');
      expect(parsed.status, 'upcoming');
    });
  });

  group('AI Trip Planner Models Tests', () {
    test('AiTripPlannerRequestModel serializes correctly to map', () {
      final req = AiTripPlannerRequestModel(
        destination: 'Tokyo',
        startDate: '2026-10-01',
        endDate: '2026-10-07',
        travelers: 2,
        travelerType: 'Couple',
        budget: 2500.0,
        currency: 'USD',
        travelStyle: 'Luxury',
        interests: ['Food', 'Culture'],
        transportation: 'Flight',
        accommodation: 'Resort',
      );

      final map = req.toMap();

      expect(map['destination'], 'Tokyo');
      expect(map['travelers'], 2);
      expect(map['budget'], 2500.0);
      expect(map['interests'], contains('Food'));
    });

    test('AiTripPlannerResponseModel deserializes Step 14 n8n JSON response map correctly', () {
      final n8nResponseMap = {
        'tripTitle': 'Goa Adventure',
        'destination': 'Goa',
        'totalEstimatedCost': 45000,
        'currency': 'INR',
        'days': [
          {
            'dayNumber': 1,
            'title': 'North Goa',
            'activities': [
              {
                'time': '10:00',
                'title': 'Baga Beach',
                'location': 'Baga Beach',
                'category': 'Beach',
              }
            ],
          }
        ],
      };

      final response = AiTripPlannerResponseModel.fromMap(n8nResponseMap);

      expect(response.destination, 'Goa');
      expect(response.title, 'Goa Adventure');
      expect(response.estimatedTotalCost, 45000.0);
      expect(response.currency, 'INR');
      expect(response.itinerary.length, 1);

      final day1 = response.itinerary.first;
      expect(day1.dayNumber, 1);
      expect(day1.title, 'North Goa');
      expect(day1.activities.length, 1);

      final activity = day1.activities.first;
      expect(activity.time, '10:00');
      expect(activity.title, 'Baga Beach');
      expect(activity.location, 'Baga Beach');
      expect(activity.category, 'Beach');
    });
  });
}
