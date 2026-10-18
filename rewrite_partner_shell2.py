import re

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'r') as f:
    content = f.read()

venues_tab_repl = """
class PartnerVenuesTab extends ConsumerWidget {
  const PartnerVenuesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.teal.shade700,
            indicatorColor: Colors.teal.shade700,
            tabs: const [
              Tab(text: 'Venues'),
              Tab(text: 'Courts'),
              Tab(text: 'Rental Items'),
              Tab(text: 'Turf Partners'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVenuesList(context, ref),
                const PartnerCourtsView(),
                const PartnerRentalItemsView(),
                const PartnerVendorPartnersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
"""

content = re.sub(
    r'class PartnerVenuesTab extends ConsumerWidget \{.*?Widget build\(BuildContext context, WidgetRef ref\) \{.*?return DefaultTabController\(.*?length: 3,.*?children: \[.*?_buildVenuesList\(context, ref\),.*?const PartnerRentalItemsView\(\),.*?const PartnerVendorPartnersView\(\),.*?],.*?\},.*?\)?,.*?\},.*?\}',
    venues_tab_repl,
    content,
    flags=re.DOTALL
)

courts_view = """
class PartnerCourtsView extends ConsumerWidget {
  const PartnerCourtsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(partnerVenuesProvider).value ?? [];
    if (venues.isEmpty) return const Center(child: Text('No venues available.'));
    return PartnerCourtsList(venues: venues);
  }
}

class PartnerCourtsList extends ConsumerStatefulWidget {
  final List<dynamic> venues;
  const PartnerCourtsList({super.key, required this.venues});
  @override
  ConsumerState<PartnerCourtsList> createState() => _PartnerCourtsListState();
}

class _PartnerCourtsListState extends ConsumerState<PartnerCourtsList> {
  int? selectedVenueId;

  @override
  void initState() {
    super.initState();
    if (widget.venues.isNotEmpty) {
      selectedVenueId = widget.venues.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedVenueId == null) return const Center(child: Text('No venue selected.'));
    final courtsAsync = ref.watch(partnerCourtsProvider(selectedVenueId!));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: selectedVenueId,
                items: widget.venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                onChanged: (val) => setState(() => selectedVenueId = val),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddCourtDialog(context, ref, selectedVenueId!);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Court'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: courtsAsync.when(
              data: (courts) {
                return ListView.builder(
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return Card(
                      child: ListTile(
                        title: Text(court['name'] ?? 'Court'),
                        subtitle: Text('Sport: ${court['sport']}'),
                      ),
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

  void _showAddCourtDialog(BuildContext context, WidgetRef ref, int venueId) {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Court'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (e.g. Pitch 1)')),
            TextField(controller: sportController, decoration: const InputDecoration(labelText: 'Sport')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.post('venues/courts/', data: {
                  'venue': venueId,
                  'name': nameController.text,
                  'sport': sportController.text,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerCourtsProvider(venueId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Court added')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

// -------------------------------------------------------------
// PARTNER SLOT PRICING TAB
// -------------------------------------------------------------
"""

content = re.sub(
    r'// -------------------------------------------------------------\n// PARTNER SLOT PRICING TAB\n// -------------------------------------------------------------',
    courts_view,
    content
)


slot_pricing_tab_repl = """
class PartnerSlotPricingTab extends ConsumerStatefulWidget {
  const PartnerSlotPricingTab({super.key});

  @override
  ConsumerState<PartnerSlotPricingTab> createState() => _PartnerSlotPricingTabState();
}

class _PartnerSlotPricingTabState extends ConsumerState<PartnerSlotPricingTab> {
  int? selectedVenueId;
  int? selectedCourtId;

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(partnerVenuesProvider).value ?? [];
    if (venues.isEmpty) return const Center(child: Text('No venues available.'));

    selectedVenueId ??= venues.first['id'];

    final courtsAsync = ref.watch(partnerCourtsProvider(selectedVenueId!));

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Slot Pricing by Court', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<int>(
                value: selectedVenueId,
                items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedVenueId = val;
                    selectedCourtId = null;
                  });
                },
              ),
              const SizedBox(width: 24),
              courtsAsync.when(
                data: (courts) {
                  if (courts.isEmpty) return const Text('No courts available for this venue.');
                  if (selectedCourtId == null || !courts.any((c) => c['id'] == selectedCourtId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && selectedCourtId == null) {
                        setState(() {
                          selectedCourtId = courts.first['id'];
                        });
                      }
                    });
                  }
                  return DropdownButton<int>(
                    value: selectedCourtId,
                    items: courts.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCourtId = val;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (selectedCourtId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time Periods Pricing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddPricingDialog(context, ref, selectedCourtId!),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Period'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final pricings = ref.watch(partnerSlotPricingsProvider(selectedCourtId!));
                  return pricings.when(
                    data: (data) {
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final p = data[index];
                          return Card(
                            child: ListTile(
                              title: Text(p['time_period']),
                              subtitle: Text('${p['start_time']} - ${p['end_time']}'),
                              trailing: Text('₹${p['price']}'),
                              onTap: () => _showEditPricingDialog(context, ref, p),
                            ),
                          );
                        }
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                }
              )
            ),
          ]
        ],
      )
    );
  }

  void _showAddPricingDialog(BuildContext context, WidgetRef ref, int courtId) {
    String timePeriod = 'Morning';
    final startTimeController = TextEditingController(text: '06:00:00');
    final endTimeController = TextEditingController(text: '12:00:00');
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Time Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: timePeriod,
                items: ['Morning', 'Daytime', 'Evening', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => timePeriod = val!),
              ),
              TextField(controller: startTimeController, decoration: const InputDecoration(labelText: 'Start Time (HH:MM:SS)')),
              TextField(controller: endTimeController, decoration: const InputDecoration(labelText: 'End Time (HH:MM:SS)')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            ]
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('venues/court-slot-pricings/', data: {
                    'court': courtId,
                    'time_period': timePeriod,
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(partnerSlotPricingsProvider(courtId));
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            )
          ]
        )
      )
    );
  }

  void _showEditPricingDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> pricing) {
    final priceController = TextEditingController(text: pricing['price'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price for ${pricing['time_period']}'),
        content: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('venues/court-slot-pricings/${pricing['id']}/', data: {
                  'price': double.tryParse(priceController.text) ?? 0,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerSlotPricingsProvider(pricing['court']));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          )
        ]
      )
    );
  }
}
"""

content = re.sub(
    r'class PartnerSlotPricingTab extends ConsumerStatefulWidget \{.*?class _PartnerSlotPricingTabState extends ConsumerState<PartnerSlotPricingTab> \{.*?\n\}\n\n// -------------------------------------------------------------\n// PARTNER BOOKINGS TAB\n// -------------------------------------------------------------',
    slot_pricing_tab_repl + "\n// -------------------------------------------------------------\n// PARTNER BOOKINGS TAB\n// -------------------------------------------------------------",
    content,
    flags=re.DOTALL
)

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'w') as f:
    f.write(content)
