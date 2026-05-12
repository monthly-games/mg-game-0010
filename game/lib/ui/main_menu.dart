import 'package:mg_common_game/core/ui/layout/mg_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/core/ui/screens/prestige_screen.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/systems/quests/daily_quest.dart';
import 'package:mg_common_game/core/ui/screens/daily_quest_screen.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';
import 'package:mg_common_game/core/ui/screens/settings_screen.dart' as common;
import 'package:mg_common_game/systems/stats/statistics_manager.dart';
import 'package:mg_common_game/core/ui/screens/statistics_screen.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'package:mg_common_game/systems/quests/weekly_challenge.dart';
import 'package:mg_common_game/core/ui/screens/weekly_challenge_screen.dart';
import 'main_screen.dart';
import 'tutorial_overlay.dart';
import 'package:provider/provider.dart';
import '../game/shop_manager.dart';
import '../game/crafting_manager.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';


class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2c1810), // 어두운 갈색
              Color(0xFF0f0a05), // 거의 검은색
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 게임 제목
                const Text(
                  'DUNGEON',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFd4a574), // 골드
                    shadows: [
                      Shadow(
                        offset: Offset(4, 4),
                        blurRadius: 8,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'SHOP',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: MGColors.warning, // 새들브라운
                    shadows: [
                      Shadow(
                        offset: Offset(4, 4),
                        blurRadius: 8,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'SIMULATOR',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // 플레이 버튼
                _MenuButton(
                  icon: Icons.play_arrow,
                  label: 'PLAY STAGE',
                  color: MGColors.warning,
                  onPressed: () async {
                    final hasSeenTutorial = await TutorialOverlay.hasSeenTutorial();

                    if (!hasSeenTutorial && context.mounted) {
                      // 튜토리얼 먼저 보여주기
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            body: Stack(
                              children: [
                                const MainScreen(),
                                TutorialOverlay(
                                  onComplete: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      // 튜토리얼을 이미 본 경우 바로 게임 시작
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: MGSpacing.mdLg),

                // 데일리 & 위클리 퀘스트 Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _showDailyQuestsScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: MGColors.textHighEmphasis,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in, size: 20),
                            SizedBox(width: MGSpacing.xxs),
                            Text(
                              'DAILY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: MGSpacing.md),
                    SizedBox(
                      width: 130,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _showWeeklyChallengesScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, size: 20),
                            SizedBox(width: MGSpacing.xxs),
                            Text(
                              'WEEKLY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MGSpacing.mdLg),

                // 프레스티지 버튼
                _MenuButton(
                  icon: Icons.auto_awesome,
                  label: 'PRESTIGE',
                  color: Colors.amber.shade800,
                  onPressed: () {
                    _showPrestigeScreen(context);
                  },
                ),
                const SizedBox(height: MGSpacing.mdLg),

                // 설정 및 통계 버튼 Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => common.SettingsScreen(
                                settingsManager: GetIt.I<SettingsManager>(),
                                title: 'Settings',
                                accentColor: MGColors.warning,
                                onClose: () => Navigator.of(context).pop(),
                                version: '1.0.0',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF654321),
                          foregroundColor: MGColors.textHighEmphasis,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings, size: 24),
                            SizedBox(width: 6),
                            Text(
                              'SETTINGS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: MGSpacing.md),
                    SizedBox(
                      width: 130,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _showStatisticsScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: MGColors.textHighEmphasis,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 24),
                            SizedBox(width: 6),
                            Text(
                              'STATS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MGSpacing.mdLg),

                // 정보 버튼
                _MenuButton(
                  icon: Icons.info_outline,
                  label: 'HOW TO PLAY',
                  color: const Color(0xFF704214),
                  onPressed: () {
                    _showHowToPlay(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrestigeScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrestigeScreen(
          prestigeManager: GetIt.I<PrestigeManager>(),
          progressionManager: GetIt.I<ProgressionManager>(),
          title: 'Dungeon Shop Prestige',
          accentColor: Colors.amber.shade800,
          onClose: () => Navigator.of(context).pop(),
          onPrestige: () => _performPrestige(context),
        ),
      ),
    );
  }

  void _performPrestige(BuildContext context) {
    final prestigeManager = GetIt.I<PrestigeManager>();
    final progressionManager = GetIt.I<ProgressionManager>();

    // Perform prestige and get points earned
    final pointsGained = prestigeManager.performPrestige(progressionManager.currentLevel);

    // Reset progression
    progressionManager.reset();

    // Reset gold (spend all current gold)
    final goldManager = GetIt.I<GoldManager>();
    goldManager.trySpendGold(goldManager.currentGold);

    // Reset shop and crafting managers using Provider
    final shopManager = Provider.of<ShopManager>(context, listen: false);
    final craftingManager = Provider.of<CraftingManager>(context, listen: false);

    shopManager.reset();
    craftingManager.reset();

    // Close prestige screen
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prestige successful! Gained $pointsGained points'),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh the UI
    setState(() {});
  }

  void _showDailyQuestsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyQuestScreen(
          questManager: GetIt.I<DailyQuestManager>(),
          title: 'Daily Quests',
          accentColor: Colors.amber.shade800,
          onClaimReward: (questId, goldReward, xpReward) {
            // Give rewards
            final goldManager = GetIt.I<GoldManager>();
            final progressionManager = GetIt.I<ProgressionManager>();

            goldManager.addGold(goldReward);
            progressionManager.addXp(xpReward);
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showStatisticsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          statisticsManager: GetIt.I<StatisticsManager>(),
          progressionManager: GetIt.I<ProgressionManager>(),
          prestigeManager: GetIt.I<PrestigeManager>(),
          questManager: GetIt.I<DailyQuestManager>(),
          achievementManager: GetIt.I<AchievementManager>(),
          title: 'Statistics',
          accentColor: MGColors.warning,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showWeeklyChallengesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WeeklyChallengeScreen(
          challengeManager: GetIt.I<WeeklyChallengeManager>(),
          title: 'Weekly Challenges',
          accentColor: Colors.amber,
          onClaimReward: (challengeId, goldReward, xpReward, prestigeReward) {
            // Give rewards
            final goldManager = GetIt.I<GoldManager>();
            final progressionManager = GetIt.I<ProgressionManager>();
            final prestigeManager = GetIt.I<PrestigeManager>();

            goldManager.addGold(goldReward);
            progressionManager.addXp(xpReward);
            if (prestigeReward > 0) {
              prestigeManager.addPrestigePoints(prestigeReward);
            }
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFFd4a574)),
            SizedBox(width: MGSpacing.xs),
            const Text('How to Play'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏪 Shop Tab',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MGSpacing.xs),
            const Text('Sell items to customers to earn gold'),
            const Text('Upgrade your shop with new equipment'),
            SizedBox(height: MGSpacing.md),
            const Text(
              '⚒️ Crafting Tab',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MGSpacing.xs),
            const Text('Craft items from materials you gather'),
            const Text('Unlock new recipes as you level up'),
            const Text('Create better items for higher profits'),
            SizedBox(height: MGSpacing.md),
            const Text(
              '🗡️ Dungeon Tab',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MGSpacing.xs),
            const Text('Explore dungeons to fight monsters'),
            const Text('Gather rare materials from defeated foes'),
            const Text('Find rare loot and treasure'),
            SizedBox(height: MGSpacing.md),
            const Text(
              '💰 Idle Income',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MGSpacing.xs),
            const Text('Earn gold while away from the game'),
            const Text('Up to 2 hours of offline income'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: MGColors.textHighEmphasis,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.black45,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: MGSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
