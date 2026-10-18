with open('goathlete_workspace/apps/admin_console/lib/screens/executive_screen.dart', 'r') as f:
    content = f.read()

import re

old_trailing = """trailing: Chip(
                            label: Text(exec['is_active'] == true ? 'Active' : 'Pending', style: TextStyle(color: exec['is_active'] == true ? Colors.green : Colors.grey)),
                            backgroundColor: exec['is_active'] == true ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                          ),"""

new_trailing = """trailing: Switch(
                            value: exec['is_active'] == true,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              try {
                                final dio = ref.read(dioProvider);
                                await dio.patch('users/executives/${exec['id']}/', data: {'is_active': val});
                                ref.invalidate(executivesProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                }
                              }
                            },
                          ),"""

content = content.replace(old_trailing, new_trailing)

with open('goathlete_workspace/apps/admin_console/lib/screens/executive_screen.dart', 'w') as f:
    f.write(content)
