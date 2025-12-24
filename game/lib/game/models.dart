/// 아이템 타입
enum ItemType {
  weapon, // 무기
  armor, // 방어구
  potion, // 포션
  material, // 재료
}

/// 아이템 클래스
class Item {
  final String id;
  final String name;
  final ItemType type;
  final int basePrice;
  final int craftingTime; // 초 단위
  final Map<String, int> materials; // 필요 재료 {재료ID: 수량}

  const Item({
    required this.id,
    required this.name,
    required this.type,
    required this.basePrice,
    required this.craftingTime,
    this.materials = const {},
  });

  /// 기본 아이템 목록
  static List<Item> getDefaultItems() {
    return [
      const Item(
        id: 'wood_sword',
        name: '나무 검',
        type: ItemType.weapon,
        basePrice: 10,
        craftingTime: 5,
        materials: {'wood': 2},
      ),
      const Item(
        id: 'iron_sword',
        name: '철 검',
        type: ItemType.weapon,
        basePrice: 50,
        craftingTime: 15,
        materials: {'iron': 3, 'wood': 1},
      ),
      const Item(
        id: 'leather_armor',
        name: '가죽 갑옷',
        type: ItemType.armor,
        basePrice: 30,
        craftingTime: 10,
        materials: {'leather': 4},
      ),
      const Item(
        id: 'health_potion',
        name: '체력 물약',
        type: ItemType.potion,
        basePrice: 20,
        craftingTime: 8,
        materials: {'herb': 2},
      ),
    ];
  }
}

/// 재료 클래스
class GameMaterial {
  final String id;
  final String name;
  final int basePrice;

  const GameMaterial({
    required this.id,
    required this.name,
    required this.basePrice,
  });

  static List<GameMaterial> getDefaultMaterials() {
    return [
      const GameMaterial(id: 'wood', name: '나무', basePrice: 2),
      const GameMaterial(id: 'iron', name: '철', basePrice: 10),
      const GameMaterial(id: 'leather', name: '가죽', basePrice: 5),
      const GameMaterial(id: 'herb', name: '약초', basePrice: 3),
    ];
  }
}

/// 제작 중인 아이템
class CraftingSlot {
  final Item item;
  final DateTime startTime;
  final int durationSeconds;

  CraftingSlot({
    required this.item,
    required this.startTime,
    int? duration,
  }) : durationSeconds = duration ?? item.craftingTime;

  bool get isComplete =>
      DateTime.now().difference(startTime).inSeconds >= durationSeconds;

  int get remainingSeconds {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return (durationSeconds - elapsed).clamp(0, durationSeconds);
  }

  double get progress {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
  }
}

/// 던전 몬스터
class Monster {
  final String name;
  final int hp;
  final int attack;
  final Map<String, int> drops; // 드롭 재료 {재료ID: 수량}

  const Monster({
    required this.name,
    required this.hp,
    required this.attack,
    required this.drops,
  });

  static List<Monster> getDungeonMonsters() {
    return [
      const Monster(
        name: '슬라임',
        hp: 20,
        attack: 5,
        drops: {'herb': 1},
      ),
      const Monster(
        name: '고블린',
        hp: 30,
        attack: 8,
        drops: {'wood': 2, 'leather': 1},
      ),
      const Monster(
        name: '오크',
        hp: 50,
        attack: 12,
        drops: {'iron': 2, 'leather': 2},
      ),
    ];
  }
}
