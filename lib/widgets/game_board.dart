import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import 'arrow_path_painter.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final level = gameState.level;
        if (level == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            // Extra margin for arrow heads at edges
            const double arrowMargin = 20.0;
            final cellSize = (size - 32 - arrowMargin * 2) / level.gridSize;
            final boardSize = cellSize * level.gridSize;
            final totalSize = boardSize + arrowMargin * 2;

            return Stack(
              children: [
                Center(
                  child: Container(
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onDoubleTap: _resetZoom,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        boundaryMargin: EdgeInsets.zero,
                        constrained: false,
                        onInteractionUpdate: (details) {
                          setState(() {
                            _currentScale = _transformationController.value.getMaxScaleOnAxis();
                          });
                        },
                        child: SizedBox(
                          width: totalSize,
                          height: totalSize,
                          child: Stack(
                        children: [
                          // Paths painter with offset for margin
                          Positioned(
                            left: arrowMargin,
                            top: arrowMargin,
                            child: CustomPaint(
                              size: Size(boardSize, boardSize),
                              painter: ArrowsPainter(
                                paths: level.paths,
                                flyingArrow: gameState.flyingArrow,
                                flyingArrows: gameState.flyingArrows,
                                gridSize: level.gridSize,
                                cellSize: cellSize,
                                hintPathId: gameState.hintPathId,
                              ),
                            ),
                          ),
                          // Tap detection layer with offset
                          Positioned(
                            left: arrowMargin,
                            top: arrowMargin,
                            child: SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: level.gridSize,
                              ),
                              itemCount: level.gridSize * level.gridSize,
                              itemBuilder: (context, index) {
                                final row = index ~/ level.gridSize;
                                final col = index % level.gridSize;

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    // Allow tapping even during animation (for multiple arrows)
                                    gameState.tapCell(row, col);
                                  },
                                  child: const SizedBox.expand(),
                                );
                              },
                            ),
                          ),
                          ),
                        ],
                      ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Zoom indicator and reset button
                if (_currentScale > 1.05)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_currentScale * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          onPressed: _resetZoom,
                          backgroundColor: const Color(0xFF4ECDC4),
                          child: const Icon(Icons.zoom_out_map, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
