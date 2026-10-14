import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/ai_planner_provider.dart';

class AiPlannerScreen extends ConsumerStatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  ConsumerState<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends ConsumerState<AiPlannerScreen> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  final List<String> _currencies = ['USD', 'EUR', 'INR', 'GBP', 'JPY', 'AUD'];
  final List<String> _travelerTypes = ['Solo', 'Couple', 'Family', 'Friends'];
  final List<String> _travelStyles = ['Relaxed', 'Moderate', 'Fast-Paced', 'Adventure', 'Cultural', 'Luxury'];
  final List<String> _interestOptions = ['Beaches', 'Food', 'Museums', 'Nature', 'Shopping', 'Nightlife', 'History'];
  final List<String> _transportOptions = ['Flight', 'Train', 'Rental Car', 'Public Transit'];
  final List<String> _accommodationOptions = ['Hotel', 'Resort', 'Airbnb', 'Hostel'];

  @override
  void initState() {
    super.initState();
    final req = ref.read(aiPlannerProvider).requestModel;
    _destinationController.text = req.destination;
    _budgetController.text = req.budget.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _onGenerateTap() async {
    final notifier = ref.read(aiPlannerProvider.notifier);
    notifier.updateRequest(
      destination: _destinationController.text.trim(),
      budget: double.tryParse(_budgetController.text) ?? 1000.0,
    );

    final success = await notifier.generatePlan();
    if (success && mounted) {
      final trip = ref.read(aiPlannerProvider).generatedTrip;
      if (trip != null) {
        context.push('/trip-detail/${trip.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiPlannerProvider);
    final notifier = ref.read(aiPlannerProvider.notifier);
    final req = aiState.requestModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner'),
        actions: [
          Row(
            children: [
              const Text('Dev Mock', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Switch(
                value: aiState.useMockFallback,
                onChanged: (val) => notifier.toggleMockFallback(val),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Header
                  _buildStepHeader(aiState.currentStep),
                  const SizedBox(height: 24),

                  if (aiState.errorMessage != null) ...[
                    CustomErrorWidget(
                      message: aiState.errorMessage!,
                      onRetry: () => notifier.retry(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Wizard Steps Content
                  if (aiState.currentStep == 0) _buildStep1(req, notifier),
                  if (aiState.currentStep == 1) _buildStep2(req, notifier),
                  if (aiState.currentStep == 2) _buildStep3(req, notifier),

                  const SizedBox(height: 32),

                  // Wizard Navigation Buttons
                  Row(
                    children: [
                      if (aiState.currentStep > 0)
                        Expanded(
                          child: CustomButton(
                            text: 'Back',
                            isOutlined: true,
                            onPressed: () => notifier.previousStep(),
                          ),
                        ),
                      if (aiState.currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: aiState.currentStep == 2 ? 'Generate AI Itinerary' : 'Next Step',
                          icon: aiState.currentStep == 2 ? Icons.auto_awesome : Icons.arrow_forward,
                          onPressed: () {
                            if (aiState.currentStep < 2) {
                              notifier.updateRequest(
                                destination: _destinationController.text.trim(),
                                budget: double.tryParse(_budgetController.text) ?? 1000.0,
                              );
                              notifier.nextStep();
                            } else {
                              _onGenerateTap();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (aiState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: LoadingIndicator(
                  message: 'Connecting to AI Webhook & orchestrating custom itinerary...',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Step Header Wizard ---
  Widget _buildStepHeader(int currentStep) {
    final titles = ['Destination & Dates', 'Travelers & Budget', 'Style & Preferences'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : isActive
                          ? AppColors.secondary
                          : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of 3',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              titles[currentStep],
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 1: Destination & Dates ---
  Widget _buildStep1(dynamic req, AiPlannerNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Where do you want to go?',
          hint: 'e.g. Tokyo, Paris, Bali, New York',
          controller: _destinationController,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(req.startDate) ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    notifier.updateRequest(startDate: picked.toIso8601String().split('T').first);
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'Start Date',
                    hint: req.startDate,
                    controller: TextEditingController(text: req.startDate),
                    prefixIcon: Icons.calendar_today,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(req.endDate) ?? DateTime.now().add(const Duration(days: 10)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    notifier.updateRequest(endDate: picked.toIso8601String().split('T').first);
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'End Date',
                    hint: req.endDate,
                    controller: TextEditingController(text: req.endDate),
                    prefixIcon: Icons.event,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 2: Travelers, Budget & Currency ---
  Widget _buildStep2(dynamic req, AiPlannerNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who is traveling?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: _travelerTypes.map((type) {
            final isSelected = req.travelerType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
              onSelected: (selected) {
                if (selected) notifier.updateRequest(travelerType: type);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Number of Travelers', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                  onPressed: req.travelers > 1
                      ? () => notifier.updateRequest(travelers: req.travelers - 1)
                      : null,
                ),
                Text('${req.travelers}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: () => notifier.updateRequest(travelers: req.travelers + 1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                label: 'Total Budget',
                hint: '1500',
                controller: _budgetController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currency', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: req.currency,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder)),
                    ),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.updateRequest(currency: val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 3: Style, Interests, Transport & Accommodation ---
  Widget _buildStep3(dynamic req, AiPlannerNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Travel Style', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _travelStyles.map((style) {
            final isSelected = req.travelStyle == style;
            return ChoiceChip(
              label: Text(style),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
              onSelected: (selected) {
                if (selected) notifier.updateRequest(travelStyle: style);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Interests (Select multiple)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((interest) {
            final isSelected = (req.interests as List<String>).contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
              onSelected: (selected) {
                final currentList = List<String>.from(req.interests);
                if (selected) {
                  currentList.add(interest);
                } else {
                  currentList.remove(interest);
                }
                notifier.updateRequest(interests: currentList);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transportation', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: req.transportation,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder)),
                    ),
                    items: _transportOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.updateRequest(transportation: val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Accommodation', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: req.accommodation,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder)),
                    ),
                    items: _accommodationOptions.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.updateRequest(accommodation: val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
