import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  int _selectedDateIndex = 0;
  int _selectedSlotIndex = -1;

  final List<Map<String, String>> _dates = [
    {'day': 'Today', 'date': '24 Oct'},
    {'day': 'Tomorrow', 'date': '25 Oct'},
    {'day': 'Wed', 'date': '26 Oct'},
    {'day': 'Thu', 'date': '27 Oct'},
  ];

  final List<Map<String, dynamic>> _slots = [
    {'time': '5:00 PM - 6:00 PM', 'available': false},
    {'time': '6:00 PM - 7:00 PM', 'available': true},
    {'time': '7:00 PM - 8:00 PM', 'available': true},
    {'time': '8:00 PM - 9:00 PM', 'available': false},
    {'time': '9:00 PM - 10:00 PM', 'available': true},
    {'time': '10:00 PM - 11:00 PM', 'available': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Select Slot'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDateIndex = index;
                      _selectedSlotIndex = -1; // reset slot selection
                    }),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? GoAthleteColors.athleticOrange : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? GoAthleteColors.athleticOrange : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dates[index]['day']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dates[index]['date']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _slots.length,
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final isAvailable = slot['available'] as bool;
                final isSelected = _selectedSlotIndex == index;

                return GestureDetector(
                  onTap: isAvailable
                      ? () => setState(() => _selectedSlotIndex = index)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GoAthleteColors.athleticOrange.withOpacity(0.1)
                          : (isAvailable ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainerLowest),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? GoAthleteColors.athleticOrange
                            : (isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      slot['time'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? GoAthleteColors.athleticOrange
                            : (isAvailable ? Theme.of(context).colorScheme.onSurface : Colors.grey),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          onPressed: _selectedSlotIndex != -1
              ? () {
                  context.push('/booking-checkout');
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: GoAthleteColors.deepNavy,
          ),
          child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
