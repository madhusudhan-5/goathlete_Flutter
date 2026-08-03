import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final vendorDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('bookings/vendor-dashboard/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to load onboarded venues: $e');
  }
});

final vendorCreateBookingProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post(
      'vendor-bookings/',
      data: data,
    );
    return response.statusCode == 201;
  } catch (e) {
    throw Exception('Failed to create manual booking: $e');
  }
});

final vendorVenuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('vendor-venues/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load vendor venues: $e');
  }
});

final vendorUpdateVenueProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final id = data['id'];
    final response = await dio.patch(
      'vendor-venues/$id/',
      data: data,
    );
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to update venue: $e');
  }
});
