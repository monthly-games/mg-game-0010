import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/crafting_manager.dart';
import '../game/shop_manager.dart';
import '../game/models.dart';

class CraftingTab extends StatelessWidget {
  const CraftingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CraftingManager, ShopManager>(
      builder: (context, crafting, shop, _) {
        return Column(
          children: [
            // 제작 슬롯
            if (crafting.craftingSlots.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '제작 중',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: crafting.craftingSlots.length,
                  itemBuilder: (context, index) {
                    final slot = crafting.craftingSlots[index];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: slot.progress),
                              const SizedBox(height: 4),
                              Text('${slot.remainingSeconds}초 남음'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 수집 버튼
              if (crafting.completedCount > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final items = crafting.collectCompletedItems();
                      for (final item in items) {
                        shop.addItem(item);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${items.length}개 아이템 수집!')),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: Text('완성된 아이템 수집 (${crafting.completedCount})'),
                  ),
                ),
            ],

            // 재료 현황
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '보유 재료',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: GameMaterial.getDefaultMaterials().map((material) {
                      final count = crafting.getMaterialCount(material.id);
                      return Chip(
                        label: Text('${material.name}: $count'),
                        avatar: const Icon(Icons.inventory_2, size: 16),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(),

            // 제작 가능한 아이템
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: Item.getDefaultItems().length,
                itemBuilder: (context, index) {
                  final item = Item.getDefaultItems()[index];
                  final canCraft = _canCraft(item, crafting);

                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('제작 시간: ${item.craftingTime}초'),
                          Text(
                            '필요 재료: ${item.materials.entries.map((e) => '${GameMaterial.getDefaultMaterials().firstWhere((m) => m.id == e.key).name} ${e.value}').join(', ')}',
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: canCraft
                            ? () {
                                if (crafting.startCrafting(item)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item.name} 제작 시작!')),
                                  );
                                }
                              }
                            : null,
                        child: const Text('제작'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _canCraft(Item item, CraftingManager crafting) {
    for (final entry in item.materials.entries) {
      if (crafting.getMaterialCount(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }
}
