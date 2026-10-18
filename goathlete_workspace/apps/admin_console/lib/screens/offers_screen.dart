import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class PromotionalOffersScreen extends ConsumerWidget {
  final bool showAppBar;
  const PromotionalOffersScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(promotionalOffersProvider);

    final content = offersAsync.when(
      data: (offers) {
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
                      Text('Promotional Offers & Coupons', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Create and manage discount promo codes and tournament vouchers.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateOfferDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Promo Code'),
                    style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (offers.isEmpty)
                const Expanded(
                  child: Center(child: Text('No promotional offers available.')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: offers.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF3E0),
                            child: Icon(Icons.local_offer, color: GoAthleteColors.athleticOrange),
                          ),
                          title: Text(offer['code'] ?? 'PROMO', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          subtitle: Text(offer['title'] ?? (offer['discount_percent'] != null ? '${offer['discount_percent']}% Off' : '₹${offer['discount_amount'] ?? 50} Off')),
                          trailing: Chip(
                            label: Text(offer['is_active'] == true ? 'Active' : 'Inactive', style: TextStyle(color: offer['is_active'] == true ? Colors.green : Colors.grey)),
                            backgroundColor: offer['is_active'] == true ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
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
      error: (error, stack) => Center(child: Text('Error: $error')),
    );

    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promotional Offers'), backgroundColor: GoAthleteColors.athleticOrange),
        body: content,
      );
    }
    return content;
  }

  void _showCreateOfferDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final discCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Promotional Coupon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SPORT20)')),
            const SizedBox(height: 12),
            TextField(controller: discCtrl, decoration: const InputDecoration(labelText: 'Discount % or Flat ₹')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created!')));
              ref.invalidate(promotionalOffersProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
