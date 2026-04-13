import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 방치 수익 시스템 관리 (MG-0010 simplified version)
class UnifiedIdleManager extends ChangeNotifier {
  static const String _keyLastOnlineTime = 'last_online_time';
  static const String _keyIdleProductionRate = 'idle_production_rate';

  DateTime? _lastOnlineTime;
  int _idleProductionRate = 1; // 시간당 골드 생산량
  int _offlineGoldEarned = 0;

  int get idleProductionRate => _idleProductionRate;
  int get offlineGoldEarned => _offlineGoldEarned;

  /// 앱 시작 시 호출 - 오프라인 보상 계산
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _idleProductionRate = prefs.getInt(_keyIdleProductionRate) ?? 1;

    final lastOnlineStr = prefs.getString(_keyLastOnlineTime);
    if (lastOnlineStr != null) {
      _lastOnlineTime = DateTime.tryParse(lastOnlineStr);
    }

    _refreshOfflineRewards();

    notifyListeners();
  }

  void _refreshOfflineRewards() {
    final lastOnlineTime = _lastOnlineTime;

    if (lastOnlineTime == null) {
      _offlineGoldEarned = 0;
      return;
    }

    // Calculate offline reward (max 2 hours, 120 minutes)
    final now = DateTime.now();
    final diff = now.difference(lastOnlineTime);
    final offlineMinutes = diff.inMinutes.clamp(0, 120); // Max 2 hours

    // Gold earned = production rate * hours
    _offlineGoldEarned = (_idleProductionRate * (offlineMinutes / 60)).floor();
  }

  /// 오프라인 보상 수령
  int claimOfflineRewards() {
    _refreshOfflineRewards();

    final reward = _offlineGoldEarned;
    _offlineGoldEarned = 0;

    notifyListeners();
    return reward;
  }

  /// 방치 생산률 업그레이드
  Future<void> upgradeIdleProduction(int amount) async {
    _idleProductionRate += amount;
    _refreshOfflineRewards();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdleProductionRate, _idleProductionRate);

    notifyListeners();
  }

  /// 앱 종료 시 호출 - 현재 시간 저장
  Future<void> saveLastOnlineTime() async {
    final now = DateTime.now();
    _lastOnlineTime = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOnlineTime, now.toIso8601String());

    notifyListeners();
  }

  /// 오프라인 보상이 있는지 확인
  bool get hasOfflineRewards => _offlineGoldEarned > 0;

  /// 오프라인 시간 (분)
  int get offlineMinutes {
    if (_lastOnlineTime == null) return 0;
    return DateTime.now().difference(_lastOnlineTime!).inMinutes;
  }
}
