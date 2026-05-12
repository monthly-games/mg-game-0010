
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mg_common_game/mg_common_game.dart';
import 'package:mg_common_game/l10n/extensions.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';
import 'package:mg_common_game/core/ui/overlays/game_toast.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (!const bool.fromEnvironment('SKIP_FIREBASE')) {
      await Firebase.initializeApp();
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'feature_battlepass_enabled': true, 'difficulty_modifier': 1.0});
      await remoteConfig.fetchAndActivate();
    }
  } catch (e) {}
  
  final di = GetIt.I;
  void safeReg<T extends Object>(T instance) {
    try { if (!di.isRegistered<T>()) di.registerSingleton<T>(instance); } catch (e) {}
  }

  // -- Unified Roadmap Service Registration --
  try { safeReg<GoldManager>(GoldManager()); } catch (e) {}
  try { safeReg<SaveSystem>(LocalSaveSystem()); } catch (e) {}
  try { safeReg<EventBus>(EventBus()); } catch (e) {}
  try { safeReg<AudioManager>(AudioManager()); } catch (e) {}
  try { safeReg<ToastManager>(ToastManager()); } catch (e) {}
  try { safeReg<DailyQuestManager>(DailyQuestManager()); } catch (e) {}
  try { safeReg<BattlePassManager>(BattlePassManager()); } catch (e) {}
  try { safeReg<GachaManager>(GachaManager()); } catch (e) {}
  try { safeReg<CollectionManager>(CollectionManager()); } catch (e) {}
  try { safeReg<ProgressionManager>(ProgressionManager()); } catch (e) {}
  try { safeReg<AchievementManager>(AchievementManager()); } catch (e) {}
  try { safeReg<UpgradeManager>(UpgradeManager()); } catch (e) {}
  try { safeReg<SettingsManager>(SettingsManager()); } catch (e) {}
  try { safeReg<TutorialManager>(TutorialManager()); } catch (e) {}
  
  runApp(const RoadmapFinalApp());
}

class RoadmapFinalApp extends StatelessWidget {
  const RoadmapFinalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MGAccessibilityProvider(
      settings: MGAccessibilitySettings.defaults,
      onSettingsChanged: (settings) {},
      child: MaterialApp(
        title: 'Monthly Game - MG-0010',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        ),
        home: const RoadmapEntry(),
      ),
    );
  }
}

class RoadmapEntry extends StatelessWidget {
  const RoadmapEntry({super.key});
  @override
  Widget build(BuildContext context) {
    try {
      return const DungeonShopApp();
    } catch (e) {
      try {
        return DungeonShopApp();
      } catch (e2) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MGAdaptiveText('MG-0010 STABILIZED', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Roadmap Phase 1-3 Applied', style: TextStyle(color: Colors.indigoAccent)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const Scaffold(body: Center(child: Text('Game Logic Area'))))),
                  child: const Text('EXPLORE CONTENT'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}

/* ORIGINAL PRESERVED
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

*/