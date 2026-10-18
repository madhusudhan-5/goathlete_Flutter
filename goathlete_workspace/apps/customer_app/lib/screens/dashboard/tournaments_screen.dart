import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/app_drawer.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        actions: [
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
                final tournament = _tournaments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [GoAthleteColors.deepNavy, GoAthleteColors.deepestMidnight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            image: (tournament['banner_image'] != null && tournament['banner_image'].toString().isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(tournament['banner_image']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: GoAthleteColors.athleticOrange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '₹${tournament['entry_fee'] ?? 'Free'} Entry',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tournament['name'] ?? 'Tournament',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GoAthleteColors.athleticOrange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tournament['sport_name'] ?? 'Sport',
                                      style: const TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: GoAthleteColors.athleticOrange),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(tournament['location'] ?? 'TBD', style: Theme.of(context).textTheme.bodyMedium)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${tournament['start_date'] ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(width: 16),
                                  Icon(Icons.sports, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('Official: ${tournament['default_umpire_name'] ?? 'Organizer'}', style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const Divider(height: 24),
                              _TournamentMatchesPreview(tournamentId: tournament['id']),
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
        label: const Text('Create Tournament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Text('No matches scheduled yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
              TextButton.icon(
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text('Generate Fixtures', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final msg = await ref.read(tournamentProvider.notifier).generateFixtures(tournamentId);
                  if (msg != null) {
                    ref.refresh(tournamentMatchesProvider(tournamentId));
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              final scoreText = '${score['team_a_score'] ?? 0} - ${score['team_b_score'] ?? 0}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status == 'Ongoing' ? Colors.green : Colors.transparent,
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status == 'Ongoing' ? '🔴 LIVE: $scoreText' : (status == 'Completed' ? 'Winner: ${m['winner_name'] ?? 'TBD'} ($scoreText)' : 'Status: $status'),
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'Ongoing' ? Colors.green[800] : Colors.grey[700],
                              fontWeight: status == 'Ongoing' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status != 'Completed')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'Ongoing' ? Colors.green : GoAthleteColors.athleticOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          context.push('/live-scorer/${m['id']}');
                        },
                        child: Text(
                          status == 'Ongoing' ? 'Live Score' : 'Open Match',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

