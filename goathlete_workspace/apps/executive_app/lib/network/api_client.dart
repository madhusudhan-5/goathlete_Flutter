import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _rawApiOrigin = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.goathlete.org.in',
);
final String _baseUrl = _rawApiOrigin.endsWith('/api/')
    ? _rawApiOrigin
    : '${_rawApiOrigin.replaceAll(RegExp(r'/+$'), '')}/api/';



final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'access_token');
          await storage.delete(key: 'refresh_token');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
