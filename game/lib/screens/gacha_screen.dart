// ============================================================
// Gacha Screen — MG-0010 Dungeon Shop Simulator
// Genre: Idle Simulation · Gacha System UI
// ============================================================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/core/ui/widgets/gacha/gacha_pull_animation.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';

const int _kSinglePullCost = 160;
const int _kMultiPullCost = 1600;
const int _kMultiPullCount = 10;

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with SingleTickerProviderStateMixin {
  late final GachaManager _gachaManager;
  late final TabController _tabController;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  String? _selectedPoolId;
  List<GachaResult>? _pullResults;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _gachaManager = GetIt.I<GachaManager>();
    _tabController = TabController(length: 2, vsync: this);
    _gachaManager.addListener(_onGachaChanged);

    final pools = _gachaManager.activePools;
    if (pools.isNotEmpty) {
      _selectedPoolId = pools.first.id;
    }

    _analytics.logEvent(
      name: 'gacha_screen_opened',
      parameters: {
        'pool_count': _gachaManager.activePools.length,
        'selected_pool': _selectedPoolId ?? 'none',
      },
    );
  }

  @override
  void dispose() {
    _gachaManager.removeListener(_onGachaChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onGachaChanged() {
    if (mounted) setState(() {});
  }

  GachaPool? get _currentPool {
    if (_selectedPoolId == null) return null;
    return _gachaManager.activePools
        .where((p) => p.id == _selectedPoolId)
        .firstOrNull;
  }

  Future<void> _onSinglePull() async {
    if (_selectedPoolId == null || _isAnimating) return;
    final result = _gachaManager.pull(_selectedPoolId!);
    if (result == null) return;
    setState(() {
      _pullResults = [result];
      _isAnimating = true;
    });
    await _analytics.logEvent(
      name: 'gacha_pull',
      parameters: {
        'pool_id': _selectedPoolId!,
        'pull_count': 1,
        'currency_spent': _kSinglePullCost,
        'result_rarity': result.item.rarity.nameKr,
        'is_pity_triggered': result.isPityTriggered,
      },
    );
  }

  Future<void> _onMultiPull() async {
    if (_selectedPoolId == null || _isAnimating) return;
    final results = _gachaManager.multiPull(
      _selectedPoolId!,
      count: _kMultiPullCount,
    );
    if (results.isEmpty) return;
    final highestRarity = results
        .map((r) => r.item.rarity.index)
        .reduce((a, b) => a > b ? a : b);
    setState(() {
      _pullResults = results;
      _isAnimating = true;
    });
    await _analytics.logEvent(
      name: 'gacha_pull',
      parameters: {
        'pool_id': _selectedPoolId!,
        'pull_count': _kMultiPullCount,
        'currency_spent': _kMultiPullCost,
        'highest_rarity': GachaRarity.values[highestRarity].nameKr,
        'pity_triggered_count':
            results.where((r) => r.isPityTriggered).length,
      },
    );
  }

  Future<void> _onPoolSelected(String poolId) async {
    setState(() => _selectedPoolId = poolId);
    await _analytics.logEvent(
      name: 'gacha_pool_selected',
      parameters: {'pool_id': poolId},
    );
  }

  void _onAnimationComplete() {
    setState(() => _isAnimating = false);
  }

  void _dismissResults() {
    setState(() {
      _pullResults = null;
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pullResults != null) {
      return Scaffold(
        backgroundColor: MGColors.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(MGSpacing.md),
                  child: MGIconButton(
                    icon: Icons.close,
                    onPressed: _dismissResults,
                    color: MGColors.textHighEmphasis,
                    backgroundColor: MGColors.surfaceDark,
                    size: 40,
                    enabled: !_isAnimating,
                  ),
                ),
              ),
              Expanded(
                child: GachaPullAnimation(
                  results: _pullResults!.map((r) => r.item).toList(),
                  onComplete: _onAnimationComplete,
                ),
              ),
              if (!_isAnimating) _buildResultSummary(),
              if (!_isAnimating)
                Padding(
                  padding: EdgeInsets.all(MGSpacing.lg),
                  child: MGButton(
                    label: 'OK',
                    onPressed: _dismissResults,
                    size: MGButtonSize.large,
                    width: double.infinity,
                    backgroundColor: MGColors.primaryAction,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MGColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPullTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: MGSpacing.symmetric(
        horizontal: MGSpacing.md,
        vertical: MGSpacing.xs,
      ),
      child: Row(
        children: [
          MGIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            color: MGColors.textHighEmphasis,
            backgroundColor: MGColors.surfaceDark,
            size: 40,
          ),
          const Spacer(),
          MGResourceBar(
            icon: Icons.diamond,
            value: '2,400',
            iconColor: MGColors.gem,
          ),
          SizedBox(width: MGSpacing.sm),
          MGResourceBar(
            icon: Icons.confirmation_number,
            value: '5',
            iconColor: MGColors.year1Accent,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MGColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: MGColors.gem,
        labelColor: MGColors.textHighEmphasis,
        unselectedLabelColor: MGColors.textDisabled,
        onTap: (index) {
          if (index == 1) {
            _analytics.logEvent(
              name: 'gacha_history_viewed',
              parameters: {
                'pool_id': _selectedPoolId ?? 'none',
                'total_pulls':
                    _gachaManager.getPityState(_selectedPoolId ?? '')
                        ?.totalPulls ?? 0,
              },
            );
          }
        },
        tabs: const [
          Tab(icon: Icon(Icons.auto_awesome), text: 'Summon'),
          Tab(icon: Icon(Icons.history), text: 'History'),
        ],
      ),
    );
  }

  Widget _buildPullTab() {
    final pools = _gachaManager.activePools;
    if (pools.isEmpty) {
      return const Center(
        child: Text(
          'No active gacha pools',
          style: TextStyle(color: MGColors.textMediumEmphasis),
        ),
      );
    }
    final pool = _currentPool;
    if (pool == null) return const SizedBox.shrink();
    final pityState = _gachaManager.getPityState(pool.id);
    final pityConfig = _gachaManager.pityConfig;

    return SingleChildScrollView(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Column(
        children: [
          if (pools.length > 1) ...[
            _buildPoolSelector(pools),
            SizedBox(height: MGSpacing.lg),
          ],
          _buildBannerArea(pool),
          SizedBox(height: MGSpacing.lg),
          _buildRateTable(pool),
          SizedBox(height: MGSpacing.lg),
          if (pityState != null)
            GachaPityIndicator(
              currentPulls: pityState.currentPity,
              softPity: pityConfig.softPityStart,
              hardPity: pityConfig.hardPity,
            ),
          SizedBox(height: MGSpacing.lg),
          _buildPullButtons(),
        ],
      ),
    );
  }

  Widget _buildPoolSelector(List<GachaPool> pools) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pools.length,
        separatorBuilder: (_, _) => SizedBox(width: MGSpacing.sm),
        itemBuilder: (context, index) {
          final pool = pools[index];
          final isSelected = pool.id == _selectedPoolId;
          return GestureDetector(
            onTap: () => _onPoolSelected(pool.id),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.md,
                vertical: MGSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? MGColors.gem.withValues(alpha: 0.3)
                    : MGColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? MGColors.gem : MGColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                pool.nameKr,
                style: TextStyle(
                  color: isSelected
                      ? MGColors.textHighEmphasis
                      : MGColors.textMediumEmphasis,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerArea(GachaPool pool) {
    return MGCard(
      backgroundColor: MGColors.surfaceDark,
      borderColor: MGColors.gem.withValues(alpha: 0.3),
      padding: EdgeInsets.all(MGSpacing.lg),
      child: Column(
        children: [
          Text(
            pool.nameKr,
            style: MGTextStyles.h2.copyWith(
              color: MGColors.textHighEmphasis,
            ),
          ),
          if (pool.description != null) ...[
            SizedBox(height: MGSpacing.xs),
            Text(
              pool.description!,
              style: MGTextStyles.bodySmall.copyWith(
                color: MGColors.textMediumEmphasis,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: MGSpacing.md),
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MGColors.gem.withValues(alpha: 0.15),
                  MGColors.legendary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MGColors.gem.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: MGColors.gem, size: 40),
                  SizedBox(height: MGSpacing.xs),
                  Text(
                    '${pool.items.length} items available',
                    style: MGTextStyles.caption.copyWith(
                      color: MGColors.textMediumEmphasis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pool.remainingSeconds != null) ...[
            SizedBox(height: MGSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: MGColors.warning, size: 16),
                SizedBox(width: MGSpacing.xs),
                Text(
                  _formatRemainingTime(pool.remainingSeconds!),
                  style: MGTextStyles.caption.copyWith(
                    color: MGColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateTable(GachaPool pool) {
    return MGCard.outlined(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drop Rates',
            style: MGTextStyles.h3.copyWith(
              color: MGColors.textHighEmphasis,
            ),
          ),
          SizedBox(height: MGSpacing.sm),
          ...GachaRarity.values.reversed.map((rarity) {
            final rate = pool.getRateForRarity(rarity);
            if (rate <= 0) return const SizedBox.shrink();
            return _buildRateRow(rarity, rate);
          }),
        ],
      ),
    );
  }

  Widget _buildRateRow(GachaRarity rarity, double rate) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MGSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.xs,
              vertical: MGSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _getRarityColor(rarity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rarity.nameKr,
              style: const TextStyle(
                color: MGColors.textHighEmphasis,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: MGSpacing.sm),
          Expanded(
            child: MGLinearProgress(
              value: rate / 100,
              height: 6,
              valueColor: _getRarityColor(rarity),
              backgroundColor: MGColors.surfaceDark,
              borderRadius: 3,
            ),
          ),
          SizedBox(width: MGSpacing.sm),
          SizedBox(
            width: 50,
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: MGTextStyles.caption.copyWith(
                color: MGColors.textHighEmphasis,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPullButtons() {
    return Row(
      children: [
        Expanded(
          child: GachaPullButton(
            label: '1x Pull',
            cost: _kSinglePullCost,
            onPressed: _onSinglePull,
          ),
        ),
        SizedBox(width: MGSpacing.md),
        Expanded(
          child: GachaPullButton(
            label: '10x Pull',
            cost: _kMultiPullCost,
            onPressed: _onMultiPull,
          ),
        ),
      ],
    );
  }

  Widget _buildResultSummary() {
    if (_pullResults == null) return const SizedBox.shrink();
    final rarityCounts = <GachaRarity, int>{};
    for (final result in _pullResults!) {
      rarityCounts[result.item.rarity] =
          (rarityCounts[result.item.rarity] ?? 0) + 1;
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MGSpacing.md),
      child: Wrap(
        spacing: MGSpacing.sm,
        children: rarityCounts.entries.map((entry) {
          return Chip(
            avatar: CircleAvatar(
              backgroundColor: _getRarityColor(entry.key),
              radius: 10,
            ),
            label: Text(
              '${entry.key.nameKr} x${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: MGColors.surfaceDark,
            side: BorderSide(
              color: _getRarityColor(entry.key).withValues(alpha: 0.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final history = _gachaManager.history;
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: MGColors.textDisabled, size: 64),
            SizedBox(height: MGSpacing.md),
            Text(
              'No pull history yet',
              style: MGTextStyles.body.copyWith(color: MGColors.textDisabled),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(MGSpacing.md),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final rarityColor = _getRarityColor(entry.rarity);
        return Padding(
          padding: EdgeInsets.only(bottom: MGSpacing.xs),
          child: MGCard(
            backgroundColor: MGColors.surfaceDark,
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.md,
              vertical: MGSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor),
                  ),
                  child: Center(
                    child: Text(
                      entry.rarity.nameKr,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MGSpacing.sm),
                Expanded(
                  child: Text(
                    entry.itemId,
                    style: MGTextStyles.bodySmall.copyWith(
                      color: MGColors.textHighEmphasis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRarityColor(GachaRarity rarity) {
    return switch (rarity) {
      GachaRarity.normal => MGColors.common,
      GachaRarity.rare => MGColors.rare,
      GachaRarity.superRare => MGColors.epic,
      GachaRarity.ultraRare => MGColors.legendary,
      GachaRarity.legendary => MGColors.mythic,
    };
  }

  String _formatRemainingTime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    if (days > 0) return '${days}d ${hours}h remaining';
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m remaining';
  }
}
