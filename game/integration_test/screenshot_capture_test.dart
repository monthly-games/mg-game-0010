import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:platformer/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Capture', () {
    testWidgets('Capture all store screens', (WidgetTester tester) async {
      // Launch app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for app to be fully rendered
      await tester.pumpAndSettle(const Duration(seconds: 1));

      print('📱 App launched');

      // 1. Main Menu Screen
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot('MG-0010/01_main_menu');
      print('✓ Captured: 01_main_menu');

      // 2. Game Screen - Initial State
      final startButton = find.byKey(const ValueKey('start-game'));
      if (tester.any(startButton)) {
        await tester.tap(startButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/02_game_play_initial');
        print('✓ Captured: 02_game_play_initial');

        // 3. Game Screen - Progressed State
        final completeButton = find.byKey(const ValueKey('complete-action'));
        if (tester.any(completeButton)) {
          for (int i = 0; i < 5; i++) {
            await tester.tap(completeButton);
            await tester.pumpAndSettle();
          }
        }

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/03_game_play_progressed');
        print('✓ Captured: 03_game_play_progressed');

        // Return to menu
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 4. Level Roadmap Screen
      final roadmapButton = find.byKey(const ValueKey('level-roadmap'));
      if (tester.any(roadmapButton)) {
        await tester.tap(roadmapButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/04_level_roadmap');
        print('✓ Captured: 04_level_roadmap');

        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 5. Daily Quests Screen
      final dailyButton = find.byKey(const ValueKey('daily-quests'));
      if (tester.any(dailyButton)) {
        await tester.tap(dailyButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/05_daily_quests');
        print('✓ Captured: 05_daily_quests');

        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 6. Tournament Screen
      final tournamentButton = find.byKey(const ValueKey('tournament'));
      if (tester.any(tournamentButton)) {
        await tester.tap(tournamentButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/06_tournament');
        print('✓ Captured: 06_tournament');

        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 7. Seasonal Event Screen
      final eventButton = find.byKey(const ValueKey('seasonal-event'));
      if (tester.any(eventButton)) {
        await tester.tap(eventButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('MG-0010/07_seasonal_event');
        print('✓ Captured: 07_seasonal_event');
      }

      print('✅ All screenshots captured!');
    });
  });
}
