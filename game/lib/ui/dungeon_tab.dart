import 'package:mg_common_game/core/ui/layout/mg_spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/dungeon_manager.dart';
import '../game/crafting_manager.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';


class DungeonTab extends StatelessWidget {
  const DungeonTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DungeonManager, CraftingManager>(
      builder: (context, dungeon, crafting, _) {
        if (!dungeon.inDungeon) {
          // 던전 입장 화면
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.terrain, size: 100, color: Colors.brown),
                const SizedBox(height: MGSpacing.lg),
                const Text(
                  '던전 탐험',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: MGSpacing.md),
                const Text(
                  '몬스터를 처치하고 재료를 획득하세요!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: MGSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () => dungeon.enterDungeon(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('던전 입장'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        }

        // 던전 전투 화면
        return Column(
          children: [
            // 플레이어 상태
            Container(
              padding: const EdgeInsets.all(MGSpacing.md),
              color: MGColors.info.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '플레이어',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: MGSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: MGColors.error, size: 20),
                          const SizedBox(width: MGSpacing.xxs),
                          Text('${dungeon.playerHp} / ${dungeon.playerMaxHp}'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.flash_on, color: MGColors.warning, size: 20),
                          const SizedBox(width: MGSpacing.xxs),
                          Text('${dungeon.playerAttack}'),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => dungeon.exitDungeon(),
                    child: const Text('던전 퇴장'),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 몬스터
            if (dungeon.currentMonster != null) ...[
              Container(
                padding: const EdgeInsets.all(MGSpacing.lg),
                decoration: BoxDecoration(
                  color: MGColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pest_control,
                      size: 80,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: MGSpacing.md),
                    Text(
                      dungeon.currentMonster!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: MGSpacing.xs),
                    LinearProgressIndicator(
                      value: dungeon.currentMonsterHp / dungeon.currentMonster!.hp,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(MGColors.error),
                    ),
                    const SizedBox(height: MGSpacing.xxs),
                    Text('HP: ${dungeon.currentMonsterHp} / ${dungeon.currentMonster!.hp}'),
                    const SizedBox(height: MGSpacing.xs),
                    Text('공격력: ${dungeon.currentMonster!.attack}'),
                  ],
                ),
              ),
              const SizedBox(height: MGSpacing.xl),
              ElevatedButton.icon(
                onPressed: () {
                  final rewards = dungeon.attack();
                  if (rewards != null && rewards.isNotEmpty) {
                    // 재료 획득
                    for (final entry in rewards.entries) {
                      crafting.addMaterial(entry.key, entry.value);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '재료 획득! ${rewards.entries.map((e) => '${e.key} +${e.value}').join(', ')}',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('공격'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: MGColors.warning,
                ),
              ),
            ],

            const Spacer(),
          ],
        );
      },
    );
  }
}
