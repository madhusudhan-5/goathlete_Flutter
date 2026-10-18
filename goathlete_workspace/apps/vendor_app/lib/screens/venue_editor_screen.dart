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
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VendorPartnersScreen(venueId: _venueId!)));
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Manage Vendor Partners'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RentalItemsScreen(venueId: _venueId!)));
                  },
                  icon: const Icon(Icons.sports_tennis),
                  label: const Text('Manage Rental Items'),
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

class VendorPartnersScreen extends ConsumerStatefulWidget {
  final int venueId;
  const VendorPartnersScreen({super.key, required this.venueId});

  @override
  ConsumerState<VendorPartnersScreen> createState() => _VendorPartnersScreenState();
}

class _VendorPartnersScreenState extends ConsumerState<VendorPartnersScreen> {
  final _emailController = TextEditingController();

  Future<void> _addPartner() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await ref.read(addVendorPartnerProvider({'venue': widget.venueId, 'user_email': email, 'role': 'Manager'}).future);
      _emailController.clear();
      ref.invalidate(vendorPartnersProvider(widget.venueId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner added successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(vendorPartnersProvider(widget.venueId));
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Partners'), backgroundColor: GoAthleteColors.athleticOrange),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Partner Email'))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addPartner, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: partnersAsync.when(
              data: (partners) {
                if (partners.isEmpty) return const Center(child: Text('No partners found.'));
                return ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final p = partners[index];
                    return ListTile(
                      title: Text(p['user'] != null ? p['user']['email'] ?? 'Unknown' : 'Unknown'),
                      subtitle: Text(p['role'] ?? ''),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class RentalItemsScreen extends ConsumerStatefulWidget {
  final int venueId;
  const RentalItemsScreen({super.key, required this.venueId});

  @override
  ConsumerState<RentalItemsScreen> createState() => _RentalItemsScreenState();
}

class _RentalItemsScreenState extends ConsumerState<RentalItemsScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final stock = _stockController.text.trim();
    if (name.isEmpty || price.isEmpty || stock.isEmpty) return;
    try {
      await ref.read(addRentalItemProvider({
        'venue': widget.venueId,
        'name': name,
        'price_per_unit': price,
        'stock_quantity': stock,
      }).future);
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      ref.invalidate(rentalItemsProvider(widget.venueId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(rentalItemsProvider(widget.venueId));
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Items'), backgroundColor: GoAthleteColors.athleticOrange),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _addItem, child: const Text('Add Item')),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('No rental items found.'));
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['name'] ?? ''),
                      subtitle: Text('Price: \$${item['price_per_unit']} | Stock: ${item['stock_quantity']}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
