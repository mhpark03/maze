import 'package:flutter/material.dart';
import '../models/maze.dart';

class MazeWidget extends StatefulWidget {
  final Maze maze;
  final void Function(Position direction)? onMove;
  final List<Position>? hintPath;

  const MazeWidget({
    super.key,
    required this.maze,
    this.onMove,
    this.hintPath,
  });

  @override
  State<MazeWidget> createState() => _MazeWidgetState();
}

class _MazeWidgetState extends State<MazeWidget> {
  Offset? _dragStart;
  bool _isDraggingPlayer = false;
  Size? _widgetSize;
  static const double _dragThreshold = 15.0;

  bool _isOnPlayer(Offset position) {
    if (_widgetSize == null) return false;

    final cellWidth = _widgetSize!.width / widget.maze.cols;
    final cellHeight = _widgetSize!.height / widget.maze.rows;

    final col = (position.dx / cellWidth).floor();
    final row = (position.dy / cellHeight).floor();

    final playerPos = widget.maze.playerPos;
    return row == playerPos.row && col == playerPos.col;
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isOnPlayer(details.localPosition)) {
      _isDraggingPlayer = true;
      _dragStart = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDraggingPlayer || _dragStart == null || widget.onMove == null) return;

    final delta = details.localPosition - _dragStart!;

    if (delta.distance < _dragThreshold) return;

    Position? direction;
    if (delta.dx.abs() > delta.dy.abs()) {
      direction = delta.dx > 0
          ? const Position(0, 1)
          : const Position(0, -1);
    } else {
      direction = delta.dy > 0
          ? const Position(1, 0)
          : const Position(-1, 0);
    }

    widget.onMove!(direction);
    _dragStart = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    _dragStart = null;
    _isDraggingPlayer = false;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.maze.cols / widget.maze.rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6B5B95), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  painter: MazePainter(
                    maze: widget.maze,
                    hintPath: widget.hintPath,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MazePainter extends CustomPainter {
  final Maze maze;
  final List<Position>? hintPath;

  MazePainter({required this.maze, this.hintPath});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / maze.cols;
    final cellHeight = size.height / maze.rows;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (int row = 0; row < maze.rows; row++) {
      for (int col = 0; col < maze.cols; col++) {
        final cellType = maze.getCell(row, col);
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );
        final pos = Position(row, col);
        final isVisited = maze.visitedPath.contains(pos);

        final paint = Paint();

        switch (cellType) {
          case CellType.wall:
            paint.color = const Color(0xFF6B5B95);
            canvas.drawRect(rect, paint);
            break;
          case CellType.path:
            if (isVisited) {
              paint.color = const Color(0xFFE8D5F2);
              canvas.drawRect(rect, paint);
            }
            break;
          case CellType.start:
            if (isVisited) {
              paint.color = const Color(0xFFE8D5F2);
              canvas.drawRect(rect, paint);
            }
            final startPaint = Paint()..color = const Color(0xFF6B5B95);
            canvas.drawCircle(
              Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2),
              cellWidth * 0.35,
              startPaint,
            );
            break;
          case CellType.end:
            final endPaint = Paint()..color = const Color(0xFFFFD700);
            canvas.drawCircle(
              Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2),
              cellWidth * 0.4,
              endPaint,
            );
            break;
          case CellType.player:
            final playerPaint = Paint()..color = const Color(0xFFE94560);
            canvas.drawCircle(
              Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2),
              cellWidth * 0.35,
              playerPaint,
            );
            break;
        }
      }
    }

    if (hintPath != null && hintPath!.length > 1) {
      final hintPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)
        ..strokeWidth = cellWidth * 0.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final firstPos = hintPath!.first;
      path.moveTo(
        firstPos.col * cellWidth + cellWidth / 2,
        firstPos.row * cellHeight + cellHeight / 2,
      );

      for (int i = 1; i < hintPath!.length; i++) {
        final pos = hintPath![i];
        path.lineTo(
          pos.col * cellWidth + cellWidth / 2,
          pos.row * cellHeight + cellHeight / 2,
        );
      }

      canvas.drawPath(path, hintPaint);

      final lastPos = hintPath!.last;
      final arrowPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          lastPos.col * cellWidth + cellWidth / 2,
          lastPos.row * cellHeight + cellHeight / 2,
        ),
        cellWidth * 0.2,
        arrowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter oldDelegate) {
    return true;
  }
}
