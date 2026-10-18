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
  final bool requiresPasswordChange;
  final String? role;

  AuthState({
    this.isAuthenticated = false, 
    this.isLoading = false, 
    this.error,
    this.requiresPasswordChange = false,
    this.role,
  });

  AuthState copyWith({
    bool? isAuthenticated, 
    bool? isLoading, 
    String? error,
    bool clearError = false,
    bool? requiresPasswordChange,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      requiresPasswordChange: requiresPasswordChange ?? this.requiresPasswordChange,
      role: role ?? this.role,
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
      await _fetchProfile();
    }
  }
  
  Future<void> _fetchProfile() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;
      final response = await _dio.get('users/profile/', options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      final role = response.data['role'];
      final requiresChange = response.data['requires_password_change'] ?? false;
      state = state.copyWith(isAuthenticated: true, role: role, requiresPasswordChange: requiresChange);
    } catch (e) {
      logout();
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('users/login/', data: {
        'username': username,
        'password': password,
      });
      
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];
      
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      await _fetchProfile();
      
      if (state.role != 'EXECUTIVE' && state.role != 'SUPER_ADMIN') {
        await logout();
        state = state.copyWith(isLoading: false, error: 'Access Denied. Executive privileges required.');
        return false;
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        state = state.copyWith(isLoading: false, error: 'Connection Error: Cannot reach server.');
      } else {
        final backendError = e.response?.data?['detail'] ?? 'Invalid credentials.';
        state = state.copyWith(isLoading: false, error: backendError.toString());
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _storage.read(key: 'access_token');
      await _dio.post('users/change-password/', 
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        )
      );
      
      state = state.copyWith(isLoading: false, requiresPasswordChange: false);
      return true;
    } on DioException catch (e) {
      final backendError = e.response?.data?['error'] ?? 'Failed to change password.';
      state = state.copyWith(isLoading: false, error: backendError.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: ${e.toString()}');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = state.copyWith(isAuthenticated: false, role: null, requiresPasswordChange: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});
