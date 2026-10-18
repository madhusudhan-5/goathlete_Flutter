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

final activeTournamentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('tournaments/tournaments/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final tournamentMatchesProvider = FutureProvider.family<List<dynamic>, int>((ref, tournamentId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('tournaments/matches/');
    final allMatches = response.data as List<dynamic>;
    return allMatches.where((m) => m['tournament'] == tournamentId).toList();
  } catch (e) {
    return [];
  }
});

final tournamentTeamsProvider = FutureProvider.family<List<dynamic>, int>((ref, tournamentId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('tournaments/teams/', queryParameters: {'tournament': tournamentId});
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

final allRegisteredTeamsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('tournaments/teams/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});


final singleMatchProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, matchId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('tournaments/matches/$matchId/');
  return response.data as Map<String, dynamic>;
});

final userLookupProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('users/lookup/', queryParameters: {'q': query.trim()});
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
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

  Future<Map<String, dynamic>?> createTournamentStreamlined({
    required String name,
    required int sportTemplateId,
    required String startDate,
    required String endDate,
    required String location,
    int? venueId,
    required List<String> teamNames,
    String? umpireGoathId,
    String format = 'Knockout',
    double playerFee = 0.0,
    double teamFee = 0.0,
    double visitorFee = 0.0,
    double prizePool = 0.0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('tournaments/tournaments/create_streamlined/', data: {
        'name': name,
        'sport_template': sportTemplateId,
        'start_date': startDate,
        'end_date': endDate,
        'location': location,
        if (venueId != null) 'venue_id': venueId,
        'team_names': teamNames,
        'umpire_goath_id': umpireGoathId,
        'format': format,
        'player_fee': playerFee,
        'team_fee': teamFee,
        'visitor_fee': visitorFee,
        'prize_pool': prizePool,
      });
      state = state.copyWith(isLoading: false);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?.toString() ?? 'Failed to create tournament';
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
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

  Future<bool> startMatch(String matchId) async {
    try {
      final response = await _dio.post('tournaments/matches/$matchId/start_match/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateScore(String matchId, Map<String, dynamic> scoreData, {String? status, int? winnerId}) async {
    try {
      final payload = <String, dynamic>{'current_score': scoreData};
      if (status != null) payload['status'] = status;
      if (winnerId != null) payload['winner_id'] = winnerId;

      final response = await _dio.post('tournaments/matches/$matchId/update_score/', data: payload);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> logEvent({
    required String matchId,
    required int sportEventId,
    required int teamId,
    int? playerId,
  }) async {
    try {
      final data = <String, dynamic>{
        'sport_event': sportEventId,
        'team': teamId,
      };
      if (playerId != null) data['player'] = playerId;

      final response = await _dio.post('tournaments/matches/$matchId/log_event/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<int?> createTeam(String name, [int? tournamentId]) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payload = <String, dynamic>{'name': name};
      if (tournamentId != null) {
        payload['tournament'] = tournamentId;
      }
      final response = await _dio.post('tournaments/teams/', data: payload);
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

  Future<Map<String, dynamic>?> addPlayerToTeam(int teamId, {String? goathId, String? phoneNumber}) async {
    try {
      final payload = <String, dynamic>{};
      if (goathId != null) payload['goath_id'] = goathId;
      if (phoneNumber != null) payload['phone_number'] = phoneNumber;

      final response = await _dio.post('tournaments/teams/$teamId/add_player/', data: payload);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Could not add player.';
      state = state.copyWith(error: msg);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> setTeamCaptain(int teamId, {String? goathId, int? playerId}) async {
    try {
      final payload = <String, dynamic>{};
      if (goathId != null) payload['goath_id'] = goathId;
      if (playerId != null) payload['player_id'] = playerId;

      final response = await _dio.post('tournaments/teams/$teamId/set_captain/', data: payload);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> setTournamentUmpire(int tournamentId, {String? goathId, String? phoneNumber}) async {
    try {
      final payload = <String, dynamic>{};
      if (goathId != null) payload['goath_id'] = goathId;
      if (phoneNumber != null) payload['phone_number'] = phoneNumber;

      final response = await _dio.post('tournaments/tournaments/$tournamentId/set_umpire/', data: payload);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<bool> assignMatchUmpire(String matchId, {required String goathId}) async {
    try {
      final response = await _dio.post('tournaments/matches/$matchId/assign_umpire/', data: {'goath_id': goathId});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removePlayerFromTeam(int teamId, {String? goathId, int? playerId}) async {
    try {
      final payload = <String, dynamic>{};
      if (goathId != null) payload['goath_id'] = goathId;
      if (playerId != null) payload['player_id'] = playerId;

      final response = await _dio.post('tournaments/teams/$teamId/remove_player/', data: payload);
      return response.statusCode == 200;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Could not remove player.';
      state = state.copyWith(error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }


  Future<String?> generateFixtures(int tournamentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('tournaments/tournaments/$tournamentId/generate_fixtures/');
      state = state.copyWith(isLoading: false);
      return response.data['message'] as String;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Failed to generate fixtures';
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
