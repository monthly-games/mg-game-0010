import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../systems/dungeon_manager.dart';
import '../core/data/game_data.dart';

class DungeonScreen extends StatefulWidget {
  const DungeonScreen({super.key});

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  final DungeonManager _dungeonManager = GetIt.I<DungeonManager>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dungeonManager,
      builder: (context, child) {
        if (_dungeonManager.state == ExplorationState.exploring) {
          return _buildExploringView();
        } else if (_dungeonManager.state == ExplorationState.completed) {
          return _buildCompletedView();
        } else {
          return _buildSelectionView();
        }
      },
    );
  }

  Widget _buildSelectionView() {
    final dungeons = GameData.dungeons;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dungeons.length,
      itemBuilder: (context, index) {
        final dungeon = dungeons[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.terrain, size: 40),
            title: Text(dungeon.name),
            subtitle: Text(
                '${dungeon.description}\nTime: ${dungeon.durationSeconds}s'),
            trailing: ElevatedButton(
              onPressed: () {
                _dungeonManager.startExploration(dungeon);
              },
              child: const Text('Explore'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExploringView() {
    final dungeon = _dungeonManager.currentDungeon!;
    final remaining = _dungeonManager.remainingSeconds;
    final total = dungeon.durationSeconds;
    final progress = 1.0 - (remaining / total);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Exploring ${dungeon.name}...',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
          const SizedBox(height: 20),
          Text('$remaining s remaining', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
          TextButton(
              onPressed: () => _dungeonManager.cancelExploration(),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)))
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    final rewards = _dungeonManager.lastRewards;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 20),
          const Text('Exploration Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Rewards:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          if (rewards.isEmpty)
            const Text("No loot found...",
                style: TextStyle(fontStyle: FontStyle.italic)),
          ...rewards.entries.map((e) => Text(
                '${e.key.name} x${e.value}',
                style: const TextStyle(fontSize: 16, color: Colors.amber),
              )),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _dungeonManager.claimRewards();
            },
            child: const Text('Claim Logic'),
          ),
        ],
      ),
    );
  }
}
