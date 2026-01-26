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

    // Step 1: Generate block positions first (without directions)
    final blockPositions = <({int x, int y, int z, Color color})>[];
    int attempts = 0;
    while (blockPositions.length < targetBlockCount && attempts < targetBlockCount * 3) {
      attempts++;

      final x = _random.nextInt(gridWidth);
      final z = _random.nextInt(gridDepth);
      final currentHeight = heightMap[x][z];

      // Don't stack too high
      if (currentHeight >= maxHeight) continue;

      blockPositions.add((
        x: x,
        y: currentHeight,
        z: z,
        color: _blockColors[_random.nextInt(_blockColors.length)],
      ));
      heightMap[x][z] = currentHeight + 1;
    }

    // Step 2: Assign directions after all blocks are placed
    for (final pos in blockPositions) {
      final direction = _getEscapableDirection(
        pos.x, pos.z, pos.y,
        gridWidth, gridDepth,
        blockPositions,
      );

      blocks.add(TapBlock(
        x: pos.x,
        y: pos.y,
        z: pos.z,
        direction: direction,
        color: pos.color,
      ));
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

  /// Get a direction where the block can potentially escape
  /// Prefers directions where there's no block in the path at the same Y level
  static ArrowDirection _getEscapableDirection(
    int x, int z, int y,
    int gridWidth, int gridDepth,
    List<({int x, int y, int z, Color color})> allBlocks,
  ) {
    // Shuffle directions to add randomness
    final directions = List<ArrowDirection>.from(ArrowDirection.values)..shuffle(_random);

    // Try to find a direction with clear path
    for (final dir in directions) {
      if (_hasEscapePath(x, z, y, dir, allBlocks)) {
        return dir;
      }
    }

    // If no clear path found, return random (game is still playable with bounces)
    return directions.first;
  }

  /// Check if there's a clear escape path in the given direction
  static bool _hasEscapePath(
    int x, int z, int y,
    ArrowDirection direction,
    List<({int x, int y, int z, Color color})> allBlocks,
  ) {
    // Check if any block at the same Y level blocks the path
    for (final other in allBlocks) {
      if (other.y != y) continue; // Only check same height
      if (other.x == x && other.z == z) continue; // Skip self

      switch (direction) {
        case ArrowDirection.up: // -X direction
          if (other.z == z && other.x < x) return false;
          break;
        case ArrowDirection.down: // +X direction
          if (other.z == z && other.x > x) return false;
          break;
        case ArrowDirection.left: // +Z direction
          if (other.x == x && other.z > z) return false;
          break;
        case ArrowDirection.right: // -Z direction
          if (other.x == x && other.z < z) return false;
          break;
      }
    }

    return true;
  }
}
