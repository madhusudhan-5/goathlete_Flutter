with open('lib/screens/executive_screen.dart', 'r') as f:
    content = f.read()

if 'import \'package:admin_console/network/api_client.dart\';' not in content:
    content = "import 'package:admin_console/network/api_client.dart';\n" + content

with open('lib/screens/executive_screen.dart', 'w') as f:
    f.write(content)
