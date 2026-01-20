import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'level_generator.dart';

class GameState extends ChangeNotifier {
  final LevelGenerator _levelGenerator = LevelGenerator();

  int _currentDifficulty = 0;
  static const List<int> gridSizes = [10, 30, 50];
  static const List<double> animationSpeeds = [0.15, 0.3, 0.5]; // cells per frame

  int _errorCount = 0;
  GameLevel? _level;

  // Support multiple flying arrows
  List<FlyingArrow> _flyingArrows = [];
  Map<int, ArrowPath> _flyingPaths = {}; // Map arrow id to its path

  bool _isAnimating = false;
  bool _isLevelComplete = false;
  bool _isLoading = false;
  Timer? _animationTimer;

  // Timer for elapsed time
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  // Hint feature
  int? _hintPathId; // ID of the path to highlight as hint
  int _hintCount = 0; // Number of hints used
  bool _noHintAvailable = false; // True when no escapable arrow found

  int get currentDifficulty => _currentDifficulty;
  int get gridSize => gridSizes[_currentDifficulty];
  int get errorCount => _errorCount;
  GameLevel? get level => _level;

  // For backwards compatibility, return first flying arrow
  FlyingArrow? get flyingArrow => _flyingArrows.isNotEmpty ? _flyingArrows.first : null;

  // New getter for all flying arrows
  List<FlyingArrow> get flyingArrows => _flyingArrows;

  bool get isAnimating => _isAnimating;
  bool get isLevelComplete => _isLevelComplete;
  bool get isLoading => _isLoading;

  // Timer getters
  int get elapsedSeconds => _elapsedSeconds;
  String get elapsedTimeString {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Hint getters
  int? get hintPathId => _hintPathId;
  int get hintCount => _hintCount;
  bool get noHintAvailable => _noHintAvailable;

  void startGame([int difficulty = 0]) {
    _currentDifficulty = difficulty;
    _errorCount = 0;
    _loadLevelAsync();
  }

  Future<void> _loadLevelAsync() async {
    _isLoading = true;
    _flyingArrows = [];
    _flyingPaths = {};
    _isAnimating = false;
    _isLevelComplete = false;
    _errorCount = 0;
    _hintPathId = null;
    _hintCount = 0;
    _noHintAvailable = false;
    _stopElapsedTimer();
    _elapsedSeconds = 0;
    notifyListeners();

    // Generate level in background isolate
    _level = await _levelGenerator.generateLevelAsync(gridSizes[_currentDifficulty]);

    _isLoading = false;
    _startElapsedTimer();
    notifyListeners();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLevelComplete) {
        _elapsedSeconds++;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  // Find and show hint (an arrow that can escape)
  void showHint() {
    if (_level == null || _isLevelComplete) return;

    // Clear previous states
    _hintPathId = null;
    _noHintAvailable = false;

    // Find an arrow that can escape
    for (var path in _level!.paths) {
      if (path.isRemoved) continue;

      if (_canPathEscape(path)) {
        _hintPathId = path.id;
        _hintCount++;
        notifyListeners();

        // Clear hint after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (_hintPathId == path.id) {
            _hintPathId = null;
            notifyListeners();
          }
        });
        return;
      }
    }

    // No escapable arrow found
    _noHintAvailable = true;
    notifyListeners();

    // Clear the flag after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _noHintAvailable = false;
      notifyListeners();
    });
  }

  // Check if a path can escape without hitting other paths
  bool _canPathEscape(ArrowPath path) {
    if (_level == null) return false;

    PathCell endCell = path.endCell;
    Direction dir = path.direction;

    int checkRow = endCell.row;
    int checkCol = endCell.col;

    for (int step = 0; step < _level!.gridSize; step++) {
      checkRow += dir.delta.dy.toInt();
      checkCol += dir.delta.dx.toInt();

      // Reached edge - can escape
      if (checkRow < 0 || checkRow >= _level!.gridSize ||
          checkCol < 0 || checkCol >= _level!.gridSize) {
        return true;
      }

      // Check if blocked by another path
      for (var otherPath in _level!.paths) {
        if (otherPath.id == path.id) continue;
        if (otherPath.isRemoved) continue;

        if (otherPath.occupiesCell(checkRow, checkCol)) {
          return false;
        }
      }
    }
    return true;
  }

  void tapPath(ArrowPath path) {
    if (path.isRemoved) return;
    _startFlyingAnimation(path);
  }

  void tapCell(int row, int col) {
    if (_level == null) return;

    ArrowPath? path = _level!.getPathAt(row, col);
    if (path != null && !path.isRemoved) {
      _startFlyingAnimation(path);
    }
  }

  void _startFlyingAnimation(ArrowPath path) {
    path.isRemoved = true;

    FlyingArrow newArrow = FlyingArrow(
      id: path.id,
      x: 0,
      y: 0,
      direction: path.direction,
      color: path.color,
      pathCells: path.cells,
    );

    _flyingArrows.add(newArrow);
    _flyingPaths[path.id] = path;

    // Start animation timer if not already running
    if (!_isAnimating) {
      _isAnimating = true;
      _animateFlying();
    }

    notifyListeners();
  }

  void _animateFlying() {
    const duration = Duration(milliseconds: 16);
    final speed = animationSpeeds[_currentDifficulty];

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(duration, (timer) {
      if (_flyingArrows.isEmpty || _level == null) {
        timer.cancel();
        _isAnimating = false;
        _checkLevelComplete();
        return;
      }

      List<int> escapedIds = [];
      List<int> collidedIds = [];

      // Update all flying arrows
      for (int i = 0; i < _flyingArrows.length; i++) {
        FlyingArrow arrow = _flyingArrows[i];
        if (arrow.collided) continue; // Skip already collided arrows

        ArrowPath? path = _flyingPaths[arrow.id];
        if (path == null) continue;

        double headProgress = arrow.x + speed;
        PathCell endCell = path.endCell;
        Direction dir = path.direction;

        double headX = endCell.col + dir.delta.dx * headProgress;
        double headY = endCell.row + dir.delta.dy * headProgress;

        // Check if escaped
        bool headOutOfGrid = headX < -0.5 || headX >= _level!.gridSize + 0.5 ||
            headY < -0.5 || headY >= _level!.gridSize + 0.5;

        if (headOutOfGrid) {
          double pathLength = path.cells.length.toDouble();
          if (headProgress >= pathLength + 1.5) {
            escapedIds.add(arrow.id);
            continue;
          }
        }

        // Check collision with static paths
        bool collided = false;
        int checkRow = headY.round();
        int checkCol = headX.round();

        if (checkRow >= 0 && checkRow < _level!.gridSize &&
            checkCol >= 0 && checkCol < _level!.gridSize) {
          for (var otherPath in _level!.paths) {
            if (otherPath.id == path.id) continue;
            if (otherPath.isRemoved) continue;

            if (otherPath.occupiesCell(checkRow, checkCol)) {
              for (var otherCell in otherPath.cells) {
                if (otherCell.row == checkRow && otherCell.col == checkCol) {
                  double dx = (headX - otherCell.col).abs();
                  double dy = (headY - otherCell.row).abs();
                  if (dx < 0.45 && dy < 0.45) {
                    collided = true;
                    break;
                  }
                }
              }
            }
            if (collided) break;
          }
        }

        if (collided) {
          collidedIds.add(arrow.id);
        } else {
          // Update arrow progress
          _flyingArrows[i] = arrow.copyWith(x: headProgress);
        }
      }

      // Handle escaped arrows
      for (int id in escapedIds) {
        _flyingArrows.removeWhere((a) => a.id == id);
        _flyingPaths.remove(id);
      }

      // Handle collided arrows
      for (int id in collidedIds) {
        int index = _flyingArrows.indexWhere((a) => a.id == id);
        if (index >= 0) {
          _flyingArrows[index] = _flyingArrows[index].copyWith(collided: true);
        }
      }

      // Schedule removal of collided arrows
      if (collidedIds.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 400), () {
          for (int id in collidedIds) {
            ArrowPath? path = _flyingPaths[id];
            if (path != null) {
              path.isRemoved = false;
            }
            _flyingArrows.removeWhere((a) => a.id == id);
            _flyingPaths.remove(id);
            _errorCount++;
          }
          notifyListeners();
        });
      }

      // Check if all arrows are done
      if (_flyingArrows.isEmpty) {
        timer.cancel();
        _isAnimating = false;
        _checkLevelComplete();
      }

      notifyListeners();
    });
  }

  void _checkLevelComplete() {
    if (_level != null && _level!.remainingPaths == 0 && _flyingArrows.isEmpty) {
      _stopElapsedTimer();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isLevelComplete = true;
        notifyListeners();
      });
    }
  }

  void nextLevel() {
    if (_currentDifficulty < gridSizes.length - 1) {
      _currentDifficulty++;
    }
    _loadLevelAsync();
  }

  void resetLevel() {
    _animationTimer?.cancel();
    _flyingArrows = [];
    _flyingPaths = {};
    _isAnimating = false;
    _loadLevelAsync();
  }

  void restartGame() {
    _animationTimer?.cancel();
    startGame();
  }

  void setDifficulty(int difficulty) {
    if (difficulty >= 0 && difficulty < gridSizes.length) {
      _currentDifficulty = difficulty;
      _errorCount = 0;
      _loadLevelAsync();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
