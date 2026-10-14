import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get usersCollection => _db.collection('users');
  CollectionReference get tripsCollection => _db.collection('trips');
  CollectionReference get destinationsCollection => _db.collection('destinations');
  CollectionReference get savedPlacesCollection => _db.collection('saved_places');
  CollectionReference get notificationsCollection => _db.collection('notifications');
  CollectionReference get aiRequestsCollection => _db.collection('ai_requests');
  CollectionReference get reviewsCollection => _db.collection('reviews');

  // USER CRUD
  Future<void> saveUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await usersCollection.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService saveUserDocument error: $e');
    }
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  Future<void> updateUserActiveStatus(String uid, bool isActive) async {
    await usersCollection.doc(uid).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // TRIPS CRUD
  Future<void> createTrip(Map<String, dynamic> tripData) async {
    await tripsCollection.add(tripData);
  }

  Stream<QuerySnapshot> getUserTripsStream(String userId) {
    return tripsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  // DESTINATIONS
  Stream<QuerySnapshot> getDestinationsStream() {
    return destinationsCollection.snapshots();
  }

  // SAVED PLACES
  Stream<QuerySnapshot> getSavedPlacesStream(String userId) {
    return savedPlacesCollection.where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> savePlace(Map<String, dynamic> placeData) async {
    await savedPlacesCollection.add(placeData);
  }

  // NOTIFICATIONS
  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return notificationsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  // AI REQUESTS
  Future<DocumentReference> createAiRequest(Map<String, dynamic> requestData) async {
    return await aiRequestsCollection.add(requestData);
  }

  // REVIEWS
  Future<void> addReview(Map<String, dynamic> reviewData) async {
    await reviewsCollection.add(reviewData);
  }
}
