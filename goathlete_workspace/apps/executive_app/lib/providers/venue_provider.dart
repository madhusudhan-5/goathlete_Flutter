import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final venueSubmitProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.post(
      'pre-register-venues/',
      data: data,
    );
    return response.statusCode == 201;
  } catch (e) {
    throw Exception('Failed to submit venue onboarding: $e');
  }
});

final venuesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('pre-register-venues/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load onboarded venues: $e');
  }
});
