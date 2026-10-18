import re

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "r") as f:
    content = f.read()

# 1. Fix Venue Dropdown __CUSTOM__
content = content.replace(
    "Text('+ Enter Custom Venue / Ground', style: TextStyle(fontWeight: FontWeight.bold, color: GoAthleteColors.athleticOrange)),",
    "Expanded(child: Text('+ Enter Custom Venue / Ground', style: TextStyle(fontWeight: FontWeight.bold, color: GoAthleteColors.athleticOrange), overflow: TextOverflow.ellipsis)),"
)

# 2. Fix Team Catalog Dropdown
content = content.replace(
"""                                    Text(
                                      teamName,
                                      style: TextStyle(
                                        fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.bold,
                                        color: isAlreadyAdded ? Colors.grey : null,
                                      ),
                                    ),""",
"""                                    Expanded(
                                      child: Text(
                                        teamName,
                                        style: TextStyle(
                                          fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.bold,
                                          color: isAlreadyAdded ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),"""
)

# 3. Fix RadioListTile Row
old_radio = """                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Knockout', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Single elimination', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                        value: 'Knockout',
                        groupValue: _format,
                        onChanged: (val) => setState(() => _format = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('League', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Round-Robin', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                        value: 'League',
                        groupValue: _format,
                        onChanged: (val) => setState(() => _format = val!),
                      ),
                    ),
                  ],
                ),"""

new_radio = """                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Knockout', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Single elimination', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                      value: 'Knockout',
                      groupValue: _format,
                      onChanged: (val) => setState(() => _format = val!),
                    ),
                    RadioListTile<String>(
                      title: const Text('League', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Round-Robin', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                      value: 'League',
                      groupValue: _format,
                      onChanged: (val) => setState(() => _format = val!),
                    ),
                  ],
                ),"""

content = content.replace(old_radio, new_radio)

with open("goathlete_workspace/apps/customer_app/lib/screens/organizer/create_tournament_wizard.dart", "w") as f:
    f.write(content)
