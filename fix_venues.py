import re

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'r') as f:
    content = f.read()

original_tab_and_list = """
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

  Widget _buildVenuesList(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(partnerVenuesProvider);

    return venuesAsync.when(

      data: (venues) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Sports Venues & Pitches', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Manage court dimensions, pitch surface specifications, and player amenities.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue creation wizard opened.')));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Venue / Court'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: venues.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final v = venues[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.sports_soccer, size: 40, color: Colors.teal.shade700),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(v['name'] ?? 'Sports Arena', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Chip(
                                        label: Text('★ ${v['rating'] ?? '4.8'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        backgroundColor: Colors.amber.shade100,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(v['address'] ?? 'Bengaluru, India', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(label: Text(v['sport'] ?? 'Football / Cricket'), visualDensity: VisualDensity.compact),
                                      Chip(label: Text('${v['total_courts'] ?? 2} Courts Available'), visualDensity: VisualDensity.compact),
                                      Chip(label: Text('Base: ₹${v['price_per_hour'] ?? 1000}/hr'), visualDensity: VisualDensity.compact),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showEditVenueDialog(context, ref, v);
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Details'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  void _showEditVenueDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> venue) {
"""

new_content = re.sub(
    r'class PartnerVenuesTab extends ConsumerWidget \{.*?void _showEditVenueDialog\(BuildContext context, WidgetRef ref, Map<String, dynamic> venue\) \{',
    original_tab_and_list,
    content,
    flags=re.DOTALL
)

with open('goathlete_workspace/apps/admin_console/lib/screens/partner/partner_shell.dart', 'w') as f:
    f.write(new_content)
