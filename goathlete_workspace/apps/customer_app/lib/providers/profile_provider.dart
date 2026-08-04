import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('users/profile/');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to load profile data: $e');
  }
});
