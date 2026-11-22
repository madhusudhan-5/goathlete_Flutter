import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';

class VenueSubmissionPayload {
  final Map<String, dynamic> fields;
  final List<XFile> imageFiles;

  const VenueSubmissionPayload({
    required this.fields,
    this.imageFiles = const [],
  });
}

final venueSubmitProvider = FutureProvider.family<bool, VenueSubmissionPayload>((ref, payload) async {
  final dio = ref.read(dioProvider);
  try {
    dynamic requestBody;
    Options? options;

    if (payload.imageFiles.isNotEmpty) {
      final formData = FormData();
      payload.fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      for (final file in payload.imageFiles) {
        final bytes = await file.readAsBytes();
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              bytes,
              filename: file.name.isNotEmpty ? file.name : 'venue_photo.jpg',
            ),
          ),
        );
      }
      requestBody = formData;
      options = Options(contentType: 'multipart/form-data');
    } else {
      requestBody = payload.fields;
    }

    final response = await dio.post(
      'venues/pre-register-venues/',
      data: requestBody,
      options: options,
    );
    return response.statusCode == 201;
  } on DioException catch (e) {
    throw Exception('Failed to submit venue onboarding: ${e.response?.data}');
  } catch (e) {
    throw Exception('Failed to submit venue onboarding: $e');
  }
});

final venuesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/pre-register-venues/');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load onboarded venues: $e');
  }
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/pre-register-venues/dashboard_stats/');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
});
