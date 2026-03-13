import 'package:mg_common_game/core/assets/asset_types.dart';

/// Spine 통합 플래그. `--dart-define=SPINE_ENABLED=true`로 활성화.
const kSpineEnabled = bool.fromEnvironment(
  'SPINE_ENABLED',
  defaultValue: false,
);

// ── Shopkeeper ───────────────────────────────────────────────

const kShopkeeperMeta = SpineAssetMeta(
  key: 'shopkeeper',
  path: 'spine/characters/shopkeeper',
  atlasPath: 'assets/spine/characters/shopkeeper/shopkeeper.atlas',
  skeletonPath: 'assets/spine/characters/shopkeeper/shopkeeper.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Customer ─────────────────────────────────────────────────

const kCustomerMeta = SpineAssetMeta(
  key: 'customer',
  path: 'spine/characters/customer',
  atlasPath: 'assets/spine/characters/customer/customer.atlas',
  skeletonPath: 'assets/spine/characters/customer/customer.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Guard ────────────────────────────────────────────────────

const kGuardMeta = SpineAssetMeta(
  key: 'guard',
  path: 'spine/characters/guard',
  atlasPath: 'assets/spine/characters/guard/guard.atlas',
  skeletonPath: 'assets/spine/characters/guard/guard.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);
