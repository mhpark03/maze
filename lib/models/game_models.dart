import 'package:flutter/material.dart';

enum Direction {
  up,
  down,
  left,
  right,
}

extension DirectionExtension on Direction {
  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }

  Offset get delta {
    switch (this) {
      case Direction.up:
        return const Offset(0, -1);
      case Direction.down:
        return const Offset(0, 1);
      case Direction.left:
        return const Offset(-1, 0);
      case Direction.right:
        return const Offset(1, 0);
    }
  }

  double get angle {
    switch (this) {
      case Direction.up:
        return -90 * 3.14159 / 180;
      case Direction.down:
        return 90 * 3.14159 / 180;
      case Direction.left:
        return 180 * 3.14159 / 180;
      case Direction.right:
        return 0;
    }
  }
}

// A single cell in a multi-cell path
class PathCell {
  final int row;
  final int col;
  final Direction entryDirection; // Direction the path enters this cell from
  final Direction exitDirection;  // Direction the path exits this cell to

  PathCell({
    required this.row,
    required this.col,
    required this.entryDirection,
    required this.exitDirection,
  });

  // Check if this cell has a curve (entry and exit are not opposite)
  bool get isCurved {
    return entryDirection != exitDirection.opposite;
  }

  // Check if this cell is straight
  bool get isStraight {
    return entryDirection == exitDirection.opposite;
  }
}

// A complete arrow path spanning multiple cells
class ArrowPath {
  final List<PathCell> cells;
  final Color color;
  final int id;
  bool isRemoved;

  ArrowPath({
    required this.cells,
    required this.color,
    required this.id,
    this.isRemoved = false,
  });

  // The direction the arrow points (exit direction of last cell)
  Direction get direction => cells.last.exitDirection;

  // Starting cell of the path
  PathCell get startCell => cells.first;

  // Ending cell of the path (where arrow head is)
  PathCell get endCell => cells.last;

  // Get all cells occupied by this path
  Set<(int, int)> get occupiedCells {
    return cells.map((c) => (c.row, c.col)).toSet();
  }

  // Check if this path occupies a specific cell
  bool occupiesCell(int row, int col) {
    return cells.any((c) => c.row == row && c.col == col);
  }

  // Get the center position of the path for tap detection
  Offset get centerPosition {
    if (cells.isEmpty) return Offset.zero;
    double sumRow = 0;
    double sumCol = 0;
    for (var cell in cells) {
      sumRow += cell.row;
      sumCol += cell.col;
    }
    return Offset(sumCol / cells.length, sumRow / cells.length);
  }
}

// Flying arrow animation state
class FlyingArrow {
  final int id; // Unique identifier for tracking
  final double x; // head progress (how far the head has traveled)
  final double y; // unused, kept for compatibility
  final Direction direction;
  final Color color;
  final bool collided;
  final List<PathCell> pathCells; // The cells of the path for drawing

  FlyingArrow({
    required this.id,
    required this.x,
    required this.y,
    required this.direction,
    required this.color,
    this.collided = false,
    this.pathCells = const [],
  });

  FlyingArrow copyWith({
    int? id,
    double? x,
    double? y,
    Direction? direction,
    Color? color,
    bool? collided,
    List<PathCell>? pathCells,
  }) {
    return FlyingArrow(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      direction: direction ?? this.direction,
      color: color ?? this.color,
      collided: collided ?? this.collided,
      pathCells: pathCells ?? this.pathCells,
    );
  }
}

class GameLevel {
  final int gridSize;
  final List<ArrowPath> paths;

  GameLevel({
    required this.gridSize,
    required this.paths,
  });

  // Get path at a specific cell
  ArrowPath? getPathAt(int row, int col) {
    try {
      return paths.firstWhere(
        (p) => !p.isRemoved && p.occupiesCell(row, col),
      );
    } catch (e) {
      return null;
    }
  }

  // Get path by ID
  ArrowPath? getPathById(int id) {
    try {
      return paths.firstWhere((p) => p.id == id && !p.isRemoved);
    } catch (e) {
      return null;
    }
  }

  int get remainingPaths => paths.where((p) => !p.isRemoved).length;

  // Check if a cell is occupied by any non-removed path
  bool isCellOccupied(int row, int col) {
    return paths.any((p) => !p.isRemoved && p.occupiesCell(row, col));
  }
}

class GameColors {
  static const Color cyan = Color(0xFF4ECDC4);
  static const Color orange = Color(0xFFFF6B35);
  static const Color yellow = Color(0xFFFFD93D);
  static const Color green = Color(0xFF6BCB77);
  static const Color pink = Color(0xFFFF69B4);
  static const Color purple = Color(0xFF9B59B6);
  static const Color blue = Color(0xFF3498DB);
  static const Color red = Color(0xFFE74C3C);

  static List<Color> get allColors => [
        cyan,
        orange,
        yellow,
        green,
        pink,
        purple,
        blue,
        red,
      ];
}
