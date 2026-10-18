import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';
import '../providers/tournament_provider.dart';

class UserSearchPickerModal extends ConsumerStatefulWidget {
  final String title;
  final String hintText;
  final String? sport;
  final ValueChanged<Map<String, dynamic>> onUserSelected;

  const UserSearchPickerModal({
    super.key,
    required this.title,
    this.hintText = 'Search by GOATH-ID, Phone, or Name',
    this.sport,
    required this.onUserSelected,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String title,
    String hintText = 'Search by GOATH-ID, Phone, or Name',
    String? sport,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => UserSearchPickerModal(
        title: title,
        hintText: hintText,
        sport: sport,
        onUserSelected: (user) => Navigator.pop(ctx, user),
      ),
    );
  }

  @override
  ConsumerState<UserSearchPickerModal> createState() => _UserSearchPickerModalState();
}

class _UserSearchPickerModalState extends ConsumerState<UserSearchPickerModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userLookupProvider(_searchQuery));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (widget.sport != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Target Sport: ${widget.sport}',
                        style: const TextStyle(fontSize: 12, color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: GoAthleteColors.athleticOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Scan Athlete QR Code',
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () async {
                    final scannedCode = await context.push('/qr-scanner');
                    if (scannedCode != null && scannedCode is String && mounted) {
                      _searchController.text = scannedCode;
                      setState(() {
                        _searchQuery = scannedCode;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _searchQuery.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Type name, phone, or GOATH-ID to find registered athletes',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : searchResults.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_off, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'No athlete found for "$_searchQuery"',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final user = users[idx] as Map<String, dynamic>;
                          final name = user['name'] ?? 'Athlete';
                          final sport = user['primary_sport'] ?? 'Sport';
                          final skill = user['skill_level'] ?? 5;
                          final isSportMatch = widget.sport != null && sport.toString().toLowerCase().contains(widget.sport!.toLowerCase());

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: GoAthleteColors.athleticOrange,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                if (isSportMatch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Sport Match', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('ID: ${user['goath_id']} • ${user['phone_number']}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$sport • Level $skill/10',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GoAthleteColors.athleticOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => widget.onUserSelected(user),
                              child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: GoAthleteColors.athleticOrange)),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
