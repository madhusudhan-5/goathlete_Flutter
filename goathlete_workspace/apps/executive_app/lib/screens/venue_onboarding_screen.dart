import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/venue_provider.dart';

class VenueOnboardingScreen extends ConsumerStatefulWidget {
  const VenueOnboardingScreen({super.key});

  @override
  ConsumerState<VenueOnboardingScreen> createState() => _VenueOnboardingScreenState();
}

class _VenueOnboardingScreenState extends ConsumerState<VenueOnboardingScreen> {
  int _currentStep = 0;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 2 Controllers
  final _addressController = TextEditingController();

  // Step 4 Controllers
  final _notesController = TextEditingController();
  DateTime? _meetingDate;

  bool _isSubmitting = false;

  Future<void> _submitData() async {
    setState(() { _isSubmitting = true; });
    final data = {
      'name': _nameController.text,
      'owner_name': _ownerController.text,
      'phone_number': _phoneController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'meeting_date': _meetingDate?.toIso8601String(),
      'meeting_notes': _notesController.text,
    };
    
    try {
      await ref.read(venueSubmitProvider(data).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue Pre-Registered successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Venue Onboarding'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            _submitData();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
        steps: [
          Step(
            title: const Text('Basic Details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Venue Name'),
                ),
                TextField(
                  controller: _ownerController,
                  decoration: const InputDecoration(labelText: 'Owner Name'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Location'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    suffixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Auto-fetch GPS Coordinates'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Media & Documents'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                const Text('Upload venue photos and KYC documents.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Files'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Meeting Schedule'),
            isActive: _currentStep >= 3,
            state: _currentStep == 3 ? StepState.editing : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_meetingDate == null ? 'No Date Chosen' : '${_meetingDate!.toLocal()}'.split(' ')[0]),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() {
                            _meetingDate = picked;
                          });
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Meeting Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSubmitting ? const CircularProgressIndicator() : null,
    );
  }
}
