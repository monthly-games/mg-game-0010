import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class DungeonManager extends ChangeNotifier {
  int _playerHp = 100;
  int _playerMaxHp = 100;
  int _playerAttack = 10;

  Monster? _currentMonster;
  int _currentMonsterHp = 0;

  bool _inDungeon = false;
  final Random _random = Random();

  int get playerHp => _playerHp;
  int get playerMaxHp => _playerMaxHp;
  int get playerAttack => _playerAttack;
  Monster? get currentMonster => _currentMonster;
  int get currentMonsterHp => _currentMonsterHp;
  bool get inDungeon => _inDungeon;

  /// 던전 입장
  void enterDungeon() {
    _inDungeon = true;
    _playerHp = _playerMaxHp;
    _spawnMonster();
    notifyListeners();
  }

  /// 던전 퇴장
  void exitDungeon() {
    _inDungeon = false;
    _currentMonster = null;
    _currentMonsterHp = 0;
    notifyListeners();
  }

  /// 몬스터 생성
  void _spawnMonster() {
    final monsters = Monster.getDungeonMonsters();
    _currentMonster = monsters[_random.nextInt(monsters.length)];
    _currentMonsterHp = _currentMonster!.hp;
    notifyListeners();
  }

  /// 공격
  Map<String, int>? attack() {
    if (_currentMonster == null || !_inDungeon) return null;

    // 플레이어가 몬스터 공격
    _currentMonsterHp -= _playerAttack;

    Map<String, int>? rewards;

    // 몬스터 처치
    if (_currentMonsterHp <= 0) {
      rewards = Map<String, int>.from(_currentMonster!.drops);
      _spawnMonster();
    } else {
      // 몬스터가 플레이어 공격
      _playerHp -= _currentMonster!.attack;

      // 플레이어 사망
      if (_playerHp <= 0) {
        exitDungeon();
      }
    }

    notifyListeners();
    return rewards;
  }

  /// 체력 회복
  void heal(int amount) {
    _playerHp = (_playerHp + amount).clamp(0, _playerMaxHp);
    notifyListeners();
  }
}
