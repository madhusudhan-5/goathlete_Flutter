import re

with open('goathlete_workspace/apps/customer_app/lib/screens/dashboard/tournaments_screen.dart', 'r') as f:
    content = f.read()

# Replace the text showing status
old_status_text = """Text(
                            status == 'Ongoing' ? '🔴 LIVE: $scoreText' : 'Status: $status',
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'Ongoing' ? Colors.green[800] : Colors.grey[700],
                              fontWeight: status == 'Ongoing' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),"""

new_status_text = """Text(
                            status == 'Ongoing' ? '🔴 LIVE: $scoreText' : (status == 'Completed' ? 'Winner: ${m['winner_name'] ?? 'TBD'} ($scoreText)' : 'Status: $status'),
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'Ongoing' ? Colors.green[800] : Colors.grey[700],
                              fontWeight: status == 'Ongoing' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),"""
content = content.replace(old_status_text, new_status_text)

# Replace the button
old_button = """ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'Ongoing' ? Colors.green : GoAthleteColors.athleticOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        context.push('/live-scorer/${m['id']}');
                      },
                      child: Text(
                        status == 'Ongoing' ? 'Live Score' : 'Open Match',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )"""

new_button = """if (status != 'Completed')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'Ongoing' ? Colors.green : GoAthleteColors.athleticOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          context.push('/live-scorer/${m['id']}');
                        },
                        child: Text(
                          status == 'Ongoing' ? 'Live Score' : 'Open Match',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )"""
content = content.replace(old_button, new_button)

with open('goathlete_workspace/apps/customer_app/lib/screens/dashboard/tournaments_screen.dart', 'w') as f:
    f.write(content)
