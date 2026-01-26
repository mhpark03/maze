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

    // Build puzzle using reverse simulation for interesting dependencies
    final blocks = _buildPuzzleWithDependencies(
      targetBlockCount,
      gridWidth,
      gridDepth,
      maxHeight,
    );

    // Sort blocks for proper rendering order (back to front, bottom to top)
    blocks.sort((a, b) {
      if (a.z != b.z) return a.z.compareTo(b.z);
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    return TapMasterPuzzle(
      blocks: blocks,
      gridWidth: gridWidth,
      gridDepth: gridDepth,
      maxHeight: maxHeight,
    );
  }

  /// Build puzzle by placing blocks with directions that create dependencies
  static List<TapBlock> _buildPuzzleWithDependencies(
    int targetCount,
    int gridWidth,
    int gridDepth,
    int maxHeight,
  ) {
    final blocks = <TapBlock>[];
    final grid = <String, TapBlock>{};
    final heightMap = List.generate(gridWidth, (_) => List.filled(gridDepth, 0));

    // Track direction usage for variety
    final directionCounts = <ArrowDirection, int>{};
    for (final dir in ArrowDirection.values) {
      directionCounts[dir] = 0;
    }

    int attempts = 0;
    while (blocks.length < targetCount && attempts < targetCount * 10) {
      attempts++;

      // Pick position - prefer stacking for taller structures
      int x, z;
      if (_random.nextDouble() < 0.7 && blocks.isNotEmpty) {
        // Stack on existing column
        final stackable = <({int x, int z})>[];
        for (int i = 0; i < gridWidth; i++) {
          for (int j = 0; j < gridDepth; j++) {
            if (heightMap[i][j] > 0 && heightMap[i][j] < maxHeight) {
              stackable.add((x: i, z: j));
            }
          }
        }
        if (stackable.isNotEmpty) {
          final pos = stackable[_random.nextInt(stackable.length)];
          x = pos.x;
          z = pos.z;
        } else {
          x = _random.nextInt(gridWidth);
          z = _random.nextInt(gridDepth);
        }
      } else {
        x = _random.nextInt(gridWidth);
        z = _random.nextInt(gridDepth);
      }

      final y = heightMap[x][z];
      if (y >= maxHeight) continue;

      // Find directions that create interesting gameplay
      final direction = _selectInterestingDirection(
        x, y, z,
        grid,
        directionCounts,
        gridWidth, gridDepth, maxHeight,
      );

      if (direction == null) continue;

      final block = TapBlock(
        x: x,
        y: y,
        z: z,
        direction: direction,
        color: _blockColors[_random.nextInt(_blockColors.length)],
      );

      blocks.add(block);
      grid['$x,$y,$z'] = block;
      heightMap[x][z] = y + 1;
      directionCounts[direction] = directionCounts[direction]! + 1;
    }

    return blocks;
  }

  /// Select a direction that creates interesting gameplay
  static ArrowDirection? _selectInterestingDirection(
    int x, int y, int z,
    Map<String, TapBlock> grid,
    Map<ArrowDirection, int> directionCounts,
    int gridWidth, int gridDepth, int maxHeight,
  ) {
    final candidates = <ArrowDirection, double>{};

    for (final dir in ArrowDirection.values) {
      // Check if this direction has any blocking blocks
      final blockingCount = _countBlockingBlocks(x, y, z, dir, grid, gridWidth, gridDepth, maxHeight);

      // Calculate score - prefer directions with blocking blocks (creates dependencies)
      // but also consider variety
      double score = 0;

      if (blockingCount > 0) {
        // Has blocking blocks - this creates a dependency (good for difficulty)
        score += 10.0 + blockingCount * 2;
      } else {
        // Clear path to edge - always valid but less interesting
        score += 5.0;
      }

      // Bonus for less-used directions (variety)
      final usage = directionCounts[dir] ?? 0;
      final totalBlocks = grid.length;
      if (totalBlocks > 0) {
        final avgUsage = totalBlocks / 6.0;
        if (usage < avgUsage) {
          score += (avgUsage - usage) * 3;
        }
      } else {
        score += 3.0; // First block gets bonus for any direction
      }

      // Small random factor
      score += _random.nextDouble() * 2;

      candidates[dir] = score;
    }

    if (candidates.isEmpty) return null;

    // Weighted random selection based on scores
    final totalScore = candidates.values.reduce((a, b) => a + b);
    var threshold = _random.nextDouble() * totalScore;

    for (final entry in candidates.entries) {
      threshold -= entry.value;
      if (threshold <= 0) {
        return entry.key;
      }
    }

    return candidates.keys.first;
  }

  /// Count how many blocks are in the path of the given direction
  static int _countBlockingBlocks(
    int x, int y, int z,
    ArrowDirection dir,
    Map<String, TapBlock> grid,
    int gridWidth, int gridDepth, int maxHeight,
  ) {
    int count = 0;

    switch (dir) {
      case ArrowDirection.north: // -X
        for (int i = x - 1; i >= 0; i--) {
          if (grid.containsKey('$i,$y,$z')) count++;
        }
        break;
      case ArrowDirection.south: // +X
        for (int i = x + 1; i < gridWidth; i++) {
          if (grid.containsKey('$i,$y,$z')) count++;
        }
        break;
      case ArrowDirection.east: // -Z
        for (int i = z - 1; i >= 0; i--) {
          if (grid.containsKey('$x,$y,$i')) count++;
        }
        break;
      case ArrowDirection.west: // +Z
        for (int i = z + 1; i < gridDepth; i++) {
          if (grid.containsKey('$x,$y,$i')) count++;
        }
        break;
      case ArrowDirection.skyward: // +Y
        for (int i = y + 1; i < maxHeight; i++) {
          if (grid.containsKey('$x,$i,$z')) count++;
        }
        break;
      case ArrowDirection.groundward: // -Y
        for (int i = y - 1; i >= 0; i--) {
          if (grid.containsKey('$x,$i,$z')) count++;
        }
        break;
    }

    return count;
  }
}
