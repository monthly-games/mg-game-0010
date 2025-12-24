import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 방치 수익 시스템 관리
class IdleManager extends ChangeNotifier {
  static const String _keyLastOnlineTime = 'last_online_time';
  static const String _keyIdleProductionRate = 'idle_production_rate';

  DateTime? _lastOnlineTime;
  int _idleProductionRate = 1; // 시간당 골드 생산량
  int _offlineGoldEarned = 0;

  // 최대 오프라인 보상 시간 (시간 단위)
  static const int maxOfflineHours = 2;

  int get idleProductionRate => _idleProductionRate;
  int get offlineGoldEarned => _offlineGoldEarned;

  /// 앱 시작 시 호출 - 오프라인 보상 계산
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 마지막 온라인 시간 불러오기
    final lastOnlineStr = prefs.getString(_keyLastOnlineTime);
    if (lastOnlineStr != null) {
      _lastOnlineTime = DateTime.parse(lastOnlineStr);
      _calculateOfflineRewards();
    }

    // 방치 생산률 불러오기
    _idleProductionRate = prefs.getInt(_keyIdleProductionRate) ?? 1;

    notifyListeners();
  }

  /// 오프라인 보상 계산
  void _calculateOfflineRewards() {
    if (_lastOnlineTime == null) return;

    final now = DateTime.now();
    final offlineDuration = now.difference(_lastOnlineTime!);
    final offlineHours = offlineDuration.inHours;

    // 최대 시간 제한
    final cappedHours = offlineHours > maxOfflineHours ? maxOfflineHours : offlineHours;

    // 보상 계산 (시간당 생산량)
    _offlineGoldEarned = cappedHours * _idleProductionRate;
  }

  /// 오프라인 보상 수령
  int claimOfflineRewards() {
    final reward = _offlineGoldEarned;
    _offlineGoldEarned = 0;
    notifyListeners();
    return reward;
  }

  /// 방치 생산률 업그레이드
  Future<void> upgradeIdleProduction(int amount) async {
    _idleProductionRate += amount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdleProductionRate, _idleProductionRate);

    notifyListeners();
  }

  /// 앱 종료 시 호출 - 현재 시간 저장
  Future<void> saveLastOnlineTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOnlineTime, DateTime.now().toIso8601String());
  }

  /// 오프라인 보상이 있는지 확인
  bool get hasOfflineRewards => _offlineGoldEarned > 0;

  /// 오프라인 시간 (분)
  int get offlineMinutes {
    if (_lastOnlineTime == null) return 0;
    return DateTime.now().difference(_lastOnlineTime!).inMinutes;
  }
}
