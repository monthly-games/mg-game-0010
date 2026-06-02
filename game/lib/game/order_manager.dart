import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'models.dart';

/// Order rarity tiers affecting rewards and difficulty
enum OrderRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Order status tracking
enum OrderStatus {
  pending,     // Waiting for player to accept
  active,      // Player accepted, working on it
  completed,   // Order fulfilled
  expired,     // Time ran out
  cancelled,   // Player cancelled
}

/// Enhanced order with rarity, time limits, and tips
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final CustomerType customerType;
  final OrderRarity rarity;
  final Map<String, int> requestedItems; // {itemId: quantity}
  final int baseReward;
  final int timeLimitSeconds;
  final DateTime createdAt;
  final DateTime expiresAt;

  OrderStatus status = OrderStatus.pending;
  DateTime? acceptedAt;
  DateTime? completedAt;
  int tipAmount = 0;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.rarity,
    required this.requestedItems,
    required this.baseReward,
    required this.timeLimitSeconds,
    required this.createdAt,
  }) : expiresAt = createdAt.add(Duration(seconds: timeLimitSeconds));

  /// Time remaining before expiration
  Duration get timeRemaining {
    if (status == OrderStatus.completed || status == OrderStatus.expired) {
      return Duration.zero;
    }
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  /// Whether order has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Calculate tip based on completion speed
  /// Faster completion = higher tip (up to 50% of base reward)
  int calculateTip() {
    if (acceptedAt == null || completedAt == null) return 0;

    final completionTime = completedAt!.difference(acceptedAt!).inSeconds;
    final totalTimeLimit = timeLimitSeconds;
    final remainingRatio = 1.0 - (completionTime / totalTimeLimit);

    // Tip scales with remaining time and rarity
    final rarityMultiplier = switch (rarity) {
      OrderRarity.common => 1.0,
      OrderRarity.uncommon => 1.2,
      OrderRarity.rare => 1.5,
      OrderRarity.epic => 2.0,
      OrderRarity.legendary => 3.0,
    };

    final tipPercentage = (remainingRatio * 0.5 * rarityMultiplier).clamp(0.0, 0.5);
    return (baseReward * tipPercentage).floor();
  }

  /// Total reward including tip
  int get totalReward => baseReward + tipAmount;
}

/// Reputation levels affecting order quality and frequency
enum ReputationLevel {
  novice,      // 0-20 reputation: Common orders only
  apprentice,  // 21-50: Common + Uncommon
  expert,      // 51-100: + Rare orders
  master,      // 101-200: + Epic orders
  legendary,   // 201+: + Legendary orders
}

/// Manages orders with rarity, tips, and reputation
class OrderManager extends ChangeNotifier {
  final AchievementManager _achievementManager = GetIt.I<AchievementManager>();
  final Random _random = Random();
  Timer? _orderTimer;
  Timer? _expirationTimer;

  // State
  final List<Order> _orders = [];
  int _reputation = 0;
  int _totalOrdersCompleted = 0;
  int _totalTipsEarned = 0;
  int _totalOrdersExpired = 0;

  // Getters
  List<Order> get orders => List.unmodifiable(_orders);
  int get reputation => _reputation;
  ReputationLevel get reputationLevel => _calculateReputationLevel();
  int get totalOrdersCompleted => _totalOrdersCompleted;
  int get totalTipsEarned => _totalTipsEarned;
  int get totalOrdersExpired => _totalOrdersExpired;

  /// Orders currently active (accepted by player)
  List<Order> get activeOrders => _orders.where((o) => o.status == OrderStatus.active).toList();

  /// Orders waiting for acceptance
  List<Order> get pendingOrders => _orders.where((o) => o.status == OrderStatus.pending).toList();

  /// Base order generation interval (reduced by reputation)
  int get orderIntervalSeconds {
    final level = reputationLevel;
    return switch (level) {
      ReputationLevel.novice => 30,
      ReputationLevel.apprentice => 25,
      ReputationLevel.expert => 20,
      ReputationLevel.master => 15,
      ReputationLevel.legendary => 10,
    };
  }

  OrderManager() {
    _startOrderGeneration();
    _startExpirationCheck();
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    _expirationTimer?.cancel();
    super.dispose();
  }

  ReputationLevel _calculateReputationLevel() {
    if (_reputation >= 201) return ReputationLevel.legendary;
    if (_reputation >= 101) return ReputationLevel.master;
    if (_reputation >= 51) return ReputationLevel.expert;
    if (_reputation >= 21) return ReputationLevel.apprentice;
    return ReputationLevel.novice;
  }

  void _startOrderGeneration() {
    _orderTimer?.cancel();
    _orderTimer = Timer.periodic(
      Duration(seconds: orderIntervalSeconds),
      (_) => _generateOrder(),
    );
  }

  void _startExpirationCheck() {
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkExpirations();
    });
  }

  void _checkExpirations() {
    bool changed = false;
    for (final order in _orders) {
      if (order.status == OrderStatus.active && order.isExpired) {
        order.status = OrderStatus.expired;
        _totalOrdersExpired++;
        _adjustReputation(-2); // Lose reputation for expired orders
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void _generateOrder() {
    if (pendingOrders.length >= 5) return; // Max 5 pending orders

    final rarity = _rollRarity();
    final order = _createOrder(rarity);
    _orders.add(order);
    notifyListeners();
  }

  OrderRarity _rollRarity() {
    final level = reputationLevel;
    final roll = _random.nextDouble();

    // Rarity chances based on reputation level
    final chances = switch (level) {
      ReputationLevel.novice => {
        OrderRarity.common: 1.0,
        OrderRarity.uncommon: 0.0,
        OrderRarity.rare: 0.0,
        OrderRarity.epic: 0.0,
        OrderRarity.legendary: 0.0,
      },
      ReputationLevel.apprentice => {
        OrderRarity.common: 0.7,
        OrderRarity.uncommon: 0.3,
        OrderRarity.rare: 0.0,
        OrderRarity.epic: 0.0,
        OrderRarity.legendary: 0.0,
      },
      ReputationLevel.expert => {
        OrderRarity.common: 0.5,
        OrderRarity.uncommon: 0.35,
        OrderRarity.rare: 0.15,
        OrderRarity.epic: 0.0,
        OrderRarity.legendary: 0.0,
      },
      ReputationLevel.master => {
        OrderRarity.common: 0.3,
        OrderRarity.uncommon: 0.4,
        OrderRarity.rare: 0.25,
        OrderRarity.epic: 0.05,
        OrderRarity.legendary: 0.0,
      },
      ReputationLevel.legendary => {
        OrderRarity.common: 0.2,
        OrderRarity.uncommon: 0.3,
        OrderRarity.rare: 0.3,
        OrderRarity.epic: 0.15,
        OrderRarity.legendary: 0.05,
      },
    };

    double cumulative = 0.0;
    for (final entry in chances.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) return entry.key;
    }
    return OrderRarity.common;
  }

  Order _createOrder(OrderRarity rarity) {
    final customerNames = [
      'Adventurer Kai', 'Mage Luna', 'Knight Rowan', 'Ranger Elara',
      'Merchant Doran', 'Noble Isolde', 'Warrior Thane', 'Healer Sera',
      'Scout Finn', 'Alchemist Nyx', 'Bard Mira', 'Paladin Gavin',
    ];
    final customerTypes = CustomerType.values;

    final customerType = customerTypes[_random.nextInt(customerTypes.length)];
    final availableItems = Item.getDefaultItems();

    // Select items based on customer preference and rarity
    final requestedItems = <String, int>{};
    final itemCount = switch (rarity) {
      OrderRarity.common => 1,
      OrderRarity.uncommon => 1 + _random.nextInt(2),
      OrderRarity.rare => 2 + _random.nextInt(2),
      OrderRarity.epic => 3 + _random.nextInt(2),
      OrderRarity.legendary => 4 + _random.nextInt(3),
    };

    int addedItems = 0;
    final shuffledItems = availableItems.toList()..shuffle();

    for (final item in shuffledItems) {
      if (addedItems >= itemCount) break;

      // Check customer preference
      bool prefersItem = switch (customerType) {
        CustomerType.warrior => item.type == ItemType.weapon || item.type == ItemType.armor,
        CustomerType.mage => item.type == ItemType.potion,
        CustomerType.ranger => item.type == ItemType.weapon || item.type == ItemType.armor,
        CustomerType.merchant => true,
        CustomerType.noble => true,
      };

      if (prefersItem) {
        final quantity = switch (rarity) {
          OrderRarity.common => 1,
          OrderRarity.uncommon => 1 + _random.nextInt(2),
          OrderRarity.rare => 2 + _random.nextInt(2),
          OrderRarity.epic => 2 + _random.nextInt(3),
          OrderRarity.legendary => 3 + _random.nextInt(4),
        };
        requestedItems[item.id] = quantity;
        addedItems++;
      }
    }

    // Calculate rewards based on rarity and item values
    final baseValue = requestedItems.entries.fold(0, (sum, entry) {
      final item = availableItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.basePrice * entry.value);
    });

    final rarityMultiplier = switch (rarity) {
      OrderRarity.common => 1.0,
      OrderRarity.uncommon => 1.5,
      OrderRarity.rare => 2.5,
      OrderRarity.epic => 4.0,
      OrderRarity.legendary => 7.0,
    };

    final baseReward = (baseValue * rarityMultiplier).ceil();

    // Time limit based on rarity and total crafting time
    final totalCraftingTime = requestedItems.entries.fold(0, (sum, entry) {
      final item = availableItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.craftingTime * entry.value);
    });

    final timeMultiplier = switch (rarity) {
      OrderRarity.common => 2.0,
      OrderRarity.uncommon => 1.8,
      OrderRarity.rare => 1.5,
      OrderRarity.epic => 1.3,
      OrderRarity.legendary => 1.0,
    };

    final timeLimitSeconds = (totalCraftingTime * timeMultiplier).ceil();

    return Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      customerId: 'customer_${_random.nextInt(1000)}',
      customerName: customerNames[_random.nextInt(customerNames.length)],
      customerType: customerType,
      rarity: rarity,
      requestedItems: requestedItems,
      baseReward: baseReward,
      timeLimitSeconds: timeLimitSeconds,
      createdAt: DateTime.now(),
    );
  }

  /// Accept an order
  bool acceptOrder(String orderId) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (order.status != OrderStatus.pending) return false;
    if (order.isExpired) return false;

    order.status = OrderStatus.active;
    order.acceptedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Complete an order
  bool completeOrder(String orderId, Map<String, int> providedItems) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (order.status != OrderStatus.active) return false;

    // Verify all required items are provided
    for (final entry in order.requestedItems.entries) {
      if ((providedItems[entry.key] ?? 0) < entry.value) {
        return false; // Missing items
      }
    }

    order.status = OrderStatus.completed;
    order.completedAt = DateTime.now();
    order.tipAmount = order.calculateTip();

    _totalOrdersCompleted++;
    _totalTipsEarned += order.tipAmount;
    _adjustReputation(switch (order.rarity) {
      OrderRarity.common => 1,
      OrderRarity.uncommon => 2,
      OrderRarity.rare => 4,
      OrderRarity.epic => 8,
      OrderRarity.legendary => 15,
    });

    // Check achievements
    if (_totalOrdersCompleted >= 100) {
      _achievementManager.unlock('order_master');
    }
    if (order.rarity == OrderRarity.legendary) {
      _achievementManager.unlock('legendary_crafter');
    }
    if (order.tipAmount >= order.baseReward ~/ 2) {
      _achievementManager.unlock('speed_demon');
    }

    notifyListeners();
    return true;
  }

  /// Cancel an active order (penalty)
  bool cancelOrder(String orderId) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (order.status != OrderStatus.active) return false;

    order.status = OrderStatus.cancelled;
    _adjustReputation(-1); // Small penalty for cancelling

    notifyListeners();
    return true;
  }

  /// Remove completed/expired orders from list
  void cleanupOrders() {
    _orders.removeWhere((o) =>
      o.status == OrderStatus.completed ||
      o.status == OrderStatus.expired ||
      o.status == OrderStatus.cancelled
    );
    notifyListeners();
  }

  void _adjustReputation(int amount) {
    _reputation = (_reputation + amount).clamp(0, 999);
  }

  /// Reset for prestige
  void reset() {
    _orders.clear();
    _reputation = 0;
    _totalOrdersCompleted = 0;
    _totalTipsEarned = 0;
    _totalOrdersExpired = 0;
    notifyListeners();
  }
}
