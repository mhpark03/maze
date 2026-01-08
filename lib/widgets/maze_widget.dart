import 'package:flutter/material.dart';
import '../models/maze.dart';

class MazeWidget extends StatelessWidget {
  final Maze maze;

  const MazeWidget({super.key, required this.maze});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: maze.cols / maze.rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CustomPaint(
            painter: MazePainter(maze: maze),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class MazePainter extends CustomPainter {
  final Maze maze;

  MazePainter({required this.maze});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / maze.cols;
    final cellHeight = size.height / maze.rows;

    for (int row = 0; row < maze.rows; row++) {
      for (int col = 0; col < maze.cols; col++) {
        final cellType = maze.getCell(row, col);
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );

        final paint = Paint();

        switch (cellType) {
          case CellType.wall:
            paint.color = const Color(0xFF1A1A2E);
            canvas.drawRect(rect, paint);
            break;
          case CellType.path:
            paint.color = const Color(0xFF16213E);
            canvas.drawRect(rect, paint);
            break;
          case CellType.start:
            paint.color = const Color(0xFF16213E);
            canvas.drawRect(rect, paint);
            // Draw start marker
            final startPaint = Paint()..color = const Color(0xFF00D9FF);
            canvas.drawCircle(
              Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2),
              cellWidth * 0.3,
              startPaint,
            );
            break;
          case CellType.end:
            paint.color = const Color(0xFF16213E);
            canvas.drawRect(rect, paint);
            // Draw end marker (star shape)
            final endPaint = Paint()..color = const Color(0xFFFFD700);
            canvas.drawCircle(
              Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2),
              cellWidth * 0.35,
              endPaint,
            );
            break;
          case CellType.player:
            paint.color = const Color(0xFF16213E);
            canvas.drawRect(rect, paint);
            // Draw player
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

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF0F3460).withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= maze.rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }
    for (int i = 0; i <= maze.cols; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter oldDelegate) {
    return true;
  }
}
