import re

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "r") as f:
    content = f.read()

# 1. Remove hardcoded teams and only add if they have players
old_teams_init = """    // Compile teams dropdown list
    final List<String> teamOptions = [
      'Thunder FC',
      'Royal Strikers',
      'Phoenix SC',
      'Titan Warriors',
      'Apex Legends',
    ];
    allTeamsAsync.whenData((registeredTeams) {
      for (final t in registeredTeams) {
        final tName = t['name'] as String?;
        if (tName != null && tName.isNotEmpty && !teamOptions.contains(tName)) {
          teamOptions.add(tName);
        }
      }
    });"""

new_teams_init = """    // Compile teams dropdown list
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

content = content.replace(old_teams_init, new_teams_init)

# 2. Fix the label: "Select from Teams Dropdown or Add Custom Team" -> "Select from Teams Dropdown"
content = content.replace("'Select from Teams Dropdown or Add Custom Team'", "'Select from Teams Dropdown'")
content = content.replace("'Select teams from the catalog or type custom team names below.'", "'Select teams from the catalog.'")

# 3. Remove the New Team Name text field and add button
# I will use regex or find/replace to remove lines 488 to 514
start_str = """                    // Add custom team input
                    Row(
                      children: [
                        Expanded(
                          child: TextField("""
end_str = """                      ],
                    ),
                    const SizedBox(height: 10),"""

start_idx = content.find(start_str)
end_idx = content.find(end_str) + len(end_str)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx:]

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "w") as f:
    f.write(content)

print("Patched.")
