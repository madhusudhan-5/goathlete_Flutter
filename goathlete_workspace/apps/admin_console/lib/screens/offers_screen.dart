import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class PromotionalOffersScreen extends ConsumerWidget {
  const PromotionalOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(promotionalOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotional Offers'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return const Center(child: Text('No promotional offers available.'));
          }
          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_offer, color: GoAthleteColors.athleticOrange),
                  title: Text(offer['code'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(offer['discount_percent'] != null
                      ? '${offer['discount_percent']}% Off'
                      : '\$${offer['flat_discount']} Off'),
                  trailing: Switch(
                    value: offer['is_active'],
                    onChanged: (val) {
                      // Toggle active state
                    },
                    activeColor: GoAthleteColors.athleticOrange,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show add offer dialog
        },
        icon: const Icon(Icons.add),
        label: const Text('New Offer'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
    );
  }
}
