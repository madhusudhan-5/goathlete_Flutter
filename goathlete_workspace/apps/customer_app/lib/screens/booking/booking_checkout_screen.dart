import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/booking_provider.dart';
import 'components/mock_payment_gateway.dart';

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final venue = flowState.venue ?? {};
    final venueName = venue['name'] ?? 'Unknown Venue';
    final pricePerHour = double.tryParse(venue['price_per_hour']?.toString() ?? '0') ?? 0.0;
    
    // MVP: assume 1 hour duration
    final platformFee = 20.0;
    final gst = pricePerHour * 0.18;
    final total = pricePerHour + platformFee + gst;

    final date = flowState.date ?? 'Unknown Date';
    final startTime = flowState.startTime ?? '00:00:00';
    final endTime = flowState.endTime ?? '00:00:00';
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
                      Text(venueName, style: Theme.of(context).textTheme.titleLarge),
                      const Icon(Icons.sports_soccer, color: GoAthleteColors.athleticOrange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Turf Booking', style: Theme.of(context).textTheme.bodyMedium),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: GoAthleteColors.athleticOrange),
                      const SizedBox(width: 12),
                      Text(date, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: GoAthleteColors.athleticOrange),
                      const SizedBox(width: 12),
                      Text('$startTime - $endTime', style: Theme.of(context).textTheme.titleMedium),
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
                  _buildPriceRow(context, 'Turf Booking', '₹${pricePerHour.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildPriceRow(context, 'Platform Fee', '₹${platformFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildPriceRow(context, 'GST (18%)', '₹${gst.toStringAsFixed(2)}'),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Payable', style: Theme.of(context).textTheme.titleLarge),
                      Text('₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold)),
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
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final venueId = venue['id'];
                  
                  final response = await ref.read(bookingProvider.notifier).createPaymentIntent(
                    venueId,
                    date,
                    startTime,
                    endTime,
                  );
                  
                  setState(() => _isLoading = false);

                  if (response != null && mounted) {
                    _showPaymentGateway(context, total, response['payment_id'], response['clientSecret']);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initiate booking.')));
                  }
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: GoAthleteColors.deepNavy,
          ),
          child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm & Pay', style: TextStyle(fontSize: 16)),
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

  void _showPaymentGateway(BuildContext context, double total, int paymentId, String clientSecret) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MockPaymentGateway(
        amount: total,
        clientSecret: clientSecret,
        onPaymentSuccess: (transactionId) async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          final success = await ref.read(bookingProvider.notifier).confirmPayment(paymentId, transactionId);
          setState(() => _isLoading = false);
          
          if (success && mounted) {
            _showSuccessDialog(context);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed or could not be verified.')));
          }
        },
      ),
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
                  'Your slot has been successfully booked.',
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
