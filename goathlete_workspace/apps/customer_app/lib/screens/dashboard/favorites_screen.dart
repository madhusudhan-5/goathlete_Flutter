import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Saved Favorites'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbb2639446?auto=format&fit=crop&w=300&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Smash It Turf', style: Theme.of(context).textTheme.titleMedium),
                              const Icon(Icons.favorite, color: Colors.red, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Football, Cricket', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 16),
                              Text(' 4.8', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(width: 12),
                              Text('1.2 km', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
