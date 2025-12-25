/// 가챠 시스템 어댑터 - MG-0010 Idle Shop
library;

import 'package:flutter/foundation.dart';
import 'package:mg_common_game/systems/gacha/gacha_config.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';

/// 게임 내 Item 모델
class Item {
  final String id;
  final String name;
  final GachaRarity rarity;
  final Map<String, dynamic> stats;

  const Item({
    required this.id,
    required this.name,
    required this.rarity,
    this.stats = const {},
  });
}

/// Idle Shop 가챠 어댑터
class ItemGachaAdapter extends ChangeNotifier {
  final GachaManager _gachaManager = GachaManager(
    pityConfig: const PityConfig(
      softPityStart: 70,
      hardPity: 80,
      softPityBonus: 6.0,
    ),
    multiPullGuarantee: const MultiPullGuarantee(
      minRarity: GachaRarity.rare,
    ),
  );

  static const String _poolId = 'shop_pool';

  ItemGachaAdapter() {
    _initPool();
  }

  void _initPool() {
    final pool = GachaPool(
      id: _poolId,
      name: 'Idle Shop 가챠',
      items: _generateItems(),
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    );
    _gachaManager.registerPool(pool);
  }

  List<GachaItem> _generateItems() {
    return [
      // UR (0.6%)
      GachaItem(id: 'ur_shop_001', name: '전설의 Item', rarity: GachaRarity.ultraRare, weight: 1.0),
      GachaItem(id: 'ur_shop_002', name: '신화의 Item', rarity: GachaRarity.ultraRare, weight: 1.0),
      // SSR (2.4%)
      GachaItem(id: 'ssr_shop_001', name: '영웅의 Item', rarity: GachaRarity.superSuperRare, weight: 1.0),
      GachaItem(id: 'ssr_shop_002', name: '고대의 Item', rarity: GachaRarity.superSuperRare, weight: 1.0),
      GachaItem(id: 'ssr_shop_003', name: '황금의 Item', rarity: GachaRarity.superSuperRare, weight: 1.0),
      // SR (12%)
      GachaItem(id: 'sr_shop_001', name: '희귀한 Item A', rarity: GachaRarity.superRare, weight: 1.0),
      GachaItem(id: 'sr_shop_002', name: '희귀한 Item B', rarity: GachaRarity.superRare, weight: 1.0),
      GachaItem(id: 'sr_shop_003', name: '희귀한 Item C', rarity: GachaRarity.superRare, weight: 1.0),
      GachaItem(id: 'sr_shop_004', name: '희귀한 Item D', rarity: GachaRarity.superRare, weight: 1.0),
      // R (35%)
      GachaItem(id: 'r_shop_001', name: '우수한 Item A', rarity: GachaRarity.rare, weight: 1.0),
      GachaItem(id: 'r_shop_002', name: '우수한 Item B', rarity: GachaRarity.rare, weight: 1.0),
      GachaItem(id: 'r_shop_003', name: '우수한 Item C', rarity: GachaRarity.rare, weight: 1.0),
      GachaItem(id: 'r_shop_004', name: '우수한 Item D', rarity: GachaRarity.rare, weight: 1.0),
      GachaItem(id: 'r_shop_005', name: '우수한 Item E', rarity: GachaRarity.rare, weight: 1.0),
      // N (50%)
      GachaItem(id: 'n_shop_001', name: '일반 Item A', rarity: GachaRarity.normal, weight: 1.0),
      GachaItem(id: 'n_shop_002', name: '일반 Item B', rarity: GachaRarity.normal, weight: 1.0),
      GachaItem(id: 'n_shop_003', name: '일반 Item C', rarity: GachaRarity.normal, weight: 1.0),
      GachaItem(id: 'n_shop_004', name: '일반 Item D', rarity: GachaRarity.normal, weight: 1.0),
      GachaItem(id: 'n_shop_005', name: '일반 Item E', rarity: GachaRarity.normal, weight: 1.0),
      GachaItem(id: 'n_shop_006', name: '일반 Item F', rarity: GachaRarity.normal, weight: 1.0),
    ];
  }

  /// 단일 뽑기
  Item? pullSingle() {
    final result = _gachaManager.pull(_poolId);
    if (result == null) return null;
    notifyListeners();
    return _convertToItem(result.item);
  }

  /// 10연차
  List<Item> pullTen() {
    final results = _gachaManager.multiPull(_poolId, count: 10);
    notifyListeners();
    return results.map((r) => _convertToItem(r.item)).toList();
  }

  Item _convertToItem(GachaItem item) {
    return Item(
      id: item.id,
      name: item.name,
      rarity: item.rarity,
    );
  }

  /// 천장까지 남은 횟수
  int get pullsUntilPity => _gachaManager.remainingPity(_poolId);

  /// 총 뽑기 횟수
  int get totalPulls => _gachaManager.getPityState(_poolId)?.totalPulls ?? 0;

  /// 통계
  GachaStats get stats => _gachaManager.getStats(_poolId);

  Map<String, dynamic> toJson() => _gachaManager.toJson();
  void loadFromJson(Map<String, dynamic> json) {
    _gachaManager.loadFromJson(json);
    notifyListeners();
  }
}
