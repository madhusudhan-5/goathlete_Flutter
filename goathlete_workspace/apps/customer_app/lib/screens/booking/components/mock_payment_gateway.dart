import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class MockPaymentGateway extends StatefulWidget {
  final double amount;
  final String clientSecret;
  final Function(String transactionId) onPaymentSuccess;

  const MockPaymentGateway({
    super.key,
    required this.amount,
    required this.clientSecret,
    required this.onPaymentSuccess,
  });

  @override
  State<MockPaymentGateway> createState() => _MockPaymentGatewayState();
}

class _MockPaymentGatewayState extends State<MockPaymentGateway> {
  final _transactionController = TextEditingController(text: 'test_tx_12345');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mock Payment (Dev)', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Amount to pay: ₹${widget.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: GoAthleteColors.athleticOrange),
          ),
          const SizedBox(height: 24),
          const Text('Enter a mock transaction ID to simulate a successful payment. This will be replaced by Stripe in Production.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _transactionController,
            decoration: const InputDecoration(
              labelText: 'Mock Transaction ID',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_transactionController.text.trim().isEmpty) return;
                widget.onPaymentSuccess(_transactionController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GoAthleteColors.athleticOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simulate Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
