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

  CarFacing get opposite {
    switch (this) {
      case CarFacing.up: return CarFacing.down;
      case CarFacing.down: return CarFacing.up;
      case CarFacing.left: return CarFacing.right;
      case CarFacing.right: return CarFacing.left;
    }
  }

  CarFacing get turnLeft {
    switch (this) {
      case CarFacing.up: return CarFacing.left;
      case CarFacing.left: return CarFacing.down;
      case CarFacing.down: return CarFacing.right;
      case CarFacing.right: return CarFacing.up;
    }
  }

  CarFacing get turnRight {
    switch (this) {
      case CarFacing.up: return CarFacing.right;
      case CarFacing.right: return CarFacing.down;
      case CarFacing.down: return CarFacing.left;
      case CarFacing.left: return CarFacing.up;
    }
  }
}

enum TurnType { straight, leftTurn, rightTurn, uTurnLeft, uTurnRight }

extension TurnTypeExtension on TurnType {
  // Get the first turn direction (for U-turns, this is the first of two turns)
  CarFacing getFirstTurnDirection(CarFacing travelDirection) {
    switch (this) {
      case TurnType.straight:
        return travelDirection;
      case TurnType.leftTurn:
        return travelDirection.turnLeft;
      case TurnType.rightTurn:
        return travelDirection.turnRight;
      case TurnType.uTurnLeft:
        return travelDirection.turnLeft;
      case TurnType.uTurnRight:
        return travelDirection.turnRight;
    }
  }

  // Get the final exit direction (after all turns)
  CarFacing getExitDirection(CarFacing travelDirection) {
    switch (this) {
      case TurnType.straight:
        return travelDirection;
      case TurnType.leftTurn:
        return travelDirection.turnLeft;
      case TurnType.rightTurn:
        return travelDirection.turnRight;
      case TurnType.uTurnLeft:
        // Left then left = opposite direction
        return travelDirection.opposite;
      case TurnType.uTurnRight:
        // Right then right = opposite direction
        return travelDirection.opposite;
    }
  }

  bool get isUTurn => this == TurnType.uTurnLeft || this == TurnType.uTurnRight;

  IconData get icon {
    switch (this) {
      case TurnType.straight:
        return Icons.arrow_upward;
      case TurnType.leftTurn:
        return Icons.turn_left;
      case TurnType.rightTurn:
        return Icons.turn_right;
      case TurnType.uTurnLeft:
        return Icons.u_turn_left;
      case TurnType.uTurnRight:
        return Icons.u_turn_right;
    }
  }
}

class GridCar {
  final int id;
  int gridX;
  int gridY;
  final CarFacing travelDirection; // Direction the car is moving
  final TurnType turnType; // What to do at the next intersection
  final Color color;
  bool isExiting = false;
  bool hasExited = false;

  GridCar({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.travelDirection,
    required this.turnType,
    required this.color,
  });

  // The direction the car will exit after making its turn
  CarFacing get exitDirection => turnType.getExitDirection(travelDirection);

  GridCar copyWith({
    int? id,
    int? gridX,
    int? gridY,
    CarFacing? travelDirection,
    TurnType? turnType,
    Color? color,
  }) {
    final car = GridCar(
      id: id ?? this.id,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      travelDirection: travelDirection ?? this.travelDirection,
      turnType: turnType ?? this.turnType,
      color: color ?? this.color,
    );
    car.isExiting = isExiting;
    car.hasExited = hasExited;
    return car;
  }
}

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

  bool isOnRoad(int x, int y) {
    for (var segment in roadSegments) {
      if (segment.containsPoint(x, y)) return true;
    }
    return false;
  }

  bool isIntersection(int x, int y) {
    return intersections.any((i) => i.x == x && i.y == y);
  }

  bool hasRoadInDirection(int x, int y, CarFacing direction) {
    for (var segment in roadSegments) {
      if (!segment.containsPoint(x, y)) continue;
      if (direction.isHorizontal && segment.isHorizontal) return true;
      if (direction.isVertical && segment.isVertical) return true;
    }
    return false;
  }

  // Get the full path: car position -> intersection(s) -> turn(s) -> exit
  List<(int, int)> getFullPath(GridCar car) {
    List<(int, int)> path = [];
    int x = car.gridX;
    int y = car.gridY;
    CarFacing currentDir = car.travelDirection;

    // For U-turns, we need to make two turns at two different intersections
    // For other turns, we make one turn at one intersection
    int turnsNeeded = car.turnType.isUTurn ? 2 : 1;
    int turnsMade = 0;

    int maxSteps = gridSize * 4; // Safety limit
    int steps = 0;

    while (steps < maxSteps) {
      int nextX = x + currentDir.dx;
      int nextY = y + currentDir.dy;

      // Reached edge - exit point
      if (nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize) {
        break;
      }

      // Check if next cell is on road
      if (!isOnRoad(nextX, nextY)) {
        break;
      }

      path.add((nextX, nextY));
      x = nextX;
      y = nextY;
      steps++;

      // Check if we reached an intersection
      if (turnsMade < turnsNeeded && isIntersection(x, y)) {
        CarFacing newDir;

        if (car.turnType.isUTurn) {
          // For U-turn: first turn is left/right, second turn is same direction
          if (car.turnType == TurnType.uTurnLeft) {
            newDir = currentDir.turnLeft;
          } else {
            newDir = currentDir.turnRight;
          }
        } else {
          // For regular turns: apply the turn type
          newDir = car.turnType.getFirstTurnDirection(currentDir);
        }

        // Check if we can turn (there's a road in that direction)
        if (hasRoadInDirection(x, y, newDir)) {
          currentDir = newDir;
          turnsMade++;
        } else {
          // Can't make the required turn - path ends here (car can't exit)
          break;
        }
      }
    }

    return path;
  }

  bool canCarExit(GridCar car) {
    if (car.hasExited || car.isExiting) return false;

    // Get occupied cells excluding this car's position
    final occupied = occupiedCells;
    occupied.remove((car.gridX, car.gridY)); // Exclude self

    final path = getFullPath(car);

    // Must have a path to edge
    if (path.isEmpty) {
      // Check if car is already at edge
      int nextX = car.gridX + car.travelDirection.dx;
      int nextY = car.gridY + car.travelDirection.dy;
      if (nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize) {
        return true;
      }
      return false;
    }

    // Verify path actually reaches the edge
    if (!_pathReachesEdge(car, path)) {
      return false;
    }

    // Check if path is clear (excluding self)
    for (var cell in path) {
      if (occupied.contains(cell)) {
        return false;
      }
    }

    return true;
  }

  // Check if the path's last cell is adjacent to the grid edge
  bool _pathReachesEdge(GridCar car, List<(int, int)> path) {
    if (path.isEmpty) return false;

    final lastCell = path.last;
    final exitDir = car.turnType.getExitDirection(car.travelDirection);

    // Check if moving one more step from last cell would exit the grid
    int nextX = lastCell.$1 + exitDir.dx;
    int nextY = lastCell.$2 + exitDir.dy;

    return nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize;
  }

  GridCar? getBlockingCar(GridCar car) {
    if (car.hasExited || car.isExiting) return null;

    final path = getFullPath(car);

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
