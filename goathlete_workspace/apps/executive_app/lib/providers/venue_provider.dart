import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

final venueSubmitProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post(
      'venues/pre-register-venues/',
      data: data,
    );
    return response.statusCode == 201;
  } on DioException catch (e) {
    throw Exception('Failed to submit venue onboarding: ${e.response?.data}');
  } catch (e) {
    throw Exception('Failed to submit venue onboarding: $e');
  }
});

final venuesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/pre-register-venues/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load onboarded venues: $e');
  }
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/pre-register-venues/dashboard_stats/');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
});
