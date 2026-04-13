import 'package:mg_common_game/systems/progression/achievement_manager.dart';

import 'package:mg_common_game/mg_common_game.dart' hide CraftingManager, ShopManager, UnifiedIdleManager;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'game/shop_manager.dart';
import 'game/crafting_manager.dart';
import 'game/dungeon_manager.dart';
import 'game/idle_manager.dart';
import 'game/customer_manager.dart';
import 'ui/main_screen.dart';
import 'screens/collection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized - skip in tests
  }
  await _initializeSystems();
  runApp(const DungeonShopApp());
}

/// Initialize all DI-registered systems in correct dependency order.
Future<void> _initializeSystems() async {
  final di = GetIt.I;

  // ── mg_common_game core systems ──────────────────────────
  if (!di.isRegistered<SettingsManager>()) {
    final settings = SettingsManager();
    await settings.loadSettings();
    di.registerSingleton<SettingsManager>(settings);
  }

  if (!di.isRegistered<ProgressionManager>()) {
    di.registerSingleton<ProgressionManager>(ProgressionManager());
  }

  if (!di.isRegistered<AchievementManager>()) {
    final achievements = AchievementManager();
    di.registerSingleton<AchievementManager>(achievements);
    _registerAchievements(achievements);
  }

  if (!di.isRegistered<UpgradeManager>()) {
    final upgrades = UpgradeManager();
    di.registerSingleton<UpgradeManager>(upgrades);
    _registerUpgrades(upgrades);
    await upgrades.loadUpgrades();
  }

  if (!di.isRegistered<PrestigeManager>()) {
    final prestigeManager = PrestigeManager();
    di.registerSingleton(prestigeManager);
    _setupPrestige(prestigeManager);
    await prestigeManager.loadPrestigeData();
  }

  // ── Game-specific managers ───────────────────────────────
  if (!di.isRegistered<ShopManager>()) {
    di.registerSingleton<ShopManager>(ShopManager());
  }

  if (!di.isRegistered<CraftingManager>()) {
    di.registerSingleton<CraftingManager>(CraftingManager());
  }

  if (!di.isRegistered<DungeonManager>()) {
    di.registerSingleton<DungeonManager>(DungeonManager());
  }

  if (!di.isRegistered<UnifiedIdleManager>()) {
    final idleManager = UnifiedIdleManager();
    await idleManager.initialize();
    di.registerSingleton<UnifiedIdleManager>(idleManager);
  }

  if (!di.isRegistered<CustomerManager>()) {
    final customers = CustomerManager();
    di.registerSingleton<CustomerManager>(customers);
    customers.startCustomerCycle();
  }

  // ── Daily Quest Manager ─────────────────────────────────────
  if (!di.isRegistered<DailyQuestManager>()) {
    final questManager = DailyQuestManager();

    // Register Healing Garden themed quests
    questManager.registerQuest(DailyQuest(
      id: 'garden_harvest_20',
      title: 'Herbalist',
      description: 'Harvest 20 herbs',
      targetValue: 20,
      goldReward: 150,
      xpReward: 50,
    ));

    questManager.registerQuest(DailyQuest(
      id: 'garden_heal_10',
      title: 'Master Healer',
      description: 'Heal 10 patients',
      targetValue: 10,
      goldReward: 200,
      xpReward: 75,
    ));

    questManager.registerQuest(DailyQuest(
      id: 'garden_gold_1200',
      title: 'Garden Prosperity',
      description: 'Earn 1200 gold from remedies',
      targetValue: 1200,
      goldReward: 250,
      xpReward: 80,
    ));

    di.registerSingleton<DailyQuestManager>(questManager);
  }
}

void _registerUpgrades(UpgradeManager manager) {
  manager.registerUpgrade(Upgrade(
    id: 'craft_speed',
    name: 'Forge Mastery',
    description: 'Reduce crafting time by 10% per level.',
    maxLevel: 15,
    baseCost: 50,
    costMultiplier: 1.4,
    valuePerLevel: 0.1,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'sell_price',
    name: 'Haggling',
    description: 'Increase sell prices by 10% per level.',
    maxLevel: 20,
    baseCost: 80,
    costMultiplier: 1.35,
    valuePerLevel: 0.1,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'inventory_space',
    name: 'Storage Expansion',
    description: 'Add 5 inventory slots per level.',
    maxLevel: 10,
    baseCost: 150,
    costMultiplier: 1.5,
    valuePerLevel: 5.0,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'idle_production',
    name: 'Idle Income',
    description: 'Increase offline gold generation by 20% per level.',
    maxLevel: 10,
    baseCost: 300,
    costMultiplier: 1.8,
    valuePerLevel: 0.2,
  ));
}

void _registerAchievements(AchievementManager manager) {
  manager.onAchievementUnlocked = (achievement) {
    FirebaseAnalytics.instance.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievement.id,
      },
    );
  };

  manager.registerAchievement(Achievement(
    id: 'first_sale',
    title: 'Open for Business',
    description: 'Complete your first sale.',
    iconAsset: 'assets/icons/achievement_sale.png',
  ));

  manager.registerAchievement(Achievement(
    id: 'master_crafter',
    title: 'Master Crafter',
    description: 'Craft 50 items.',
    iconAsset: 'assets/icons/achievement_craft.png',
  ));

  manager.registerAchievement(Achievement(
    id: 'master_merchant',
    title: 'Master Merchant',
    description: 'Accumulate 5,000 gold.',
    iconAsset: 'assets/icons/achievement_gold.png',
  ));
}

void _setupPrestige(PrestigeManager manager) {
  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'gold_multiplier',
    name: 'Gold Multiplier',
    description: 'Gold earned +10%',
    maxLevel: 50,
    costPerLevel: 1,
    bonusPerLevel: 0.1,
  ));

  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'xp_boost',
    name: 'XP Boost',
    description: 'XP earned +15%',
    maxLevel: 40,
    costPerLevel: 2,
    bonusPerLevel: 0.15,
  ));
}

class DungeonShopApp extends StatelessWidget {
  const DungeonShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GetIt.I<ShopManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<CraftingManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<DungeonManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<UnifiedIdleManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<CustomerManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<UpgradeManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<ProgressionManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<AchievementManager>()),
      ],
      child: MaterialApp(
        title: 'Dungeon Shop Simulator',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MGColors.gold,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }


  Widget _buildSpineCharacter() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.cyan.withAlpha(150), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 24, color: Colors.white),
            SizedBox(height: 2),
            Text(
              'Hero',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

}
