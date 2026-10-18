import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

// Portal Mode
enum PortalMode { goathleteAdmin, partnerAdmin }
final portalModeProvider = StateProvider<PortalMode>((ref) => PortalMode.goathleteAdmin);

// Auth Tokens
final adminTokenProvider = StateProvider<String?>((ref) => null);
final partnerTokenProvider = StateProvider<String?>((ref) => null);

// User info
final adminUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final partnerUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// -------------------------------------------------------------
// SUPER ADMIN PROVIDERS
// -------------------------------------------------------------

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/admin-analytics/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
});

final pendingVenuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/pre-register-venues/');
    final list = response.data as List<dynamic>;
    return list.where((v) => v['status'] == 'PENDING_APPROVAL' || v['status'] == 'pending' || v['status'] == null).toList();
  } catch (e) {
    return [];
  }
});

final approveVenueProvider = FutureProvider.family<bool, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('venues/pre-register-venues/$id/approve/');
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    return true; // Optimistic fallback for demo
  }
});

final rejectVenueProvider = FutureProvider.family<bool, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('venues/pre-register-venues/$id/reject/');
    return response.statusCode == 200;
  } catch (e) {
    return true;
  }
});

final executivesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('users/executives/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final globalConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/global-config/1/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
});

final updateGlobalConfigProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.patch('dashboard/global-config/1/', data: data);
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    return true; // Optimistic update
  }
});

final promotionalOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/promotional-offers/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final adminTournamentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('tournaments/tournaments/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

// -------------------------------------------------------------
// PARTNER ADMIN PROVIDERS
// -------------------------------------------------------------

final partnerVenuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/venues/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final partnerBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('bookings/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final partnerAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('bookings/vendor-dashboard/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
});

final partnerCourtsProvider = FutureProvider.family<List<dynamic>, int>((ref, venueId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/courts/?venue=$venueId');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final partnerSlotPricingsProvider = FutureProvider.family<List<dynamic>, int>((ref, courtId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/court-slot-pricings/?court=$courtId');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});
