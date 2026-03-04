import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'models.dart';
import 'shop_manager.dart';

/// Customer type — affects item preferences and budget
enum CustomerType {
  warrior, // Prefers weapons
  mage, // Prefers potions and staves
  ranger, // Prefers bows and leather
  merchant, // Buys anything, higher budget
  noble, // Prefers rare+ items, biggest budget
}

/// Represents a visiting customer
class Customer {
  final String name;
  final CustomerType type;
  final int budget;
  final double patience; // 0.0-1.0, how long they browse

  const Customer({
    required this.name,
    required this.type,
    required this.budget,
    required this.patience,
  });

  /// Whether this customer prefers a given item type
  bool prefersItemType(ItemType itemType) {
    switch (type) {
      case CustomerType.warrior:
        return itemType == ItemType.weapon || itemType == ItemType.armor;
      case CustomerType.mage:
        return itemType == ItemType.potion || itemType == ItemType.weapon;
      case CustomerType.ranger:
        return itemType == ItemType.weapon || itemType == ItemType.armor;
      case CustomerType.merchant:
        return true; // Buys anything
      case CustomerType.noble:
        return true; // Buys anything rare+
    }
  }
}

/// Manages customer visits, purchases, and satisfaction
class CustomerManager extends ChangeNotifier {
  final UpgradeManager _upgradeManager = GetIt.I<UpgradeManager>();
  final AchievementManager _achievementManager = GetIt.I<AchievementManager>();
  final ShopManager _shopManager = GetIt.I<ShopManager>();

  final Random _random = Random();
  Timer? _visitTimer;

  // State
  Customer? _currentCustomer;
  double _satisfaction = 0.7; // 0.0 - 1.0
  int _totalCustomersServed = 0;
  int _totalSalesFromCustomers = 0;
  bool _shopOpen = true;

  // Getters
  Customer? get currentCustomer => _currentCustomer;
  double get satisfaction => _satisfaction;
  int get totalCustomersServed => _totalCustomersServed;
  int get totalSalesFromCustomers => _totalSalesFromCustomers;
  bool get shopOpen => _shopOpen;

  /// Satisfaction as a percentage string
  String get satisfactionPercent => '${(_satisfaction * 100).toInt()}%';

  /// Base visit interval in seconds (reduced by customer_attraction upgrade)
  int get visitIntervalSeconds {
    final attractionUpgrade =
        _upgradeManager.getUpgrade('customer_attraction');
    final multiplier = 1.0 + (attractionUpgrade?.currentValue ?? 0.0);
    // Base: 15 seconds. Higher attraction = faster visits
    return (15 / multiplier).clamp(3, 30).round();
  }

  /// Start the customer visit cycle
  void startCustomerCycle() {
    _visitTimer?.cancel();
    _scheduleNextVisit();
  }

  /// Stop the customer visit cycle
  void stopCustomerCycle() {
    _visitTimer?.cancel();
    _currentCustomer = null;
    notifyListeners();
  }

  /// Toggle shop open/closed
  void toggleShop() {
    _shopOpen = !_shopOpen;
    if (_shopOpen) {
      _scheduleNextVisit();
    } else {
      _visitTimer?.cancel();
      _currentCustomer = null;
    }
    notifyListeners();
  }

  void _scheduleNextVisit() {
    if (!_shopOpen) return;
    _visitTimer?.cancel();
    _visitTimer = Timer(
      Duration(seconds: visitIntervalSeconds),
      _customerArrives,
    );
  }

  void _customerArrives() {
    _currentCustomer = _generateCustomer();
    notifyListeners();

    // Customer browses then makes a purchase decision
    final browseTime =
        (3 + (_currentCustomer!.patience * 5)).round();
    Timer(Duration(seconds: browseTime), _customerDecides);
  }

  /// Customer decides whether to buy something
  void _customerDecides() {
    if (_currentCustomer == null) return;

    final customer = _currentCustomer!;
    final inventory = _shopManager.inventory;

    // Find items customer might want
    String? bestItemId;
    int bestPrice = 0;

    for (final entry in inventory.entries) {
      if (entry.value <= 0) continue;

      // Find the Item definition
      final item = Item.getDefaultItems().cast<Item?>().firstWhere(
            (i) => i?.id == entry.key,
            orElse: () => null,
          );
      if (item == null) continue;

      // Check preference and budget
      if (customer.prefersItemType(item.type) &&
          item.basePrice <= customer.budget) {
        if (item.basePrice > bestPrice) {
          bestPrice = item.basePrice;
          bestItemId = item.id;
        }
      }
    }

    if (bestItemId != null && _random.nextDouble() < _purchaseProbability()) {
      // Purchase!
      final item = Item.getDefaultItems().firstWhere((i) => i.id == bestItemId);
      if (_shopManager.sellItem(item)) {
        _totalSalesFromCustomers++;
        _totalCustomersServed++;
        _adjustSatisfaction(0.05); // Happy customer

        // Check achievements
        if (_totalSalesFromCustomers >= 100) {
          _achievementManager.unlock('shop_legend');
        }
        if (_satisfaction >= 0.9) {
          _achievementManager.unlock('customer_favorite');
        }
      }
    } else {
      // Customer leaves without buying
      _totalCustomersServed++;
      _adjustSatisfaction(-0.02); // Slightly unhappy
    }

    _currentCustomer = null;
    notifyListeners();
    _scheduleNextVisit();
  }

  /// Purchase probability based on satisfaction and display quality
  double _purchaseProbability() {
    final displayUpgrade =
        _upgradeManager.getUpgrade('display_quality');
    final displayBonus = displayUpgrade?.currentValue ?? 0.0;
    // Base 60% + satisfaction bonus + display bonus
    return (0.6 + _satisfaction * 0.2 + displayBonus).clamp(0.0, 0.95);
  }

  void _adjustSatisfaction(double delta) {
    _satisfaction = (_satisfaction + delta).clamp(0.0, 1.0);
  }

  Customer _generateCustomer() {
    final names = [
      'Adventurer Kai',
      'Mage Luna',
      'Knight Rowan',
      'Ranger Elara',
      'Merchant Doran',
      'Noble Isolde',
      'Warrior Thane',
      'Healer Sera',
      'Scout Finn',
      'Alchemist Nyx',
    ];
    final types = CustomerType.values;
    final type = types[_random.nextInt(types.length)];

    // Budget based on type
    final baseBudget = switch (type) {
      CustomerType.warrior => 50 + _random.nextInt(100),
      CustomerType.mage => 40 + _random.nextInt(120),
      CustomerType.ranger => 30 + _random.nextInt(80),
      CustomerType.merchant => 100 + _random.nextInt(200),
      CustomerType.noble => 200 + _random.nextInt(500),
    };

    return Customer(
      name: names[_random.nextInt(names.length)],
      type: type,
      budget: baseBudget,
      patience: 0.3 + _random.nextDouble() * 0.7,
    );
  }

  /// Reset for prestige
  void reset() {
    _satisfaction = 0.7;
    _totalCustomersServed = 0;
    _totalSalesFromCustomers = 0;
    _currentCustomer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _visitTimer?.cancel();
    super.dispose();
  }
}
