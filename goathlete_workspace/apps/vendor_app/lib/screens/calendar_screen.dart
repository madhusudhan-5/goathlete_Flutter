import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/vendor_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;
  
  // Note: For a multi-venue vendor, they would pick a venue from a dropdown here. 
  // We'll assume a hardcoded venue ID for scaffolding purposes which can be wired dynamically later.
  final int _selectedVenueId = 1; 

  Future<void> _createBooking() async {
    setState(() { _isSubmitting = true; });
    final data = {
      'venue': _selectedVenueId,
      'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
    };

    try {
      await ref.read(vendorCreateBookingProvider(data).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual slot booked/blocked successfully!')),
        );
        ref.refresh(vendorDashboardProvider);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slot Management'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Manually add walk-in bookings or block slots for maintenance.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() { _selectedDate = picked; });
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Start Time: ${_startTime.format(context)}'),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                  if (picked != null) setState(() { _startTime = picked; });
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: Text('End Time: ${_endTime.format(context)}'),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _endTime);
                  if (picked != null) setState(() { _endTime = picked; });
                },
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createBooking,
              style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Block Slot', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
