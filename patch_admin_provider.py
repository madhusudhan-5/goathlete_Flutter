with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'r') as f:
    content = f.read()

import re

# We want to replace the catch block in executivesProvider
old_catch = """catch (e) {
    return [
      {'id': 1, 'first_name': 'Arjun', 'last_name': 'Verma', 'goath_id': 'GOATH-EX-001', 'phone_number': '+91 98765 43210', 'email': 'arjun@goathlete.com', 'is_active': true},
      {'id': 2, 'first_name': 'Sneha', 'last_name': 'Patil', 'goath_id': 'GOATH-EX-002', 'phone_number': '+91 98765 43211', 'email': 'sneha@goathlete.com', 'is_active': true},
      {'id': 3, 'first_name': 'Rahul', 'last_name': 'Mehta', 'goath_id': 'GOATH-EX-003', 'phone_number': '+91 98765 43212', 'email': 'rahul@goathlete.com', 'is_active': false},
    ];
  }"""

new_catch = """catch (e) {
    return [];
  }"""

content = content.replace(old_catch, new_catch)

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'w') as f:
    f.write(content)
