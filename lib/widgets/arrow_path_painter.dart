import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class ArrowsPainter extends CustomPainter {
  final List<ArrowPath> paths;
  final FlyingArrow? flyingArrow; // For backwards compatibility
  final List<FlyingArrow> flyingArrows; // Multiple flying arrows
  final int gridSize;
  final double cellSize;
  final int? hintPathId; // ID of the path to highlight as hint

  ArrowsPainter({
    required this.paths,
    this.flyingArrow,
    this.flyingArrows = const [],
    required this.gridSize,
    required this.cellSize,
    this.hintPathId,
  });

  // Calculate stroke width based on grid size (thinner for larger grids)
  double get strokeWidth {
    if (gridSize <= 10) return 5.0;
    if (gridSize <= 30) return 3.0;
    return 2.0;
  }

  // Calculate path radius (how far path extends from center)
  double get pathRadius => cellSize * 0.42;

  // Calculate arrow head size based on grid size
  double get arrowHeadSize {
    if (gridSize <= 10) return cellSize * 0.2;
    if (gridSize <= 30) return cellSize * 0.25;
    return cellSize * 0.3;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // Draw static paths
    for (var path in paths) {
      if (!path.isRemoved) {
        bool isHint = hintPathId != null && path.id == hintPathId;
        _drawStaticPath(canvas, path.cells, path.color, isHint: isHint);
      }
    }

    // Draw all flying paths
    for (var arrow in flyingArrows) {
      if (arrow.pathCells.isNotEmpty) {
        _drawFlyingPath(
          canvas,
          arrow.pathCells,
          arrow.color,
          arrow.direction,
          arrow.x,
          arrow.collided,
        );
      }
    }

    // Backwards compatibility: draw single flyingArrow if no flyingArrows
    if (flyingArrows.isEmpty && flyingArrow != null && flyingArrow!.pathCells.isNotEmpty) {
      _drawFlyingPath(
        canvas,
        flyingArrow!.pathCells,
        flyingArrow!.color,
        flyingArrow!.direction,
        flyingArrow!.x,
        flyingArrow!.collided,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, gridSize * cellSize),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(gridSize * cellSize, i * cellSize),
        paint,
      );
    }
  }

  void _drawStaticPath(Canvas canvas, List<PathCell> cells, Color color, {bool isHint = false}) {
    if (cells.isEmpty) return;

    // Hint highlight effect - strong pulsing glow
    if (isHint) {
      // Outer glow (large, faint)
      final outerGlowPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.4)
        ..strokeWidth = strokeWidth + 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      // Inner glow (bright)
      final innerGlowPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.9)
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final hintPath = _buildPathFromCells(cells, Offset.zero);
      canvas.drawPath(hintPath, outerGlowPaint);
      canvas.drawPath(hintPath, innerGlowPaint);
    }

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final pathPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = _buildPathFromCells(cells, Offset.zero);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, pathPaint);

    // Draw arrow head
    _drawArrowHead(canvas, cells.last, color, 1.0, Offset.zero);
  }

  void _drawFlyingPath(
    Canvas canvas,
    List<PathCell> cells,
    Color color,
    Direction direction,
    double headProgress,
    bool collided,
  ) {
    if (cells.isEmpty) return;

    final displayColor = collided ? Colors.red : color;
    final currentStrokeWidth = collided ? strokeWidth * 1.2 : strokeWidth;

    double pathLength = cells.length.toDouble();

    // Snake-like animation: head extends first, tail follows to maintain length
    // Tail only starts moving after head has extended by 1 cell (gives sliding effect)
    double tailDelay = 1.0; // Delay before tail starts shrinking
    double visibleStart = math.max(0, headProgress - tailDelay);
    visibleStart = math.min(visibleStart, pathLength);
    double headExtension = headProgress;

    final glowPaint = Paint()
      ..color = displayColor.withValues(alpha: 0.3)
      ..strokeWidth = currentStrokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final pathPaint = Paint()
      ..color = displayColor
      ..strokeWidth = currentStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = _buildAnimatedPath(cells, visibleStart, headExtension, direction);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, pathPaint);

    // Draw arrow head at the extended position
    if (headExtension > 0) {
      _drawExtendedArrowHead(canvas, cells.last, displayColor, direction, headExtension);
    } else {
      _drawArrowHead(canvas, cells.last, displayColor, 1.0, Offset.zero);
    }

    // Draw trail effect behind the head
    if (!collided && headExtension > 0) {
      _drawTrailEffect(canvas, cells.last, color, direction, headExtension);
    }
  }

  Path _buildPathFromCells(List<PathCell> cells, Offset offset) {
    final path = Path();
    if (cells.isEmpty) return path;

    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final centerX = cell.col * cellSize + cellSize / 2 + offset.dx;
      final centerY = cell.row * cellSize + cellSize / 2 + offset.dy;

      if (i == 0) {
        Offset startPoint = _getEdgePoint(cell, cell.entryDirection);
        startPoint = Offset(startPoint.dx + offset.dx, startPoint.dy + offset.dy);
        path.moveTo(startPoint.dx, startPoint.dy);

        if (cell.isStraight) {
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          endPoint = Offset(endPoint.dx + offset.dx, endPoint.dy + offset.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        } else {
          path.lineTo(centerX, centerY);
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          endPoint = Offset(endPoint.dx + offset.dx, endPoint.dy + offset.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
      } else {
        if (cell.isStraight) {
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          endPoint = Offset(endPoint.dx + offset.dx, endPoint.dy + offset.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        } else {
          path.lineTo(centerX, centerY);
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          endPoint = Offset(endPoint.dx + offset.dx, endPoint.dy + offset.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
      }
    }

    return path;
  }

  Path _buildAnimatedPath(List<PathCell> cells, double visibleStart, double headExtension, Direction direction) {
    final path = Path();
    if (cells.isEmpty) return path;

    double pathLength = cells.length.toDouble();

    // When the entire original path has been consumed, draw straight line flying
    if (visibleStart >= pathLength) {
      PathCell lastCell = cells.last;
      Offset exitPoint = _getEdgePoint(lastCell, lastCell.exitDirection);

      // Head position
      double headX = exitPoint.dx + direction.delta.dx * headExtension * cellSize;
      double headY = exitPoint.dy + direction.delta.dy * headExtension * cellSize;

      // Tail position: maintain length equal to (pathLength + tailDelay)
      // Since visibleStart has tailDelay=1, the flying straight part should be pathLength+1 long
      double flyingLength = pathLength + 1.0;
      double tailOffset = headExtension - flyingLength;
      if (tailOffset < 0) tailOffset = 0;
      double tailX = exitPoint.dx + direction.delta.dx * tailOffset * cellSize;
      double tailY = exitPoint.dy + direction.delta.dy * tailOffset * cellSize;

      path.moveTo(tailX, tailY);
      path.lineTo(headX, headY);
      return path;
    }

    int startCellIndex = visibleStart.floor();
    double startCellProgress = visibleStart - startCellIndex;

    bool pathStarted = false;

    for (int i = startCellIndex; i < cells.length; i++) {
      final cell = cells[i];
      final centerX = cell.col * cellSize + cellSize / 2;
      final centerY = cell.row * cellSize + cellSize / 2;

      if (i == startCellIndex && startCellProgress > 0) {
        Offset startPoint;
        if (cell.isStraight) {
          Offset entry = _getEdgePoint(cell, cell.entryDirection);
          Offset exit = _getEdgePoint(cell, cell.exitDirection);
          startPoint = Offset(
            entry.dx + (exit.dx - entry.dx) * startCellProgress,
            entry.dy + (exit.dy - entry.dy) * startCellProgress,
          );
        } else {
          Offset entry = _getEdgePoint(cell, cell.entryDirection);
          if (startCellProgress < 0.5) {
            double t = startCellProgress * 2;
            startPoint = Offset(
              entry.dx + (centerX - entry.dx) * t,
              entry.dy + (centerY - entry.dy) * t,
            );
          } else {
            Offset exit = _getEdgePoint(cell, cell.exitDirection);
            double t = (startCellProgress - 0.5) * 2;
            startPoint = Offset(
              centerX + (exit.dx - centerX) * t,
              centerY + (exit.dy - centerY) * t,
            );
          }
        }
        path.moveTo(startPoint.dx, startPoint.dy);
        pathStarted = true;

        if (cell.isStraight) {
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          path.lineTo(endPoint.dx, endPoint.dy);
        } else {
          if (startCellProgress < 0.5) {
            path.lineTo(centerX, centerY);
          }
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
      } else {
        if (!pathStarted) {
          Offset startPoint = _getEdgePoint(cell, cell.entryDirection);
          path.moveTo(startPoint.dx, startPoint.dy);
          pathStarted = true;
        }

        if (cell.isStraight) {
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          path.lineTo(endPoint.dx, endPoint.dy);
        } else {
          path.lineTo(centerX, centerY);
          Offset endPoint = _getEdgePoint(cell, cell.exitDirection);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
      }
    }

    if (headExtension > 0 && cells.isNotEmpty) {
      PathCell lastCell = cells.last;
      Offset exitPoint = _getEdgePoint(lastCell, lastCell.exitDirection);
      double headX = exitPoint.dx + direction.delta.dx * headExtension * cellSize;
      double headY = exitPoint.dy + direction.delta.dy * headExtension * cellSize;
      path.lineTo(headX, headY);
    }

    return path;
  }

  Offset _getEdgePoint(PathCell cell, Direction direction) {
    final centerX = cell.col * cellSize + cellSize / 2;
    final centerY = cell.row * cellSize + cellSize / 2;

    switch (direction) {
      case Direction.up:
        return Offset(centerX, centerY - pathRadius);
      case Direction.down:
        return Offset(centerX, centerY + pathRadius);
      case Direction.left:
        return Offset(centerX - pathRadius, centerY);
      case Direction.right:
        return Offset(centerX + pathRadius, centerY);
    }
  }

  void _drawArrowHead(Canvas canvas, PathCell cell, Color color, double scale, Offset offset) {
    final centerX = cell.col * cellSize + cellSize / 2 + offset.dx;
    final centerY = cell.row * cellSize + cellSize / 2 + offset.dy;

    Offset headPos;
    switch (cell.exitDirection) {
      case Direction.up:
        headPos = Offset(centerX, centerY - pathRadius);
        break;
      case Direction.down:
        headPos = Offset(centerX, centerY + pathRadius);
        break;
      case Direction.left:
        headPos = Offset(centerX - pathRadius, centerY);
        break;
      case Direction.right:
        headPos = Offset(centerX + pathRadius, centerY);
        break;
    }

    _drawArrowHeadAt(canvas, headPos, cell.exitDirection, color, scale);
  }

  void _drawExtendedArrowHead(Canvas canvas, PathCell cell, Color color, Direction direction, double headExtension) {
    Offset exitPoint = _getEdgePoint(cell, cell.exitDirection);

    double headX = exitPoint.dx + direction.delta.dx * headExtension * cellSize;
    double headY = exitPoint.dy + direction.delta.dy * headExtension * cellSize;

    _drawArrowHeadAt(canvas, Offset(headX, headY), direction, color, 1.0);
  }

  void _drawArrowHeadAt(Canvas canvas, Offset position, Direction direction, Color color, double scale) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(direction.angle);

    final headSize = arrowHeadSize * scale;
    final headStrokeWidth = strokeWidth * scale;

    final headPaint = Paint()
      ..color = color
      ..strokeWidth = headStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final headPath = Path();
    headPath.moveTo(-headSize, -headSize * 0.8);
    headPath.lineTo(headSize * 0.3, 0);
    headPath.lineTo(-headSize, headSize * 0.8);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = headStrokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(headPath, glowPaint);
    canvas.drawPath(headPath, headPaint);

    canvas.restore();
  }

  void _drawTrailEffect(Canvas canvas, PathCell cell, Color color, Direction direction, double headExtension) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    Offset exitPoint = _getEdgePoint(cell, cell.exitDirection);

    double headX = exitPoint.dx + direction.delta.dx * headExtension * cellSize;
    double headY = exitPoint.dy + direction.delta.dy * headExtension * cellSize;

    for (int i = 1; i <= 4; i++) {
      double trailX = headX - direction.delta.dx * i * cellSize * 0.08;
      double trailY = headY - direction.delta.dy * i * cellSize * 0.08;

      double alpha = 0.3 - (i * 0.06);
      if (alpha <= 0) continue;

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(trailX, trailY), 3.0 - i * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowsPainter oldDelegate) {
    return oldDelegate.paths != paths ||
        oldDelegate.flyingArrow != flyingArrow ||
        oldDelegate.flyingArrows != flyingArrows ||
        oldDelegate.flyingArrows.length != flyingArrows.length ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.hintPathId != hintPathId;
  }
}
