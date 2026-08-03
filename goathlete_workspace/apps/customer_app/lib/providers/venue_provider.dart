import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/venue_model.dart';

class VenueNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  final Dio _dio;

  VenueNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchVenues();
  }

  Future<void> fetchVenues() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('venues/');
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
