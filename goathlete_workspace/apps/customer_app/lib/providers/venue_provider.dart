import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/venue_model.dart';
import 'package:geolocator/geolocator.dart';

class VenueNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  final Dio _dio;
  List<Venue> _allVenuesCache = [];
  String? _activeLocationFilter;
  int _latestRequestId = 0;

  VenueNotifier(this._dio) : super(const AsyncValue.loading()) {
    _preloadAllVenuesCache();
    fetchVenues();
  }

  List<Venue> get allVenuesCache => _allVenuesCache;
  String? get activeLocationFilter => _activeLocationFilter;

  Future<void> _preloadAllVenuesCache() async {
    try {
      final response = await _dio.get('venues/venues/');
      final List<dynamic> data = response.data is List ? response.data : [];
      _allVenuesCache = data.map((json) => Venue.fromJson(json)).toList();
    } catch (_) {}
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'venues/venues/reverse_geocode/',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      if (response.data is Map && response.data['location_name'] != null) {
        return response.data['location_name'].toString();
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final response = await _dio.get(
        'venues/venues/search_places/',
        queryParameters: {'q': q},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> fetchVenues({
    String? locationQuery,
    double? customLat,
    double? customLng,
  }) async {
    final int reqId = ++_latestRequestId;
    state = const AsyncValue.loading();
    _activeLocationFilter = locationQuery;
    try {
      double? lat = customLat;
      double? lng = customLng;

      // Only use device GPS if no custom location filter or custom coordinates were supplied
      if ((lat == null || lng == null) &&
          (locationQuery == null ||
              locationQuery.trim().isEmpty ||
              locationQuery.trim().toLowerCase() == 'all locations')) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse) {
              Position position = await Geolocator.getCurrentPosition();
              lat = position.latitude;
              lng = position.longitude;
            }
          }
        } catch (_) {
          // ignore geolocator errors
        }
      }

      final Map<String, dynamic> queryParams = {};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }
      if (locationQuery != null &&
          locationQuery.trim().isNotEmpty &&
          locationQuery.trim().toLowerCase() != 'all locations') {
        queryParams['location'] = locationQuery.trim();
      }

      final response = await _dio.get(
        'venues/venues/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Ignore stale responses if a newer location selection was triggered
      if (reqId != _latestRequestId) return;

      final List<dynamic> data = response.data is List ? response.data : [];
      final venues = data.map((json) => Venue.fromJson(json)).toList();

      if (locationQuery == null ||
          locationQuery.trim().isEmpty ||
          locationQuery.trim().toLowerCase() == 'all locations') {
        _allVenuesCache = venues;
      }

      state = AsyncValue.data(venues);
    } catch (e, stack) {
      if (reqId != _latestRequestId) return;
      state = AsyncValue.error(e, stack);
    }
  }
}

final venueProvider =
    StateNotifierProvider<VenueNotifier, AsyncValue<List<Venue>>>((ref) {
  return VenueNotifier(ref.watch(dioProvider));
});
