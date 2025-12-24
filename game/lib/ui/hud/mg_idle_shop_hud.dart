import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// MG UI 기반 아이들 샵 게임 HUD
/// mg_common_game의 공통 UI 컴포넌트 활용
class MGIdleShopHud extends StatelessWidget {
  final int gold;
  final int customersServed;
  final int itemsCrafted;
  final String currentTab;
  final VoidCallback? onSettings;

  const MGIdleShopHud({
    super.key,
    required this.gold,
    this.customersServed = 0,
    this.itemsCrafted = 0,
    this.currentTab = 'shop',
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return Positioned.fill(
      child: Column(
        children: [
          // 상단 HUD: 골드 + 탭 정보 + 설정
          Container(
            padding: EdgeInsets.only(
              top: safeArea.top + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 현재 탭 표시
                _buildTabIndicator(),

                // 골드 표시
                MGResourceBar(
                  icon: Icons.monetization_on,
                  value: _formatNumber(gold),
                  iconColor: MGColors.gold,
                  onTap: null,
                ),

                // 설정 버튼
                if (onSettings != null)
                  MGIconButton(
                    icon: Icons.settings,
                    onPressed: onSettings,
                    size: 44,
                    backgroundColor: Colors.black54,
                    color: Colors.white,
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),

          // 중앙 영역 확장 (게임 영역)
          const Expanded(child: SizedBox()),

          // 하단: 통계 표시
          Container(
            padding: EdgeInsets.only(
              bottom: safeArea.bottom + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBadge(
                  Icons.people,
                  'Served: $customersServed',
                  Colors.green,
                ),
                MGSpacing.hMd,
                _buildStatBadge(
                  Icons.build,
                  'Crafted: $itemsCrafted',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIndicator() {
    IconData icon;
    String label;
    Color color;

    switch (currentTab) {
      case 'shop':
        icon = Icons.store;
        label = 'SHOP';
        color = const Color(0xFF8B4513);
        break;
      case 'crafting':
        icon = Icons.build;
        label = 'CRAFT';
        color = Colors.orange;
        break;
      case 'dungeon':
        icon = Icons.terrain;
        label = 'DUNGEON';
        color = Colors.purple;
        break;
      default:
        icon = Icons.store;
        label = 'SHOP';
        color = const Color(0xFF8B4513);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            label,
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          MGSpacing.hXs,
          Text(
            text,
            style: MGTextStyles.caption.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
