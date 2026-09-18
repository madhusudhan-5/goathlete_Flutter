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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No Tribes Joined',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a Play Tribe to connect and split match costs with local players.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTribes(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No Tribes in Your Area',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a sports tribe in your local area!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

