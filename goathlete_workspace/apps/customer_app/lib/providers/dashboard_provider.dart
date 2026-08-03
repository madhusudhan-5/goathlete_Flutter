import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../network/api_client.dart';
import 'package:dio/dio.dart';

final dashboardProvider = FutureProvider<DashboardConfig>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('dashboard/config/');
    return DashboardConfig.fromJson(response.data);
  } catch (e) {
    throw Exception('Failed to load dashboard config: $e');
  }
});
