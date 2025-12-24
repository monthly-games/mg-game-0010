import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'systems/shop_manager.dart';
import 'systems/dungeon_manager.dart';
import 'ui/shop_screen.dart';

// Common Imports (Keep these if you need them later, or comment out)
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  runApp(const DungeonShopApp());
}

Future<void> _setupDI() async {
  // Register ShopManager
  if (!GetIt.I.isRegistered<ShopManager>()) {
    final manager = ShopManager();
    await manager.loadState();
    GetIt.I.registerSingleton(manager);
  }

  // Register DungeonManager
  if (!GetIt.I.isRegistered<DungeonManager>()) {
    GetIt.I.registerSingleton(DungeonManager());
  }

  // Register GoldManager if needed by common UI components (though ShopManager has its own Gold for now)
  // Integrating Common Gold Manager might be good later, but for Phase 1 we use ShopManager's gold.
}

class DungeonShopApp extends StatelessWidget {
  const DungeonShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dungeon Shop Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ShopScreen(),
    );
  }
}
