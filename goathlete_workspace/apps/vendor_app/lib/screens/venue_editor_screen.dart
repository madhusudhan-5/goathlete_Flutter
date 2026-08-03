import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/vendor_provider.dart';

class VenueEditorScreen extends ConsumerStatefulWidget {
  const VenueEditorScreen({super.key});

  @override
  ConsumerState<VenueEditorScreen> createState() => _VenueEditorScreenState();
}

class _VenueEditorScreenState extends ConsumerState<VenueEditorScreen> {
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  int? _venueId;
  String? _venueName;

  Future<void> _updateVenue() async {
    if (_venueId == null) return;
    setState(() { _isSubmitting = true; });
    
    final data = {
      'id': _venueId,
      'description': _descriptionController.text,
      'price_per_hour': _priceController.text,
    };

    try {
      await ref.read(vendorUpdateVenueProvider(data).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue updated successfully!')),
        );
        ref.refresh(vendorVenuesProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(vendorVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue Details'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: venuesAsync.when(
        data: (venues) {
          if (venues.isEmpty) {
            return const Center(child: Text('You have no active venues to edit.'));
          }
          
          if (_venueId == null) {
            final v = venues.first;
            _venueId = v['id'];
            _venueName = v['name'];
            _descriptionController.text = v['description'] ?? '';
            _priceController.text = v['price_per_hour']?.toString() ?? '';
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                Text('Editing: $_venueName', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description / Amenities',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price per Hour (\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateVenue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoAthleteColors.athleticOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
