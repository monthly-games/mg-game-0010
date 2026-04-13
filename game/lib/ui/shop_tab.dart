import 'package:mg_common_game/core/ui/layout/mg_spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/shop_manager.dart';
import '../game/models.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';


class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopManager>(
      builder: (context, shop, _) {
        final items = Item.getDefaultItems();

        return ListView.builder(
          padding: const EdgeInsets.all(MGSpacing.md),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final count = shop.getItemCount(item.id);

            return Card(
              child: ListTile(
                leading: Icon(
                  _getItemIcon(item.type),
                  color: _getItemColor(item.type),
                  size: 40,
                ),
                title: Text(item.name),
                subtitle: Text('재고: $count개, 판매가: ${item.basePrice}g'),
                trailing: count > 0
                    ? ElevatedButton.icon(
                        onPressed: () => shop.sellItem(item),
                        icon: const Icon(Icons.sell),
                        label: const Text('판매'),
                      )
                    : const Text(
                        '재고 없음',
                        style: TextStyle(color: MGColors.common),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getItemIcon(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return Icons.sports_martial_arts;
      case ItemType.armor:
        return Icons.shield;
      case ItemType.potion:
        return Icons.local_drink;
      case ItemType.material:
        return Icons.inventory_2;
    }
  }

  Color _getItemColor(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return MGColors.error;
      case ItemType.armor:
        return MGColors.info;
      case ItemType.potion:
        return MGColors.success;
      case ItemType.material:
        return Colors.brown;
    }
  }
}
