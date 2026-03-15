import 'package:mg_common_game/systems/balancing/balancing.dart';

/// Default balancing configuration for MG-0010: Dungeon Shop Simulator.
///
/// Placeholder values for v1.2.0 pilot integration.
/// In production, override via RemoteConfig using
/// [BalancingManager.loadFromRemote].
const kDefaultBalancingConfig = BalancingConfig(
  gameId: 'mg-0010',
  version: 1,
  currencies: [
    CurrencyConfig(id: 'gold', baseEarnRate: 10.0),
  ],
  xpCurve: XpCurveConfig(baseXp: 100, maxLevel: 100),
  difficultyScaling: DifficultyScalingConfig(),
  customParams: {
    'reward_multiplier': 1.0,
    'craft_speed_base': 1.0,
    'customer_rate_base': 1.0,
  },
);
