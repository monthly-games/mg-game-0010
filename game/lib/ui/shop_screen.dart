import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart'; // Assuming common game is available
import '../systems/shop_manager.dart';
import '../core/data/game_data.dart';
import '../core/models/recipe.dart';
import '../core/models/item.dart';
import '../core/models/customer.dart';
import 'dungeon_screen.dart';
import '../systems/audio_manager.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopManager _shopManager = GetIt.I<ShopManager>();
  final AudioManager _audio = AudioManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Debug: Add starter materials
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopManager.addMaterial(GameData.wood, 10);
      _shopManager.addMaterial(GameData.iron, 5);
      _shopManager.addMaterial(GameData.herb, 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shopManager, // Rebuild when shop state changes
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dungeon Shop Sim'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Shop', icon: Icon(Icons.store)),
                Tab(text: 'Craft', icon: Icon(Icons.build)),
                Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
              ],
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    'Gold: ${_shopManager.gold}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.campaign, color: Colors.orange),
                onPressed: () => _showMarketingDialog(context),
                tooltip: "Marketing Upgrade",
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildShopTab(),
              _buildCraftTab(),
              _buildInventoryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopTab() {
    final slots = _shopManager.displaySlots;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Display Slots - Tap to Sell',
              style: TextStyle(fontSize: 18)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final isLocked = index >= _shopManager.unlockedSlots;
              final item = slots[index];

              if (isLocked) {
                return GestureDetector(
                  onTap: () => _showUnlockDialog(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey),
                        Text("Locked",
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  if (item != null) {
                    // Simulate User Sell
                    _shopManager.sellItemFromSlot(index);
                    _audio.playSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Sold ${item.name}!'),
                          duration: const Duration(milliseconds: 500)),
                    );
                  } else {
                    _showSlotAssignmentDialog(index);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: item != null ? Colors.amber : Colors.grey),
                  ),
                  child: item != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag,
                                color: Colors.amber, size: 32),
                            Text(item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                            Text('${item.basePrice} G',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.yellowAccent)),
                          ],
                        )
                      : const Center(
                          child: Text('Empty',
                              style: TextStyle(color: Colors.white54))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUnlockDialog(BuildContext context) {
    final cost = _shopManager.nextSlotCost;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Unlock New Slot?"),
              content: Text("Expand your shop for $cost G?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (_shopManager.buySlotUpgrade()) {
                      Navigator.pop(context);
                      _audio.playSuccess(); // Reusing success sound
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Not enough Gold!")));
                    }
                  },
                  child: const Text("Buy"),
                )
              ],
            ));
  }

  void _showMarketingDialog(BuildContext context) {
    final level = _shopManager.marketingLevel;
    final cost = _shopManager.nextMarketingCost;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Marketing Level $level"),
              content: Text("Increase customer traffic?\nCost: $cost G"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (_shopManager.buyMarketingUpgrade()) {
                      Navigator.pop(context);
                      _audio.playSuccess();
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Not enough Gold!")));
                    }
                  },
                  child: const Text("Upgrade"),
                )
              ],
            ));
  }

  void _showSlotAssignmentDialog(int slotIndex) {
    final inventory = _shopManager.inventoryItems;
    if (inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No items to display! Craft something first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Item to Display'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory.keys.elementAt(index);
              final count = inventory[item]!;
              return ListTile(
                title: Text(item.name),
                subtitle: Text('In Stock: $count'),
                trailing: Text('${item.basePrice} G'),
                onTap: () {
                  _shopManager.displayItem(item, slotIndex);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCraftTab() {
    final recipes = GameData.recipes;

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final canCraft = _shopManager.hasMaterials(recipe.requiredMaterials);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.book),
            title: Text(recipe.resultItem.name),
            subtitle: Text(
              recipe.requiredMaterials.entries
                  .map((e) => '${e.key.name}: ${e.value}')
                  .join(', '),
            ),
            trailing: ElevatedButton(
              onPressed: canCraft
                  ? () {
                      _shopManager.craftItem(recipe);
                      _audio.playCraft();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Crafted ${recipe.resultItem.name}'),
                            duration: const Duration(milliseconds: 500)),
                      );
                    }
                  : null,
              child: const Text('Craft'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    final materials = _shopManager.materials;
    final items = _shopManager.inventoryItems;

    return ListView(
      children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Materials",
                style: TextStyle(fontWeight: FontWeight.bold))),
        ...materials.entries.map((e) => ListTile(
              leading: const Icon(Icons.grain),
              title: Text(e.key.name),
              trailing: Text('x${e.value}'),
            )),
        const Divider(),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Crafted Items",
                style: TextStyle(fontWeight: FontWeight.bold))),
        if (items.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("No items.")),
        ...items.entries.map((e) => ListTile(
              leading: const Icon(Icons.shield),
              title: Text(e.key.name),
              trailing: Text('x${e.value}'),
            )),
      ],
    );
  }
}
