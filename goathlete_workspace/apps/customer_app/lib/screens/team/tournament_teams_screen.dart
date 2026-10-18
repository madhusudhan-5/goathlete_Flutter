import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/user_search_picker.dart';

class TournamentTeamsScreen extends ConsumerStatefulWidget {
  final int tournamentId;
  final String? tournamentName;

  const TournamentTeamsScreen({
    super.key,
    required this.tournamentId,
    this.tournamentName,
  });

  @override
  ConsumerState<TournamentTeamsScreen> createState() => _TournamentTeamsScreenState();
}

class _TournamentTeamsScreenState extends ConsumerState<TournamentTeamsScreen> {
  final _newTeamController = TextEditingController();

  @override
  void dispose() {
    _newTeamController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Team'),
        content: TextField(
          controller: _newTeamController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'e.g. Thunder Strikers',
            prefixIcon: Icon(Icons.shield, color: GoAthleteColors.athleticOrange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoAthleteColors.athleticOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = _newTeamController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              _newTeamController.clear();

              final teamId = await ref.read(tournamentProvider.notifier).createTeam(name, widget.tournamentId);

              if (teamId != null) {
                ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
                ref.invalidate(activeTournamentsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Team "$name" created successfully!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerSheet(Map<String, dynamic> team) {
    final teamId = team['id'] as int;
    final teamName = team['name'] ?? 'Team';
    final goathIdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add Player to $teamName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(bottomSheetContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select an athlete from the catalog, scan a pass, or enter their GOATH-ID / phone number.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // 1. Search Catalog Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_search),
                label: const Text('Search Athlete Catalog (Name / Phone / ID)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoAthleteColors.deepNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final user = await UserSearchPickerModal.show(
                    context,
                    title: 'Add Player to $teamName',
                    hintText: 'Search athlete by name, phone, or GOATH-ID',
                  );
                  if (user != null && mounted) {
                    Navigator.pop(bottomSheetContext);
                    _executeAddPlayer(teamId, user['goath_id'], teamName);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR DIRECT ENTRY', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Direct ID or phone input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: goathIdController,
                    decoration: InputDecoration(
                      labelText: 'GOATH-ID or Phone Number',
                      hintText: 'e.g. GOATH-ABC1234 or 9876543210',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: GoAthleteColors.athleticOrange),
                        onPressed: () async {
                          final user = await UserSearchPickerModal.show(
                            context,
                            title: 'Scan Athlete Pass',
                            hintText: 'Scanning QR pass...',
                          );
                          if (user != null && mounted) {
                            Navigator.pop(bottomSheetContext);
                            _executeAddPlayer(teamId, user['goath_id'], teamName);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        Navigator.pop(bottomSheetContext);
                        _executeAddPlayer(teamId, val.trim(), teamName);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoAthleteColors.athleticOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final val = goathIdController.text.trim();
                    if (val.isNotEmpty) {
                      Navigator.pop(bottomSheetContext);
                      _executeAddPlayer(teamId, val, teamName);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _executeAddPlayer(int teamId, String idOrPhone, String teamName) async {
    final result = await ref.read(tournamentProvider.notifier).addPlayerToTeam(
      teamId,
      goathId: idOrPhone.startsWith('GOATH') ? idOrPhone : null,
      phoneNumber: !idOrPhone.startsWith('GOATH') ? idOrPhone : null,
    );

    if (result != null) {
      ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
      if (mounted) {
        final playerName = result['player_name'] ?? 'Athlete';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $playerName to $teamName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        final err = ref.read(tournamentProvider).error ?? 'Could not find or add athlete. Please verify ID or phone.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _setCaptain(int teamId, String goathId, String playerName, String teamName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Team Captain'),
        content: Text('Do you want to make $playerName the official Captain of $teamName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Captain'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(tournamentProvider.notifier).setTeamCaptain(teamId, goathId: goathId);
      if (success) {
        ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⭐ $playerName is now the Captain of $teamName!'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  void _showAssignUmpireDialog() {
    final profile = ref.read(profileProvider).value;
    final myGoathId = profile?['goath_id'] ?? '';
    final myName = profile?['first_name'] ?? 'Organizer';
    final umpireInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Scoreboard Manager / Umpire'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign the official who has authority to manage live scoring and officiate matches.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Option 1: Self
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: GoAthleteColors.athleticOrange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text('Self ($myName)'),
                subtitle: Text('GOATH-ID: $myGoathId'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoAthleteColors.deepNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _executeSetUmpire(myGoathId);
                  },
                  child: const Text('Assign Self'),
                ),
              ),
              const Divider(height: 24),

              // Option 2: Search catalog
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Search Official From Catalog'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final user = await UserSearchPickerModal.show(
                      context,
                      title: 'Select Scoreboard Manager / Umpire',
                      hintText: 'Search official by name, phone, or GOATH-ID',
                    );
                    if (user != null && mounted) {
                      _executeSetUmpire(user['goath_id']);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Option 3: Direct ID / Phone
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: umpireInputController,
                      decoration: const InputDecoration(
                        labelText: 'Or enter GOATH-ID / Phone',
                        hintText: 'e.g. GOATH-XYZ123',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                    onPressed: () {
                      final val = umpireInputController.text.trim();
                      if (val.isNotEmpty) {
                        Navigator.pop(ctx);
                        _executeSetUmpire(val);
                      }
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _executeSetUmpire(String goathIdOrPhone) async {
    final result = await ref.read(tournamentProvider.notifier).setTournamentUmpire(
      widget.tournamentId,
      goathId: goathIdOrPhone.startsWith('GOATH') ? goathIdOrPhone : null,
      phoneNumber: !goathIdOrPhone.startsWith('GOATH') ? goathIdOrPhone : null,
    );

    if (result != null) {
      ref.invalidate(activeTournamentsProvider);
      ref.invalidate(tournamentMatchesProvider(widget.tournamentId));
      if (mounted) {
        final officialName = result['default_umpire_name'] ?? 'Official';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Official Umpire / Scoreboard Manager set to $officialName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official not found. Verify the GOATH-ID or phone.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePlayer(int teamId, String goathId, String playerName, String teamName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove $playerName from $teamName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(tournamentProvider.notifier).removePlayerFromTeam(teamId, goathId: goathId);
      if (success) {
        ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$playerName removed from $teamName'), backgroundColor: Colors.orange),
          );
        }
      } else {
        if (mounted) {
          final err = ref.read(tournamentProvider).error ?? 'Could not remove player.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(widget.tournamentId));
    final matchesAsync = ref.watch(tournamentMatchesProvider(widget.tournamentId));
    final hasFixtures = (matchesAsync.value?.isNotEmpty ?? false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName != null ? '${widget.tournamentName} - Teams' : 'Teams & Squads'),
        backgroundColor: GoAthleteColors.athleticOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.sports),
            tooltip: 'Assign Official / Scoreboard Manager',
            onPressed: _showAssignUmpireDialog,
          ),
          if (!hasFixtures)
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Add Team',
              onPressed: hasFixtures ? null : _showCreateTeamDialog,
            ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No Teams Registered Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create the first team for this tournament to start adding players, designating captains, and generating match fixtures.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoAthleteColors.athleticOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: hasFixtures ? null : _showCreateTeamDialog,
                    ),
                  ],
                ),
              ),
            );
          }

          final itemCount = hasFixtures ? teams.length + 1 : teams.length + 2; // +1 for banner, +1 for bottom button if unlocked

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
              ref.invalidate(tournamentMatchesProvider(widget.tournamentId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Item 0: Locked banner if fixtures exist
                if (index == 0 && hasFixtures) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Roster Locked: Match fixtures are scheduled. Squad rosters and team additions cannot be modified.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Adjust index for teams
                final teamIndex = hasFixtures ? index - 1 : index;

                if (teamIndex == teams.length) {
                  if (hasFixtures) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Another Team', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GoAthleteColors.athleticOrange,
                        side: const BorderSide(color: GoAthleteColors.athleticOrange, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: hasFixtures ? null : _showCreateTeamDialog,
                    ),
                  );
                }

                final team = teams[teamIndex] as Map<String, dynamic>;
                final teamName = team['name'] ?? 'Team ${teamIndex + 1}';
                final captainName = team['captain_name'] ?? 'Captain';
                final players = (team['players'] as List<dynamic>?) ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      leading: CircleAvatar(
                        backgroundColor: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                        child: Text(
                          teamName.isNotEmpty ? teamName[0].toUpperCase() : 'T',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: GoAthleteColors.athleticOrange),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              teamName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${players.length} Players',
                              style: const TextStyle(color: GoAthleteColors.athleticOrange, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Captain: $captainName',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Squad Roster (${players.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (hasFixtures)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, size: 12, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text('Roster Locked', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add, size: 16),
                                  label: const Text('Add Player', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GoAthleteColors.athleticOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () => _showAddPlayerSheet(team),
                                ),
                            ],
                          ),
                        ),

                        if (players.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'No players added to $teamName yet.',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  if (!hasFixtures) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.person_add, size: 16),
                                      label: const Text('Add First Player', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showAddPlayerSheet(team),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: players.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                            itemBuilder: (ctx, pIdx) {
                              final p = players[pIdx] as Map<String, dynamic>;
                              final pName = p['player_name'] ?? 'Athlete';
                              final pGoathId = p['goath_id'] ?? '';
                              final isCaptain = pName == captainName;

                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isCaptain ? Colors.amber : (isDark ? Colors.white24 : Colors.grey.shade300),
                                  child: Icon(
                                    isCaptain ? Icons.star : Icons.person,
                                    size: 14,
                                    color: isCaptain ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        pName, 
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCaptain) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Captain',
                                          style: TextStyle(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text('GOATH-ID: $pGoathId', style: const TextStyle(fontSize: 11)),
                                trailing: hasFixtures
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isCaptain)
                                            IconButton(
                                              icon: const Icon(Icons.star_outline, size: 18, color: Colors.amber),
                                              tooltip: 'Select as Captain',
                                              onPressed: () => _setCaptain(team['id'] as int, pGoathId, pName, teamName),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent),
                                            tooltip: 'Remove Player',
                                            onPressed: () => _removePlayer(team['id'] as int, pGoathId, pName, teamName),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: GoAthleteColors.athleticOrange)),
        error: (e, _) => Center(child: Text('Error loading teams: $e')),
      ),
    );
  }

}
