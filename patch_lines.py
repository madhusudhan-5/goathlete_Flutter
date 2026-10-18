with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "r") as f:
    lines = f.readlines()

new_block = """    // Compile teams dropdown list
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
    });\n"""

lines[161:181] = [new_block]

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "w") as f:
    f.writelines(lines)
