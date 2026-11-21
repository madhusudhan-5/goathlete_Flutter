import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/app_drawer.dart';
import '../profile/notifications_screen.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {
  bool _isLoading = true;
  List<dynamic> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() => _isLoading = true);
    _tournaments = await ref.read(tournamentProvider.notifier).fetchTournaments();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  double _parsePlayerFee(Map<String, dynamic> tournament) {
    final raw = tournament['player_fee'] ??
        (tournament['tournament_rules'] is Map
            ? tournament['tournament_rules']['player_fee']
            : 0);
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  Future<void> _showJoinTournamentSheet(Map<String, dynamic> tournament) async {
    final int tournamentId = tournament['id'] as int;
    final String tournamentName = tournament['name']?.toString() ?? 'Tournament';
    final String sportName = tournament['sport_name']?.toString() ?? 'Sport';
    final String startDate = tournament['start_date']?.toString() ?? 'TBD';
    final String location = tournament['location']?.toString() ?? 'TBD';
    final double playerFee = _parsePlayerFee(tournament);
    final int totalAvailableSlots = (tournament['available_player_slots'] as num?)?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return _JoinTeamBottomSheet(
          tournamentId: tournamentId,
          tournamentName: tournamentName,
          sportName: sportName,
          startDate: startDate,
          location: location,
          playerFee: playerFee,
          initialAvailableSlots: totalAvailableSlots,
          onJoinedSuccess: (result) async {
            Navigator.of(sheetCtx).pop();
            await _fetchTournaments();
            ref.invalidate(activeTournamentsProvider);
            ref.invalidate(tournamentTeamsProvider(tournamentId));

            final String teamName = result['team_name']?.toString() ?? 'Team';
            final String matchDateTime =
                result['match_datetime']?.toString() ?? '$startDate (09:00 AM)';
            final String venue = result['location']?.toString() ?? location;
            final double feePaid = (result['fee_paid'] as num?)?.toDouble() ?? playerFee;
            final String payText =
                feePaid > 0 ? '₹${feePaid.toInt()} Paid' : 'Free Entry';

            // Save to in-app notifications list
            ref.read(appNotificationsProvider.notifier).addNotification(
                  AppNotificationItem(
                    title: '🎉 Successfully Joined Team "$teamName"!',
                    body:
                        'You have joined "$teamName" in $tournamentName ($sportName). Be ready at the venue on time!',
                    timestamp: matchDateTime,
                    tournamentName: tournamentName,
                    teamName: teamName,
                    matchDateTime: matchDateTime,
                    location: venue,
                    paymentStatus: payText,
                  ),
                );

            if (!mounted) return;

            // Show floating notification banner
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green.shade800,
                duration: const Duration(seconds: 5),
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Joined "$teamName" for $tournamentName! Date & Time: $matchDateTime',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Show detailed notification confirmation dialog with Date & Time of tournament
            _showJoinConfirmationDialog(
              tournamentName: tournamentName,
              sportName: sportName,
              teamName: teamName,
              matchDateTime: matchDateTime,
              location: venue,
              paymentStatus: payText,
            );
          },
        );
      },
    );
  }

  void _showJoinConfirmationDialog({
    required String tournamentName,
    required String sportName,
    required String teamName,
    required String matchDateTime,
    required String location,
    required String paymentStatus,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Successfully Joined Team!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your spot in the tournament has been confirmed. A notification has also been added to your Notifications tab.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GoAthleteColors.athleticOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GoAthleteColors.athleticOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmRow(Icons.emoji_events, 'Tournament', '$tournamentName ($sportName)'),
                  const SizedBox(height: 8),
                  _buildConfirmRow(Icons.shield, 'Joined Team', teamName),
                  const SizedBox(height: 8),
                  _buildConfirmRow(Icons.access_time_filled, 'Date & Time', matchDateTime),
                  const SizedBox(height: 8),
                  _buildConfirmRow(Icons.location_on, 'Venue', location),
                  const SizedBox(height: 8),
                  _buildConfirmRow(Icons.payments, 'Entry Fee', paymentStatus),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/notifications');
            },
            child: const Text('View Notifications'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoAthleteColors.athleticOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: GoAthleteColors.athleticOrange),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTournaments,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tournaments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No tournaments yet',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                  itemCount: _tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = _tournaments[index] as Map<String, dynamic>;
                    final int availableSlots =
                        (tournament['available_player_slots'] as num?)?.toInt() ?? 0;
                    final int totalCapacity =
                        (tournament['total_player_capacity'] as num?)?.toInt() ?? 0;
                    final int joinedCount =
                        (tournament['joined_players_count'] as num?)?.toInt() ?? 0;
                    final int teamsCount =
                        (tournament['teams_count'] as num?)?.toInt() ?? 0;
                    final double playerFee = _parsePlayerFee(tournament);
                    final Map<String, dynamic>? myJoinedTeam =
                        tournament['my_joined_team'] is Map
                            ? Map<String, dynamic>.from(tournament['my_joined_team'] as Map)
                            : null;
                    final bool hasSlots = availableSlots > 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    GoAthleteColors.deepNavy,
                                    GoAthleteColors.deepestMidnight
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                image: (tournament['banner_image'] != null &&
                                        tournament['banner_image'].toString().isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(tournament['banner_image']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.transparent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Entry Fee Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: GoAthleteColors.athleticOrange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        playerFee > 0
                                            ? '₹${playerFee.toInt()}/Player Entry'
                                            : 'Free Entry',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    // Slots Badge on Card Banner
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: hasSlots
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasSlots
                                                ? Icons.event_seat
                                                : Icons.block,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasSlots
                                                ? '$availableSlots / $totalCapacity Slots Open'
                                                : 'No Slots Available',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tournament['name'] ?? 'Tournament',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: GoAthleteColors.athleticOrange
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tournament['sport_name'] ?? 'Sport',
                                          style: const TextStyle(
                                            color: GoAthleteColors.athleticOrange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: GoAthleteColors.athleticOrange,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          tournament['location'] ?? 'TBD',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tournament['start_date'] ?? ''}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.sports,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Official: ${tournament['default_umpire_name'] ?? 'Organizer'}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Available Slots & Teams Status Box inside Card
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: hasSlots
                                          ? Colors.green.withValues(alpha: 0.08)
                                          : Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: hasSlots
                                            ? Colors.green.withValues(alpha: 0.35)
                                            : Colors.red.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasSlots
                                              ? Icons.groups
                                              : Icons.group_off,
                                          size: 20,
                                          color: hasSlots
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hasSlots
                                                    ? '$availableSlots Player Slots Available ($teamsCount Teams)'
                                                    : 'No Player Slots Available ($teamsCount Teams Full)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: hasSlots
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                              Text(
                                                'Joined Players: $joinedCount / $totalCapacity • ${playerFee > 0 ? "Fee: ₹${playerFee.toInt()}/Player" : "Free Registration"}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (myJoinedTeam != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: GoAthleteColors.athleticOrange
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.verified_user,
                                            size: 18,
                                            color: GoAthleteColors.athleticOrange,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'You joined team "${myJoinedTeam['team_name']}" (${myJoinedTeam['payment_status'] == 'PAID' ? 'Fee Paid' : 'Free Entry'})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                                color: GoAthleteColors.athleticOrange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Join Team / Player & View Teams Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: myJoinedTeam != null
                                                ? Colors.green.shade700
                                                : (hasSlots
                                                    ? GoAthleteColors.athleticOrange
                                                    : Colors.grey.shade600),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 11, horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: Icon(
                                            myJoinedTeam != null
                                                ? Icons.check_circle
                                                : (hasSlots
                                                    ? Icons.person_add_alt_1
                                                    : Icons.block),
                                            size: 18,
                                          ),
                                          label: Text(
                                            myJoinedTeam != null
                                                ? 'Joined: ${myJoinedTeam['team_name']}'
                                                : (hasSlots
                                                    ? (playerFee > 0
                                                        ? 'Join Team (₹${playerFee.toInt()})'
                                                        : 'Join Team (Free)')
                                                    : 'No Slots Available'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onPressed: () {
                                            _showJoinTournamentSheet(tournament);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                GoAthleteColors.athleticOrange,
                                            side: const BorderSide(
                                              color: GoAthleteColors.athleticOrange,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 11, horizontal: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(Icons.groups, size: 18),
                                          label: const Text(
                                            'Squads',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final tName = Uri.encodeComponent(
                                              tournament['name'] ?? 'Tournament',
                                            );
                                            await context.push(
                                              '/tournament-teams/${tournament['id']}?name=$tName',
                                            );
                                            _fetchTournaments();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 24),
                                  _TournamentMatchesPreview(
                                      tournamentId: tournament['id']),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/create-tournament');
        },
        backgroundColor: GoAthleteColors.athleticOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Tournament',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _JoinTeamBottomSheet extends ConsumerStatefulWidget {
  final int tournamentId;
  final String tournamentName;
  final String sportName;
  final String startDate;
  final String location;
  final double playerFee;
  final int initialAvailableSlots;
  final ValueChanged<Map<String, dynamic>> onJoinedSuccess;

  const _JoinTeamBottomSheet({
    required this.tournamentId,
    required this.tournamentName,
    required this.sportName,
    required this.startDate,
    required this.location,
    required this.playerFee,
    required this.initialAvailableSlots,
    required this.onJoinedSuccess,
  });

  @override
  ConsumerState<_JoinTeamBottomSheet> createState() =>
      _JoinTeamBottomSheetState();
}

class _JoinTeamBottomSheetState extends ConsumerState<_JoinTeamBottomSheet> {
  bool _loadingTeams = true;
  bool _submitting = false;
  List<dynamic> _teams = [];
  int? _selectedTeamId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loadingTeams = true;
      _errorMessage = null;
    });
    final teams = await ref
        .read(tournamentProvider.notifier)
        .fetchTournamentTeams(widget.tournamentId);
    if (!mounted) return;

    int? firstOpenTeamId;
    for (final t in teams) {
      final avail = (t['available_slots'] as num?)?.toInt() ?? 0;
      if (avail > 0) {
        firstOpenTeamId = t['id'] as int;
        break;
      }
    }

    setState(() {
      _teams = teams;
      _selectedTeamId = firstOpenTeamId;
      _loadingTeams = false;
    });
  }

  Future<void> _handleJoinTeam() async {
    if (_selectedTeamId == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(tournamentProvider.notifier)
        .joinTournamentTeam(_selectedTeamId!, feePaid: true);

    if (!mounted) return;

    if (result != null) {
      setState(() => _submitting = false);
      widget.onJoinedSuccess(result);
    } else {
      final err = ref.read(tournamentProvider).error ??
          'Failed to join team. Please try again.';
      setState(() {
        _submitting = false;
        _errorMessage = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalAvailable = _teams.fold<int>(
      0,
      (sum, t) => sum + ((t['available_slots'] as num?)?.toInt() ?? 0),
    );
    final bool hasAnyOpenSlots =
        _loadingTeams ? widget.initialAvailableSlots > 0 : totalAvailable > 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join ${widget.tournamentName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.sportName} • ${widget.startDate} • ${widget.location}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),

            if (_loadingTeams)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_teams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No teams have been created in this tournament yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else ...[
              // Slots availability header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hasAnyOpenSlots
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasAnyOpenSlots ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasAnyOpenSlots ? Icons.check_circle : Icons.error,
                      color: hasAnyOpenSlots
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasAnyOpenSlots
                            ? '$totalAvailable Player Slots Available — Select a team below to join:'
                            : 'No Slots Available — All teams in this tournament are full.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: hasAnyOpenSlots
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.38,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final team = _teams[idx] as Map<String, dynamic>;
                    final int teamId = team['id'] as int;
                    final String teamName = team['name']?.toString() ?? 'Team';
                    final String captainName =
                        team['captain_name']?.toString() ?? 'TBA';
                    final int playersCount =
                        (team['players_count'] as num?)?.toInt() ??
                            ((team['players'] as List?)?.length ?? 0);
                    final int maxPlayers =
                        (team['max_players'] as num?)?.toInt() ?? 11;
                    final int availSlots =
                        (team['available_slots'] as num?)?.toInt() ??
                            (maxPlayers - playersCount);
                    final bool isTeamOpen = availSlots > 0;
                    final bool isSelected = _selectedTeamId == teamId;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isTeamOpen
                          ? () => setState(() => _selectedTeamId = teamId)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GoAthleteColors.athleticOrange
                                  .withValues(alpha: 0.1)
                              : (isTeamOpen
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.grey.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? GoAthleteColors.athleticOrange
                                : Colors.grey.withValues(alpha: 0.35),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTeamOpen
                                  ? (isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off)
                                  : Icons.lock,
                              color: isTeamOpen
                                  ? (isSelected
                                      ? GoAthleteColors.athleticOrange
                                      : Colors.grey)
                                  : Colors.red.shade400,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teamName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isTeamOpen ? null : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Captain: $captainName • Roster: $playersCount / $maxPlayers Players',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isTeamOpen
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                isTeamOpen
                                    ? '$availSlots Slots Open'
                                    : 'No Slots (Full)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: isTeamOpen
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Entry fee summary & CTA
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Player Entry Fee:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    Text(
                      widget.playerFee > 0
                          ? '₹${widget.playerFee.toInt()} (Pay & Join)'
                          : 'FREE (₹0)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: widget.playerFee > 0
                            ? GoAthleteColors.athleticOrange
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasAnyOpenSlots
                        ? GoAthleteColors.athleticOrange
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (!hasAnyOpenSlots ||
                          _selectedTeamId == null ||
                          _submitting)
                      ? null
                      : _handleJoinTeam,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          hasAnyOpenSlots
                              ? (widget.playerFee > 0
                                  ? Icons.payment
                                  : Icons.how_to_reg)
                              : Icons.block,
                        ),
                  label: Text(
                    !hasAnyOpenSlots
                        ? 'No Slots Available to Join'
                        : (widget.playerFee > 0
                            ? 'Pay ₹${widget.playerFee.toInt()} & Join Selected Team'
                            : 'Join Selected Team (Free)'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TournamentMatchesPreview extends ConsumerWidget {
  final int tournamentId;
  const _TournamentMatchesPreview({required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournamentId));

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'No matches scheduled yet',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              TextButton.icon(
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text(
                  'Generate Fixtures',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final msg = await ref
                      .read(tournamentProvider.notifier)
                      .generateFixtures(tournamentId);
                  if (msg != null) {
                    ref.invalidate(tournamentMatchesProvider(tournamentId));
                  }
                },
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fixtures & Matches (${matches.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap match to open scoreboard',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...matches.map((m) {
              final teamA = m['team_a_name'] ?? 'Team A';
              final teamB = m['team_b_name'] ?? 'Team B';
              final status = m['status'] ?? 'Scheduled';
              final score = m['current_score'] ?? {};
              final scoreText =
                  '${score['team_a_score'] ?? 0} - ${score['team_b_score'] ?? 0}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        status == 'Ongoing' ? Colors.green : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$teamA vs $teamB',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status == 'Ongoing'
                                ? '🔴 LIVE: $scoreText'
                                : (status == 'Completed'
                                    ? 'Winner: ${m['winner_name'] ?? 'TBD'} ($scoreText)'
                                    : 'Status: $status'),
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'Ongoing'
                                  ? Colors.green[800]
                                  : Colors.grey[700],
                              fontWeight: status == 'Ongoing'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status != 'Completed')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'Ongoing'
                              ? Colors.green
                              : GoAthleteColors.athleticOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          context.push('/live-scorer/${m['id']}');
                        },
                        child: Text(
                          status == 'Ongoing' ? 'Live Score' : 'Open Match',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
