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

  /// Get a direction that ensures the puzzle is solvable
  /// Blocks in the same row/column at the same height should point towards the edge
  static ArrowDirection _getEscapableDirection(
    int x, int z, int y,
    int gridWidth, int gridDepth,
    List<({int x, int y, int z, Color color})> allBlocks,
  ) {
    // Find blocks in the same row (same Y, same Z) or column (same Y, same X)
    final sameRowBlocks = allBlocks.where((b) => b.y == y && b.z == z && b.x != x).toList();
    final sameColBlocks = allBlocks.where((b) => b.y == y && b.x == x && b.z != z).toList();

    // Prefer direction towards the nearest edge to avoid deadlocks
    final possibleDirections = <ArrowDirection>[];

    // Check X-axis directions (up = -X, down = +X)
    if (sameRowBlocks.isEmpty) {
      // No blocks in same row, can go either X direction
      possibleDirections.add(x <= gridWidth ~/ 2 ? ArrowDirection.up : ArrowDirection.down);
    } else {
      // There are blocks in the same row - point towards the nearest edge
      final minX = sameRowBlocks.map((b) => b.x).reduce(min);
      final maxX = sameRowBlocks.map((b) => b.x).reduce(max);

      if (x <= minX) {
        // This block is at or before the leftmost - point left (up = -X)
        possibleDirections.add(ArrowDirection.up);
      } else if (x >= maxX) {
        // This block is at or after the rightmost - point right (down = +X)
        possibleDirections.add(ArrowDirection.down);
      }
      // If in the middle, we'll use Z direction instead
    }

    // Check Z-axis directions (left = +Z, right = -Z)
    if (sameColBlocks.isEmpty) {
      // No blocks in same column, can go either Z direction
      possibleDirections.add(z <= gridDepth ~/ 2 ? ArrowDirection.right : ArrowDirection.left);
    } else {
      // There are blocks in the same column - point towards the nearest edge
      final minZ = sameColBlocks.map((b) => b.z).reduce(min);
      final maxZ = sameColBlocks.map((b) => b.z).reduce(max);

      if (z <= minZ) {
        // This block is at or before the front - point back (right = -Z)
        possibleDirections.add(ArrowDirection.right);
      } else if (z >= maxZ) {
        // This block is at or after the back - point front (left = +Z)
        possibleDirections.add(ArrowDirection.left);
      }
      // If in the middle, we'll use X direction instead
    }

    // If we have possible directions, pick one randomly
    if (possibleDirections.isNotEmpty) {
      return possibleDirections[_random.nextInt(possibleDirections.length)];
    }

    // Fallback: point towards nearest edge
    final distToLeft = x;
    final distToRight = gridWidth - 1 - x;
    final distToFront = z;
    final distToBack = gridDepth - 1 - z;

    final minDist = [distToLeft, distToRight, distToFront, distToBack].reduce(min);

    if (minDist == distToLeft) return ArrowDirection.up;
    if (minDist == distToRight) return ArrowDirection.down;
    if (minDist == distToFront) return ArrowDirection.right;
    return ArrowDirection.left;
  }
}
