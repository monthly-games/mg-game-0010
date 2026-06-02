import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'models.dart';

/// Trade offer status
enum TradeStatus {
  available,    // Available to accept
  accepted,     // Player accepted
  completed,    // Trade finished
  expired,      // Time ran out
}

/// Trade rarity affecting bonuses
enum TradeRarity {
  common,
  uncommon,
  rare,
  epic,
}

/// A trade offer from a guild member
class TradeOffer {
  final String id;
  final String guildMemberName;
  final TradeRarity rarity;
  final Map<String, int> requestedResources; // What they want
  final Map<String, int> offeredResources;   // What they offer
  final DateTime createdAt;
  final DateTime expiresAt;

  TradeStatus status = TradeStatus.available;
  DateTime? acceptedAt;

  TradeOffer({
    required this.id,
    required this.guildMemberName,
    required this.rarity,
    required this.requestedResources,
    required this.offeredResources,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Time remaining
  Duration get timeRemaining {
    if (status == TradeStatus.completed || status == TradeStatus.expired) {
      return Duration.zero;
    }
    final now = DateTime.now();
    return now.isAfter(expiresAt) ? Duration.zero : expiresAt.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Calculate trade bonus percentage
  double get bonusPercentage {
    return switch (rarity) {
      TradeRarity.common => 0.0,
      TradeRarity.uncommon => 0.1,
      TradeRarity.rare => 0.25,
      TradeRarity.epic => 0.5,
    };
  }

  /// Get bonus resources (extra items from epic trades)
  Map<String, int> get bonusResources {
    if (rarity != TradeRarity.epic) return {};
    return {
      'gold': [50, 100, 150][Random().nextInt(3)],
    };
  }
}

/// Active trade route with cooldown
class TradeRoute {
  final String id;
  final String name;
  final String destinationGuild;
  final Map<String, int> requiredResources;
  final int travelTimeMinutes;
  final Map<String, int> rewards;

  DateTime? lastUsed;
  bool get isOnCooldown => lastUsed != null &&
      DateTime.now().difference(lastUsed!).inMinutes < travelTimeMinutes;

  Duration get remainingCooldown {
    if (lastUsed == null) return Duration.zero;
    final elapsed = DateTime.now().difference(lastUsed!).inMinutes;
    final remaining = travelTimeMinutes - elapsed;
    return Duration(minutes: remaining.clamp(0, travelTimeMinutes));
  }

  TradeRoute({
    required this.id,
    required this.name,
    required this.destinationGuild,
    required this.requiredResources,
    required this.travelTimeMinutes,
    required this.rewards,
  });
}

/// Guild marketplace listing
class MarketplaceListing {
  final String id;
  final String sellerName;
  final String resourceId;
  final int quantity;
  final int pricePerUnit;
  final DateTime listedAt;
  final DateTime expiresAt;

  MarketplaceListing({
    required this.id,
    required this.sellerName,
    required this.resourceId,
    required this.quantity,
    required this.pricePerUnit,
    required this.listedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get totalPrice => pricePerUnit * quantity;
}

/// Manages guild trading, trade routes, and marketplace
class GuildTradeManager extends ChangeNotifier {
  final AchievementManager _achievementManager = GetIt.I<AchievementManager>();
  final Random _random = Random();
  Timer? _tradeOfferTimer;
  Timer? _marketplaceTimer;
  Timer? _routeTimer;

  // State
  final List<TradeOffer> _tradeOffers = [];
  final List<MarketplaceListing> _marketplaceListings = [];
  final List<TradeRoute> _tradeRoutes = [];
  int _guildReputation = 0;
  int _totalTradesCompleted = 0;
  int _totalProfitFromTrades = 0;

  // Cooldowns
  DateTime? _lastMarketplaceRefresh;
  DateTime? _lastTradeOfferGeneration;

  // Static trade routes
  static List<TradeRoute> getDefaultTradeRoutes() {
    return [
      TradeRoute(
        id: 'route_iron_mine',
        name: 'Iron Mine Route',
        destinationGuild: 'Iron Miners Guild',
        requiredResources: {'gold': 50},
        travelTimeMinutes: 10,
        rewards: {'iron': 20},
      ),
      TradeRoute(
        id: 'route_herb_forest',
        name: 'Herbalist Trail',
        destinationGuild: 'Forest Alchemists',
        requiredResources: {'gold': 30},
        travelTimeMinutes: 5,
        rewards: {'herb': 15},
      ),
      TradeRoute(
        id: 'route_leather_outpost',
        name: 'Hunter Outpost',
        destinationGuild: 'Hunter League',
        requiredResources: {'gold': 40, 'herb': 5},
        travelTimeMinutes: 8,
        rewards: {'leather': 12},
      ),
      TradeRoute(
        id: 'route_rare_trade',
        name: 'Rare Trade Route',
        destinationGuild: 'Merchant Alliance',
        requiredResources: {'gold': 150},
        travelTimeMinutes: 20,
        rewards: {'iron': 15, 'leather': 10, 'herb': 10},
      ),
    ];
  }

  // Getters
  List<TradeOffer> get tradeOffers => List.unmodifiable(_tradeOffers);
  List<MarketplaceListing> get marketplaceListings => List.unmodifiable(_marketplaceListings);
  List<TradeRoute> get tradeRoutes => List.unmodifiable(_tradeRoutes);
  int get guildReputation => _guildReputation;
  int get totalTradesCompleted => _totalTradesCompleted;
  int get totalProfitFromTrades => _totalProfitFromTrades;

  /// Available trade offers
  List<TradeOffer> get availableTradeOffers =>
      _tradeOffers.where((t) => t.status == TradeStatus.available && !t.isExpired).toList();

  /// Active trades (accepted but not completed)
  List<TradeOffer> get activeTrades =>
      _tradeOffers.where((t) => t.status == TradeStatus.accepted && !t.isExpired).toList();

  GuildTradeManager() {
    _tradeRoutes.addAll(getDefaultTradeRoutes());
    _startTradeOfferGeneration();
    _startMarketplaceRefresh();
    _startRouteCooldownCheck();
    _generateInitialOffers();
  }

  @override
  void dispose() {
    _tradeOfferTimer?.cancel();
    _marketplaceTimer?.cancel();
    _routeTimer?.cancel();
    super.dispose();
  }

  void _generateInitialOffers() {
    // Generate initial trade offers
    for (int i = 0; i < 3; i++) {
      _tradeOffers.add(_createTradeOffer());
    }
    // Generate initial marketplace listings
    for (int i = 0; i < 5; i++) {
      _marketplaceListings.add(_createMarketplaceListing());
    }
  }

  void _startTradeOfferGeneration() {
    _tradeOfferTimer?.cancel();
    _tradeOfferTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (availableTradeOffers.length < 5) {
        _tradeOffers.add(_createTradeOffer());
        notifyListeners();
      }
    });
  }

  void _startMarketplaceRefresh() {
    _marketplaceTimer?.cancel();
    _marketplaceTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _refreshMarketplace();
    });
  }

  void _startRouteCooldownCheck() {
    _routeTimer?.cancel();
    _routeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      notifyListeners(); // Update cooldown displays
    });
  }

  void _refreshMarketplace() {
    // Remove expired listings
    _marketplaceListings.removeWhere((l) => l.isExpired);

    // Add new listings if below limit
    while (_marketplaceListings.length < 8) {
      _marketplaceListings.add(_createMarketplaceListing());
    }

    _lastMarketplaceRefresh = DateTime.now();
    notifyListeners();
  }

  TradeOffer _createTradeOffer() {
    final guildMembers = [
      'Elena the Smith', 'Marcus the Merchant', 'Sylas the Ranger',
      'Theron the Alchemist', 'Iris the Enchanter', 'Gareth the Warrior',
      'Lyra the Gatherer', 'Oscar the Trader', 'Vera the Artisan',
    ];

    final materials = ['wood', 'iron', 'leather', 'herb'];
    final material = materials[_random.nextInt(materials.length)];

    final rarity = _rollTradeRarity();
    final quantity = switch (rarity) {
      TradeRarity.common => 5 + _random.nextInt(10),
      TradeRarity.uncommon => 8 + _random.nextInt(15),
      TradeRarity.rare => 12 + _random.nextInt(20),
      TradeRarity.epic => 20 + _random.nextInt(30),
    };

    // Calculate trade values
    final basePrices = {
      'wood': 2,
      'iron': 10,
      'leather': 5,
      'herb': 3,
    };

    final requestedValue = basePrices[material]! * quantity;
    final bonusMultiplier = 1.0 + switch (rarity) {
      TradeRarity.common => 0.0,
      TradeRarity.uncommon => 0.1,
      TradeRarity.rare => 0.25,
      TradeRarity.epic => 0.5,
    };

    // Determine what they offer (different material)
    final availableMaterials = materials.where((m) => m != material).toList();
    final offeredMaterial = availableMaterials[_random.nextInt(availableMaterials.length)];
    final offeredQuantity = ((requestedValue * bonusMultiplier) / basePrices[offeredMaterial]!).floor();

    return TradeOffer(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      guildMemberName: guildMembers[_random.nextInt(guildMembers.length)],
      rarity: rarity,
      requestedResources: {material: quantity},
      offeredResources: {offeredMaterial: offeredQuantity},
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: switch (rarity) {
        TradeRarity.common => 10,
        TradeRarity.uncommon => 8,
        TradeRarity.rare => 6,
        TradeRarity.epic => 5,
      })),
    );
  }

  MarketplaceListing _createMarketplaceListing() {
    final sellers = [
      'Guild Master Aldric', 'Trader Jasmine', 'Merchant Kael',
      'Vendor Rosalind', 'Dealer Magnus',
    ];

    final materials = ['wood', 'iron', 'leather', 'herb'];
    final material = materials[_random.nextInt(materials.length)];

    final basePrices = {'wood': 2, 'iron': 10, 'leather': 5, 'herb': 3};
    final basePrice = basePrices[material]!;

    // Price variance: +/- 30%
    final priceVariation = 0.7 + (_random.nextDouble() * 0.6);
    final pricePerUnit = (basePrice * priceVariation).ceil().clamp(1, basePrice * 2);

    final quantity = 5 + _random.nextInt(25);

    return MarketplaceListing(
      id: 'listing_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      sellerName: sellers[_random.nextInt(sellers.length)],
      resourceId: material,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      listedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 10 + _random.nextInt(20))),
    );
  }

  TradeRarity _rollTradeRarity() {
    final roll = _random.nextDouble();
    if (roll < 0.50) return TradeRarity.common;
    if (roll < 0.80) return TradeRarity.uncommon;
    if (roll < 0.95) return TradeRarity.rare;
    return TradeRarity.epic;
  }

  /// Accept a trade offer
  bool acceptTradeOffer(String tradeId, Map<String, int> playerResources) {
    final trade = _tradeOffers.firstWhere((t) => t.id == tradeId);
    if (trade.status != TradeStatus.available) return false;
    if (trade.isExpired) return false;

    // Check if player has required resources
    for (final entry in trade.requestedResources.entries) {
      if ((playerResources[entry.key] ?? 0) < entry.value) {
        return false; // Insufficient resources
      }
    }

    trade.status = TradeStatus.accepted;
    trade.acceptedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Complete an accepted trade (return rewards)
  Map<String, int> completeTrade(String tradeId) {
    final trade = _tradeOffers.firstWhere((t) => t.id == tradeId);
    if (trade.status != TradeStatus.accepted) return {};

    trade.status = TradeStatus.completed;

    final rewards = Map<String, int>.from(trade.offeredResources);

    // Add bonus for epic trades
    if (trade.rarity == TradeRarity.epic) {
      final bonus = trade.bonusResources;
      for (final entry in bonus.entries) {
        rewards[entry.key] = (rewards[entry.key] ?? 0) + entry.value;
      }
    }

    // Calculate profit
    final requestedValue = trade.requestedResources.entries.fold(0, (sum, entry) {
      final basePrices = {'wood': 2, 'iron': 10, 'leather': 5, 'herb': 3};
      return sum + (basePrices[entry.key]! * entry.value);
    });

    final rewardValue = rewards.entries.fold(0, (sum, entry) {
      final basePrices = {'wood': 2, 'iron': 10, 'leather': 5, 'herb': 3, 'gold': 1};
      return sum + (basePrices[entry.key] ?? 1 * entry.value);
    });

    _totalTradesCompleted++;
    _totalProfitFromTrades += (rewardValue - requestedValue);
    _guildReputation += switch (trade.rarity) {
      TradeRarity.common => 1,
      TradeRarity.uncommon => 2,
      TradeRarity.rare => 4,
      TradeRarity.epic => 8,
    };

    // Check achievements
    if (_totalTradesCompleted >= 50) {
      _achievementManager.unlock('guild_trader');
    }
    if (_guildReputation >= 100) {
      _achievementManager.unlock('guild_respected');
    }

    notifyListeners();
    return rewards;
  }

  /// Buy from marketplace
  bool buyFromMarketplace(String listingId, int gold) {
    final listing = _marketplaceListings.firstWhere((l) => l.id == listingId);
    if (listing.isExpired) return false;
    if (gold < listing.totalPrice) return false;

    _marketplaceListings.remove(listing);
    _guildReputation += 1;
    notifyListeners();
    return true;
  }

  /// Sell to marketplace (create listing)
  bool sellToMarketplace(String resourceId, int quantity, int askingPrice) {
    if (quantity <= 0 || askingPrice <= 0) return false;

    final listing = MarketplaceListing(
      id: 'listing_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      sellerName: 'Player',
      resourceId: resourceId,
      quantity: quantity,
      pricePerUnit: askingPrice,
      listedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 15)),
    );

    _marketplaceListings.add(listing);
    notifyListeners();
    return true;
  }

  /// Send caravan on trade route
  bool sendCaravan(String routeId, Map<String, int> playerResources) {
    final route = _tradeRoutes.firstWhere((r) => r.id == routeId);

    if (route.isOnCooldown) return false;

    // Check required resources
    for (final entry in route.requiredResources.entries) {
      if ((playerResources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    route.lastUsed = DateTime.now();
    _guildReputation += 2;
    notifyListeners();
    return true;
  }

  /// Collect rewards from completed trade route
  Map<String, int> collectRouteRewards(String routeId) {
    final route = _tradeRoutes.firstWhere((r) => r.id == routeId);

    if (route.isOnCooldown) return {}; // Not ready yet

    route.lastUsed = null; // Reset for next use
    notifyListeners();
    return Map.from(route.rewards);
  }

  /// Cleanup expired offers and listings
  void cleanupExpired() {
    _tradeOffers.removeWhere((t) => t.isExpired && t.status == TradeStatus.available);
    _marketplaceListings.removeWhere((l) => l.isExpired);
    notifyListeners();
  }

  /// Reset for prestige
  void reset() {
    _tradeOffers.clear();
    _marketplaceListings.clear();
    _guildReputation = 0;
    _totalTradesCompleted = 0;
    _totalProfitFromTrades = 0;
    _tradeRoutes.clear();
    _tradeRoutes.addAll(getDefaultTradeRoutes());
    _generateInitialOffers();
    notifyListeners();
  }
}
