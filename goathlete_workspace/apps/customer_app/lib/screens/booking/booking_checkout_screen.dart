import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';

class BookingCheckoutScreen extends StatelessWidget {
  const BookingCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Summary', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Smash It Turf', style: Theme.of(context).textTheme.titleLarge),
                      const Icon(Icons.sports_soccer, color: GoAthleteColors.athleticOrange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Football - 5v5', style: Theme.of(context).textTheme.bodyMedium),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: GoAthleteColors.athleticOrange),
                      const SizedBox(width: 12),
                      Text('24 Oct 2024', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: GoAthleteColors.athleticOrange),
                      const SizedBox(width: 12),
                      Text('6:00 PM - 7:00 PM', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Price Breakdown', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPriceRow(context, 'Turf Booking (1 hr)', '₹800.00'),
                  const SizedBox(height: 12),
                  _buildPriceRow(context, 'Platform Fee', '₹20.00'),
                  const SizedBox(height: 12),
                  _buildPriceRow(context, 'GST (18%)', '₹144.00'),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Payable', style: Theme.of(context).textTheme.titleLarge),
                      Text('₹964.00', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            _showSuccessDialog(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: GoAthleteColors.deepNavy,
          ),
          child: const Text('Confirm & Pay', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(amount, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 24),
                Text('Booking Confirmed!', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'Your slot at Smash It Turf has been successfully booked.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to home and remove all booking routes
                      context.go('/explore');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
