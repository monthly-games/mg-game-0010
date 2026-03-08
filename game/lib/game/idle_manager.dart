import 'package:flutter/foundation.dart';
import 'package:mg_common_game/systems/idle/idle_config.dart';
import 'package:mg_common_game/systems/idle/legacy_idle_adapter.dart';
import 'package:mg_common_game/systems/idle/unified_idle_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 방치 수익 시스템 관리
class IdleManager extends ChangeNotifier {
  static const String _keyLastOnlineTime = 'last_online_time';
  static const String _keyIdleProductionRate = 'idle_production_rate';
  static const String _legacyRateModifierId = 'mg0010_legacy_idle_rate';

  late final IdleConfig _config;
  UnifiedIdleManager? _unified;
  DateTime? _lastOnlineTime;
  int _idleProductionRate = 1; // 시간당 골드 생산량
  int _offlineGoldEarned = 0;

  int get idleProductionRate => _idleProductionRate;
  int get offlineGoldEarned => _offlineGoldEarned;

  /// 앱 시작 시 호출 - 오프라인 보상 계산
  Future<void> initialize() async {
    _config = LegacyIdleAdapter.detectConfig('mg-game-0010');
    _unified = UnifiedIdleManager(config: _config);

    final prefs = await SharedPreferences.getInstance();
    _idleProductionRate = prefs.getInt(_keyIdleProductionRate) ?? 1;

    final lastOnlineStr = prefs.getString(_keyLastOnlineTime);
    if (lastOnlineStr != null) {
      _lastOnlineTime = DateTime.tryParse(lastOnlineStr);
    }

    _applyLegacyRateModifier();
    _refreshOfflineRewards();

    notifyListeners();
  }

  void _applyLegacyRateModifier() {
    final unified = _unified;
    if (unified == null) {
      return;
    }

    final baseRate = _config.baseProductionRate;
    final multiplier = baseRate <= 0 ? 0.0 : _idleProductionRate / baseRate;
    unified.addModifier(
      IdleModifier(
        id: _legacyRateModifierId,
        value: multiplier,
        type: IdleModifierType.multiplicative,
      ),
    );
  }

  void _refreshOfflineRewards() {
    final lastOnlineTime = _lastOnlineTime;
    final unified = _unified;

    if (lastOnlineTime == null || unified == null) {
      _offlineGoldEarned = 0;
      return;
    }

    final reward = unified.getOfflineReward(lastOnlineTime, _config.offlineCaps);
    _offlineGoldEarned = reward.amount.floor();
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
    _applyLegacyRateModifier();
    _refreshOfflineRewards();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdleProductionRate, _idleProductionRate);

    notifyListeners();
  }

  /// 앱 종료 시 호출 - 현재 시간 저장
  Future<void> saveLastOnlineTime() async {
    _unified?.saveState();

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
