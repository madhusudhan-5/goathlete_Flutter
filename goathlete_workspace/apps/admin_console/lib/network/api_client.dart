import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin_console/providers/admin_provider.dart';

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

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(adminTokenProvider) ?? ref.read(partnerTokenProvider);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  return dio;
});

