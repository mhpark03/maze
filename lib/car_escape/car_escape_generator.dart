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

    for (int attempt = 0; attempt < 100; attempt++) {
      final puzzle = _generatePuzzle(gridSize, intersectionCount, targetCars);
      if (puzzle != null && _isSolvable(puzzle)) {
        return puzzle;
      }
      if (attempt % 20 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // Fallback: generate a guaranteed multi-intersection puzzle
    return _generateGuaranteedPuzzle(gridSize, intersectionCount);
  }

  static CarJamPuzzle? _generatePuzzle(int gridSize, int intersectionCount, int targetCars) {
    // Generate random intersections using grid-based approach
    List<Intersection> intersections = _generateGridIntersections(gridSize, intersectionCount);
    if (intersections.length < 2) return null;

    // Generate road segments connecting intersections and edges
    List<RoadSegment> roadSegments = _generateRoadSegments(gridSize, intersections);
    if (roadSegments.isEmpty) return null;

    // Generate cars on road segments
    List<GridCar> cars = _generateCars(gridSize, roadSegments, targetCars);
    if (cars.length < 3) return null; // Need at least 3 cars

    return CarJamPuzzle(
      gridSize: gridSize,
      intersections: intersections,
      roadSegments: roadSegments,
      cars: cars,
    );
  }

  // Generate intersections on a virtual grid to ensure good distribution
  static List<Intersection> _generateGridIntersections(int gridSize, int count) {
    List<Intersection> intersections = [];

    // Calculate how many rows/cols of intersections we can fit
    int divisions = (sqrt(count) + 0.5).ceil();
    if (divisions < 2) divisions = 2;

    // Available positions (excluding edges)
    int availableSize = gridSize - 2; // positions 1 to gridSize-2
    double spacing = availableSize / (divisions + 1);

    // Generate candidate positions
    List<(int, int)> candidates = [];
    for (int i = 1; i <= divisions; i++) {
      for (int j = 1; j <= divisions; j++) {
        int x = (1 + spacing * i).round().clamp(1, gridSize - 2);
        int y = (1 + spacing * j).round().clamp(1, gridSize - 2);
        candidates.add((x, y));
      }
    }

    // Shuffle and pick required number
    candidates.shuffle(_random);
    Set<(int, int)> used = {};

    for (var pos in candidates) {
      if (intersections.length >= count) break;
      if (!used.contains(pos)) {
        intersections.add(Intersection(pos.$1, pos.$2));
        used.add(pos);
      }
    }

    // If we still need more, add random positions
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

    // Each intersection connects to 2-4 edges
    for (var intersection in intersections) {
      List<int> directions = [0, 1, 2, 3]..shuffle(_random);
      int connectCount = 2 + _random.nextInt(2); // 2-3 connections to edges

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

    // Connect nearby intersections (same row or column)
    for (int i = 0; i < intersections.length; i++) {
      for (int j = i + 1; j < intersections.length; j++) {
        var a = intersections[i];
        var b = intersections[j];

        // Connect if on same row or column
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
      case 0: // Up to edge
        return RoadSegment(
          x1: intersection.x, y1: intersection.y,
          x2: intersection.x, y2: 0,
        );
      case 1: // Down to edge
        return RoadSegment(
          x1: intersection.x, y1: intersection.y,
          x2: intersection.x, y2: gridSize - 1,
        );
      case 2: // Left to edge
        return RoadSegment(
          x1: intersection.x, y1: intersection.y,
          x2: 0, y2: intersection.y,
        );
      case 3: // Right to edge
        return RoadSegment(
          x1: intersection.x, y1: intersection.y,
          x2: gridSize - 1, y2: intersection.y,
        );
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

    // Find cells that can exit
    Map<(int, int), List<CarFacing>> exitableCells = {};
    for (var cell in roadCells) {
      List<CarFacing> possibleFacings = [];

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

      if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) {
        return true;
      }

      if (!roadCells.contains((cx, cy))) {
        return false;
      }
    }
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

  // Generate a guaranteed working puzzle with multiple intersections
  static CarJamPuzzle _generateGuaranteedPuzzle(int gridSize, int intersectionCount) {
    List<Intersection> intersections = [];
    List<RoadSegment> roadSegments = [];
    Set<String> addedSegments = {};

    // Create a grid pattern of intersections
    int cols = (sqrt(intersectionCount) + 0.5).ceil();
    int rows = (intersectionCount / cols).ceil();

    double xSpacing = (gridSize - 2) / (cols + 1);
    double ySpacing = (gridSize - 2) / (rows + 1);

    int created = 0;
    for (int row = 1; row <= rows && created < intersectionCount; row++) {
      for (int col = 1; col <= cols && created < intersectionCount; col++) {
        int x = (1 + xSpacing * col).round().clamp(1, gridSize - 2);
        int y = (1 + ySpacing * row).round().clamp(1, gridSize - 2);

        // Avoid duplicate positions
        bool duplicate = intersections.any((i) => i.x == x && i.y == y);
        if (!duplicate) {
          intersections.add(Intersection(x, y));
          created++;
        }
      }
    }

    // Connect each intersection to at least 2 edges
    for (var intersection in intersections) {
      // Horizontal road (left and right edges)
      var hSegment = RoadSegment(
        x1: 0, y1: intersection.y,
        x2: gridSize - 1, y2: intersection.y,
      );
      String hKey = _segmentKey(hSegment);
      if (!addedSegments.contains(hKey)) {
        roadSegments.add(hSegment);
        addedSegments.add(hKey);
      }

      // Vertical road (top and bottom edges)
      var vSegment = RoadSegment(
        x1: intersection.x, y1: 0,
        x2: intersection.x, y2: gridSize - 1,
      );
      String vKey = _segmentKey(vSegment);
      if (!addedSegments.contains(vKey)) {
        roadSegments.add(vSegment);
        addedSegments.add(vKey);
      }
    }

    // Generate cars
    Set<(int, int)> roadCells = {};
    for (var segment in roadSegments) {
      roadCells.addAll(segment.cells);
    }

    List<GridCar> cars = [];
    List<Color> shuffledColors = List.from(_carColors)..shuffle(_random);
    int carId = 0;
    Set<(int, int)> occupied = {};

    // Place cars that can definitely exit
    List<(int, int)> cellList = roadCells.toList()..shuffle(_random);

    for (var cell in cellList) {
      if (cars.length >= intersectionCount * 2) break;
      if (occupied.contains(cell)) continue;

      // Find a valid facing for this cell
      CarFacing? validFacing;
      for (var facing in CarFacing.values) {
        if (_canExitInDirection(cell.$1, cell.$2, facing, gridSize, roadCells)) {
          validFacing = facing;
          break;
        }
      }

      if (validFacing != null) {
        cars.add(GridCar(
          id: carId,
          gridX: cell.$1,
          gridY: cell.$2,
          facing: validFacing,
          color: shuffledColors[carId % shuffledColors.length],
        ));
        occupied.add(cell);
        carId++;
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
