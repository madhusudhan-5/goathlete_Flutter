import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

final sportsNewsProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  try {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}dashboard/sports-news/')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['news'] as List<dynamic>;
    }
  } catch (e) {
    print('Failed to fetch sports news: $e');
  }
  return [];
});
