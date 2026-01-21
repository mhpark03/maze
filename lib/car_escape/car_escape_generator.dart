import 'dart:math';
import 'package:flutter/material.dart';
import 'models/car_escape_models.dart';

class CarEscapeGenerator {
  static final Random _random = Random();

  static final List<Color> _carColors = [
    Colors.yellow.shade600,
    Colors.yellow.shade700,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red.shade400,
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.blue.shade400,
    Colors.cyan,
    Colors.teal,
    Colors.green.shade400,
    Colors.lightGreen,
    Colors.lime,
  ];

  static final List<CarEscapeColor> _vehicleColors = CarEscapeColor.values;

  static Future<CarJamPuzzle> generate(CarEscapeDifficulty difficulty) async {
    final gridSize = difficulty.gridSize;
    final intersectionCount = difficulty.intersectionCount;
    final (minCars, maxCars) = difficulty.carCountRange;
    final targetCars = minCars + _random.nextInt(maxCars - minCars + 1);

    for (int attempt = 0; attempt < 100; attempt++) {
      final puzzle = _generatePuzzle(gridSize, intersectionCount, targetCars);
      if (puzzle != null && _isSolvable(puzzle)) {
        return puzzle;
      }
      if (attempt % 20 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    return _generateGuaranteedPuzzle(gridSize, intersectionCount);
  }

  static CarJamPuzzle? _generatePuzzle(int gridSize, int intersectionCount, int targetCars) {
    List<Intersection> intersections = _generateGridIntersections(gridSize, intersectionCount);
    if (intersections.length < 2) return null;

    List<RoadSegment> roadSegments = _generateRoadSegments(gridSize, intersections);
    if (roadSegments.isEmpty) return null;

    List<GridCar> cars = _generateCars(gridSize, roadSegments, intersections, targetCars);
    if (cars.length < 3) return null;

    return CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars,
    );
  }

  static List<Intersection> _generateGridIntersections(int gridSize, int count) {
    List<Intersection> intersections = [];

    int divisions = (sqrt(count) + 0.5).ceil();
    if (divisions < 2) divisions = 2;

    int availableSize = gridSize - 2;
    double spacing = availableSize / (divisions + 1);

    List<(int, int)> candidates = [];
    for (int i = 1; i <= divisions; i++) {
      for (int j = 1; j <= divisions; j++) {
        int x = (1 + spacing * i).round().clamp(1, gridSize - 2);
        int y = (1 + spacing * j).round().clamp(1, gridSize - 2);
        candidates.add((x, y));
      }
    }

    candidates.shuffle(_random);
    Set<(int, int)> used = {};

    for (var pos in candidates) {
      if (intersections.length >= count) break;
      if (!used.contains(pos)) {
        intersections.add(Intersection(pos.$1, pos.$2));
        used.add(pos);
      }
    }

    int attempts = 0;
    while (intersections.length < count && attempts < 50) {
      int x = 1 + _random.nextInt(gridSize - 2);
      int y = 1 + _random.nextInt(gridSize - 2);
      if (!used.contains((x, y))) {
        intersections.add(Intersection(x, y));
        used.add((x, y));
      }
      attempts++;
    }

    return intersections;
  }

  static List<RoadSegment> _generateRoadSegments(int gridSize, List<Intersection> intersections) {
    List<RoadSegment> segments = [];
    Set<String> addedSegments = {};

    for (var intersection in intersections) {
      List<int> directions = [0, 1, 2, 3]..shuffle(_random);
      int connectCount = 2 + _random.nextInt(2);

      for (int i = 0; i < connectCount && i < directions.length; i++) {
        RoadSegment? segment = _createEdgeSegment(intersection, directions[i], gridSize);
        if (segment != null) {
          String key = _segmentKey(segment);
          if (!addedSegments.contains(key)) {
            segments.add(segment);
            addedSegments.add(key);
          }
        }
      }
    }

    for (int i = 0; i < intersections.length; i++) {
      for (int j = i + 1; j < intersections.length; j++) {
        var a = intersections[i];
        var b = intersections[j];

        if (a.x == b.x || a.y == b.y) {
          var segment = RoadSegment(x1: a.x, y1: a.y, x2: b.x, y2: b.y);
          String key = _segmentKey(segment);
          if (!addedSegments.contains(key)) {
            segments.add(segment);
            addedSegments.add(key);
          }
        }
      }
    }

    return segments;
  }

  static RoadSegment? _createEdgeSegment(Intersection intersection, int direction, int gridSize) {
    switch (direction) {
      case 0:
        return RoadSegment(x1: intersection.x, y1: intersection.y, x2: intersection.x, y2: 0);
      case 1:
        return RoadSegment(x1: intersection.x, y1: intersection.y, x2: intersection.x, y2: gridSize - 1);
      case 2:
        return RoadSegment(x1: intersection.x, y1: intersection.y, x2: 0, y2: intersection.y);
      case 3:
        return RoadSegment(x1: intersection.x, y1: intersection.y, x2: gridSize - 1, y2: intersection.y);
    }
    return null;
  }

  static String _segmentKey(RoadSegment s) {
    int minX = min(s.x1, s.x2);
    int maxX = max(s.x1, s.x2);
    int minY = min(s.y1, s.y2);
    int maxY = max(s.y1, s.y2);
    return '$minX,$minY-$maxX,$maxY';
  }

  static List<GridCar> _generateCars(int gridSize, List<RoadSegment> roadSegments, List<Intersection> intersections, int targetCars) {
    List<GridCar> cars = [];
    Set<(int, int)> occupied = {};
    List<Color> shuffledColors = List.from(_carColors)..shuffle(_random);
    List<CarEscapeColor> shuffledVehicleColors = List.from(_vehicleColors)..shuffle(_random);
    int carId = 0;

    // Get intersection positions as a set
    Set<(int, int)> intersectionSet = intersections.map((i) => (i.x, i.y)).toSet();

    // Collect road cells that are NOT intersections
    Set<(int, int)> roadCells = {};
    for (var segment in roadSegments) {
      for (var cell in segment.cells) {
        if (!intersectionSet.contains(cell)) {
          roadCells.add(cell);
        }
      }
    }

    // Find valid car placements
    List<_CarPlacement> possiblePlacements = [];

    for (var cell in roadCells) {
      // Determine which direction the car can travel (based on road type)
      bool isOnHorizontal = _isOnHorizontalRoad(cell.$1, cell.$2, roadSegments);
      bool isOnVertical = _isOnVerticalRoad(cell.$1, cell.$2, roadSegments);

      List<CarFacing> travelDirections = [];
      if (isOnHorizontal) {
        travelDirections.add(CarFacing.left);
        travelDirections.add(CarFacing.right);
      }
      if (isOnVertical) {
        travelDirections.add(CarFacing.up);
        travelDirections.add(CarFacing.down);
      }

      for (var travelDir in travelDirections) {
        // Find the intersection this car would reach
        var intersectionInfo = _findNextIntersection(cell.$1, cell.$2, travelDir, gridSize, roadSegments, intersectionSet);

        if (intersectionInfo != null) {
          var (intX, intY) = intersectionInfo;

          // Check what turns are possible at this intersection
          for (var turnType in TurnType.values) {
            // Skip U-turns here - they're handled separately below
            if (turnType.isUTurn) continue;

            CarFacing exitDir = turnType.getExitDirection(travelDir);

            // Check if there's a road in the exit direction at the intersection
            if (_hasRoadInDirection(intX, intY, exitDir, roadSegments)) {
              // Check if the car can exit to edge after turning
              if (_canReachEdge(intX, intY, exitDir, gridSize, roadSegments)) {
                // Additional validation: simulate the full path
                if (_validateFullPath(cell.$1, cell.$2, travelDir, turnType, gridSize, roadSegments, intersectionSet)) {
                  possiblePlacements.add(_CarPlacement(
                    x: cell.$1,
                    y: cell.$2,
                    travelDirection: travelDir,
                    turnType: turnType,
                  ));
                }
              }
            }
          }

          // Handle U-turns separately - they require two intersections
          for (var uTurnType in [TurnType.uTurnLeft, TurnType.uTurnRight]) {
            // First turn direction at first intersection
            CarFacing firstTurnDir = uTurnType == TurnType.uTurnLeft
                ? travelDir.turnLeft
                : travelDir.turnRight;

            // Check if there's a road in the first turn direction
            if (_hasRoadInDirection(intX, intY, firstTurnDir, roadSegments)) {
              // Find second intersection after first turn
              var secondIntersection = _findNextIntersection(
                  intX, intY, firstTurnDir, gridSize, roadSegments, intersectionSet);

              if (secondIntersection != null) {
                var (int2X, int2Y) = secondIntersection;

                // Second turn direction (same as first: left or right)
                CarFacing secondTurnDir = uTurnType == TurnType.uTurnLeft
                    ? firstTurnDir.turnLeft
                    : firstTurnDir.turnRight;

                // Check if we can make second turn and reach edge
                if (_hasRoadInDirection(int2X, int2Y, secondTurnDir, roadSegments)) {
                  if (_canReachEdge(int2X, int2Y, secondTurnDir, gridSize, roadSegments)) {
                    // Full path validation
                    if (_validateFullPath(cell.$1, cell.$2, travelDir, uTurnType, gridSize, roadSegments, intersectionSet)) {
                      possiblePlacements.add(_CarPlacement(
                        x: cell.$1,
                        y: cell.$2,
                        travelDirection: travelDir,
                        turnType: uTurnType,
                      ));
                    }
                  }
                }
              }
            }
          }
        } else {
          // No intersection found, car goes straight to edge - only allow straight
          if (_canReachEdge(cell.$1, cell.$2, travelDir, gridSize, roadSegments)) {
            possiblePlacements.add(_CarPlacement(
              x: cell.$1,
              y: cell.$2,
              travelDirection: travelDir,
              turnType: TurnType.straight,
            ));
          }
        }
      }
    }

    possiblePlacements.shuffle(_random);

    for (var placement in possiblePlacements) {
      if (carId >= targetCars) break;
      if (occupied.contains((placement.x, placement.y))) continue;

      cars.add(GridCar(
        id: carId,
        gridX: placement.x,
        gridY: placement.y,
        travelDirection: placement.travelDirection,
        turnType: placement.turnType,
        color: shuffledColors[carId % shuffledColors.length],
        vehicleColor: shuffledVehicleColors[carId % shuffledVehicleColors.length],
      ));
      occupied.add((placement.x, placement.y));
      carId++;
    }

    return cars;
  }

  static bool _isOnHorizontalRoad(int x, int y, List<RoadSegment> roadSegments) {
    for (var segment in roadSegments) {
      if (segment.isHorizontal && segment.containsPoint(x, y)) return true;
    }
    return false;
  }

  static bool _isOnVerticalRoad(int x, int y, List<RoadSegment> roadSegments) {
    for (var segment in roadSegments) {
      if (segment.isVertical && segment.containsPoint(x, y)) return true;
    }
    return false;
  }

  static (int, int)? _findNextIntersection(int x, int y, CarFacing direction, int gridSize, List<RoadSegment> roadSegments, Set<(int, int)> intersections) {
    int cx = x;
    int cy = y;

    while (true) {
      cx += direction.dx;
      cy += direction.dy;

      if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) {
        return null; // Reached edge without finding intersection
      }

      if (intersections.contains((cx, cy))) {
        return (cx, cy);
      }

      // Check if still on road
      bool onRoad = false;
      for (var segment in roadSegments) {
        if (segment.containsPoint(cx, cy)) {
          onRoad = true;
          break;
        }
      }
      if (!onRoad) return null;
    }
  }

  static bool _hasRoadInDirection(int x, int y, CarFacing direction, List<RoadSegment> roadSegments) {
    for (var segment in roadSegments) {
      if (!segment.containsPoint(x, y)) continue;
      if (direction.isHorizontal && segment.isHorizontal) return true;
      if (direction.isVertical && segment.isVertical) return true;
    }
    return false;
  }

  static bool _canReachEdge(int x, int y, CarFacing direction, int gridSize, List<RoadSegment> roadSegments) {
    int cx = x;
    int cy = y;

    while (true) {
      cx += direction.dx;
      cy += direction.dy;

      if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) {
        return true;
      }

      bool onRoad = false;
      for (var segment in roadSegments) {
        if (segment.containsPoint(cx, cy)) {
          onRoad = true;
          break;
        }
      }
      if (!onRoad) return false;
    }
  }

  // Validate the full path: car -> intersection(s) -> turn(s) -> exit
  static bool _validateFullPath(int startX, int startY, CarFacing travelDir, TurnType turnType, int gridSize, List<RoadSegment> roadSegments, Set<(int, int)> intersections) {
    int x = startX;
    int y = startY;
    CarFacing currentDir = travelDir;

    // U-turns require 2 turns at 2 different intersections
    int turnsNeeded = turnType.isUTurn ? 2 : 1;
    int turnsMade = 0;

    int steps = 0;
    int maxSteps = gridSize * 4;

    while (steps < maxSteps) {
      int nextX = x + currentDir.dx;
      int nextY = y + currentDir.dy;

      // Reached edge - success only if all turns were made
      if (nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize) {
        return turnsMade == turnsNeeded;
      }

      // Check if next cell is on road
      bool onRoad = false;
      for (var segment in roadSegments) {
        if (segment.containsPoint(nextX, nextY)) {
          onRoad = true;
          break;
        }
      }
      if (!onRoad) return false;

      x = nextX;
      y = nextY;
      steps++;

      // Apply turn at intersection
      if (turnsMade < turnsNeeded && intersections.contains((x, y))) {
        CarFacing newDir;

        if (turnType.isUTurn) {
          // U-turn: turn left twice or right twice
          if (turnType == TurnType.uTurnLeft) {
            newDir = currentDir.turnLeft;
          } else {
            newDir = currentDir.turnRight;
          }
        } else {
          // Regular turn
          newDir = turnType.getFirstTurnDirection(currentDir);
        }

        // Verify there's a road in the new direction
        if (!_hasRoadInDirection(x, y, newDir, roadSegments)) {
          return false;
        }

        currentDir = newDir;
        turnsMade++;
      }
    }

    return false; // Too many steps without reaching edge
  }

  static bool _isSolvable(CarJamPuzzle puzzle) {
    if (puzzle.cars.isEmpty) return false;

    final testPuzzle = puzzle.copyWith();
    int maxIterations = testPuzzle.cars.length * 3;
    int iterations = 0;

    while (!testPuzzle.isComplete && iterations < maxIterations) {
      bool foundMove = false;

      for (var car in testPuzzle.activeCars) {
        if (testPuzzle.canCarExit(car)) {
          testPuzzle.removeCar(car.id);
          foundMove = true;
          break;
        }
      }

      if (!foundMove) {
        return false;
      }
      iterations++;
    }

    return testPuzzle.isComplete;
  }

  static CarJamPuzzle _generateGuaranteedPuzzle(int gridSize, int intersectionCount) {
    List<Intersection> intersections = [];
    List<RoadSegment> roadSegments = [];
    Set<String> addedSegments = {};

    int cols = (sqrt(intersectionCount) + 0.5).ceil();
    int rows = (intersectionCount / cols).ceil();

    double xSpacing = (gridSize - 2) / (cols + 1);
    double ySpacing = (gridSize - 2) / (rows + 1);

    int created = 0;
    for (int row = 1; row <= rows && created < intersectionCount; row++) {
      for (int col = 1; col <= cols && created < intersectionCount; col++) {
        int x = (1 + xSpacing * col).round().clamp(1, gridSize - 2);
        int y = (1 + ySpacing * row).round().clamp(1, gridSize - 2);

        bool duplicate = intersections.any((i) => i.x == x && i.y == y);
        if (!duplicate) {
          intersections.add(Intersection(x, y));
          created++;
        }
      }
    }

    for (var intersection in intersections) {
      var hSegment = RoadSegment(x1: 0, y1: intersection.y, x2: gridSize - 1, y2: intersection.y);
      String hKey = _segmentKey(hSegment);
      if (!addedSegments.contains(hKey)) {
        roadSegments.add(hSegment);
        addedSegments.add(hKey);
      }

      var vSegment = RoadSegment(x1: intersection.x, y1: 0, x2: intersection.x, y2: gridSize - 1);
      String vKey = _segmentKey(vSegment);
      if (!addedSegments.contains(vKey)) {
        roadSegments.add(vSegment);
        addedSegments.add(vKey);
      }
    }

    Set<(int, int)> intersectionSet = intersections.map((i) => (i.x, i.y)).toSet();
    Set<(int, int)> roadCells = {};
    for (var segment in roadSegments) {
      for (var cell in segment.cells) {
        if (!intersectionSet.contains(cell)) {
          roadCells.add(cell);
        }
      }
    }

    List<GridCar> cars = [];
    List<Color> shuffledColors = List.from(_carColors)..shuffle(_random);
    List<CarEscapeColor> shuffledVehicleColors = List.from(_vehicleColors)..shuffle(_random);
    int carId = 0;
    Set<(int, int)> occupied = {};

    List<(int, int)> cellList = roadCells.toList()..shuffle(_random);

    for (var cell in cellList) {
      if (cars.length >= intersectionCount * 2) break;
      if (occupied.contains(cell)) continue;

      bool isOnHorizontal = _isOnHorizontalRoad(cell.$1, cell.$2, roadSegments);
      bool isOnVertical = _isOnVerticalRoad(cell.$1, cell.$2, roadSegments);

      List<CarFacing> travelDirs = [];
      if (isOnHorizontal) {
        travelDirs.add(CarFacing.left);
        travelDirs.add(CarFacing.right);
      }
      if (isOnVertical) {
        travelDirs.add(CarFacing.up);
        travelDirs.add(CarFacing.down);
      }

      if (travelDirs.isEmpty) continue;

      travelDirs.shuffle(_random);
      List<TurnType> turnTypes = List.from(TurnType.values)..shuffle(_random);

      bool placed = false;
      for (var travelDir in travelDirs) {
        if (placed) break;

        var intersectionInfo = _findNextIntersection(cell.$1, cell.$2, travelDir, gridSize, roadSegments, intersectionSet);

        for (var turnType in turnTypes) {
          if (placed) break;

          if (intersectionInfo != null) {
            var (intX, intY) = intersectionInfo;

            // U-turns require special validation - need two intersections
            if (turnType.isUTurn) {
              // First turn direction at first intersection
              CarFacing firstTurnDir = turnType == TurnType.uTurnLeft
                  ? travelDir.turnLeft
                  : travelDir.turnRight;

              // Check if there's a road in the first turn direction
              if (!_hasRoadInDirection(intX, intY, firstTurnDir, roadSegments)) continue;

              // Find second intersection after first turn
              var secondIntersection = _findNextIntersection(
                  intX, intY, firstTurnDir, gridSize, roadSegments, intersectionSet);

              if (secondIntersection == null) continue;

              var (int2X, int2Y) = secondIntersection;

              // Second turn direction (same as first: left or right)
              CarFacing secondTurnDir = turnType == TurnType.uTurnLeft
                  ? firstTurnDir.turnLeft
                  : firstTurnDir.turnRight;

              // Check if we can make second turn and reach edge
              if (!_hasRoadInDirection(int2X, int2Y, secondTurnDir, roadSegments)) continue;
              if (!_canReachEdge(int2X, int2Y, secondTurnDir, gridSize, roadSegments)) continue;
            } else {
              // Regular turns (straight, left, right)
              CarFacing exitDir = turnType.getExitDirection(travelDir);

              if (!_hasRoadInDirection(intX, intY, exitDir, roadSegments)) continue;
              if (!_canReachEdge(intX, intY, exitDir, gridSize, roadSegments)) continue;
            }
          } else {
            if (turnType != TurnType.straight) continue;
            if (!_canReachEdge(cell.$1, cell.$2, travelDir, gridSize, roadSegments)) continue;
          }

          cars.add(GridCar(
            id: carId,
            gridX: cell.$1,
            gridY: cell.$2,
            travelDirection: travelDir,
            turnType: turnType,
            color: shuffledColors[carId % shuffledColors.length],
            vehicleColor: shuffledVehicleColors[carId % shuffledVehicleColors.length],
          ));
          occupied.add(cell);
          carId++;
          placed = true;
        }
      }
    }

    return CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars,
    );
  }
}

class _CarPlacement {
  final int x, y;
  final CarFacing travelDirection;
  final TurnType turnType;

  _CarPlacement({
    required this.x,
    required this.y,
    required this.travelDirection,
    required this.turnType,
  });
}
