# Resource Audit: mg-game-0010 (Dungeon Shop Simulator)

## 1. Executive Summary
The project is in a **Fragmented State** with two conflicting implementations co-existing.
- **Active Code**: Uses `lib/systems/` and `ShopScreen` (Home). Features `Shop`, `Craft`, `Inventory` tabs. **Missing Dungeon Tab**.
- **Legacy/Alternate Code**: Uses `lib/game/` and `MainScreen`. Features `Shop`, `Craft`, `Dungeon` tabs. **Unused**.
- **Assets**: The game currently relies entirely on `Flutter Material Icons` and debug `print` statements for audio.

## 2. Project Structure Audit
- **Declared Assets (`pubspec.yaml`)**:
  - `assets/images/`: Declared but **Empty**.
  - `assets/audio/`: **Not Declared**.
- **Existing Asset Files**:
  - `game/assets/images/`: Empty.
  - `game/assets/audio/`: Does not exist.

## 3. Code Usage Audit
- **Visuals**:
  - No `Image.asset` or `AssetImage` usage found.
  - UI uses `Icon(Icons.*)` (e.g., `Icons.store`, `Icons.pest_control`).
- **Audio**:
  - `AudioManager` exists in `lib/systems/` but contains only `print` statements.
  - No actual audio playback logic or files.

## 4. Architectural Discrepancy (Critical)
The project has duplicate feature logic in `lib/game/` and `lib/systems/`.

| Feature | Active Code (`main.dart` -> `ShopScreen`) | Legacy Code (`MainScreen` -> `DungeonTab`) |
| :--- | :--- | :--- |
| **Logic Path** | `lib/systems/` | `lib/game/` |
| **DI Pattern** | `GetIt` (Singleton) | `Provider` (`Consumer`) |
| **Tabs** | Shop, Craft, **Inventory** | Shop, Craft, **Dungeon** |
| **Dungeon** | Accessible via `DungeonManager` logic but **No UI** linked. | Has `DungeonTab` UI but uses legacy manager. |

## 5. Recommendations
1.  **Consolidate Architecture**:
    - Standardize on `lib/systems/` and `GetIt` (as used in `main.dart`).
    - Migrate `DungeonTab` UI from `lib/ui/dungeon_tab.dart` to use `systems/DungeonManager` and `GetIt`.
    - Integrate `DungeonTab` into `ShopScreen`, likely replacing `Inventory` or adding a 4th tab/navigation.
    - Delete legacy `lib/game/` directory.
2.  **Generate Assets**:
    - **Audio**: Generate BGM and SFX (Click, Success, Craft, Attack) and implement real playback in `AudioManager`.
    - **Visuals**: Generate sprites for Items, Monsters (Slime, Goblin, Orc), and UI elements to replace Icons.
3.  **Update Manifest**:
    - Add `assets/audio/` to `pubspec.yaml`.
    - Add `assets/images/` content.
