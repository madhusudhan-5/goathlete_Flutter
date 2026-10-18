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
      'bookings/vendor-bookings/',
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
    final response = await dio.get('venues/vendor-venues/');
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
      'venues/vendor-venues/$id/',
      data: data,
    );
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to update venue: $e');
  }
});

final vendorPartnersProvider = FutureProvider.family<List<dynamic>, int>((ref, venueId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/vendor-partners/', queryParameters: {'venue': venueId});
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final addVendorPartnerProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('venues/vendor-partners/', data: data);
    return response.statusCode == 201;
  } catch (e) {
    throw Exception('Failed to add vendor partner: $e');
  }
});

final rentalItemsProvider = FutureProvider.family<List<dynamic>, int>((ref, venueId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/rental-items/', queryParameters: {'venue': venueId});
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final addRentalItemProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('venues/rental-items/', data: data);
    return response.statusCode == 201;
  } catch (e) {
    throw Exception('Failed to add rental item: $e');
  }
});

final approveBookingRentalItemProvider = FutureProvider.family<bool, int>((ref, bookingRentalItemId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('bookings/rental-items/$bookingRentalItemId/approve/');
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to approve rental item booking: $e');
  }
});
