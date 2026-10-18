import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/user_search_picker.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  final int? initialTournamentId;
  final int? initialTeamId;
  final String? initialTeamName;

  const CreateTeamScreen({
    super.key,
    this.initialTournamentId,
    this.initialTeamId,
    this.initialTeamName,
  });

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _teamNameController = TextEditingController();
  final _goathIdController = TextEditingController();
  int? _selectedTournamentId;
  int? _createdTeamId;
  bool _isAddingPlayer = false;
  
  final List<Map<String, String>> _invitedPlayers = [];

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.initialTournamentId;
    if (widget.initialTeamId != null) {
      _createdTeamId = widget.initialTeamId;
      _teamNameController.text = widget.initialTeamName ?? 'Team';
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _goathIdController.dispose();
    super.dispose();
  }

  void _createTeam() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name.')),
      );
      return;
    }
    
    final teamId = await ref.read(tournamentProvider.notifier).createTeam(
      teamName, 
      _selectedTournamentId,
    );
    if (teamId != null) {
      setState(() {
        _createdTeamId = teamId;
      });
      ref.invalidate(allRegisteredTeamsProvider);
      if (_selectedTournamentId != null) {
        ref.invalidate(tournamentTeamsProvider(_selectedTournamentId!));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "$teamName" created! Now add your squad players.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      final err = ref.read(tournamentProvider).error ?? 'Failed to create team';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _invitePlayer([String? customId]) async {
    final idToUse = (customId ?? _goathIdController.text).trim();
    if (idToUse.isEmpty || _createdTeamId == null) return;

    setState(() => _isAddingPlayer = true);
    
    final result = await ref.read(tournamentProvider.notifier).addPlayerToTeam(_createdTeamId!, goathId: idToUse);
    setState(() => _isAddingPlayer = false);

    if (result != null) {
      final playerName = result['player_name'] ?? 'Athlete';
      final goathId = result['goath_id'] ?? idToUse;
      setState(() {
        _invitedPlayers.add({
          'name': playerName.toString(),
          'id': goathId.toString(),
        });
        _goathIdController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $playerName to squad!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Athlete not found. Verify the GOATH-ID or phone number.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(activeTournamentsProvider);
    final tournamentState = ref.watch(tournamentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_createdTeamId == null ? 'Create Team' : 'Build Squad Roster'),
        backgroundColor: GoAthleteColors.athleticOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Steps indicator
            Row(
              children: [
                _buildStepBadge(1, 'Team Details', isActive: _createdTeamId == null, isCompleted: _createdTeamId != null),
                const SizedBox(width: 8),
                Expanded(child: Divider(color: _createdTeamId != null ? Colors.green : Colors.grey)),
                const SizedBox(width: 8),
                _buildStepBadge(2, 'Add Squad Players', isActive: _createdTeamId != null, isCompleted: false),
              ],
            ),
            const SizedBox(height: 24),

            if (_createdTeamId == null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 1: Team & Tournament Info',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a club team first, or optionally assign it to an active tournament right away.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _teamNameController,
                        decoration: const InputDecoration(
                          labelText: 'Team / Club Name *',
                          hintText: 'e.g., Royal Strikers, Thunderbolts FC',
                          prefixIcon: Icon(Icons.shield, color: GoAthleteColors.athleticOrange),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      tournamentsAsync.when(
                        data: (tournaments) {
                          return DropdownButtonFormField<int?>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Tournament (Optional)',
                              prefixIcon: Icon(Icons.emoji_events, color: GoAthleteColors.athleticOrange),
                              border: OutlineInputBorder(),
                              helperText: 'Leave as Standalone Club Team if creating before tournament',
                              helperMaxLines: 2,
                            ),
                            value: _selectedTournamentId,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('None (Standalone Club Team)', overflow: TextOverflow.ellipsis),
                              ),
                              ...tournaments.map<DropdownMenuItem<int?>>((t) {
                                return DropdownMenuItem<int?>(
                                  value: t['id'] as int?,
                                  child: Text(t['name'] ?? 'Tournament', overflow: TextOverflow.ellipsis),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTournamentId = val;
                              });
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: tournamentState.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Create Team & Add Squad Players', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GoAthleteColors.athleticOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: tournamentState.isLoading ? null : _createTeam,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                        child: const Icon(Icons.groups, color: GoAthleteColors.athleticOrange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _teamNameController.text.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Team ID: #$_createdTeamId',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Step 2: Add Players to Squad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Search registered athletes or enter their GOATH-ID / phone number.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Search modal button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_search, size: 20),
                  label: const Text('Search & Select Athlete From Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoAthleteColors.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final user = await UserSearchPickerModal.show(
                      context,
                      title: 'Find Athlete for Team',
                      hintText: 'Search by Name, Phone, or GOATH-ID',
                    );
                    if (user != null && mounted) {
                      _invitePlayer(user['goath_id']);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Or manual input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goathIdController,
                      decoration: InputDecoration(
                        labelText: 'Or enter GOATH-ID / Phone',
                        hintText: 'e.g. GOATH-A1B2C or 9876543210',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'Scan QR Code',
                          icon: const Icon(Icons.qr_code_scanner, color: GoAthleteColors.athleticOrange),
                          onPressed: () async {
                            final user = await UserSearchPickerModal.show(
                              context,
                              title: 'Scan Athlete QR',
                              hintText: 'Scanning athlete card...',
                            );
                            if (user != null && mounted) {
                              _invitePlayer(user['goath_id']);
                            }
                          },
                        ),
                      ),
                      onSubmitted: (_) => _invitePlayer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isAddingPlayer ? null : () => _invitePlayer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isAddingPlayer 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Roster
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Squad Roster (${_invitedPlayers.length + 1} Athletes)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Active Squad', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Captain Tile
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.amber.shade400, width: 1),
                ),
                child: const ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 16,
                    child: Icon(Icons.star, color: Colors.white, size: 18),
                  ),
                  title: Text('Team Captain (Creator)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: Text('Captain', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),

              // Player list
              ..._invitedPlayers.map((player) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      radius: 16,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    title: Text(player['name'] ?? 'Player', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('ID: ${player['id'] ?? ''}', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
                );
              }),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Done & Return to Tournaments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    context.pop();
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge(int stepNum, String title, {required bool isActive, required bool isCompleted}) {
    Color bg = isCompleted ? Colors.green : (isActive ? GoAthleteColors.athleticOrange : Colors.grey);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bg,
          child: isCompleted 
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$stepNum', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? null : Colors.grey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
