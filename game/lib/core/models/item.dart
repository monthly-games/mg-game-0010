enum ItemType {
  weapon,
  armor,
  potion,
  accessory,
}

enum ItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class Item {
  final String id;
  final String name;
  final ItemType type;
  final ItemRarity rarity;
  final int basePrice;
  final String description;

  const Item({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.basePrice,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
