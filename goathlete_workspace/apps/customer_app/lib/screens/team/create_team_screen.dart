import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tournament_provider.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _teamNameController = TextEditingController();
  final _goathIdController = TextEditingController();
  int? _selectedTournamentId;
  int? _createdTeamId;
  
  final List<String> _invitedPlayers = [];

  void _createTeam() async {
    if (_teamNameController.text.isEmpty || _selectedTournamentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter team name and select tournament')));
      return;
    }
    
    final teamId = await ref.read(tournamentProvider.notifier).createTeam(_teamNameController.text, _selectedTournamentId!);
    if (teamId != null) {
      setState(() {
        _createdTeamId = teamId;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created! Now invite players.')));
    }
  }

  void _invitePlayer() async {
    if (_goathIdController.text.isEmpty) return;
    
    final playerName = await ref.read(tournamentProvider.notifier).addPlayerToTeam(_createdTeamId!, _goathIdController.text);
    if (playerName != null) {
      setState(() {
        _invitedPlayers.add('$playerName (${_goathIdController.text})');
        _goathIdController.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$playerName added to team!')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add player. Check GOATH-ID.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(activeTournamentsProvider);
    final tournamentState = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Team'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_createdTeamId == null) ...[
              Text('Step 1: Create Team', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              tournamentsAsync.when(
                data: (tournaments) {
                  if (tournaments.isEmpty) return const Text('No active tournaments available.');
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Tournament'),
                    value: _selectedTournamentId,
                    items: tournaments.map((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'],
                        child: Text(t['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTournamentId = val;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Error loading tournaments: $e'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teamNameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: tournamentState.isLoading ? null : _createTeam,
                  style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                  child: tournamentState.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Team'),
                ),
              ),
            ] else ...[
              Text('Step 2: Invite Players', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Team: ${_teamNameController.text}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goathIdController,
                      decoration: const InputDecoration(labelText: 'Enter GOATH-ID'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final scannedId = await context.push('/qr-scanner');
                      if (scannedId != null && scannedId is String && mounted) {
                        setState(() {
                          _goathIdController.text = scannedId;
                        });
                        _invitePlayer();
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, color: GoAthleteColors.athleticOrange, size: 32),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _invitePlayer,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Roster (${_invitedPlayers.length + 1})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('You (Captain)'),
              ),
              ..._invitedPlayers.map((p) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(p),
              )).toList(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Finish Registration'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
