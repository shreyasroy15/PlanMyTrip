import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../models/trip_model.dart';
import '../../models/itinerary_model.dart';

abstract class ITripRepository {
  Future<List<TripModel>> getUserTrips(String userId);
  Future<void> createTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip(String tripId);
  Future<void> addActivity(String tripId, ItineraryItem activity);
  Future<void> toggleActivityCompleted(String tripId, String activityId);
}

class TripRepository implements ITripRepository {
  final FirebaseFirestore _firestore;

  TripRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _tripsCollection =>
      _firestore.collection(AppConstants.tripsCollection);

  @override
  Future<List<TripModel>> getUserTrips(String userId) async {
    try {
      final snapshot = await _tripsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TripModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('TripRepository getUserTrips error: $e');
      return [];
    }
  }

  @override
  Future<void> createTrip(TripModel trip) async {
    try {
      await _tripsCollection.doc(trip.id).set(trip.toMap());
    } catch (e) {
      debugPrint('TripRepository createTrip error: $e');
    }
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    try {
      await _tripsCollection.doc(trip.id).update(trip.toMap());
    } catch (e) {
      debugPrint('TripRepository updateTrip error: $e');
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripsCollection.doc(tripId).delete();
    } catch (e) {
      debugPrint('TripRepository deleteTrip error: $e');
    }
  }

  @override
  Future<void> addActivity(String tripId, ItineraryItem activity) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      if (doc.exists) {
        final trip = TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final updatedItinerary = [...trip.itinerary, activity];
        await _tripsCollection.doc(tripId).update({
          'itinerary': updatedItinerary.map((i) => i.toMap()).toList(),
        });
      }
    } catch (e) {
      debugPrint('TripRepository addActivity error: $e');
    }
  }

  @override
  Future<void> toggleActivityCompleted(String tripId, String activityId) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      if (doc.exists) {
        final trip = TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final updatedItinerary = trip.itinerary.map((item) {
          if (item.id == activityId) {
            return item.copyWith(isCompleted: !item.isCompleted);
          }
          return item;
        }).toList();

        await _tripsCollection.doc(tripId).update({
          'itinerary': updatedItinerary.map((i) => i.toMap()).toList(),
        });
      }
    } catch (e) {
      debugPrint('TripRepository toggleActivityCompleted error: $e');
    }
  }
}
