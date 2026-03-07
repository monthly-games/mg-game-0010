import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

/// Achievement category for UI grouping.
///
/// Games should customize [_AchievementScreenState._categoryMap]
/// for their specific achievements.
enum AchievementCategory {
  combat('Combat', Icons.sports_martial_arts_rounded),
  progression('Progression', Icons.trending_up_rounded),
  collection('Collection', Icons.collections_bookmark_rounded),
  social('Social', Icons.people_rounded),
  special('Special', Icons.star_rounded);

  final String label;
  final IconData icon;
  const AchievementCategory(this.label, this.icon);
}

/// Achievement screen for MG-0010 Dungeon Shop Simulator.
///
/// Template for MG-Games retention system (Stage 4).
/// Displays achievements grouped by category with unlock states,
/// point values, and completion percentages.
///
/// ## Firebase Analytics Events
/// | Event | Trigger | Parameters |
/// |-------|---------|------------|
/// | `achievement_screen_viewed` | Screen opened | total_achievements, unlocked_count |
/// | `achievement_tab_changed` | Category tab switched | category |
/// | `achievement_unlocked` | Achievement unlocked (via callback in main.dart) | achievement_id, category, points |
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late final AchievementManager _achievementManager;
  late final TabController _tabController;

  // ── Per-game configuration ──────────────────────────────
  // Customize these maps per game. Unmapped achievements
  // default to [AchievementCategory.special] and 10 points.

  /// Maps achievement IDs to display categories.
  static const Map<String, AchievementCategory> _categoryMap = {
    'first_sale': AchievementCategory.progression,
    'master_crafter': AchievementCategory.progression,
    'master_merchant': AchievementCategory.progression,
    'shop_legend': AchievementCategory.special,
    'customer_favorite': AchievementCategory.social,
  };

  /// Maps achievement IDs to point values.
  static const Map<String, int> _pointsMap = {
    'first_sale': 10,
    'master_crafter': 25,
    'master_merchant': 25,
    'shop_legend': 50,
    'customer_favorite': 30,
  };

  static const int _defaultPoints = 10;

  @override
  void initState() {
    super.initState();
    _achievementManager = GetIt.I<AchievementManager>();
    _achievementManager.addListener(_onUpdate);
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    // Firebase Analytics: Screen view event
    FirebaseAnalytics.instance.logEvent(
      name: 'achievement_screen_viewed',
      parameters: {
        'total_achievements': _achievementManager.totalCount,
        'unlocked_count': _achievementManager.unlockedCount,
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _achievementManager.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final category =
        AchievementCategory.values[_tabController.index];

    // Firebase Analytics: Tab change event
    FirebaseAnalytics.instance.logEvent(
      name: 'achievement_tab_changed',
      parameters: {'category': category.name},
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  AchievementCategory _getCategory(Achievement achievement) {
    return _categoryMap[achievement.id] ?? AchievementCategory.special;
  }

  int _getPoints(Achievement achievement) {
    return _pointsMap[achievement.id] ?? _defaultPoints;
  }

  List<Achievement> _achievementsFor(AchievementCategory cat) {
    return _achievementManager.allAchievements
        .where((a) => _getCategory(a) == cat)
        .toList();
  }

  int _totalPoints() {
    return _achievementManager.unlockedAchievements.fold<int>(
      0,
      (sum, a) => sum + _getPoints(a),
    );
  }

  int _maxPoints() {
    return _achievementManager.allAchievements.fold<int>(
      0,
      (sum, a) => sum + _getPoints(a),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalPts = _totalPoints();
    final maxPts = _maxPoints();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: MGTextStyles.h2.copyWith(
            color: MGColors.textHighEmphasis,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Total points badge in AppBar
          Padding(
            padding: MGSpacing.horizontal(MGSpacing.md),
            child: Center(
              child: Container(
                padding: MGSpacing.symmetric(
                  horizontal: MGSpacing.sm,
                  vertical: MGSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: MGColors.gold.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(MGSpacing.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: MGIcons.badgeSize,
                      color: MGColors.gold,
                    ),
                    MGSpacing.hXxs,
                    Text(
                      '$totalPts / $maxPts',
                      style: MGTextStyles.hudSmall.copyWith(
                        color: MGColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: MGColors.gold,
          labelColor: MGColors.gold,
          unselectedLabelColor: MGColors.textMediumEmphasis,
          tabs: AchievementCategory.values.map((cat) {
            final list = _achievementsFor(cat);
            final unlocked =
                list.where((a) => a.unlocked).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: MGIcons.badgeSize),
                  MGSpacing.hXxs,
                  Text(cat.label),
                  if (list.isNotEmpty) ...[
                    MGSpacing.hXxs,
                    Text(
                      '($unlocked/${list.length})',
                      style: MGTextStyles.caption,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AchievementCategory.values
            .map(_buildCategoryTab)
            .toList(),
      ),
    );
  }

  /// Build a single category tab.
  Widget _buildCategoryTab(AchievementCategory category) {
    final achievements = _achievementsFor(category);

    if (achievements.isEmpty) {
      return _buildEmptyCategory(category);
    }

    final unlockedCount =
        achievements.where((a) => a.unlocked).length;
    final pct =
        (unlockedCount / achievements.length * 100).round();

    return Padding(
      padding: MGSpacing.horizontal(MGSpacing.md),
      child: Column(
        children: [
          MGSpacing.vMd,
          _buildCategoryHeader(
            category,
            unlockedCount,
            achievements.length,
            pct,
          ),
          MGSpacing.vSm,
          Expanded(
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < achievements.length - 1
                        ? MGSpacing.xs
                        : 0,
                  ),
                  child: _buildAchievementTile(
                    achievements[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state for categories with no achievements.
  Widget _buildEmptyCategory(AchievementCategory category) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: MGSpacing.xxl,
            color: MGColors.textDisabled,
          ),
          MGSpacing.vMd,
          Text(
            'No ${category.label} achievements yet',
            style: MGTextStyles.body.copyWith(
              color: MGColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  /// Category progress header with completion bar.
  Widget _buildCategoryHeader(
    AchievementCategory category,
    int unlockedCount,
    int totalCount,
    int pct,
  ) {
    return MGCard(
      backgroundColor: MGColors.surfaceDark,
      borderColor: MGColors.border,
      borderWidth: 1,
      padding: MGSpacing.symmetric(
        horizontal: MGSpacing.md,
        vertical: MGSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            category.icon,
            size: MGIcons.navigationSize,
            color: MGColors.gold,
          ),
          MGSpacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlockedCount / $totalCount unlocked',
                  style: MGTextStyles.bodySmall.copyWith(
                    color: MGColors.textHighEmphasis,
                  ),
                ),
                MGSpacing.vXxs,
                MGLinearProgress(
                  value: totalCount > 0
                      ? unlockedCount / totalCount
                      : 0,
                  valueColor: MGColors.gold,
                  height: 4,
                  borderRadius: 2,
                ),
              ],
            ),
          ),
          MGSpacing.hSm,
          Text(
            '$pct%',
            style: MGTextStyles.hud.copyWith(
              color: MGColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual achievement tile with locked/unlocked state.
  Widget _buildAchievementTile(Achievement achievement) {
    final isUnlocked = achievement.unlocked;
    final points = _getPoints(achievement);

    return MGCard(
      backgroundColor: isUnlocked
          ? MGColors.cardDark
          : MGColors.surfaceDark,
      borderColor: isUnlocked
          ? MGColors.success.withValues(alpha: 0.4)
          : MGColors.border,
      borderWidth: 1,
      child: Row(
        children: [
          // Achievement icon — gold for unlocked, gray for locked
          Container(
            width: MGSpacing.xxl,
            height: MGSpacing.xxl,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? MGColors.gold.withValues(alpha: 0.2)
                  : MGColors.common.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(MGSpacing.sm),
            ),
            child: Icon(
              isUnlocked
                  ? Icons.emoji_events_rounded
                  : Icons.lock_rounded,
              color: isUnlocked
                  ? MGColors.gold
                  : MGColors.common,
              size: MGIcons.navigationSize,
            ),
          ),
          MGSpacing.hSm,
          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: MGTextStyles.body.copyWith(
                    color: isUnlocked
                        ? MGColors.textHighEmphasis
                        : MGColors.textDisabled,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  achievement.hidden && !isUnlocked
                      ? '???'
                      : achievement.description,
                  style: MGTextStyles.caption.copyWith(
                    color: MGColors.textMediumEmphasis,
                  ),
                ),
              ],
            ),
          ),
          // Points badge + unlock status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: MGSpacing.symmetric(
                  horizontal: MGSpacing.xs,
                  vertical: MGSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? MGColors.gold.withValues(alpha: 0.2)
                      : MGColors.common
                          .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(MGSpacing.xxs),
                ),
                child: Text(
                  '$points pts',
                  style: MGTextStyles.caption.copyWith(
                    color: isUnlocked
                        ? MGColors.gold
                        : MGColors.textDisabled,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isUnlocked) ...[
                MGSpacing.vXxs,
                Icon(
                  Icons.check_circle_rounded,
                  size: MGIcons.badgeSize,
                  color: MGColors.success,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
