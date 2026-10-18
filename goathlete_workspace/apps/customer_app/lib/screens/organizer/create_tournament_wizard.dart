import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/user_search_picker.dart';

class CreateTournamentWizard extends ConsumerStatefulWidget {
  const CreateTournamentWizard({super.key});

  @override
  ConsumerState<CreateTournamentWizard> createState() => _CreateTournamentWizardState();
}

class _CreateTournamentWizardState extends ConsumerState<CreateTournamentWizard> {
  int _currentStep = 0;

  // Step 1: Sport & Basics
  int? _selectedSportId;
  final _nameController = TextEditingController();
  String? _selectedVenue;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  // Step 2: Quick Teams
  final _teamNameInputController = TextEditingController();
  final List<String> _teams = [];
  String? _selectedTeamFromDropdown;

  // Step 3: Fees & Tickets
  String _feeModel = 'player'; // 'player', 'team', 'free'
  final _playerFeeController = TextEditingController(text: '200');
  final _teamFeeController = TextEditingController(text: '2000');
  final _visitorFeeController = TextEditingController(text: '50');
  final _prizePoolController = TextEditingController(text: '10000');

  // Step 4: Umpire & Format
  String _format = 'Knockout';
  String? _umpireGoathId;
  String? _umpireDisplayName = 'Self (You as Official)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        setState(() {
          _umpireGoathId = profile['goath_id'];
          _umpireDisplayName = 'Self (${profile['first_name'] ?? 'Organizer'})';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamNameInputController.dispose();
    _playerFeeController.dispose();
    _teamFeeController.dispose();
    _visitorFeeController.dispose();
    _prizePoolController.dispose();
    super.dispose();
  }

  void _addTeam() {
    final text = _teamNameInputController.text.trim();
    if (text.isNotEmpty) {
      if (_teams.contains(text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team already added.')),
        );
        return;
      }
      setState(() {
        _teams.add(text);
        _teamNameInputController.clear();
      });
    }
  }

  void _submitStreamlined() async {
    if (_selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a sport.')));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter tournament name.')));
      return;
    }
    if (_teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least 2 teams.')));
      return;
    }

    final startDateStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endDateStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    double playerFee = 0.0;
    double teamFee = 0.0;
    if (_feeModel == 'player') {
      playerFee = double.tryParse(_playerFeeController.text.trim()) ?? 0.0;
    } else if (_feeModel == 'team') {
      teamFee = double.tryParse(_teamFeeController.text.trim()) ?? 0.0;
    }
    final visitorFee = double.tryParse(_visitorFeeController.text.trim()) ?? 0.0;
    final prizePool = double.tryParse(_prizePoolController.text.trim()) ?? 0.0;

    final venuesAsync = ref.read(venueProvider).value ?? [];
    int? venueId;
    try {
      final selectedV = venuesAsync.firstWhere((v) => v.name == _selectedVenue);
      venueId = selectedV.id;
    } catch (_) {}

    final result = await ref.read(tournamentProvider.notifier).createTournamentStreamlined(
      name: _nameController.text.trim(),
      sportTemplateId: _selectedSportId!,
      startDate: startDateStr,
      endDate: endDateStr,
      location: _selectedVenue!,
      venueId: venueId,
      teamNames: _teams,
      umpireGoathId: _umpireGoathId,
      format: _format,
      playerFee: playerFee,
      teamFee: teamFee,
      visitorFee: visitorFee,
      prizePool: prizePool,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(result['message'] ?? 'Tournament and fixtures created successfully!'),
        ),
      );
      ref.invalidate(activeTournamentsProvider);
      context.pop();
    } else if (mounted) {
      final error = ref.read(tournamentProvider).error ?? 'Failed to create tournament';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(sportsProvider);
    final venuesAsync = ref.watch(venueProvider);
    final allTeamsAsync = ref.watch(allRegisteredTeamsProvider);
    final tournamentState = ref.watch(tournamentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compile venue dropdown list
    final List<String> venueOptions = [];
    venuesAsync.whenData((venues) {
      for (final v in venues) {
        if (!venueOptions.contains(v.name)) {
          venueOptions.add(v.name);
        }
      }
    });

    // Compile teams dropdown list
    final List<String> teamOptions = [];
    allTeamsAsync.whenData((registeredTeams) {
      for (final t in registeredTeams) {
        final tName = t['name'] as String?;
        final playersList = t['players'] as List?;
        if (tName != null && tName.isNotEmpty && !teamOptions.contains(tName)) {
          if (playersList != null && playersList.isNotEmpty) {
            teamOptions.add(tName);
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapid Tournament Creator'),
        backgroundColor: GoAthleteColors.athleticOrange,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_selectedSportId == null || _nameController.text.trim().isEmpty || _selectedVenue == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select sport, enter tournament name, and choose a venue')),
              );
              return;
            }
          }
          if (_currentStep == 1) {
            if (_teams.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add at least 2 teams to continue')),
              );
              return;
            }
          }

          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            _submitStreamlined();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: tournamentState.isLoading ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == 3 ? Colors.green[700] : GoAthleteColors.athleticOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: tournamentState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 3 ? '⚡ Create & Auto-Schedule' : 'Next Step',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                ),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      side: BorderSide(color: isDark ? Colors.white30 : Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Sport & Basics
          Step(
            title: const Text('Basics'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Sport', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                sportsAsync.when(
                  data: (sports) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sports.map((s) {
                        final isSelected = _selectedSportId == s['id'];
                        return ChoiceChip(
                          label: Text(
                            s['name'] ?? '',
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: GoAthleteColors.athleticOrange,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          side: BorderSide(
                            color: isSelected ? GoAthleteColors.athleticOrange : (isDark ? Colors.white24 : Colors.grey.shade400),
                            width: isSelected ? 2 : 1,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSportId = s['id'];
                                if (_nameController.text.isEmpty) {
                                  _nameController.text = '${s['name']} Premier Cup 2026';
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading sports: $e'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name',
                    hintText: 'e.g. Bangalore Cricket League',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select Venue / Location', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: venueOptions.contains(_selectedVenue) ? _selectedVenue : null,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Venue',
                    prefixIcon: Icon(Icons.location_on_outlined, color: GoAthleteColors.athleticOrange),
                    border: OutlineInputBorder(),
                  ),
                  items: venueOptions.map((v) => DropdownMenuItem<String>(
                    value: v,
                    child: Text(v, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedVenue = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Step 2: Quick Teams
          Step(
            title: const Text('Teams'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Builder(
              builder: (context) {
                final selectedSport = sportsAsync.value?.firstWhere(
                  (s) => s['id'] == _selectedSportId,
                  orElse: () => null,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedSport != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: GoAthleteColors.athleticOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GoAthleteColors.athleticOrange, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports, color: GoAthleteColors.athleticOrange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${selectedSport['name']} Rules: ${selectedSport['min_players_per_team']} to ${selectedSport['max_players_per_team']} Players per Team',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Select from Teams Dropdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select teams from the catalog.',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Teams Dropdown selector
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: teamOptions.contains(_selectedTeamFromDropdown) ? _selectedTeamFromDropdown : null,
                            hint: const Text('Choose team from dropdown...'),
                            decoration: const InputDecoration(
                              labelText: 'Team Catalog Dropdown',
                              prefixIcon: Icon(Icons.groups, color: GoAthleteColors.athleticOrange),
                              border: OutlineInputBorder(),
                            ),
                            items: teamOptions.map((teamName) {
                              final isAlreadyAdded = _teams.contains(teamName);
                              return DropdownMenuItem<String>(
                                value: teamName,
                                child: Row(
                                  children: [
                                    Icon(Icons.shield, size: 16, color: isAlreadyAdded ? Colors.grey : GoAthleteColors.athleticOrange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teamName,
                                        style: TextStyle(
                                          fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.bold,
                                          color: isAlreadyAdded ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isAlreadyAdded)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6.0),
                                        child: Text('(Added)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedTeamFromDropdown = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GoAthleteColors.deepNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          onPressed: () {
                            if (_selectedTeamFromDropdown != null && _selectedTeamFromDropdown!.isNotEmpty) {
                              if (!_teams.contains(_selectedTeamFromDropdown)) {
                                setState(() {
                                  _teams.add(_selectedTeamFromDropdown!);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Team already added.')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('OR TYPE CUSTOM TEAM', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.group_add, size: 16, color: GoAthleteColors.athleticOrange),
                        label: const Text('Create Full Squad & Invite Players', style: TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () async {
                          await context.push('/create-team');
                          ref.invalidate(allRegisteredTeamsProvider);
                        },
                      ),
                    ),
                const SizedBox(height: 20),
                if (_teams.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '💡 Quick Presets:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: ['Team Alpha', 'Team Bravo', 'Royal Strikers', 'Elite Knights'].map((preset) {
                            return ActionChip(
                              backgroundColor: isDark ? GoAthleteColors.deepNavy : Colors.white,
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                              label: Text(
                                '+ $preset',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (!_teams.contains(preset)) {
                                  setState(() => _teams.add(preset));
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _teams.map((t) {
                      return Chip(
                        avatar: const CircleAvatar(
                          backgroundColor: GoAthleteColors.athleticOrange,
                          child: Icon(Icons.shield, size: 14, color: Colors.white),
                        ),
                        label: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: () {
                          setState(() => _teams.remove(t));
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),

          // Step 3: Fees & Tickets

          Step(
            title: const Text('Fees'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Participant Entry Fee', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Set how players or teams will be charged to register for the tournament.', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Per Player Fee'),
                      selected: _feeModel == 'player',
                      selectedColor: GoAthleteColors.athleticOrange,
                      onSelected: (val) {
                        if (val) setState(() => _feeModel = 'player');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Per Team Fee'),
                      selected: _feeModel == 'team',
                      selectedColor: GoAthleteColors.athleticOrange,
                      onSelected: (val) {
                        if (val) setState(() => _feeModel = 'team');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Free Entry (₹0)'),
                      selected: _feeModel == 'free',
                      selectedColor: GoAthleteColors.athleticOrange,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _feeModel = 'free';
                            _playerFeeController.text = '0';
                            _teamFeeController.text = '0';
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_feeModel == 'player') ...[
                  TextField(
                    controller: _playerFeeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fee per Player (₹)',
                      hintText: 'e.g. 200',
                      prefixIcon: Icon(Icons.person),
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['100', '250', '500', '1000'].map((preset) {
                      return ActionChip(
                        label: Text('₹$preset'),
                        onPressed: () {
                          setState(() => _playerFeeController.text = preset);
                        },
                      );
                    }).toList(),
                  ),
                ] else if (_feeModel == 'team') ...[
                  TextField(
                    controller: _teamFeeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fee per Team (₹)',
                      hintText: 'e.g. 2000',
                      prefixIcon: Icon(Icons.groups),
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['1000', '2500', '5000', '10000'].map((preset) {
                      return ActionChip(
                        label: Text('₹$preset'),
                        onPressed: () {
                          setState(() => _teamFeeController.text = preset);
                        },
                      );
                    }).toList(),
                  ),
                ],
                const Divider(height: 32),
                Text('Visitor / Spectator Ticket Fee', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Price per spectator pass to enter the stadium and watch live matches.', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: _visitorFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Spectator Pass Fee (₹)',
                    hintText: 'e.g. 50 (or 0 for free entry)',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['0', '50', '100', '200'].map((preset) {
                    return ActionChip(
                      label: Text(preset == '0' ? 'Free (₹0)' : '₹$preset'),
                      onPressed: () {
                        setState(() => _visitorFeeController.text = preset);
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 32),
                Text('Tournament Prize Pool (Optional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Display total cash prize / pool to attract top teams and athletes.', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: _prizePoolController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Prize Pool (₹)',
                    hintText: 'e.g. 10000',
                    prefixIcon: Icon(Icons.emoji_events, color: Colors.amber),
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['0', '5000', '10000', '25000', '50000'].map((preset) {
                    return ActionChip(
                      label: Text(preset == '0' ? 'No Cash Prize' : '₹$preset'),
                      onPressed: () {
                        setState(() => _prizePoolController.text = preset);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Step 4: Umpire & Format
          Step(
            title: const Text('Format'),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tournament Format', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Knockout', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Single elimination', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                      value: 'Knockout',
                      groupValue: _format,
                      onChanged: (val) => setState(() => _format = val!),
                    ),
                    RadioListTile<String>(
                      title: const Text('League', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Round-Robin', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                      value: 'League',
                      groupValue: _format,
                      onChanged: (val) => setState(() => _format = val!),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text('Designated Umpire / Scorer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Only this designated official (and organizer) will have edit rights on the live scoreboard.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : GoAthleteColors.athleticOrange.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: GoAthleteColors.athleticOrange, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      child: Icon(Icons.sports, color: Colors.white),
                    ),
                    title: Text(
                      _umpireDisplayName ?? 'Select Official',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      _umpireGoathId != null ? 'GOATH-ID: $_umpireGoathId' : 'Default: Tournament Organizer',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Search Athlete or Scan QR',
                          icon: const Icon(Icons.qr_code_scanner, color: GoAthleteColors.athleticOrange),
                          onPressed: () async {
                            final user = await UserSearchPickerModal.show(
                              context,
                              title: 'Assign Match Umpire / Scorer',
                              hintText: 'Search GOATH-ID or Scan QR Code',
                            );
                            if (user != null && mounted) {
                              setState(() {
                                _umpireGoathId = user['goath_id'];
                                _umpireDisplayName = '${user['name']} (${user['goath_id']})';
                              });
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reset to Self',
                          icon: const Icon(Icons.person),
                          onPressed: () {
                            final profile = ref.read(profileProvider).value;
                            setState(() {
                              _umpireGoathId = profile?['goath_id'];
                              _umpireDisplayName = 'Self (${profile?['first_name'] ?? 'Organizer'})';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

