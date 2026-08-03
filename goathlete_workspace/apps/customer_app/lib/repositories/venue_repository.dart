import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../models/venue_model.dart';
import 'package:dio/dio.dart';

class VenueRepository {
  final Dio _dio;

  VenueRepository(this._dio);

  Future<List<Venue>> getVenues() async {
    try {
      final response = await _dio.get('venues/');
      final List<dynamic> data = response.data;
      return data.map((json) => Venue.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load venues: $e');
    }
  }
}

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository(ref.watch(dioProvider));
});

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  final repository = ref.watch(venueRepositoryProvider);
  return repository.getVenues();
});
