# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for specific platforms
flutter build apk          # Android APK
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows

# Run tests
flutter test               # Run all tests
flutter test test/widget_test.dart  # Run specific test file

# Code analysis
flutter analyze            # Run Dart analyzer
flutter analyze lib/car_escape  # Analyze specific module
```

## Architecture Overview

This is a Flutter multi-game puzzle app with 4 distinct game modes, all using grid-based mechanics.

### State Management

Uses Provider pattern with ChangeNotifier:
- **GameState** (`lib/game/game_state.dart`): Arrow Maze game logic
- **LocaleProvider** (`lib/l10n/locale_provider.dart`): Korean/English switching, persisted via SharedPreferences

### Game Modules

Each game is self-contained in its own directory with consistent structure:

| Game | Directory | Key Features |
|------|-----------|--------------|
| Arrow Maze | `lib/game/`, `lib/screens/`, `lib/widgets/` | Colored arrows, path visualization, collision detection |
| Maze | `lib/maze/` | BFS pathfinding, swipe navigation |
| Parking Jam | `lib/parking_jam/` | Vehicle dragging, exit detection, multiple vehicle types |
| Car Escape | `lib/car_escape/` | Turn-based movement, intersection navigation, U-turns |

### Common Module Structure

Each game module follows this pattern:
- `models/` - Data classes, enums, difficulty extensions
- `widgets/` - Custom painters and interactive board widgets
- `*_generator.dart` - Puzzle generation with validation
- `*_screen.dart` - Full screen with timer, hint system, win dialog

### Shared Services

- **AdService** (`lib/services/ad_service.dart`): Google Mobile Ads singleton
  - Banner ads on home screen
  - Rewarded video ads for hints (with confirmation dialog)
- **Localization** (`lib/l10n/`): Korean/English support

### Car Escape Specifics

Complex turn system with path validation:
- `TurnType`: straight, leftTurn, rightTurn, uTurnLeft, uTurnRight
- U-turns require two consecutive intersections
- Generator validates paths can reach grid edge
- Collision animation: move → shake → return

### Difficulty Configuration

Difficulty settings are defined via Dart extensions on enum types (e.g., `CarEscapeDifficultyExtension`), providing:
- Grid sizes
- Entity counts (intersections, vehicles)
- Complexity ranges

### UI Patterns

- Dark theme (`Color(0xFF1A1A2E)` background, `Color(0xFF2D2D44)` cards)
- Adaptive layouts using `LayoutBuilder` for responsive sizing
- Custom `CustomPainter` for roads, paths, and game boards
- Animation controllers for exit/collision effects
