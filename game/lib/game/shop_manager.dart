import 'package:flutter/foundation.dart';
import 'models.dart';

import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

class ShopManager extends ChangeNotifier {
  final ProgressionManager progression = GetIt.I<ProgressionManager>();
  final UpgradeManager upgradeManager = GetIt.I<UpgradeManager>();
  final AchievementManager achievements = GetIt.I<AchievementManager>();

  int _gold = 100; // 초기 골드
  final Map<String, int> _inventory = {}; // {아이템ID: 수량}

  int get gold => _gold;
  Map<String, int> get inventory => Map.unmodifiable(_inventory);

  // Upgrade-based Capacity
  int get maxInventorySlots =>
      20 +
      (upgradeManager.getUpgrade('inventory_space')?.currentValue.toInt() ?? 0);
  int get currentInventoryCount =>
      _inventory.values.fold(0, (sum, count) => sum + count);

  /// 아이템 판매
  bool sellItem(Item item) {
    final itemCount = _inventory[item.id] ?? 0;
    if (itemCount <= 0) return false;

    // Apply Sell Price Upgrade
    // Value = 0.1 (10%) per level
    final hagglingUpgrade = upgradeManager.getUpgrade('sell_price');
    final priceMultiplier = 1.0 + (hagglingUpgrade?.currentValue ?? 0.0);
    final sellPrice = (item.basePrice * priceMultiplier).ceil();

    _inventory[item.id] = itemCount - 1;
    _gold += sellPrice;

    // Add XP based on value (10% of price)
    progression.addXp((sellPrice / 10).ceil());

    // Check Achievement
    if (_gold >= 5000) {
      achievements.unlock('master_merchant');
    }

    notifyListeners();
    return true;
  }

  /// 아이템 추가 (제작 완료 시)
  bool addItem(Item item) {
    if (currentInventoryCount >= maxInventorySlots) {
      return false; // Storage Full
    }
    _inventory[item.id] = (_inventory[item.id] ?? 0) + 1;
    notifyListeners();
    return true;
  }

  /// 골드 사용
  bool spendGold(int amount) {
    if (_gold < amount) return false;
    _gold -= amount;
    notifyListeners();
    return true;
  }

  /// Upgrade purchase wrapper
  bool buyUpgrade(String upgradeId) {
    return upgradeManager.purchaseUpgrade(
        upgradeId, () => _gold, (cost) => spendGold(cost));
  }

  /// 골드 추가
  void addGold(int amount) {
    _gold += amount;
    notifyListeners();
  }

  /// 아이템 개수 확인
  int getItemCount(String itemId) {
    return _inventory[itemId] ?? 0;
  }

  /// 상점 리셋 (프레스티지용)
  void reset() {
    _gold = 100;
    _inventory.clear();
    upgradeManager.setUpgradeLevel('inventory_space', 0);
    upgradeManager.setUpgradeLevel('sell_price', 0);
    notifyListeners();
  }
}
