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
```

## Architecture Overview

This is a Flutter puzzle game (Arrow Maze) where players direct colored arrows through grid-based paths to clear levels.

### State Management

Uses Provider pattern with ChangeNotifier:
- **GameState** (`lib/game/game_state.dart`): Central game logic, level progression, arrow movement, collision detection
- **LocaleProvider** (`lib/l10n/locale_provider.dart`): Language switching (Korean/English), persisted via SharedPreferences

### Key Modules

| Directory | Purpose |
|-----------|---------|
| `lib/game/` | Core game logic - state management and async level generation |
| `lib/models/` | Data models for game entities |
| `lib/screens/` | Full-page screens (game selection, gameplay) |
| `lib/widgets/` | Reusable UI components including custom arrow path painter |
| `lib/maze/` | Alternate maze game mode with BFS pathfinding |
| `lib/services/` | External integrations (Google Mobile Ads) |
| `lib/l10n/` | Localization support |

### Monetization

Google Mobile Ads integration (`lib/services/ad_service.dart`):
- Banner ads on home screen
- Rewarded video ads for hint system
- Uses singleton pattern for ad management

### Game Features

- 3 difficulty levels (Easy/Medium/Hard) with grid sizes of 10, 30, 50 cells
- Multiple colored arrow paths with collision detection
- Hint system gated by rewarded ads with confirmation dialog
- Stopwatch for tracking level completion time
- Custom painting for arrow path visualization (`lib/widgets/arrow_path_painter.dart`)
