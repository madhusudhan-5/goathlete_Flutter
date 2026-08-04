import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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

  double? _latitude;
  double? _longitude;
  List<XFile> _selectedFiles = [];

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_addressController.text.isEmpty) {
          _addressController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location fetched successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching location: $e')));
    }
  }

  Future<void> _pickFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images);
      });
    }
  }

  Future<void> _submitData() async {
    setState(() { _isSubmitting = true; });
    final data = <String, dynamic>{
      'name': _nameController.text,
      'owner_name': _ownerController.text,
      'phone_number': _phoneController.text,
    };
    if (_emailController.text.isNotEmpty) data['email'] = _emailController.text;
    if (_addressController.text.isNotEmpty) data['address'] = _addressController.text;
    if (_latitude != null) data['latitude'] = _latitude!.toStringAsFixed(6);
    if (_longitude != null) data['longitude'] = _longitude!.toStringAsFixed(6);
    if (_selectedFiles.isNotEmpty) data['document_url'] = 'https://dummy-storage.goathlete.com/${_selectedFiles.first.name}';
    if (_meetingDate != null) data['meeting_date'] = _meetingDate!.toIso8601String();
    if (_notesController.text.isNotEmpty) data['meeting_notes'] = _notesController.text;
    
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
                  onPressed: _fetchLocation,
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
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Files'),
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _selectedFiles.map((f) => Chip(
                      label: Text(f.name, style: const TextStyle(fontSize: 12)),
                      onDeleted: () {
                        setState(() {
                          _selectedFiles.remove(f);
                        });
                      },
                    )).toList(),
                  )
                ]
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
