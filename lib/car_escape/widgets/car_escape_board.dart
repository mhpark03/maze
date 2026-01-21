import 'dart:math';
import 'package:flutter/material.dart';
import '../models/car_escape_models.dart';

class CarEscapeBoard extends StatefulWidget {
  final CarJamPuzzle puzzle;
  final Function(GridCar) onCarTap;
  final Function(GridCar) onCarExited;
  final int? hintCarId;

  const CarEscapeBoard({
    super.key,
    required this.puzzle,
    required this.onCarTap,
    required this.onCarExited,
    this.hintCarId,
  });

  @override
  State<CarEscapeBoard> createState() => _CarEscapeBoardState();
}

class _CarEscapeBoardState extends State<CarEscapeBoard>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _exitControllers = {};
  final Map<int, List<Offset>> _exitPaths = {}; // Store the path for each car
  final Map<int, List<CarFacing>> _exitDirections = {}; // Store direction at each path point
  final Map<int, AnimationController> _collisionControllers = {};
  final Map<int, List<Offset>> _collisionPaths = {}; // Path to collision point
  final Map<int, List<CarFacing>> _collisionDirections = {}; // Direction during collision
  int? _highlightedBlockingCarId;
  double _cellSize = 50; // Default cell size, updated in build

  @override
  void dispose() {
    for (var controller in _exitControllers.values) {
      controller.dispose();
    }
    for (var controller in _collisionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCarTap(GridCar car) {
    if (_exitControllers.containsKey(car.id)) return;
    if (_collisionControllers.containsKey(car.id)) return;
    if (car.hasExited || car.isExiting) return;

    if (widget.puzzle.canCarExit(car)) {
      _startExitAnimation(car);
    } else {
      _startCollisionAnimation(car);
    }
  }

  void _startExitAnimation(GridCar car) {
    // Build the full path: current position -> path cells -> exit off edge
    final gridPath = widget.puzzle.getFullPath(car);
    List<Offset> pathOffsets = [Offset.zero]; // Start at current position (0,0 offset)
    List<CarFacing> pathDirections = [car.travelDirection]; // Start with initial direction

    // Track current direction and turns needed for U-turns
    CarFacing currentDirection = car.travelDirection;
    int turnsNeeded = car.turnType.isUTurn ? 2 : 1;
    int turnsMade = 0;

    // Add each cell in the path as offset from starting position
    for (var cell in gridPath) {
      // Check if this cell is an intersection where we turn
      if (turnsMade < turnsNeeded && widget.puzzle.isIntersection(cell.$1, cell.$2)) {
        CarFacing newDir;
        if (car.turnType.isUTurn) {
          // For U-turn: each turn is left or right
          if (car.turnType == TurnType.uTurnLeft) {
            newDir = currentDirection.turnLeft;
          } else {
            newDir = currentDirection.turnRight;
          }
        } else {
          newDir = car.turnType.getFirstTurnDirection(currentDirection);
        }

        if (widget.puzzle.hasRoadInDirection(cell.$1, cell.$2, newDir)) {
          currentDirection = newDir;
          turnsMade++;
        }
      }

      pathOffsets.add(Offset(
        (cell.$1 - car.gridX).toDouble(),
        (cell.$2 - car.gridY).toDouble(),
      ));
      pathDirections.add(currentDirection);
    }

    // Add final exit point off the edge
    final lastOffset = pathOffsets.last;
    double exitX = lastOffset.dx;
    double exitY = lastOffset.dy;
    switch (currentDirection) {
      case CarFacing.left:
        exitX -= 3;
        break;
      case CarFacing.right:
        exitX += 3;
        break;
      case CarFacing.up:
        exitY -= 3;
        break;
      case CarFacing.down:
        exitY += 3;
        break;
    }
    pathOffsets.add(Offset(exitX, exitY));
    pathDirections.add(currentDirection); // Final direction stays the same

    // Calculate animation duration based on path length
    final duration = Duration(milliseconds: 150 * pathOffsets.length);

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _exitControllers[car.id] = controller;
    _exitPaths[car.id] = pathOffsets;
    _exitDirections[car.id] = pathDirections;
    car.isExiting = true;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCarExited(car);
        _exitControllers.remove(car.id)?.dispose();
        _exitPaths.remove(car.id);
        _exitDirections.remove(car.id);
        if (mounted) setState(() {});
      }
    });

    controller.forward();
    setState(() {});
    widget.onCarTap(car);
  }

  // Interpolate position along the path based on animation value (0.0 to 1.0)
  Offset _getPathPosition(List<Offset> path, double t) {
    if (path.isEmpty) return Offset.zero;
    if (path.length == 1) return path[0];

    // Calculate which segment we're on
    double totalSegments = path.length - 1;
    double segmentProgress = t * totalSegments;
    int segmentIndex = segmentProgress.floor().clamp(0, path.length - 2);
    double localT = segmentProgress - segmentIndex;

    // Linear interpolation between segment points
    Offset start = path[segmentIndex];
    Offset end = path[segmentIndex + 1];
    return Offset(
      start.dx + (end.dx - start.dx) * localT,
      start.dy + (end.dy - start.dy) * localT,
    );
  }

  // Get the direction at a given point along the path
  CarFacing _getPathDirection(List<CarFacing> directions, double t) {
    if (directions.isEmpty) return CarFacing.up;
    if (directions.length == 1) return directions[0];

    double totalSegments = directions.length - 1;
    double segmentProgress = t * totalSegments;
    int segmentIndex = segmentProgress.floor().clamp(0, directions.length - 1);

    return directions[segmentIndex];
  }

  // Convert CarFacing to quarter turns for RotatedBox
  int _facingToQuarterTurns(CarFacing facing) {
    switch (facing) {
      case CarFacing.up:
        return 0;
      case CarFacing.right:
        return 1;
      case CarFacing.down:
        return 2;
      case CarFacing.left:
        return 3;
    }
  }

  void _startCollisionAnimation(GridCar car) {
    if (_collisionControllers.containsKey(car.id)) {
      return;
    }

    final blockingCar = widget.puzzle.getBlockingCar(car);

    // Build path to collision point
    final gridPath = widget.puzzle.getFullPath(car);
    List<Offset> pathOffsets = [Offset.zero];
    List<CarFacing> pathDirections = [car.travelDirection];

    CarFacing currentDirection = car.travelDirection;
    int turnsNeeded = car.turnType.isUTurn ? 2 : 1;
    int turnsMade = 0;

    // Find collision point in the path
    int collisionIndex = -1;
    if (blockingCar != null) {
      for (int i = 0; i < gridPath.length; i++) {
        if (gridPath[i].$1 == blockingCar.gridX && gridPath[i].$2 == blockingCar.gridY) {
          collisionIndex = i;
          break;
        }
      }
    }

    // Build path up to one cell before collision (or full path if no collision found)
    int pathLength = collisionIndex > 0 ? collisionIndex : (gridPath.isEmpty ? 0 : min(gridPath.length, 3));

    for (int i = 0; i < pathLength; i++) {
      var cell = gridPath[i];

      // Check for direction change at intersection
      if (turnsMade < turnsNeeded && widget.puzzle.isIntersection(cell.$1, cell.$2)) {
        CarFacing newDir;
        if (car.turnType.isUTurn) {
          if (car.turnType == TurnType.uTurnLeft) {
            newDir = currentDirection.turnLeft;
          } else {
            newDir = currentDirection.turnRight;
          }
        } else {
          newDir = car.turnType.getFirstTurnDirection(currentDirection);
        }

        if (widget.puzzle.hasRoadInDirection(cell.$1, cell.$2, newDir)) {
          currentDirection = newDir;
          turnsMade++;
        }
      }

      pathOffsets.add(Offset(
        (cell.$1 - car.gridX).toDouble(),
        (cell.$2 - car.gridY).toDouble(),
      ));
      pathDirections.add(currentDirection);
    }

    // If no path, just do a small forward movement
    if (pathOffsets.length == 1) {
      pathOffsets.add(Offset(
        car.travelDirection.dx * 0.3,
        car.travelDirection.dy * 0.3,
      ));
      pathDirections.add(car.travelDirection);
    }

    _collisionPaths[car.id] = pathOffsets;
    _collisionDirections[car.id] = pathDirections;

    // Highlight blocking car
    if (blockingCar != null) {
      setState(() {
        _highlightedBlockingCarId = blockingCar.id;
      });
    }

    // Animation duration based on path length
    final duration = Duration(milliseconds: 150 * pathOffsets.length + 300); // extra for shake

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _collisionControllers[car.id] = controller;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _collisionControllers.remove(car.id)?.dispose();
        _collisionPaths.remove(car.id);
        _collisionDirections.remove(car.id);
        if (mounted) {
          setState(() {
            _highlightedBlockingCarId = null;
          });
        }
      }
    });

    controller.forward();
    setState(() {});
  }

  // Get collision animation position: forward (0-0.4), shake (0.4-0.6), return (0.6-1.0)
  Offset _getCollisionPosition(List<Offset> path, double t, CarFacing direction) {
    if (path.isEmpty) return Offset.zero;

    if (t < 0.4) {
      // Phase 1: Move forward
      double forwardT = t / 0.4;
      return _getPathPosition(path, forwardT);
    } else if (t < 0.6) {
      // Phase 2: Shake at collision point
      double shakeT = (t - 0.4) / 0.2;
      final basePos = path.last;
      final shakeAmount = _cellSize * 0.08 / _cellSize; // Normalized shake
      double shakeOffset = sin(shakeT * pi * 4) * shakeAmount * (1 - shakeT);

      if (direction.isHorizontal) {
        return Offset(basePos.dx + shakeOffset, basePos.dy);
      } else {
        return Offset(basePos.dx, basePos.dy + shakeOffset);
      }
    } else {
      // Phase 3: Return to start
      double returnT = (t - 0.6) / 0.4;
      final endPos = _getPathPosition(path, 1.0 - returnT);
      return endPos;
    }
  }

  // Get collision animation direction
  CarFacing _getCollisionDirection(List<CarFacing> directions, double t) {
    if (directions.isEmpty) return CarFacing.up;

    if (t < 0.4) {
      double forwardT = t / 0.4;
      return _getPathDirection(directions, forwardT);
    } else if (t < 0.6) {
      return directions.last;
    } else {
      double returnT = (t - 0.6) / 0.4;
      return _getPathDirection(directions, 1.0 - returnT);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use maximum available space
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / widget.puzzle.gridSize;
        _cellSize = cellSize; // Store for use in animations

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C3F),
              borderRadius: BorderRadius.circular(cellSize * 0.15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cellSize * 0.15),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Draw roads
                  CustomPaint(
                    size: Size(size, size),
                    painter: _RoadSegmentPainter(
                      gridSize: widget.puzzle.gridSize,
                      cellSize: cellSize,
                      roadSegments: widget.puzzle.roadSegments,
                      intersections: widget.puzzle.intersections,
                    ),
                  ),
                  // Draw cars
                  ...widget.puzzle.cars.map(
                    (car) => _buildCar(car, cellSize),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCar(GridCar car, double cellSize) {
    if (car.hasExited && !_exitPaths.containsKey(car.id)) {
      return const SizedBox.shrink();
    }

    final carSize = cellSize * 0.75;
    double left = car.gridX * cellSize + (cellSize - carSize) / 2;
    double top = car.gridY * cellSize + (cellSize - carSize) / 2;

    final exitPath = _exitPaths[car.id];
    final exitController = _exitControllers[car.id];
    final collisionPath = _collisionPaths[car.id];
    final collisionController = _collisionControllers[car.id];
    final collisionDirections = _collisionDirections[car.id];
    final isHighlighted = _highlightedBlockingCarId == car.id;
    final isHintCar = widget.hintCarId == car.id;

    // Calculate rotation for car image based on travel direction
    // The car image faces UP by default
    int quarterTurns = 0;
    switch (car.travelDirection) {
      case CarFacing.up:
        quarterTurns = 0;
        break;
      case CarFacing.right:
        quarterTurns = 1;
        break;
      case CarFacing.down:
        quarterTurns = 2;
        break;
      case CarFacing.left:
        quarterTurns = 3;
        break;
    }

    Widget carWidget = GestureDetector(
      onTap: () => _onCarTap(car),
      child: SizedBox(
        width: carSize,
        height: carSize,
        child: Stack(
          children: [
            // Car image
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: quarterTurns,
                child: Image.asset(
                  car.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Highlight overlay
            if (isHighlighted || isHintCar)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cellSize * 0.15),
                  border: Border.all(
                    color: isHintCar ? Colors.yellow : Colors.white,
                    width: cellSize * 0.06,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHintCar
                          ? Colors.yellow.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.5),
                      blurRadius: cellSize * 0.25,
                      spreadRadius: cellSize * 0.08,
                    ),
                  ],
                ),
              ),
            // Turn type icon overlay - centered with transparent background
            Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: car.travelDirection.rotation * pi / 180,
                  child: Icon(
                    car.turnType.icon,
                    color: Colors.white,
                    size: carSize * 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: cellSize * 0.08,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Collision animation: move to blocking car, shake, return
    if (collisionPath != null && collisionController != null) {
      return AnimatedBuilder(
        animation: collisionController,
        builder: (context, child) {
          final t = collisionController.value;
          final offset = _getCollisionPosition(collisionPath, t, car.travelDirection);

          // Get current direction for rotation
          CarFacing currentFacing = car.travelDirection;
          if (collisionDirections != null) {
            currentFacing = _getCollisionDirection(collisionDirections, t);
          }
          int dynamicQuarterTurns = _facingToQuarterTurns(currentFacing);

          // Build car widget with dynamic rotation
          Widget animatedCarWidget = GestureDetector(
            onTap: () => _onCarTap(car),
            child: SizedBox(
              width: carSize,
              height: carSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RotatedBox(
                      quarterTurns: dynamicQuarterTurns,
                      child: Image.asset(
                        car.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (isHighlighted || isHintCar)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cellSize * 0.15),
                        border: Border.all(
                          color: isHintCar ? Colors.yellow : Colors.white,
                          width: cellSize * 0.06,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: currentFacing.rotation * pi / 180,
                        child: Icon(
                          car.turnType.icon,
                          color: Colors.white,
                          size: carSize * 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: cellSize * 0.08,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Positioned(
            left: left + offset.dx * cellSize,
            top: top + offset.dy * cellSize,
            child: animatedCarWidget,
          );
        },
      );
    }

    if (exitPath != null && exitController != null) {
      final exitDirections = _exitDirections[car.id];
      return AnimatedBuilder(
        animation: exitController,
        builder: (context, child) {
          final offset = _getPathPosition(exitPath, exitController.value);

          // Get current direction and calculate rotation
          CarFacing currentFacing = car.travelDirection;
          if (exitDirections != null) {
            currentFacing = _getPathDirection(exitDirections, exitController.value);
          }
          int dynamicQuarterTurns = _facingToQuarterTurns(currentFacing);

          // Build car widget with dynamic rotation
          Widget animatedCarWidget = GestureDetector(
            onTap: () => _onCarTap(car),
            child: SizedBox(
              width: carSize,
              height: carSize,
              child: Stack(
                children: [
                  // Car image with dynamic rotation
                  Positioned.fill(
                    child: RotatedBox(
                      quarterTurns: dynamicQuarterTurns,
                      child: Image.asset(
                        car.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Turn type icon - rotates with the car
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: currentFacing.rotation * pi / 180,
                        child: Icon(
                          car.turnType.icon,
                          color: Colors.white,
                          size: carSize * 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: cellSize * 0.08,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Positioned(
            left: left + offset.dx * cellSize,
            top: top + offset.dy * cellSize,
            child: Opacity(
              opacity: (1 - exitController.value * 0.5).clamp(0.0, 1.0),
              child: animatedCarWidget,
            ),
          );
        },
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: carWidget,
    );
  }
}

class _RoadSegmentPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final List<RoadSegment> roadSegments;
  final List<Intersection> intersections;

  _RoadSegmentPainter({
    required this.gridSize,
    required this.cellSize,
    required this.roadSegments,
    required this.intersections,
  });

  // Check if there's a road in a specific direction from a point
  bool _hasRoadInDirection(int x, int y, int dx, int dy) {
    for (var segment in roadSegments) {
      if (!segment.containsPoint(x, y)) continue;
      if (dx != 0 && segment.isHorizontal) return true;
      if (dy != 0 && segment.isVertical) return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.fill;

    final roadWidth = cellSize * 0.85;

    // Draw each road segment
    for (var segment in roadSegments) {
      _drawRoadSegment(canvas, segment, roadPaint, roadWidth, size);
    }

    // Draw intersections
    for (var intersection in intersections) {
      _drawIntersection(canvas, intersection, roadPaint, roadWidth);
    }

    // Draw exit indicators at edges
    _drawExitIndicators(canvas, size, roadWidth);
  }

  void _drawRoadSegment(Canvas canvas, RoadSegment segment, Paint roadPaint, double roadWidth, Size size) {
    if (segment.isHorizontal) {
      int minX = min(segment.x1, segment.x2);
      int maxX = max(segment.x1, segment.x2);
      double y = segment.y1 * cellSize + (cellSize - roadWidth) / 2;
      double startX = minX * cellSize + (cellSize - roadWidth) / 2;
      double endX = maxX * cellSize + (cellSize + roadWidth) / 2;

      // Extend to edge if at boundary
      if (minX == 0) startX = 0;
      if (maxX == gridSize - 1) endX = size.width;

      canvas.drawRect(
        Rect.fromLTWH(startX, y, endX - startX, roadWidth),
        roadPaint,
      );

      // Draw center dashed line
      _drawHorizontalDashedLine(canvas, startX, endX, y + roadWidth / 2);
    } else if (segment.isVertical) {
      int minY = min(segment.y1, segment.y2);
      int maxY = max(segment.y1, segment.y2);
      double x = segment.x1 * cellSize + (cellSize - roadWidth) / 2;
      double startY = minY * cellSize + (cellSize - roadWidth) / 2;
      double endY = maxY * cellSize + (cellSize + roadWidth) / 2;

      // Extend to edge if at boundary
      if (minY == 0) startY = 0;
      if (maxY == gridSize - 1) endY = size.height;

      canvas.drawRect(
        Rect.fromLTWH(x, startY, roadWidth, endY - startY),
        roadPaint,
      );

      // Draw center dashed line
      _drawVerticalDashedLine(canvas, x + roadWidth / 2, startY, endY);
    }
  }

  void _drawIntersection(Canvas canvas, Intersection intersection, Paint roadPaint, double roadWidth) {
    double x = intersection.x * cellSize + (cellSize - roadWidth) / 2;
    double y = intersection.y * cellSize + (cellSize - roadWidth) / 2;

    // Draw intersection square
    canvas.drawRect(
      Rect.fromLTWH(x, y, roadWidth, roadWidth),
      roadPaint,
    );

    // Draw direction arrows showing available roads
    final centerX = intersection.x * cellSize + cellSize / 2;
    final centerY = intersection.y * cellSize + cellSize / 2;
    final arrowSize = cellSize * 0.15;

    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Check and draw arrows for each direction
    // Up
    if (_hasRoadInDirection(intersection.x, intersection.y, 0, -1)) {
      _drawArrow(canvas, centerX, centerY - roadWidth * 0.3, 0, arrowSize, arrowPaint);
    }
    // Down
    if (_hasRoadInDirection(intersection.x, intersection.y, 0, 1)) {
      _drawArrow(canvas, centerX, centerY + roadWidth * 0.3, 180, arrowSize, arrowPaint);
    }
    // Left
    if (_hasRoadInDirection(intersection.x, intersection.y, -1, 0)) {
      _drawArrow(canvas, centerX - roadWidth * 0.3, centerY, 270, arrowSize, arrowPaint);
    }
    // Right
    if (_hasRoadInDirection(intersection.x, intersection.y, 1, 0)) {
      _drawArrow(canvas, centerX + roadWidth * 0.3, centerY, 90, arrowSize, arrowPaint);
    }
  }

  void _drawArrow(Canvas canvas, double x, double y, double rotation, double size, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation * pi / 180);

    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.6, size * 0.3);
    path.lineTo(-size * 0.6, size * 0.3);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawHorizontalDashedLine(Canvas canvas, double startX, double endX, double y) {
    final strokeWidth = cellSize * 0.04;
    final padding = cellSize * 0.2;
    final dashLength = cellSize * 0.25;
    final gapLength = cellSize * 0.4;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth;

    double x = startX + padding;
    while (x < endX - padding) {
      canvas.drawLine(
        Offset(x, y),
        Offset(min(x + dashLength, endX - padding), y),
        linePaint,
      );
      x += gapLength;
    }
  }

  void _drawVerticalDashedLine(Canvas canvas, double x, double startY, double endY) {
    final strokeWidth = cellSize * 0.04;
    final padding = cellSize * 0.2;
    final dashLength = cellSize * 0.25;
    final gapLength = cellSize * 0.4;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth;

    double y = startY + padding;
    while (y < endY - padding) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, min(y + dashLength, endY - padding)),
        linePaint,
      );
      y += gapLength;
    }
  }

  void _drawExitIndicators(Canvas canvas, Size size, double roadWidth) {
    final exitPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;

    final indicatorSize = cellSize * 0.2;
    final indicatorOffset = cellSize * 0.1;

    // Find all road segments that touch edges and draw exit indicators
    for (var segment in roadSegments) {
      if (segment.isHorizontal) {
        double y = segment.y1 * cellSize + (cellSize - roadWidth) / 2;
        int minX = min(segment.x1, segment.x2);
        int maxX = max(segment.x1, segment.x2);

        if (minX == 0) {
          // Left edge exit
          canvas.drawRect(
            Rect.fromLTWH(-indicatorOffset, y, indicatorSize, roadWidth),
            exitPaint,
          );
        }
        if (maxX == gridSize - 1) {
          // Right edge exit
          canvas.drawRect(
            Rect.fromLTWH(size.width - indicatorOffset, y, indicatorSize, roadWidth),
            exitPaint,
          );
        }
      } else if (segment.isVertical) {
        double x = segment.x1 * cellSize + (cellSize - roadWidth) / 2;
        int minY = min(segment.y1, segment.y2);
        int maxY = max(segment.y1, segment.y2);

        if (minY == 0) {
          // Top edge exit
          canvas.drawRect(
            Rect.fromLTWH(x, -indicatorOffset, roadWidth, indicatorSize),
            exitPaint,
          );
        }
        if (maxY == gridSize - 1) {
          // Bottom edge exit
          canvas.drawRect(
            Rect.fromLTWH(x, size.height - indicatorOffset, roadWidth, indicatorSize),
            exitPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
