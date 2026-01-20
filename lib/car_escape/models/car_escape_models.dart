import 'package:flutter/material.dart';

enum CarEscapeDifficulty { easy, medium, hard }

extension CarEscapeDifficultyExtension on CarEscapeDifficulty {
  int get gridSize {
    switch (this) {
      case CarEscapeDifficulty.easy:
        return 6;
      case CarEscapeDifficulty.medium:
        return 7;
      case CarEscapeDifficulty.hard:
        return 8;
    }
  }

  int get intersectionCount {
    switch (this) {
      case CarEscapeDifficulty.easy:
        return 4;
      case CarEscapeDifficulty.medium:
        return 6;
      case CarEscapeDifficulty.hard:
        return 8;
    }
  }

  (int, int) get carCountRange {
    switch (this) {
      case CarEscapeDifficulty.easy:
        return (6, 10);
      case CarEscapeDifficulty.medium:
        return (10, 16);
      case CarEscapeDifficulty.hard:
        return (16, 24);
    }
  }
}

enum CarFacing { left, right, up, down }

extension CarFacingExtension on CarFacing {
  bool get isHorizontal => this == CarFacing.left || this == CarFacing.right;
  bool get isVertical => this == CarFacing.up || this == CarFacing.down;

  int get dx {
    switch (this) {
      case CarFacing.left: return -1;
      case CarFacing.right: return 1;
      case CarFacing.up: return 0;
      case CarFacing.down: return 0;
    }
  }

  int get dy {
    switch (this) {
      case CarFacing.left: return 0;
      case CarFacing.right: return 0;
      case CarFacing.up: return -1;
      case CarFacing.down: return 1;
    }
  }

  double get rotation {
    switch (this) {
      case CarFacing.up: return 0;
      case CarFacing.right: return 90;
      case CarFacing.down: return 180;
      case CarFacing.left: return 270;
    }
  }
}

class GridCar {
  final int id;
  int gridX;
  int gridY;
  final CarFacing facing;
  final Color color;
  bool isExiting = false;
  bool hasExited = false;

  GridCar({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.facing,
    required this.color,
  });

  GridCar copyWith({
    int? id,
    int? gridX,
    int? gridY,
    CarFacing? facing,
    Color? color,
  }) {
    final car = GridCar(
      id: id ?? this.id,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      facing: facing ?? this.facing,
      color: color ?? this.color,
    );
    car.isExiting = isExiting;
    car.hasExited = hasExited;
    return car;
  }
}

// Road segment between two points
class RoadSegment {
  final int x1, y1, x2, y2;

  RoadSegment({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  bool get isHorizontal => y1 == y2;
  bool get isVertical => x1 == x2;

  // Check if a point is on this road segment
  bool containsPoint(int x, int y) {
    if (isHorizontal && y == y1) {
      int minX = x1 < x2 ? x1 : x2;
      int maxX = x1 > x2 ? x1 : x2;
      return x >= minX && x <= maxX;
    }
    if (isVertical && x == x1) {
      int minY = y1 < y2 ? y1 : y2;
      int maxY = y1 > y2 ? y1 : y2;
      return y >= minY && y <= maxY;
    }
    return false;
  }

  // Get all cells on this segment
  List<(int, int)> get cells {
    List<(int, int)> result = [];
    if (isHorizontal) {
      int minX = x1 < x2 ? x1 : x2;
      int maxX = x1 > x2 ? x1 : x2;
      for (int x = minX; x <= maxX; x++) {
        result.add((x, y1));
      }
    } else if (isVertical) {
      int minY = y1 < y2 ? y1 : y2;
      int maxY = y1 > y2 ? y1 : y2;
      for (int y = minY; y <= maxY; y++) {
        result.add((x1, y));
      }
    }
    return result;
  }

  // Check if this segment connects to grid edge
  bool connectsToEdge(int gridSize) {
    return x1 == 0 || x2 == 0 || y1 == 0 || y2 == 0 ||
           x1 == gridSize - 1 || x2 == gridSize - 1 ||
           y1 == gridSize - 1 || y2 == gridSize - 1;
  }
}

class Intersection {
  final int x, y;

  Intersection(this.x, this.y);
}

class CarJamPuzzle {
  final int gridSize;
  final List<Intersection> intersections;
  final List<RoadSegment> roadSegments;
  final List<GridCar> cars;
  int clearedCount = 0;

  CarJamPuzzle({
    required this.gridSize,
    required this.intersections,
    required this.roadSegments,
    required this.cars,
  });

  CarJamPuzzle copyWith() {
    final puzzle = CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars.map((c) => c.copyWith()).toList(),
    );
    puzzle.clearedCount = clearedCount;
    return puzzle;
  }

  List<GridCar> get activeCars => cars.where((c) => !c.hasExited).toList();

  Set<(int, int)> get occupiedCells {
    return activeCars.map((c) => (c.gridX, c.gridY)).toSet();
  }

  // Check if a point is on any road
  bool isOnRoad(int x, int y) {
    for (var segment in roadSegments) {
      if (segment.containsPoint(x, y)) return true;
    }
    return false;
  }

  // Get the path a car would take to exit
  List<(int, int)> getPathToExit(GridCar car) {
    List<(int, int)> path = [];
    int x = car.gridX;
    int y = car.gridY;

    while (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      x += car.facing.dx;
      y += car.facing.dy;

      // Check if still on a road
      if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
        if (isOnRoad(x, y)) {
          path.add((x, y));
        } else {
          // Hit non-road area, can't continue
          return [];
        }
      }
    }
    return path;
  }

  bool canCarExit(GridCar car) {
    if (car.hasExited || car.isExiting) return false;

    final occupied = occupiedCells;
    final path = getPathToExit(car);

    // Path must lead to edge
    if (path.isEmpty) {
      // Check if car is already at edge
      int nextX = car.gridX + car.facing.dx;
      int nextY = car.gridY + car.facing.dy;
      if (nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize) {
        return true; // At edge, can exit immediately
      }
      return false; // Not at edge and path blocked by non-road
    }

    for (var cell in path) {
      if (occupied.contains(cell)) {
        return false;
      }
    }
    return true;
  }

  GridCar? getBlockingCar(GridCar car) {
    if (car.hasExited || car.isExiting) return null;

    final path = getPathToExit(car);

    for (var cell in path) {
      for (var other in activeCars) {
        if (other.id != car.id && other.gridX == cell.$1 && other.gridY == cell.$2) {
          return other;
        }
      }
    }
    return null;
  }

  void removeCar(int carId) {
    final car = cars.firstWhere((c) => c.id == carId);
    car.hasExited = true;
    clearedCount++;
  }

  bool get isComplete => activeCars.isEmpty;
}
