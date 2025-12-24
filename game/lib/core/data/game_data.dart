import '../core/models/item.dart';
import '../core/models/material.dart';
import '../core/models/recipe.dart';
import '../core/models/dungeon.dart';

class GameData {
  // Materials
  static const wood = MaterialItem(
      id: 'mat_wood', name: 'Wood', description: 'Basic crafting material.');
  static const iron = MaterialItem(
      id: 'mat_iron', name: 'Iron Ore', description: 'Strong metal.');
  static const herb = MaterialItem(
      id: 'mat_herb', name: 'Herb', description: 'Medicinal plant.');

  // Items
  static const woodenSword = Item(
    id: 'weapon_wood_sword',
    name: 'Wooden Sword',
    type: ItemType.weapon,
    rarity: ItemRarity.common,
    basePrice: 50,
    description: 'A practice sword.',
  );

  static const ironDagger = Item(
    id: 'weapon_iron_dagger',
    name: 'Iron Dagger',
    type: ItemType.weapon,
    rarity: ItemRarity.uncommon,
    basePrice: 120,
    description: 'Sharp and fast.',
  );

  static const potionHealth = Item(
    id: 'potion_health',
    name: 'Health Potion',
    type: ItemType.potion,
    rarity: ItemRarity.common,
    basePrice: 30,
    description: 'Restores HP.',
  );

  // Recipes
  static final List<Recipe> recipes = [
    Recipe(
      id: 'recipe_wood_sword',
      resultItem: woodenSword,
      requiredMaterials: {wood: 2},
      craftTimeSeconds: 3,
    ),
    Recipe(
      id: 'recipe_iron_dagger',
      resultItem: ironDagger,
      requiredMaterials: {iron: 2, wood: 1},
      craftTimeSeconds: 5,
    ),
    Recipe(
      id: 'recipe_health_potion',
      resultItem: potionHealth,
      requiredMaterials: {herb: 2},
      craftTimeSeconds: 2,
    ),
  ];

  // Dungeons
  static const dungeonForest = Dungeon(
    id: 'dungeon_forest',
    name: 'Whispering Forest',
    description: 'A peaceful forest rich in wood and herbs.',
    recommendedLevel: 1,
    durationSeconds: 5,
    drops: [
      DungeonDrop(material: wood, chance: 1.0, minAmount: 2, maxAmount: 5),
      DungeonDrop(material: herb, chance: 0.5, minAmount: 1, maxAmount: 3),
    ],
  );

  static const dungeonMine = Dungeon(
    id: 'dungeon_mine',
    name: 'Old Iron Mine',
    description: 'Abandoned mine. Good source of iron.',
    recommendedLevel: 5,
    durationSeconds: 10,
    drops: [
      DungeonDrop(material: iron, chance: 0.8, minAmount: 1, maxAmount: 3),
      DungeonDrop(
          material: wood,
          chance: 0.2,
          minAmount: 1,
          maxAmount: 2), // Old support beams
    ],
  );

  static final List<Dungeon> dungeons = [dungeonForest, dungeonMine];
}
