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

  /// Generate a solvable puzzle for the given difficulty
  /// Uses center-outward construction for varied solve order
  static Future<TapMasterPuzzle> generate(TapMasterDifficulty difficulty) async {
    // Allow UI to update
    await Future.delayed(const Duration(milliseconds: 10));

    final gridWidth = difficulty.gridWidth;
    final gridDepth = difficulty.gridDepth;
    final maxHeight = difficulty.maxHeight;
    final (minBlocks, maxBlocks) = difficulty.blockCountRange;

    final targetBlockCount = minBlocks + _random.nextInt(maxBlocks - minBlocks + 1);

    // Build solvable puzzle from center outward
    final blocks = _buildPuzzleFromCenter(
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

  /// Build puzzle starting from center columns, expanding outward
  /// Central columns are built tall first, creating varied solve order
  static List<TapBlock> _buildPuzzleFromCenter(
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

    // Calculate center of grid
    final centerX = (gridWidth - 1) / 2.0;
    final centerZ = (gridDepth - 1) / 2.0;
    final centerY = (maxHeight - 1) / 2.0;

    // Generate all columns (x,z) and sort by horizontal distance from center
    final columns = <_Column>[];
    for (int x = 0; x < gridWidth; x++) {
      for (int z = 0; z < gridDepth; z++) {
        final distX = (x - centerX);
        final distZ = (z - centerZ);
        final distance = sqrt(distX * distX + distZ * distZ);
        columns.add(_Column(x: x, z: z, distance: distance));
      }
    }

    // Sort columns by distance from center (closest first) with randomness
    columns.shuffle(_random);
    columns.sort((a, b) {
      final aScore = a.distance + _random.nextDouble() * 0.8;
      final bScore = b.distance + _random.nextDouble() * 0.8;
      return aScore.compareTo(bScore);
    });

    // Determine target height for each column based on distance from center
    // Central columns should be taller
    final columnTargets = <String, int>{};
    for (final col in columns) {
      // Normalize distance (0 = center, 1 = corner)
      final maxDist = sqrt(centerX * centerX + centerZ * centerZ);
      final normalizedDist = maxDist > 0 ? col.distance / maxDist : 0;

      // Central columns get higher targets (70-100% of maxHeight)
      // Outer columns get lower targets (30-70% of maxHeight)
      final minRatio = 0.3 + (1.0 - normalizedDist) * 0.4; // 0.3~0.7 for outer, 0.7~0.7 for center
      final maxRatio = 0.7 + (1.0 - normalizedDist) * 0.3; // 0.7~1.0 for outer, 1.0~1.0 for center
      final ratio = minRatio + _random.nextDouble() * (maxRatio - minRatio);
      final targetHeight = max(1, (maxHeight * ratio).round());
      columnTargets['${col.x},${col.z}'] = targetHeight;
    }

    // Build columns from center outward
    // Each column is built from bottom to top
    for (final col in columns) {
      if (blocks.length >= targetCount) break;

      final targetHeight = columnTargets['${col.x},${col.z}'] ?? maxHeight;

      // Build this column from current height up to target
      for (int y = heightMap[col.x][col.z]; y < targetHeight && blocks.length < targetCount; y++) {
        // Find directions with CLEAR escape path (guaranteed solvable)
        final clearDirections = _getClearDirections(
          col.x, y, col.z, grid, gridWidth, gridDepth, maxHeight,
        );

        // Must have at least one clear direction to place this block
        if (clearDirections.isEmpty) break; // Can't continue this column

        // Select direction with variety preference
        final direction = _selectDirectionWithVariety(
          clearDirections,
          directionCounts,
          col.x, y, col.z,
          centerX, centerY, centerZ,
        );

        final block = TapBlock(
          x: col.x,
          y: y,
          z: col.z,
          direction: direction,
          color: _blockColors[_random.nextInt(_blockColors.length)],
        );

        blocks.add(block);
        grid['${col.x},$y,${col.z}'] = block;
        heightMap[col.x][col.z] = y + 1;
        directionCounts[direction] = directionCounts[direction]! + 1;
      }
    }

    // Second pass: fill remaining blocks if we haven't reached target
    // Try to add more blocks to columns that can accept them
    if (blocks.length < targetCount) {
      for (final col in columns) {
        if (blocks.length >= targetCount) break;

        // Try to extend this column further
        for (int y = heightMap[col.x][col.z]; y < maxHeight && blocks.length < targetCount; y++) {
          final clearDirections = _getClearDirections(
            col.x, y, col.z, grid, gridWidth, gridDepth, maxHeight,
          );

          if (clearDirections.isEmpty) break;

          final direction = _selectDirectionWithVariety(
            clearDirections,
            directionCounts,
            col.x, y, col.z,
            centerX, centerY, centerZ,
          );

          final block = TapBlock(
            x: col.x,
            y: y,
            z: col.z,
            direction: direction,
            color: _blockColors[_random.nextInt(_blockColors.length)],
          );

          blocks.add(block);
          grid['${col.x},$y,${col.z}'] = block;
          heightMap[col.x][col.z] = y + 1;
          directionCounts[direction] = directionCounts[direction]! + 1;
        }
      }
    }

    return blocks;
  }

  /// Get all directions that have a clear path to the edge (no blocking blocks)
  static List<ArrowDirection> _getClearDirections(
    int x, int y, int z,
    Map<String, TapBlock> grid,
    int gridWidth, int gridDepth, int maxHeight,
  ) {
    final clearDirs = <ArrowDirection>[];

    if (_isPathClear(x, y, z, ArrowDirection.north, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.north);
    }
    if (_isPathClear(x, y, z, ArrowDirection.south, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.south);
    }
    if (_isPathClear(x, y, z, ArrowDirection.east, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.east);
    }
    if (_isPathClear(x, y, z, ArrowDirection.west, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.west);
    }
    if (_isPathClear(x, y, z, ArrowDirection.skyward, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.skyward);
    }
    if (_isPathClear(x, y, z, ArrowDirection.groundward, grid, gridWidth, gridDepth, maxHeight)) {
      clearDirs.add(ArrowDirection.groundward);
    }

    return clearDirs;
  }

  /// Check if the path is completely clear for a given direction
  static bool _isPathClear(
    int x, int y, int z,
    ArrowDirection dir,
    Map<String, TapBlock> grid,
    int gridWidth, int gridDepth, int maxHeight,
  ) {
    switch (dir) {
      case ArrowDirection.north: // -X
        for (int i = x - 1; i >= 0; i--) {
          if (grid.containsKey('$i,$y,$z')) return false;
        }
        return true;

      case ArrowDirection.south: // +X
        for (int i = x + 1; i < gridWidth; i++) {
          if (grid.containsKey('$i,$y,$z')) return false;
        }
        return true;

      case ArrowDirection.east: // -Z
        for (int i = z - 1; i >= 0; i--) {
          if (grid.containsKey('$x,$y,$i')) return false;
        }
        return true;

      case ArrowDirection.west: // +Z
        for (int i = z + 1; i < gridDepth; i++) {
          if (grid.containsKey('$x,$y,$i')) return false;
        }
        return true;

      case ArrowDirection.skyward: // +Y
        for (int i = y + 1; i < maxHeight; i++) {
          if (grid.containsKey('$x,$i,$z')) return false;
        }
        return true;

      case ArrowDirection.groundward: // -Y
        for (int i = y - 1; i >= 0; i--) {
          if (grid.containsKey('$x,$i,$z')) return false;
        }
        return true;
    }
  }

  /// Select direction with variety and position-based preference
  static ArrowDirection _selectDirectionWithVariety(
    List<ArrowDirection> clearDirections,
    Map<ArrowDirection, int> directionCounts,
    int x, int y, int z,
    double centerX, double centerY, double centerZ,
  ) {
    if (clearDirections.length == 1) {
      return clearDirections.first;
    }

    // Calculate weights based on variety and position
    final weights = <ArrowDirection, double>{};
    final totalUsage = directionCounts.values.fold(0, (a, b) => a + b);
    final avgUsage = totalUsage > 0 ? totalUsage / 6.0 : 1.0;

    for (final dir in clearDirections) {
      final usage = directionCounts[dir] ?? 0;

      // Base weight for variety (prefer less-used directions)
      double weight = 1.0 + max(0.0, avgUsage - usage) * 2;

      // Position-based bonus: prefer directions pointing away from center
      final awayBonus = _getAwayFromCenterBonus(dir, x, y, z, centerX, centerY, centerZ);
      weight += awayBonus * 0.5;

      // Random factor for unpredictability
      weight += _random.nextDouble() * 1.0;

      weights[dir] = weight;
    }

    // Weighted random selection
    final totalWeight = weights.values.reduce((a, b) => a + b);
    var threshold = _random.nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      threshold -= entry.value;
      if (threshold <= 0) {
        return entry.key;
      }
    }

    return clearDirections[_random.nextInt(clearDirections.length)];
  }

  /// Calculate bonus for directions pointing away from center
  static double _getAwayFromCenterBonus(
    ArrowDirection dir,
    int x, int y, int z,
    double centerX, double centerY, double centerZ,
  ) {
    switch (dir) {
      case ArrowDirection.north: // -X
        return x < centerX ? 1.0 : 0.0;
      case ArrowDirection.south: // +X
        return x > centerX ? 1.0 : 0.0;
      case ArrowDirection.east: // -Z
        return z < centerZ ? 1.0 : 0.0;
      case ArrowDirection.west: // +Z
        return z > centerZ ? 1.0 : 0.0;
      case ArrowDirection.skyward: // +Y
        return y > centerY ? 1.0 : 0.0;
      case ArrowDirection.groundward: // -Y
        return y < centerY ? 1.0 : 0.0;
    }
  }
}

class _Column {
  final int x;
  final int z;
  final double distance;

  _Column({
    required this.x,
    required this.z,
    required this.distance,
  });
}
