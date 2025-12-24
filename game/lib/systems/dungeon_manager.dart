import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../core/models/dungeon.dart';
import '../core/models/material.dart';
import 'shop_manager.dart'; // Direct dependency for now or interact via UI

enum ExplorationState { idle, exploring, completed }

class DungeonManager extends ChangeNotifier {
  final ShopManager _shopManager =
      GetIt.I<ShopManager>(); // We will use GetIt to find ShopManager

  ExplorationState _state = ExplorationState.idle;
  Dungeon? _currentDungeon;
  Timer? _timer;
  int _remainingSeconds = 0;
  Map<MaterialItem, int> _lastRewards = {};

  ExplorationState get state => _state;
  Dungeon? get currentDungeon => _currentDungeon;
  int get remainingSeconds => _remainingSeconds;
  Map<MaterialItem, int> get lastRewards => Map.unmodifiable(_lastRewards);

  void startExploration(Dungeon dungeon) {
    if (_state == ExplorationState.exploring) return;

    _state = ExplorationState.exploring;
    _currentDungeon = dungeon;
    _remainingSeconds = dungeon.durationSeconds;
    _lastRewards = {};

    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeExploration();
      }
    });
  }

  void _completeExploration() {
    _timer?.cancel();
    _state = ExplorationState.completed;

    // Calculate Rewards
    final rng = Random();
    if (_currentDungeon != null) {
      for (var drop in _currentDungeon!.drops) {
        if (rng.nextDouble() <= drop.chance) {
          final count =
              drop.minAmount + rng.nextInt(drop.maxAmount - drop.minAmount + 1);
          if (count > 0) {
            _lastRewards[drop.material] =
                (_lastRewards[drop.material] ?? 0) + count;
          }
        }
      }
    }

    notifyListeners();
  }

  void claimRewards() {
    if (_state != ExplorationState.completed) return;

    // Add to ShopManager Inventory
    _lastRewards.forEach((material, amount) {
      _shopManager.addMaterial(material, amount);
    });

    // Reset
    _state = ExplorationState.idle;
    _currentDungeon = null;
    _lastRewards = {};
    notifyListeners();
  }

  // For UI Cancellation if needed
  void cancelExploration() {
    if (_state != ExplorationState.exploring) return;
    _timer?.cancel();
    _state = ExplorationState.idle;
    _currentDungeon = null;
    notifyListeners();
  }
}
