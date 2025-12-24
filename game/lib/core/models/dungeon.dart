import 'material.dart';

class DungeonDrop {
  final MaterialItem material;
  final double chance; // 0.0 to 1.0
  final int minAmount;
  final int maxAmount;

  const DungeonDrop({
    required this.material,
    required this.chance,
    this.minAmount = 1,
    this.maxAmount = 1,
  });
}

class Dungeon {
  final String id;
  final String name;
  final String description;
  final int recommendedLevel; // Placeholder for now
  final int durationSeconds;
  final List<DungeonDrop> drops;

  const Dungeon({
    required this.id,
    required this.name,
    required this.description,
    required this.recommendedLevel,
    required this.durationSeconds,
    required this.drops,
  });
}
