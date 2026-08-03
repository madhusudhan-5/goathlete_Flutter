import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class GlobalConfigurationScreen extends ConsumerStatefulWidget {
  const GlobalConfigurationScreen({super.key});

  @override
  ConsumerState<GlobalConfigurationScreen> createState() => _GlobalConfigurationScreenState();
}

class _GlobalConfigurationScreenState extends ConsumerState<GlobalConfigurationScreen> {
  final _commissionController = TextEditingController();
  final _payoutController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _isSaving = false;
  bool _isInitialized = false;

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'commission_percentage': _commissionController.text,
        'payout_cycle_days': _payoutController.text,
        'minimum_payout_threshold': _thresholdController.text,
      };
      await ref.read(updateGlobalConfigProvider(data).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully!')),
        );
        ref.refresh(globalConfigProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(globalConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Configurations'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: configAsync.when(
        data: (config) {
          if (!_isInitialized) {
            _commissionController.text = config['commission_percentage']?.toString() ?? '';
            _payoutController.text = config['payout_cycle_days']?.toString() ?? '';
            _thresholdController.text = config['minimum_payout_threshold']?.toString() ?? '';
            _isInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  const Text('Platform Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _commissionController,
                    decoration: const InputDecoration(
                      labelText: 'Platform Commission (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _payoutController,
                    decoration: const InputDecoration(
                      labelText: 'Payout Cycle (Days)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _thresholdController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Payout Threshold (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Configuration', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
