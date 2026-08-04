import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.error});

  AuthState copyWith({
    bool? isAuthenticated, 
    bool? isLoading, 
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._dio, this._storage) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<String?> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('users/send-otp/', data: {
        'phone_number': phoneNumber,
      });
      state = state.copyWith(isLoading: false);
      return response.data['dev_otp'] as String?;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP.');
      return null;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('users/verify-otp/', data: {
        'phone_number': phoneNumber,
        'otp_code': otp,
      });
      
      final role = response.data['role'];
      if (role != 'EXECUTIVE' && role != 'SUPER_ADMIN') {
        state = state.copyWith(isLoading: false, error: 'Access Denied. Executive privileges required.');
        return false;
      }

      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];
      
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid OTP or Connection Error.');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});
