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
  final Map<int, AnimationController> _shakeControllers = {};
  final Map<int, Animation<double>> _shakeAnimations = {};
  int? _highlightedBlockingCarId;

  @override
  void dispose() {
    for (var controller in _exitControllers.values) {
      controller.dispose();
    }
    for (var controller in _shakeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCarTap(GridCar car) {
    if (_exitControllers.containsKey(car.id)) return;
    if (car.hasExited || car.isExiting) return;

    if (widget.puzzle.canCarExit(car)) {
      _startExitAnimation(car);
    } else {
      _startShakeAnimation(car);
    }
  }

  void _startExitAnimation(GridCar car) {
    // Build the full path: current position -> path cells -> exit off edge
    final gridPath = widget.puzzle.getFullPath(car);
    List<Offset> pathOffsets = [Offset.zero]; // Start at current position (0,0 offset)

    // Add each cell in the path as offset from starting position
    for (var cell in gridPath) {
      pathOffsets.add(Offset(
        (cell.$1 - car.gridX).toDouble(),
        (cell.$2 - car.gridY).toDouble(),
      ));
    }

    // Determine the exit direction (after any turns)
    CarFacing finalDirection = car.travelDirection;
    if (gridPath.isNotEmpty) {
      // Check if car reached an intersection and turned
      for (var cell in gridPath) {
        if (widget.puzzle.isIntersection(cell.$1, cell.$2)) {
          CarFacing newDir = car.turnType.getExitDirection(finalDirection);
          if (widget.puzzle.hasRoadInDirection(cell.$1, cell.$2, newDir)) {
            finalDirection = newDir;
          }
          break; // Only turn at first intersection
        }
      }
    }

    // Add final exit point off the edge
    final lastOffset = pathOffsets.last;
    double exitX = lastOffset.dx;
    double exitY = lastOffset.dy;
    switch (finalDirection) {
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

    // Calculate animation duration based on path length
    final duration = Duration(milliseconds: 150 * pathOffsets.length);

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _exitControllers[car.id] = controller;
    _exitPaths[car.id] = pathOffsets;
    car.isExiting = true;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCarExited(car);
        _exitControllers.remove(car.id)?.dispose();
        _exitPaths.remove(car.id);
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

  void _startShakeAnimation(GridCar car) {
    if (_shakeControllers.containsKey(car.id)) {
      _shakeControllers[car.id]?.reset();
      _shakeControllers[car.id]?.forward();
      return;
    }

    final blockingCar = widget.puzzle.getBlockingCar(car);
    if (blockingCar != null) {
      setState(() {
        _highlightedBlockingCarId = blockingCar.id;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _highlightedBlockingCarId = null;
          });
        }
      });
    }

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    _shakeControllers[car.id] = controller;
    _shakeAnimations[car.id] = animation;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeControllers.remove(car.id)?.dispose();
        _shakeAnimations.remove(car.id);
        if (mounted) setState(() {});
      }
    });

    controller.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight) * 0.95;
        final cellSize = size / widget.puzzle.gridSize;

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C3F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
    final shakeAnim = _shakeAnimations[car.id];
    final isHighlighted = _highlightedBlockingCarId == car.id;
    final isHintCar = widget.hintCarId == car.id;

    Widget carWidget = GestureDetector(
      onTap: () => _onCarTap(car),
      child: Container(
        width: carSize,
        height: carSize,
        decoration: BoxDecoration(
          color: car.color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHintCar
                ? Colors.white
                : isHighlighted
                    ? Colors.red
                    : Colors.black.withValues(alpha: 0.3),
            width: isHintCar || isHighlighted ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHintCar
                  ? Colors.white.withValues(alpha: 0.8)
                  : isHighlighted
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.3),
              blurRadius: isHintCar || isHighlighted ? 10 : 3,
              spreadRadius: isHintCar || isHighlighted ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Car body gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            // Turn type icon
            Center(
              child: Transform.rotate(
                angle: car.travelDirection.rotation * pi / 180,
                child: Icon(
                  car.turnType.icon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: carSize * 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shakeAnim != null) {
      carWidget = AnimatedBuilder(
        animation: shakeAnim,
        builder: (context, child) {
          final offset = car.exitDirection.isHorizontal
              ? Offset(shakeAnim.value, 0)
              : Offset(0, shakeAnim.value);
          return Transform.translate(
            offset: offset,
            child: child,
          );
        },
        child: carWidget,
      );
    }

    if (exitPath != null && exitController != null) {
      return AnimatedBuilder(
        animation: exitController,
        builder: (context, child) {
          final offset = _getPathPosition(exitPath, exitController.value);
          return Positioned(
            left: left + offset.dx * cellSize,
            top: top + offset.dy * cellSize,
            child: Opacity(
              opacity: (1 - exitController.value * 0.5).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: carWidget,
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
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    double x = startX + 10;
    while (x < endX - 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset(min(x + 12, endX - 10), y),
        linePaint,
      );
      x += 20;
    }
  }

  void _drawVerticalDashedLine(Canvas canvas, double x, double startY, double endY) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    double y = startY + 10;
    while (y < endY - 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, min(y + 12, endY - 10)),
        linePaint,
      );
      y += 20;
    }
  }

  void _drawExitIndicators(Canvas canvas, Size size, double roadWidth) {
    final exitPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;

    // Find all road segments that touch edges and draw exit indicators
    for (var segment in roadSegments) {
      if (segment.isHorizontal) {
        double y = segment.y1 * cellSize + (cellSize - roadWidth) / 2;
        int minX = min(segment.x1, segment.x2);
        int maxX = max(segment.x1, segment.x2);

        if (minX == 0) {
          // Left edge exit
          canvas.drawRect(
            Rect.fromLTWH(-5, y, 10, roadWidth),
            exitPaint,
          );
        }
        if (maxX == gridSize - 1) {
          // Right edge exit
          canvas.drawRect(
            Rect.fromLTWH(size.width - 5, y, 10, roadWidth),
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
            Rect.fromLTWH(x, -5, roadWidth, 10),
            exitPaint,
          );
        }
        if (maxY == gridSize - 1) {
          // Bottom edge exit
          canvas.drawRect(
            Rect.fromLTWH(x, size.height - 5, roadWidth, 10),
            exitPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
