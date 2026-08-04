import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // Returns true if profile is complete, false if profile completion is needed
  Future<bool?> verifyOTP(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('users/verify-otp/', data: {
        'phone_number': phoneNumber,
        'otp_code': otp,
      });
      
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];
      final bool isProfileComplete = response.data['is_profile_complete'] ?? false;
      
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return isProfileComplete;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid OTP.');
      return null;
    }
  }

  // Returns true if profile is complete, false if profile completion is needed
  Future<bool?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Google sign in failed (no token).');
        return null;
      }

      final response = await _dio.post('users/google-login/', data: {
        'id_token': idToken,
      });

      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];
      final bool isProfileComplete = response.data['is_profile_complete'] ?? false;
      
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return isProfileComplete;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign In failed.');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = state.copyWith(isAuthenticated: false);
  }

  Future<String?> completeProfile(String firstName, String email, String dob) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.put('users/profile/update/', data: {
        'first_name': firstName,
        'email': email,
        'date_of_birth': dob,
      });
      state = state.copyWith(isLoading: false);
      return response.data['goath_id'] as String?;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update profile.');
      return null;
    }
  }

  Future<bool> updateProfileWithImage({
    required String firstName,
    required String dob,
    String? imagePath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var formData = FormData.fromMap({
        'first_name': firstName,
        'date_of_birth': dob,
      });

      if (imagePath != null) {
        formData.files.add(MapEntry(
          'profile_picture',
          await MultipartFile.fromFile(imagePath, filename: 'profile_pic.jpg'),
        ));
      }

      await _dio.put('users/profile/update/', data: formData);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update profile.');
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});
