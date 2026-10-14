import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/ai_trip_planner_service.dart';
import '../models/ai_trip_planner_models.dart';
import '../models/itinerary_model.dart';
import '../models/trip_model.dart';
import 'trip_provider.dart';

final aiTripPlannerServiceProvider = Provider<AiTripPlannerService>((ref) => AiTripPlannerService());

class AiPlannerState {
  final int currentStep;
  final AiTripPlannerRequestModel requestModel;
  final bool isLoading;
  final String? errorMessage;
  final AiTripPlannerResponseModel? generatedResponse;
  final TripModel? generatedTrip;
  final bool useMockFallback;

  AiPlannerState({
    this.currentStep = 0,
    required this.requestModel,
    this.isLoading = false,
    this.errorMessage,
    this.generatedResponse,
    this.generatedTrip,
    this.useMockFallback = false,
  });

  AiPlannerState copyWith({
    int? currentStep,
    AiTripPlannerRequestModel? requestModel,
    bool? isLoading,
    String? errorMessage,
    AiTripPlannerResponseModel? generatedResponse,
    TripModel? generatedTrip,
    bool? useMockFallback,
  }) {
    return AiPlannerState(
      currentStep: currentStep ?? this.currentStep,
      requestModel: requestModel ?? this.requestModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      generatedResponse: generatedResponse ?? this.generatedResponse,
      generatedTrip: generatedTrip ?? this.generatedTrip,
      useMockFallback: useMockFallback ?? this.useMockFallback,
    );
  }
}

class AiPlannerNotifier extends Notifier<AiPlannerState> {
  late final AiTripPlannerService _service;

  @override
  AiPlannerState build() {
    _service = ref.watch(aiTripPlannerServiceProvider);
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 7)).toIso8601String().split('T').first;
    final endDate = now.add(const Duration(days: 10)).toIso8601String().split('T').first;

    return AiPlannerState(
      requestModel: AiTripPlannerRequestModel(
        destination: 'Tokyo',
        startDate: startDate,
        endDate: endDate,
        travelers: 2,
        travelerType: 'Couple',
        budget: 1500.0,
        currency: 'USD',
        travelStyle: 'Moderate',
        interests: ['Culture', 'Food', 'Sightseeing'],
        transportation: 'Flight',
        accommodation: 'Hotel',
      ),
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void toggleMockFallback(bool value) {
    state = state.copyWith(useMockFallback: value);
  }

  void updateRequest({
    String? destination,
    String? startDate,
    String? endDate,
    int? travelers,
    String? travelerType,
    double? budget,
    String? currency,
    String? travelStyle,
    List<String>? interests,
    String? transportation,
    String? accommodation,
  }) {
    final updated = AiTripPlannerRequestModel(
      destination: destination ?? state.requestModel.destination,
      startDate: startDate ?? state.requestModel.startDate,
      endDate: endDate ?? state.requestModel.endDate,
      travelers: travelers ?? state.requestModel.travelers,
      travelerType: travelerType ?? state.requestModel.travelerType,
      budget: budget ?? state.requestModel.budget,
      currency: currency ?? state.requestModel.currency,
      travelStyle: travelStyle ?? state.requestModel.travelStyle,
      interests: interests ?? state.requestModel.interests,
      transportation: transportation ?? state.requestModel.transportation,
      accommodation: accommodation ?? state.requestModel.accommodation,
    );
    state = state.copyWith(requestModel: updated);
  }

  Future<bool> generatePlan() async {
    if (state.requestModel.destination.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a destination.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final responseModel = await _service.generateItinerary(
        state.requestModel,
        forceMockFallback: state.useMockFallback,
      );

      final itineraryItems = <ItineraryItem>[];
      int itemIdx = 0;
      for (final day in responseModel.itinerary) {
        for (final act in day.activities) {
          itineraryItems.add(
            ItineraryItem(
              id: 'itin_ai_${day.dayNumber}_$itemIdx',
              dayNumber: day.dayNumber,
              timeSlot: act.time,
              title: act.title,
              description: act.description.isNotEmpty
                  ? act.description
                  : '${act.category} experience in ${act.location.isNotEmpty ? act.location : responseModel.destination}',
              location: act.location.isNotEmpty ? act.location : responseModel.destination,
              cost: act.cost,
            ),
          );
          itemIdx++;
        }
      }

      final tripId = 'trip_ai_${DateTime.now().millisecondsSinceEpoch}';
      final trip = TripModel(
        id: tripId,
        userId: 'usr_active',
        title: responseModel.title,
        destination: responseModel.destination,
        startDate: DateTime.tryParse(state.requestModel.startDate) ?? DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.tryParse(state.requestModel.endDate) ?? DateTime.now().add(const Duration(days: 10)),
        budget: responseModel.estimatedTotalCost > 0 ? responseModel.estimatedTotalCost : state.requestModel.budget,
        companions: ['${state.requestModel.travelers} Travelers (${state.requestModel.travelerType})'],
        status: 'planned',
        imageUrl: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=800&q=80',
        itinerary: itineraryItems,
      );

      ref.read(tripsProvider.notifier).addTrip(trip);

      state = state.copyWith(
        isLoading: false,
        generatedResponse: responseModel,
        generatedTrip: trip,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate itinerary: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}',
      );
      return false;
    }
  }

  Future<bool> retry() async {
    state = state.copyWith(errorMessage: null);
    return generatePlan();
  }
}

final aiPlannerProvider = NotifierProvider<AiPlannerNotifier, AiPlannerState>(AiPlannerNotifier.new);
