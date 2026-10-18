import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/venue_model.dart';

import 'package:geolocator/geolocator.dart';

class VenueNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  final Dio _dio;

  VenueNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchVenues();
  }

  Future<void> fetchVenues() async {
    state = const AsyncValue.loading();
    try {
      double? lat;
      double? lng;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 3),
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        // ignore geolocator errors
      }

      String endpoint = 'venues/';
      if (lat != null && lng != null) {
        endpoint += '?lat=$lat&lng=$lng';
      }

      final response = await _dio.get(endpoint);
      final List<dynamic> data = response.data;
      final venues = data.map((json) => Venue.fromJson(json)).toList();
      state = AsyncValue.data(venues);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final venueProvider = StateNotifierProvider<VenueNotifier, AsyncValue<List<Venue>>>((ref) {
  return VenueNotifier(ref.watch(dioProvider));
});
