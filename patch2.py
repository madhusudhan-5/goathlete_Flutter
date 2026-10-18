import re

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "r") as f:
    content = f.read()

# Replace the entire block defining teamOptions
old_block_pattern = r"// Compile teams dropdown list.*?teamOptions\.add\(tName\);\s*}\s*}\s*}\s*\)"
new_block = """// Compile teams dropdown list
    final List<String> teamOptions = [];
    allTeamsAsync.whenData((registeredTeams) {
      for (final t in registeredTeams) {
        final tName = t['name'] as String?;
        final playersList = t['players'] as List?;
        if (tName != null && tName.isNotEmpty && !teamOptions.contains(tName)) {
          if (playersList != null && playersList.isNotEmpty) {
            teamOptions.add(tName);
          }
        }
      }
    });"""

content = re.sub(r"// Compile teams dropdown list\s*final List<String> teamOptions = \[\s*.*?\s*\];\s*allTeamsAsync\.whenData\(\(registeredTeams\) \{.*?\}\);\s*\}\);", new_block, content, flags=re.DOTALL)

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "w") as f:
    f.write(content)
