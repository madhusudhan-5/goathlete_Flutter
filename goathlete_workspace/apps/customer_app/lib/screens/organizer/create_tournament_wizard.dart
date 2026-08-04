import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/tournament_provider.dart';

class CreateTournamentWizard extends ConsumerStatefulWidget {
  const CreateTournamentWizard({super.key});

  @override
  ConsumerState<CreateTournamentWizard> createState() => _CreateTournamentWizardState();
}

class _CreateTournamentWizardState extends ConsumerState<CreateTournamentWizard> {
  int _currentStep = 0;
  
  // Step 1: Basics
  final _nameController = TextEditingController();
  int? _selectedSportId;
  
  // Step 2: Schedule & Venue
  DateTime? _startDate;
  DateTime? _endDate;
  final _locationController = TextEditingController();
  bool _isGettingLocation = false;
  
  // Step 3: Rules & Config
  final _maxTeamsController = TextEditingController();
  final _entryFeeController = TextEditingController();
  String _format = 'Knockout';

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationController.text = '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  void _submit() async {
    final data = {
      'name': _nameController.text,
      'sport_template': _selectedSportId,
      'start_date': '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
      'end_date': '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
      'location': _locationController.text,
      'tournament_rules': {
        'max_teams': int.tryParse(_maxTeamsController.text) ?? 16,
        'entry_fee': _entryFeeController.text,
        'format': _format,
      }
    };
    
    final success = await ref.read(tournamentProvider.notifier).createTournament(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament Created Successfully!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsyncValue = ref.watch(sportsProvider);
    final tournamentState = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_nameController.text.isEmpty || _selectedSportId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
              return;
            }
          } else if (_currentStep == 1) {
            if (_startDate == null || _endDate == null || _locationController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
              return;
            }
            if (_startDate!.isAfter(_endDate!)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start date must be before end date')));
              return;
            }
          }
          
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (tournamentState.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 2 ? 'Create Tournament' : 'Continue'),
                  ),
                const SizedBox(width: 8),
                if (_currentStep > 0 && !tournamentState.isLoading)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basics'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tournament Name'),
                ),
                const SizedBox(height: 16),
                sportsAsyncValue.when(
                  data: (sports) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Sport'),
                      value: _selectedSportId,
                      items: sports.map((sport) {
                        return DropdownMenuItem<int>(
                          value: sport['id'],
                          child: Text(sport['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSportId = val;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Venue'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if (d != null) setState(() => _startDate = d);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: _startDate ?? DateTime.now(), lastDate: DateTime(2030));
                        if (d != null) setState(() => _endDate = d);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Location/Address'),
                      ),
                    ),
                    IconButton(
                      icon: _isGettingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                      onPressed: _getLocation,
                      color: GoAthleteColors.athleticOrange,
                    )
                  ],
                )
              ],
            ),
          ),
          Step(
            title: const Text('Rules'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                TextField(
                  controller: _maxTeamsController,
                  decoration: const InputDecoration(labelText: 'Max Teams (e.g., 16)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _entryFeeController,
                  decoration: const InputDecoration(labelText: 'Entry Fee (e.g., ₹500/team)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tournament Format'),
                  value: _format,
                  items: const [
                    DropdownMenuItem(value: 'Knockout', child: Text('Knockout')),
                    DropdownMenuItem(value: 'League', child: Text('League (Round-Robin)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _format = val);
                  },
                ),
                if (tournamentState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(tournamentState.error!, style: const TextStyle(color: Colors.red)),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
