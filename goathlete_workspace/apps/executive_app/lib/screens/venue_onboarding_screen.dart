import 'dart:convert';
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

  // Step 5 Controllers (Ground Type, License & Sports Pricing)
  final _licenseController = TextEditingController();
  final _sportsPricesController = TextEditingController();

  static const List<String> _groundTypes = [
    'Artificial Turf',
    'Natural Grass',
    'Indoor Wooden Court',
    'Synthetic / Acrylic Court',
    'Clay Court',
    'Concrete / Hard Court',
    'Swimming Pool',
    'Indoor Arena / Hall',
    'Other',
  ];

  static const List<String> _availableSports = [
    'Box Cricket',
    'Cricket',
    'Football',
    'Badminton',
    'Pickleball',
    'Tennis',
    'Basketball',
    'Volleyball',
    'Table Tennis',
    'Padel',
    'Squash',
    'Swimming',
    'Kabaddi',
  ];

  String _selectedGroundType = 'Artificial Turf';
  final Map<String, TextEditingController> _sportPriceControllers = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _licenseController.dispose();
    _sportsPricesController.dispose();
    for (final c in _sportPriceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

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
    if (_meetingDate != null) data['meeting_date'] = _meetingDate!.toIso8601String();
    if (_notesController.text.isNotEmpty) data['meeting_notes'] = _notesController.text;
    data['ground_type'] = _selectedGroundType;
    if (_licenseController.text.isNotEmpty) data['license_number'] = _licenseController.text.trim();

    if (_sportPriceControllers.isNotEmpty) {
      final Map<String, dynamic> sportsMap = {};
      _sportPriceControllers.forEach((sport, ctrl) {
        final raw = ctrl.text.trim();
        final parsed = double.tryParse(raw);
        sportsMap[sport] = parsed ?? (raw.isNotEmpty ? raw : 0);
      });
      data['sports_prices'] = jsonEncode(sportsMap);
    } else if (_sportsPricesController.text.isNotEmpty) {
      data['sports_prices'] = _sportsPricesController.text.trim();
    }
    
    try {
      await ref.read(
        venueSubmitProvider(
          VenueSubmissionPayload(
            fields: data,
            imageFiles: List<XFile>.from(_selectedFiles),
          ),
        ).future,
      );
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
          if (_currentStep < 4) {
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
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
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
          Step(
            title: const Text('Ground, License & Sports'),
            isActive: _currentStep >= 4,
            state: _currentStep == 4 ? StepState.editing : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedGroundType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ground / Surface Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _groundTypes
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedGroundType = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License / Registration Number',
                    hintText: 'e.g. Trade License / GST / Sports Club ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Available Sports',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _availableSports.map((sport) {
                    final isSelected = _sportPriceControllers.containsKey(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: isSelected,
                      selectedColor: GoAthleteColors.athleticOrange.withValues(alpha: 0.22),
                      checkmarkColor: GoAthleteColors.athleticOrange,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _sportPriceControllers[sport] = TextEditingController();
                          } else {
                            _sportPriceControllers.remove(sport)?.dispose();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_sportPriceControllers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Hourly Price per Sport (₹/hr)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._sportPriceControllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: entry.value,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '${entry.key} — Price / hr (₹)',
                          hintText: 'e.g. 1200',
                          prefixText: '₹ ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _sportsPricesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Sports / Pricing Notes (Optional)',
                    hintText: 'Any extra sports or custom peak/off-peak notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
