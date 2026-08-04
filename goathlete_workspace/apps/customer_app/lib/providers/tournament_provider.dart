import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

final sportsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('tournaments/sports/');
    return response.data as List<dynamic>;
  } catch (e) {
    if (e is DioException) {
      throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
    }
    throw Exception('Failed to load sports: $e');
  }
});

final tournamentProvider = StateNotifierProvider<TournamentNotifier, TournamentState>((ref) {
  return TournamentNotifier(ref.watch(dioProvider));
});

class TournamentState {
  final bool isLoading;
  final String? error;
  
  TournamentState({this.isLoading = false, this.error});
  
  TournamentState copyWith({bool? isLoading, String? error, bool clearError = false}) {
    return TournamentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TournamentNotifier extends StateNotifier<TournamentState> {
  final Dio _dio;

  TournamentNotifier(this._dio) : super(TournamentState());

  Future<bool> createTournament(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('tournaments/tournaments/', data: data);
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.response?.data?.toString() ?? 'Failed to create tournament'
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<List<dynamic>> fetchTournaments() async {
    try {
      final response = await _dio.get('tournaments/tournaments/');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<int?> createTeam(String name, int tournamentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('tournaments/teams/', data: {
        'name': name,
        'tournament': tournamentId,
      });
      state = state.copyWith(isLoading: false);
      return response.data['id'] as int;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?.toString() ?? 'Failed to create team');
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<String?> addPlayerToTeam(int teamId, String goathId) async {
    try {
      final response = await _dio.post('tournaments/teams/$teamId/add_player/', data: {
        'goath_id': goathId,
      });
      return response.data['player_name'] as String?;
    } on DioException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> generateFixtures(int tournamentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('tournaments/tournaments/$tournamentId/generate_fixtures/');
      state = state.copyWith(isLoading: false);
      return response.data['message'] as String?;
    } on DioException catch (e) {
      final error = e.response?.data?['error']?.toString() ?? 'Failed to generate fixtures';
      state = state.copyWith(isLoading: false, error: error);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final activeTournamentsProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ref.read(tournamentProvider.notifier).fetchTournaments();
});
