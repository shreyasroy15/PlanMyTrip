import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';

enum MarkerCategory { all, activities, hotels, restaurants, currentLocation }

class MapPoint {
  final String id;
  final String title;
  final String snippet;
  final LatLng position;
  final MarkerCategory category;
  final String locationText;

  MapPoint({
    required this.id,
    required this.title,
    required this.snippet,
    required this.position,
    required this.category,
    required this.locationText,
  });
}

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng _currentLocation = LocationService.defaultLocation;
  MarkerCategory _selectedCategory = MarkerCategory.all;
  MapPoint? _selectedPoint;
  bool _isLoadingLocation = true;

  final List<MapPoint> _samplePoints = [
    MapPoint(
      id: 'dest_bali',
      title: 'Bali Destination Center',
      snippet: 'Island Destination Hub',
      position: const LatLng(-8.409518, 115.188919),
      category: MarkerCategory.activities,
      locationText: 'Denpasar, Bali, Indonesia',
    ),
    MapPoint(
      id: 'act_tanah_lot',
      title: 'Tanah Lot Temple',
      snippet: 'Activity: Sunset & Sea Temple Tour',
      position: const LatLng(-8.621213, 115.086807),
      category: MarkerCategory.activities,
      locationText: 'Beraban, Kediri, Tabanan Regency, Bali',
    ),
    MapPoint(
      id: 'hotel_seminyak',
      title: 'Seminyak Beach Resort',
      snippet: 'Hotel: 5-Star Luxury Resort',
      position: const LatLng(-8.688537, 115.155490),
      category: MarkerCategory.hotels,
      locationText: 'Jl. Kayu Aya, Seminyak, Kuta, Bali',
    ),
    MapPoint(
      id: 'rest_ubud_dining',
      title: 'Bebek Bengil Ubud',
      snippet: 'Restaurant: Balinese Dining',
      position: const LatLng(-8.514751, 115.263721),
      category: MarkerCategory.restaurants,
      locationText: 'Jl. Hanoman, Ubud, Gianyar, Bali',
    ),
    MapPoint(
      id: 'act_ubud_monkey',
      title: 'Ubud Sacred Monkey Forest',
      snippet: 'Activity: Wildlife & Sanctuary',
      position: const LatLng(-8.519444, 115.258889),
      category: MarkerCategory.activities,
      locationText: 'Jl. Monkey Forest, Ubud, Gianyar, Bali',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = pos;
        _isLoadingLocation = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 11),
      );
    }
  }

  Future<void> _openExternalNavigation(MapPoint point) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${point.position.latitude},${point.position.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external map navigation.')),
        );
      }
    }
  }

  double _getHueForCategory(MarkerCategory cat) {
    switch (cat) {
      case MarkerCategory.hotels:
        return BitmapDescriptor.hueCyan;
      case MarkerCategory.restaurants:
        return BitmapDescriptor.hueOrange;
      case MarkerCategory.activities:
        return BitmapDescriptor.hueViolet;
      case MarkerCategory.currentLocation:
        return BitmapDescriptor.hueAzure;
      case MarkerCategory.all:
        return BitmapDescriptor.hueRed;
    }
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    // Current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_user_loc'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'My Current Location'),
        onTap: () {
          setState(() {
            _selectedPoint = MapPoint(
              id: 'current_loc',
              title: 'Your Current Location',
              snippet: 'GPS Verified Location',
              position: _currentLocation,
              category: MarkerCategory.currentLocation,
              locationText: '${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
            );
          });
        },
      ),
    );

    final filtered = _samplePoints.where((p) {
      if (_selectedCategory == MarkerCategory.all) return true;
      return p.category == _selectedCategory;
    });

    for (final pt in filtered) {
      markers.add(
        Marker(
          markerId: MarkerId(pt.id),
          position: pt.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHueForCategory(pt.category)),
          infoWindow: InfoWindow(title: pt.title, snippet: pt.snippet),
          onTap: () {
            setState(() => _selectedPoint = pt);
          },
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final points = _samplePoints
        .where((p) => p.category == MarkerCategory.activities || p.category == MarkerCategory.hotels)
        .map((p) => p.position)
        .toList();

    if (points.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('itinerary_route'),
        points: points,
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(12), PatternItem.gap(6)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Travel Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _fetchUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 10.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_isLoadingLocation)
            const Positioned(
              top: 16,
              left: 16,
              child: Chip(
                avatar: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                label: Text('Locating...', style: TextStyle(fontSize: 12)),
              ),
            ),
          // Category Filter Chips Header
          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MarkerCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_getCategoryLabel(cat)),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Selected Location Info Card with External Navigation Button
          if (_selectedPoint != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPoint!.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                          onPressed: () => setState(() => _selectedPoint = null),
                        ),
                      ],
                    ),
                    Text(
                      _selectedPoint!.snippet,
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedPoint!.locationText,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openExternalNavigation(_selectedPoint!),
                        icon: const Icon(Icons.directions, color: Colors.white, size: 18),
                        label: const Text('Open in Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryLabel(MarkerCategory cat) {
    switch (cat) {
      case MarkerCategory.all:
        return 'All Markers';
      case MarkerCategory.activities:
        return 'Activities';
      case MarkerCategory.hotels:
        return 'Hotels';
      case MarkerCategory.restaurants:
        return 'Restaurants';
      case MarkerCategory.currentLocation:
        return 'My Location';
    }
  }
}
