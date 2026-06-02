import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> returnToMenu(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('core-fun-loop')), findsOneWidget);
  }

  group('MG-0010 Crafting Idle - Game Loop E2E', () {
    testWidgets('Core gameplay loop: crafting mechanics and idle progression', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('game-id')), findsOneWidget);
      expect(find.text('MG-0010'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('primary-loop')), findsOneWidget);
      expect(find.textContaining('Level 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('complete-action')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Level 2'), findsOneWidget);
    });

    testWidgets('Order system and customer requests', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      expect(find.textContaining('order'), findsOneWidget);
      expect(find.textContaining('customer'), findsOneWidget);
      expect(find.textContaining('request'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('complete-action')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Level 2'), findsOneWidget);
    });

    testWidgets('Guild trade system and economy', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('guild-war')));
      await tester.pumpAndSettle();
      expect(find.text('Guild War'), findsWidgets);
      expect(find.textContaining('trade'), findsOneWidget);
      expect(find.textContaining('economy'), findsOneWidget);
      await returnToMenu(tester);
    });

    testWidgets('Idle progression and resource accumulation', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      expect(find.textContaining('idle'), findsOneWidget);
      expect(find.textContaining('resource'), findsOneWidget);

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Level 6'), findsOneWidget);
    });

    testWidgets('Full game loop: craft -> fulfill orders -> trade', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Level 4'), findsOneWidget);
    });
  });
}