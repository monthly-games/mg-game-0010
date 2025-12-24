import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'models.dart';

class CraftingManager extends ChangeNotifier {
  final UpgradeManager upgradeManager = GetIt.I<UpgradeManager>();
  final AchievementManager achievementManager = GetIt.I<AchievementManager>();

  final Map<String, int> _materials = {
    'wood': 5,
    'iron': 3,
    'leather': 3,
    'herb': 5,
  }; // 초기 재료

  final List<CraftingSlot> _craftingSlots = [];
  Timer? _updateTimer;
  int _totalCrafted = 0; // Track for achievement

  Map<String, int> get materials => Map.unmodifiable(_materials);
  List<CraftingSlot> get craftingSlots => List.unmodifiable(_craftingSlots);

  CraftingManager() {
    // 1초마다 제작 진행 상태 업데이트
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// 재료 추가
  void addMaterial(String materialId, int amount) {
    _materials[materialId] = (_materials[materialId] ?? 0) + amount;
    notifyListeners();
  }

  /// 재료 개수 확인
  int getMaterialCount(String materialId) {
    return _materials[materialId] ?? 0;
  }

  /// 아이템 제작 시작
  bool startCrafting(Item item) {
    // 재료 확인
    for (final entry in item.materials.entries) {
      final materialId = entry.key;
      final required = entry.value;
      if (getMaterialCount(materialId) < required) {
        return false;
      }
    }

    // 재료 소비
    for (final entry in item.materials.entries) {
      _materials[entry.key] = (_materials[entry.key] ?? 0) - entry.value;
    }

    // Calculate Duration with Craft Speed Upgrade
    // Value = 0.1 (10%) per level.
    // Speed = 1 + (0.1 * level)
    // Duration = Base / Speed
    final speedUpgrade = upgradeManager.getUpgrade('craft_speed');
    final speedMultiplier = 1.0 + (speedUpgrade?.currentValue ?? 0.0);
    final duration = (item.craftingTime / speedMultiplier).ceil();

    // 제작 슬롯 추가
    _craftingSlots.add(CraftingSlot(
      item: item,
      startTime: DateTime.now(),
      duration: duration,
    ));

    notifyListeners();
    return true;
  }

  /// 완성된 아이템 수집
  List<Item> collectCompletedItems() {
    final completed = _craftingSlots.where((slot) => slot.isComplete).toList();
    _craftingSlots.removeWhere((slot) => slot.isComplete);

    if (completed.isNotEmpty) {
      _totalCrafted += completed.length;
      if (_totalCrafted >= 50) {
        achievementManager.unlock('master_crafter');
      }
    }

    notifyListeners();
    return completed.map((slot) => slot.item).toList();
  }

  /// 완성된 아이템 개수
  int get completedCount =>
      _craftingSlots.where((slot) => slot.isComplete).length;

  /// 제작 시스템 리셋 (프레스티지용)
  void reset() {
    _materials.clear();
    _materials['wood'] = 5;
    _materials['iron'] = 3;
    _materials['leather'] = 3;
    _materials['herb'] = 5;
    _craftingSlots.clear();
    _totalCrafted = 0;
    upgradeManager.setUpgradeLevel('craft_speed', 0);
    notifyListeners();
  }
}
