import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final sportsNewsProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  try {
    final response = await http.get(Uri.parse('http://72.60.193.38/api/dashboard/sports-news/?q=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['news'] as List<dynamic>;
    }
  } catch (e) {
    print('Failed to fetch sports news: $e');
  }
  return [];
});
