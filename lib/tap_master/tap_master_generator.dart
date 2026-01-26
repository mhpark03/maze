import 'dart:math';
import 'dart:ui';
import 'models/tap_master_models.dart';

class TapMasterGenerator {
  static final Random _random = Random();

  /// Block colors - wood-like tones to match the reference image
  static const List<Color> _blockColors = [
    Color(0xFFD4A574), // Light wood
    Color(0xFFC4956A), // Medium wood
    Color(0xFFB8895E), // Darker wood
    Color(0xFFDEB887), // Burlywood
    Color(0xFFE8C99B), // Pale wood
  ];

  /// Generate a puzzle for the given difficulty
  static Future<TapMasterPuzzle> generate(TapMasterDifficulty difficulty) async {
    // Allow UI to update
    await Future.delayed(const Duration(milliseconds: 10));

    final gridWidth = difficulty.gridWidth;
    final gridDepth = difficulty.gridDepth;
    final maxHeight = difficulty.maxHeight;
    final (minBlocks, maxBlocks) = difficulty.blockCountRange;

    final targetBlockCount = minBlocks + _random.nextInt(maxBlocks - minBlocks + 1);

    final blocks = <TapBlock>[];

    // Track height at each (x, z) position
    final heightMap = List.generate(
      gridWidth,
      (_) => List.filled(gridDepth, 0),
    );

    // Generate blocks column by column, building up from bottom
    int attempts = 0;
    while (blocks.length < targetBlockCount && attempts < targetBlockCount * 3) {
      attempts++;

      final x = _random.nextInt(gridWidth);
      final z = _random.nextInt(gridDepth);
      final currentHeight = heightMap[x][z];

      // Don't stack too high
      if (currentHeight >= maxHeight) continue;

      // Create block at this position
      final block = TapBlock(
        x: x,
        y: currentHeight,
        z: z,
        direction: _randomDirection(),
        color: _blockColors[_random.nextInt(_blockColors.length)],
      );

      blocks.add(block);
      heightMap[x][z] = currentHeight + 1;
    }

    // Sort blocks for proper rendering order (back to front, bottom to top)
    blocks.sort((a, b) {
      // First by z (depth), back to front
      if (a.z != b.z) return a.z.compareTo(b.z);
      // Then by y (height), bottom to top
      if (a.y != b.y) return a.y.compareTo(b.y);
      // Then by x, left to right
      return a.x.compareTo(b.x);
    });

    return TapMasterPuzzle(
      blocks: blocks,
      gridWidth: gridWidth,
      gridDepth: gridDepth,
      maxHeight: maxHeight,
    );
  }

  static ArrowDirection _randomDirection() {
    final directions = ArrowDirection.values;
    return directions[_random.nextInt(directions.length)];
  }
}
