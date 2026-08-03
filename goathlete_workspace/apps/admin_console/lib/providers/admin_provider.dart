import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/admin-analytics/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to load admin analytics: $e');
  }
});

final pendingVenuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    // Super admins get all via this endpoint
    final response = await dio.get('pre-register-venues/');
    return (response.data as List<dynamic>).where((v) => v['status'] == 'PENDING_APPROVAL').toList();
  } catch (e) {
    throw Exception('Failed to load pending venues: $e');
  }
});

final approveVenueProvider = FutureProvider.family<bool, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('pre-register-venues/$id/approve/');
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to approve venue: $e');
  }
});

final rejectVenueProvider = FutureProvider.family<bool, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('pre-register-venues/$id/reject/');
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to reject venue: $e');
  }
});

final executivesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('executives/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load executives: $e');
  }
});

final globalConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/global-config/1/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to load global config: $e');
  }
});

final updateGlobalConfigProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.patch('dashboard/global-config/1/', data: data);
    return response.statusCode == 200;
  } catch (e) {
    throw Exception('Failed to update global config: $e');
  }
});

final promotionalOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/promotional-offers/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load offers: $e');
  }
});

final createPromotionalOfferProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post('dashboard/promotional-offers/', data: data);
    return response.statusCode == 201;
  } catch (e) {
    throw Exception('Failed to create offer: $e');
  }
});
