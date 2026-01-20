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

  static Future<CarJamPuzzle> generate(CarEscapeDifficulty difficulty) async {
    final gridSize = difficulty.gridSize;
    final intersectionCount = difficulty.intersectionCount;
    final (minCars, maxCars) = difficulty.carCountRange;
    final targetCars = minCars + _random.nextInt(maxCars - minCars + 1);

    for (int attempt = 0; attempt < 50; attempt++) {
      final puzzle = _generatePuzzle(gridSize, intersectionCount, targetCars);
      if (puzzle != null && _isSolvable(puzzle)) {
        return puzzle;
      }
      if (attempt % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    return _generateSimplePuzzle(gridSize);
  }

  static CarJamPuzzle? _generatePuzzle(int gridSize, int intersectionCount, int targetCars) {
    // Generate random intersections
    List<Intersection> intersections = _generateIntersections(gridSize, intersectionCount);
    if (intersections.length < 2) return null;

    // Generate road segments connecting intersections and edges
    List<RoadSegment> roadSegments = _generateRoadSegments(gridSize, intersections);
    if (roadSegments.isEmpty) return null;

    // Generate cars on road segments
    List<GridCar> cars = _generateCars(gridSize, roadSegments, targetCars);
    if (cars.isEmpty) return null;

    return CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars,
    );
  }

  static List<Intersection> _generateIntersections(int gridSize, int count) {
    List<Intersection> intersections = [];
    Set<(int, int)> used = {};

    // Keep intersections away from edges (at least 1 cell)
    for (int i = 0; i < count * 3 && intersections.length < count; i++) {
      int x = 1 + _random.nextInt(gridSize - 2);
      int y = 1 + _random.nextInt(gridSize - 2);

      // Ensure minimum distance between intersections
      bool tooClose = false;
      for (var other in intersections) {
        int dx = (other.x - x).abs();
        int dy = (other.y - y).abs();
        if (dx + dy < 2) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose && !used.contains((x, y))) {
        intersections.add(Intersection(x, y));
        used.add((x, y));
      }
    }

    return intersections;
  }

  static List<RoadSegment> _generateRoadSegments(int gridSize, List<Intersection> intersections) {
    List<RoadSegment> segments = [];
    Set<String> addedSegments = {};

    // Connect each intersection to edges (create exits)
    for (var intersection in intersections) {
      // Randomly choose 2-4 directions to connect
      List<int> directions = [0, 1, 2, 3]..shuffle(_random);
      int connectCount = 2 + _random.nextInt(3); // 2-4 connections

      for (int i = 0; i < connectCount && i < directions.length; i++) {
        RoadSegment? segment;
        switch (directions[i]) {
          case 0: // Up to edge
            segment = RoadSegment(
              x1: intersection.x, y1: intersection.y,
              x2: intersection.x, y2: 0,
            );
            break;
          case 1: // Down to edge
            segment = RoadSegment(
              x1: intersection.x, y1: intersection.y,
              x2: intersection.x, y2: gridSize - 1,
            );
            break;
          case 2: // Left to edge
            segment = RoadSegment(
              x1: intersection.x, y1: intersection.y,
              x2: 0, y2: intersection.y,
            );
            break;
          case 3: // Right to edge
            segment = RoadSegment(
              x1: intersection.x, y1: intersection.y,
              x2: gridSize - 1, y2: intersection.y,
            );
            break;
        }

        if (segment != null) {
          String key = _segmentKey(segment);
          if (!addedSegments.contains(key)) {
            segments.add(segment);
            addedSegments.add(key);
          }
        }
      }
    }

    // Connect some intersections to each other
    for (int i = 0; i < intersections.length; i++) {
      for (int j = i + 1; j < intersections.length; j++) {
        var a = intersections[i];
        var b = intersections[j];

        // Only connect if aligned horizontally or vertically
        if (a.x == b.x || a.y == b.y) {
          if (_random.nextDouble() < 0.7) { // 70% chance to connect
            var segment = RoadSegment(x1: a.x, y1: a.y, x2: b.x, y2: b.y);
            String key = _segmentKey(segment);
            if (!addedSegments.contains(key)) {
              segments.add(segment);
              addedSegments.add(key);
            }
          }
        }
      }
    }

    return segments;
  }

  static String _segmentKey(RoadSegment s) {
    int minX = min(s.x1, s.x2);
    int maxX = max(s.x1, s.x2);
    int minY = min(s.y1, s.y2);
    int maxY = max(s.y1, s.y2);
    return '$minX,$minY-$maxX,$maxY';
  }

  static List<GridCar> _generateCars(int gridSize, List<RoadSegment> roadSegments, int targetCars) {
    List<GridCar> cars = [];
    Set<(int, int)> occupied = {};
    List<Color> shuffledColors = List.from(_carColors)..shuffle(_random);
    int carId = 0;

    // Collect all road cells
    Set<(int, int)> roadCells = {};
    for (var segment in roadSegments) {
      roadCells.addAll(segment.cells);
    }

    // Find cells that can exit (on edge-connected segments)
    Map<(int, int), List<CarFacing>> exitableCells = {};
    for (var cell in roadCells) {
      List<CarFacing> possibleFacings = [];

      // Check each direction
      for (var facing in CarFacing.values) {
        if (_canExitInDirection(cell.$1, cell.$2, facing, gridSize, roadCells)) {
          possibleFacings.add(facing);
        }
      }

      if (possibleFacings.isNotEmpty) {
        exitableCells[cell] = possibleFacings;
      }
    }

    // Place cars on exitable cells
    List<(int, int)> cellList = exitableCells.keys.toList()..shuffle(_random);

    for (var cell in cellList) {
      if (carId >= targetCars) break;
      if (occupied.contains(cell)) continue;

      var facings = exitableCells[cell]!;
      var facing = facings[_random.nextInt(facings.length)];

      cars.add(GridCar(
        id: carId,
        gridX: cell.$1,
        gridY: cell.$2,
        facing: facing,
        color: shuffledColors[carId % shuffledColors.length],
      ));
      occupied.add(cell);
      carId++;
    }

    return cars;
  }

  static bool _canExitInDirection(int x, int y, CarFacing facing, int gridSize, Set<(int, int)> roadCells) {
    int cx = x;
    int cy = y;

    while (true) {
      cx += facing.dx;
      cy += facing.dy;

      // Reached edge = can exit
      if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) {
        return true;
      }

      // Not on road = blocked
      if (!roadCells.contains((cx, cy))) {
        return false;
      }
    }
  }

  static bool _isSolvable(CarJamPuzzle puzzle) {
    if (puzzle.cars.isEmpty) return false;

    final testPuzzle = puzzle.copyWith();
    int maxIterations = testPuzzle.cars.length * 2;
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

  static CarJamPuzzle _generateSimplePuzzle(int gridSize) {
    // Create a simple cross pattern
    int centerX = gridSize ~/ 2;
    int centerY = gridSize ~/ 2;

    List<Intersection> intersections = [Intersection(centerX, centerY)];

    List<RoadSegment> roadSegments = [
      // Horizontal road through center
      RoadSegment(x1: 0, y1: centerY, x2: gridSize - 1, y2: centerY),
      // Vertical road through center
      RoadSegment(x1: centerX, y1: 0, x2: centerX, y2: gridSize - 1),
    ];

    List<GridCar> cars = [];
    List<Color> shuffledColors = List.from(_carColors)..shuffle(_random);
    int carId = 0;

    // Place cars that can definitely exit
    // Left side going left
    cars.add(GridCar(
      id: carId++,
      gridX: 1,
      gridY: centerY,
      facing: CarFacing.left,
      color: shuffledColors[carId % shuffledColors.length],
    ));

    // Right side going right
    cars.add(GridCar(
      id: carId++,
      gridX: gridSize - 2,
      gridY: centerY,
      facing: CarFacing.right,
      color: shuffledColors[carId % shuffledColors.length],
    ));

    // Top going up
    cars.add(GridCar(
      id: carId++,
      gridX: centerX,
      gridY: 1,
      facing: CarFacing.up,
      color: shuffledColors[carId % shuffledColors.length],
    ));

    // Bottom going down
    cars.add(GridCar(
      id: carId++,
      gridX: centerX,
      gridY: gridSize - 2,
      facing: CarFacing.down,
      color: shuffledColors[carId % shuffledColors.length],
    ));

    return CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars,
    );
  }
}
