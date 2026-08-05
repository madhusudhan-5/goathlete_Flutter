import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    return _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final dio = ref.watch(dioProvider);
    try {
      final response = await dio.get('users/profile/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load profile data: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.put('users/profile/update/', data: data);
      
      // Update state with new profile fetch
      state = AsyncValue.data(await _fetchProfile());
      return true;
    } catch (e) {
      state = AsyncValue.error('Failed to update profile: $e', StackTrace.current);
      return false;
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(() {
  return ProfileNotifier();
});
