with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'r') as f:
    content = f.read()

import re

old_catch = """catch (e) {
    return [
      {
        'id': 101,
        'business_name': 'HSR AstroTurf Arena',
        'owner_name': 'Vikram Rathore',
        'phone_number': '+91 98844 11223',
        'address': 'Sector 2, HSR Layout, Bengaluru',
        'sport_types': ['Football', 'Cricket'],
        'status': 'PENDING_APPROVAL',
        'created_at': '2026-09-18',
      },
      {
        'id': 102,
        'business_name': 'Smash Badminton Academy',
        'owner_name': 'Pooja Hegde',
        'phone_number': '+91 97722 33445',
        'address': 'Indiranagar 1st Stage, Bengaluru',
        'sport_types': ['Badminton'],
        'status': 'PENDING_APPROVAL',
        'created_at': '2026-09-19',
      }
    ];
  }"""

new_catch = """catch (e) {
    return [];
  }"""

content = content.replace(old_catch, new_catch)

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'w') as f:
    f.write(content)
