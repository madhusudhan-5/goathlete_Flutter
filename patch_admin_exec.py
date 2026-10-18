import re

with open('goathlete_workspace/apps/admin_console/lib/screens/executive_screen.dart', 'r') as f:
    content = f.read()

old_button = """ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executive registered successfully!')));
              ref.invalidate(executivesProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
            child: const Text('Register'),
          ),"""

new_button = """ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                final parts = nameCtrl.text.split(' ');
                final firstName = parts.isNotEmpty ? parts[0] : '';
                final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                
                await dio.post('users/executives/', data: {
                  'first_name': firstName,
                  'last_name': lastName,
                  'username': emailCtrl.text,
                  'email': emailCtrl.text,
                  'profile': {
                    'phone_number': phoneCtrl.text
                  }
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executive registered successfully! Password is Test@12345 by default.')));
                }
                ref.invalidate(executivesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
            child: const Text('Register'),
          ),"""

content = content.replace(old_button, new_button)

# Also need to add dioProvider import if missing
if 'import \'package:admin_console/providers/network_provider.dart\';' not in content:
    content = "import 'package:admin_console/providers/network_provider.dart';\n" + content

with open('goathlete_workspace/apps/admin_console/lib/screens/executive_screen.dart', 'w') as f:
    f.write(content)

