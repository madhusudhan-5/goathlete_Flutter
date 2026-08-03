import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class PlayTribesScreen extends StatelessWidget {
  const PlayTribesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Play Tribes'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {}, // Create new tribe
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: GoAthleteColors.athleticOrange,
              labelColor: GoAthleteColors.athleticOrange,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'My Tribes'),
                Tab(text: 'Discover'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyTribes(context),
                  _buildDiscoverTribes(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTribes(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildTribeCard(
          context,
          'HSR Football Freaks',
          '24 Members • Football',
          'Next game: Tomorrow, 6:00 PM',
          true,
        );
      },
    );
  }

  Widget _buildDiscoverTribes(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildTribeCard(
          context,
          'Weekend Smashers ${index + 1}',
          '1${index} Members • Badminton',
          'Open to All',
          false,
        );
      },
    );
  }

  Widget _buildTribeCard(BuildContext context, String name, String subtitle, String info, bool isMember) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=200&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GoAthleteColors.athleticOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(info, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GoAthleteColors.athleticOrange)),
                  ),
                ],
              ),
            ),
            if (!isMember)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Join'),
              ),
            if (isMember)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
  }
}
