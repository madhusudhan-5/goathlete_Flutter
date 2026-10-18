import re

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'r') as f:
    content = f.read()

# Replace dummy edit details
content = content.replace('''ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening turf configuration.')));
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Details'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                ),''', '''ElevatedButton.icon(
                                  onPressed: () {
                                    _showEditVenueDialog(context, ref, v);
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Details'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                ),''')

# Add the dialog method and change PartnerVenuesTab
venues_tab_class = '''class PartnerVenuesTab extends ConsumerWidget {
  const PartnerVenuesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.teal.shade700,
            indicatorColor: Colors.teal.shade700,
            tabs: const [
              Tab(text: 'Venues'),
              Tab(text: 'Rental Items'),
              Tab(text: 'Turf Partners'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVenuesList(context, ref),
                const PartnerRentalItemsView(),
                const PartnerVendorPartnersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuesList(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(partnerVenuesProvider);

    return venuesAsync.when(
'''

venues_tab_end = '''  void _showEditVenueDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> venue) {
    final descController = TextEditingController(text: venue['description'] ?? '');
    final priceController = TextEditingController(text: venue['price_per_hour']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Venue Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price Per Hour'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('venues/vendor-venues/${venue['id']}/', data: {
                  'description': descController.text,
                  'price_per_hour': double.tryParse(priceController.text),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerVenuesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue updated successfully')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update venue: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
'''

content = re.sub(
    r'class PartnerVenuesTab extends ConsumerWidget \{.*?return venuesAsync\.when\(',
    venues_tab_class,
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'      error: \(e, _\) => Center\(child: Text\(\'Error: \$e\'\)\),\n    \);\n  \}\n\}',
    r'      error: (e, _) => Center(child: Text(\'Error: $e\')),\n    );\n  }\n\n' + venues_tab_end,
    content,
    flags=re.DOTALL
)

# Add Rental Items and Turf Partners view
new_views = '''
// -------------------------------------------------------------
// PARTNER RENTAL ITEMS
// -------------------------------------------------------------

final partnerRentalItemsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/rental-items/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class PartnerRentalItemsView extends ConsumerWidget {
  const PartnerRentalItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(partnerRentalItemsProvider);

    return asyncData.when(
      data: (items) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rental Items', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rental Item'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['name'] ?? 'Item'),
                        subtitle: Text('Price: ₹${item['price']} | Qty: ${item['total_quantity']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    final venues = ref.read(partnerVenuesProvider).value ?? [];
    int? selectedVenueId = venues.isNotEmpty ? venues.first['id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Rental Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedVenueId,
                  items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                  onChanged: (val) => setState(() => selectedVenueId = val),
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Total Quantity'), keyboardType: TextInputType.number),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('venues/rental-items/', data: {
                      'venue': selectedVenueId,
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'total_quantity': int.tryParse(qtyController.text) ?? 1,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(partnerRentalItemsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added')));
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}

// -------------------------------------------------------------
// PARTNER VENDOR PARTNERS
// -------------------------------------------------------------

final partnerVendorPartnersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/vendor-partners/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class PartnerVendorPartnersView extends ConsumerWidget {
  const PartnerVendorPartnersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(partnerVendorPartnersProvider);

    return asyncData.when(
      data: (partners) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Turf Partners', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Partner'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final p = partners[index];
                    return Card(
                      child: ListTile(
                        title: Text(p['user_email'] ?? 'Unknown'),
                        subtitle: Text('Role: ${p['role']} | Venue: ${p['venue_name'] ?? p['venue']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    String role = 'MANAGER';
    
    final venues = ref.read(partnerVenuesProvider).value ?? [];
    int? selectedVenueId = venues.isNotEmpty ? venues.first['id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Turf Partner'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedVenueId,
                  items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                  onChanged: (val) => setState(() => selectedVenueId = val),
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'User Email')),
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['CO_OWNER', 'MANAGER', 'STAFF'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => role = val!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('venues/vendor-partners/', data: {
                      'venue': selectedVenueId,
                      'user_email': emailController.text,
                      'role': role,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(partnerVendorPartnersProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner added')));
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}
'''

content = content.replace('// -------------------------------------------------------------\n// PARTNER SLOT PRICING TAB', new_views + '\n// -------------------------------------------------------------\n// PARTNER SLOT PRICING TAB')

# Slot pricing tab
slot_tab_new = '''
class PartnerSlotPricingTab extends ConsumerStatefulWidget {
  const PartnerSlotPricingTab({super.key});

  @override
  ConsumerState<PartnerSlotPricingTab> createState() => _PartnerSlotPricingTabState();
}

class _PartnerSlotPricingTabState extends ConsumerState<PartnerSlotPricingTab> {
  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(partnerVenuesProvider);

    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const Center(child: Text('No venues available.'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue['name'] ?? 'Venue', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.teal),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Base Price Per Hour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Container(
                          width: 140,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '₹${venue['price_per_hour'] ?? 0} / hr',
                            style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            _showEditPriceDialog(context, ref, venue);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> venue) {
    final priceController = TextEditingController(text: venue['price_per_hour']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Base Price for ${venue['name']}'),
        content: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price Per Hour'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('venues/vendor-venues/${venue['id']}/', data: {
                  'price_per_hour': double.tryParse(priceController.text),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerVenuesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price updated successfully')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update price: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
'''

content = re.sub(
    r'class PartnerSlotPricingTab extends StatefulWidget \{.*?\}\n\}\n',
    slot_tab_new,
    content,
    flags=re.DOTALL
)

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'w') as f:
    f.write(content)
