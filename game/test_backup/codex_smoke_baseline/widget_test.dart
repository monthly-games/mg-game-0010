import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:game/main.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<ProgressionManager>()) {
      GetIt.I.registerSingleton(ProgressionManager());
    }
    if (!GetIt.I.isRegistered<UpgradeManager>()) {
      final upgradeManager = UpgradeManager();
      upgradeManager.registerUpgrade(Upgrade(
        id: 'inventory_space',
        name: 'Storage Expansion',
        description: 'Increases max inventory slots',
        maxLevel: 5,
        baseCost: 500,
        costMultiplier: 1.6,
        valuePerLevel: 5.0,
      ));
      GetIt.I.registerSingleton(upgradeManager);
    }
    if (!GetIt.I.isRegistered<AchievementManager>()) {
      GetIt.I.registerSingleton(AchievementManager());
    }
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('Dungeon Shop smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DungeonShopApp());

    // Verify main menu or initial state
    // Since I don't know the exact UI text, I'll just check if it builds without error
    // and maybe look for a key widget if I knew it.
    // For now, pumping successfully is a good start.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
