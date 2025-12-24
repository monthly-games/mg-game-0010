import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/shop_manager.dart';
import '../game/models.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopManager>(
      builder: (context, shop, _) {
        final items = Item.getDefaultItems();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                subtitle: Text('재고: $count개 | 판매가: ${item.basePrice}G'),
                trailing: count > 0
                    ? ElevatedButton.icon(
                        onPressed: () => shop.sellItem(item),
                        icon: const Icon(Icons.sell),
                        label: const Text('판매'),
                      )
                    : const Text(
                        '재고 없음',
                        style: TextStyle(color: Colors.grey),
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
        return Colors.red;
      case ItemType.armor:
        return Colors.blue;
      case ItemType.potion:
        return Colors.green;
      case ItemType.material:
        return Colors.brown;
    }
  }
}
