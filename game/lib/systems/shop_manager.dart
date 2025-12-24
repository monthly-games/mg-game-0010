import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/item.dart';
import '../core/models/material.dart';
import '../core/models/recipe.dart';
import '../core/data/game_data.dart';

/// Manages the Shop's state: Gold, Inventory, Display Slots.
class ShopManager extends ChangeNotifier {
  // Economy
  int _gold = 1000;
  int get gold => _gold;

  // Inventory
  final Map<MaterialItem, int> _materials = {};
  final Map<Item, int> _inventoryItems = {}; // Crafted items in storage

  // Display Slots (Simple version: Index -> Item)
  final List<Item?> _displaySlots = List.filled(3, null); // Start with 3 slots

  // Getters
  Map<MaterialItem, int> get materials => Map.unmodifiable(_materials);
  Map<Item, int> get inventoryItems => Map.unmodifiable(_inventoryItems);
  List<Item?> get displaySlots => List.unmodifiable(_displaySlots);

  // --- Logic ---

  void addGold(int amount) {
    _gold += amount;
    saveState();
    notifyListeners();
  }

  bool spendGold(int amount) {
    if (_gold >= amount) {
      _gold -= amount;
      saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addMaterial(MaterialItem material, int amount) {
    _materials[material] = (_materials[material] ?? 0) + amount;
    saveState();
    notifyListeners();
  }

  bool hasMaterials(Map<MaterialItem, int> required) {
    for (var entry in required.entries) {
      if ((_materials[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }

  void craftItem(Recipe recipe) {
    if (!hasMaterials(recipe.requiredMaterials)) return;

    // Consume materials
    recipe.requiredMaterials.forEach((material, amount) {
      _materials[material] = _materials[material]! - amount;
      if (_materials[material] == 0) _materials.remove(material);
    });

    // Add item (Simulate craft time completion immediately for now)
    _inventoryItems[recipe.resultItem] =
        (_inventoryItems[recipe.resultItem] ?? 0) + 1;

    notifyListeners();
  }

  /// Move item from inventory to display slot
  void displayItem(Item item, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _displaySlots.length) return;
    if (slotIndex >= _unlockedSlots) return; // Locked slot
    if ((_inventoryItems[item] ?? 0) <= 0) return;

    // Return current displayed item to inventory if any
    if (_displaySlots[slotIndex] != null) {
      final oldItem = _displaySlots[slotIndex]!;
      _inventoryItems[oldItem] = (_inventoryItems[oldItem] ?? 0) + 1;
    }

    // Place new item
    _inventoryItems[item] = _inventoryItems[item]! - 1;
    if (_inventoryItems[item] == 0) _inventoryItems.remove(item);

    _displaySlots[slotIndex] = item;
    notifyListeners();
  }

  /// Sell item from slot
  void sellItemFromSlot(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _displaySlots.length) return;
    final item = _displaySlots[slotIndex];
    if (item == null) return;

    // Add gold
    addGold(item.basePrice);

    // Clear slot
    _displaySlots[slotIndex] = null;
    notifyListeners();
  }

  // --- Debug / Initial Data ---
  void debugAddStarterMaterials() {
    // We need some reference to specific materials.
    // Ideally these constants come from a DataManager.
    // For now we will accept them as arguments or define basic ones here implicitly?
    // This method is just a skeleton.
  }
}
