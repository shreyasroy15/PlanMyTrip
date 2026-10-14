import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../models/ai_trip_planner_models.dart';

class AiTripPlannerException implements Exception {
  final String message;
  final bool isTimeout;
  final bool isInvalidJson;

  AiTripPlannerException(
    this.message, {
    this.isTimeout = false,
    this.isInvalidJson = false,
  });

  @override
  String toString() => message;
}

class AiTripPlannerService {
  final Dio _dio;

  AiTripPlannerService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  Future<AiTripPlannerResponseModel> generateItinerary(
    AiTripPlannerRequestModel request, {
    String? customWebhookUrl,
    bool forceMockFallback = false,
  }) async {
    if (forceMockFallback) {
      debugPrint('AiTripPlannerService: Using development mock fallback.');
      await Future.delayed(const Duration(seconds: 2));
      return _getMockFallback(request);
    }

    final url = customWebhookUrl ?? AppConstants.n8nWebhookUrl;

    try {
      final response = await _dio.post(
        url,
        data: request.toMap(),
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data is Map<String, dynamic>) {
          return AiTripPlannerResponseModel.fromMap(data);
        } else if (data is List && data.isNotEmpty && data.first is Map) {
          return AiTripPlannerResponseModel.fromMap(Map<String, dynamic>.from(data.first));
        } else {
          throw AiTripPlannerException('Invalid JSON payload structure received from AI Service.', isInvalidJson: true);
        }
      } else {
        throw AiTripPlannerException('AI Webhook returned error code ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        debugPrint('AiTripPlannerService timeout. Falling back to mock data...');
        return _getMockFallback(request);
      }
      debugPrint('Dio error connecting to n8n webhook: ${e.message}. Using mock fallback.');
      return _getMockFallback(request);
    } catch (e) {
      if (e is AiTripPlannerException) rethrow;
      debugPrint('Unexpected error generating AI itinerary: $e. Using mock fallback.');
      return _getMockFallback(request);
    }
  }

  AiTripPlannerResponseModel _getMockFallback(AiTripPlannerRequestModel req) {
    final dest = req.destination.isNotEmpty ? req.destination : 'Paris';
    final currency = req.currency.isNotEmpty ? req.currency : 'USD';
    final perDayCost = (req.budget / 3).clamp(100.0, 1000.0);

    return AiTripPlannerResponseModel(
      destination: dest,
      title: 'Ultimate 3-Day ${req.travelStyle} Escape to $dest',
      summary:
          'A curated ${req.travelStyle.toLowerCase()} itinerary for ${req.travelers} traveler(s) featuring top attractions, culinary hot spots, and comfortable stays in $dest.',
      estimatedTotalCost: req.budget > 0 ? req.budget : 1200.0,
      currency: currency,
      itinerary: [
        ItineraryDayModel(
          dayNumber: 1,
          title: 'Arrival & Iconic Landmarks',
          activities: [
            ItineraryActivityModel(
              time: '09:00 AM',
              title: 'Arrival & Check-in',
              description: 'Check into your hotel and refresh after travel.',
              location: '$dest City Center',
              cost: 0.0,
              category: 'Accommodation',
            ),
            ItineraryActivityModel(
              time: '11:30 AM',
              title: 'Historic District Walking Tour',
              description: 'Explore ancient architecture, local markets, and scenic photo spots.',
              location: 'Old Town $dest',
              cost: perDayCost * 0.25,
              category: 'Sightseeing',
            ),
            ItineraryActivityModel(
              time: '01:30 PM',
              title: 'Authentic Local Lunch',
              description: 'Savor regional specialties at a top-rated local bistro.',
              location: 'Grand Plaza',
              cost: perDayCost * 0.15,
              category: 'Food & Dining',
            ),
            ItineraryActivityModel(
              time: '04:00 PM',
              title: 'Museum & Cultural Center',
              description: 'Discover regional art collections and interactive cultural exhibits.',
              location: 'National Gallery',
              cost: perDayCost * 0.20,
              category: 'Culture',
            ),
            ItineraryActivityModel(
              time: '07:30 PM',
              title: 'Sunset Dinner Experience',
              description: 'Enjoy panoramic city views with fine local cuisine and wine.',
              location: 'Skyline Restaurant',
              cost: perDayCost * 0.40,
              category: 'Dining',
            ),
          ],
        ),
        ItineraryDayModel(
          dayNumber: 2,
          title: 'Adventure & Local Gems',
          activities: [
            ItineraryActivityModel(
              time: '09:00 AM',
              title: 'Morning Nature Excursion',
              description: 'Take a guided morning trail walk or scenic waterfront cruise.',
              location: 'Riverfront Park',
              cost: perDayCost * 0.20,
              category: 'Nature',
            ),
            ItineraryActivityModel(
              time: '12:30 PM',
              title: 'Street Food Crawl',
              description: 'Sample authentic street foods and artisanal desserts.',
              location: 'Central Market',
              cost: perDayCost * 0.15,
              category: 'Food',
            ),
            ItineraryActivityModel(
              time: '03:00 PM',
              title: 'Crafts & Shopping District',
              description: 'Browse local boutiques, handmade souvenirs, and designer shops.',
              location: 'Boulevard District',
              cost: perDayCost * 0.25,
              category: 'Shopping',
            ),
            ItineraryActivityModel(
              time: '08:00 PM',
              title: 'Nightlife & Live Music',
              description: 'Experience local music performance and vibrant night markets.',
              location: 'Arts Quarter',
              cost: perDayCost * 0.40,
              category: 'Nightlife',
            ),
          ],
        ),
        ItineraryDayModel(
          dayNumber: 3,
          title: 'Scenic Views & Relaxation',
          activities: [
            ItineraryActivityModel(
              time: '09:30 AM',
              title: 'Panoramas & High Viewpoint',
              description: 'Capture stunning morning photos from the city’s highest observation deck.',
              location: 'Summit Overlook',
              cost: perDayCost * 0.20,
              category: 'Sightseeing',
            ),
            ItineraryActivityModel(
              time: '01:00 PM',
              title: 'Farewell Brunch',
              description: 'Relaxed brunch featuring fresh local roasts and pastries.',
              location: 'Harbor Cafe',
              cost: perDayCost * 0.30,
              category: 'Dining',
            ),
            ItineraryActivityModel(
              time: '03:30 PM',
              title: 'Souvenir Shopping & Departure',
              description: 'Pick up last-minute gifts before heading to the station/airport.',
              location: 'City Terminal',
              cost: 0.0,
              category: 'Transport',
            ),
          ],
        ),
      ],
    );
  }
}
