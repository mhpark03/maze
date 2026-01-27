import 'dart:ui';

/// Direction of the arrow on each block (6 directions - all axes)
enum ArrowDirection {
  // Horizontal directions (X-Z plane)
  north,  // -X direction (toward back-left)
  south,  // +X direction (toward front-right)
  east,   // -Z direction (toward back-right)
  west,   // +Z direction (toward front-left)
  // Vertical directions (Y axis)
  skyward,    // +Y direction (upward)
  groundward, // -Y direction (downward)
}

/// Difficulty levels for TapMaster
enum TapMasterDifficulty { easy, medium, hard }

extension TapMasterDifficultyExtension on TapMasterDifficulty {
  /// Grid size (width x depth)
  int get gridWidth {
    switch (this) {
      case TapMasterDifficulty.easy:
        return 3;
      case TapMasterDifficulty.medium:
        return 5;
      case TapMasterDifficulty.hard:
        return 7;
    }
  }

  int get gridDepth {
    switch (this) {
      case TapMasterDifficulty.easy:
        return 3;
      case TapMasterDifficulty.medium:
        return 5;
      case TapMasterDifficulty.hard:
        return 7;
    }
  }

  /// Maximum stack height
  int get maxHeight {
    switch (this) {
      case TapMasterDifficulty.easy:
        return 6;
      case TapMasterDifficulty.medium:
        return 10;
      case TapMasterDifficulty.hard:
        return 14;
    }
  }

  /// Total block count range (approximately 80% of total grid capacity)
  /// Easy: 3x3x6=54, 80%=43
  /// Medium: 5x5x10=250, 80%=200
  /// Hard: 7x7x14=686, 80%=549
  (int, int) get blockCountRange {
    switch (this) {
      case TapMasterDifficulty.easy:
        return (38, 48);
      case TapMasterDifficulty.medium:
        return (180, 220);
      case TapMasterDifficulty.hard:
        return (500, 580);
    }
  }
}

/// A single block in the 3D grid
class TapBlock {
  final int x; // Left-right position
  final int y; // Height (vertical)
  final int z; // Depth (front-back)
  final ArrowDirection direction;
  final Color color;
  bool isRemoved;

  TapBlock({
    required this.x,
    required this.y,
    required this.z,
    required this.direction,
    required this.color,
    this.isRemoved = false,
  });

  TapBlock copyWith({
    int? x,
    int? y,
    int? z,
    ArrowDirection? direction,
    Color? color,
    bool? isRemoved,
  }) {
    return TapBlock(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      direction: direction ?? this.direction,
      color: color ?? this.color,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }

  @override
  String toString() => 'TapBlock($x, $y, $z, $direction)';
}

/// Complete puzzle state
class TapMasterPuzzle {
  final List<TapBlock> blocks;
  final int gridWidth;
  final int gridDepth;
  final int maxHeight;

  TapMasterPuzzle({
    required this.blocks,
    required this.gridWidth,
    required this.gridDepth,
    required this.maxHeight,
  });

  /// Get all blocks that are currently tappable (not blocked by other blocks)
  List<TapBlock> getTappableBlocks() {
    final tappable = <TapBlock>[];
    final activeBlocks = blocks.where((b) => !b.isRemoved).toList();

    for (final block in activeBlocks) {
      if (!isBlockedByOther(block, activeBlocks)) {
        tappable.add(block);
      }
    }

    return tappable;
  }

  /// Check if a block is blocked by another block in front of it
  /// A block is tappable if there's no block in front of it (higher z) at the same or higher y
  bool isBlockedByOther(TapBlock block, List<TapBlock> activeBlocks) {
    for (final other in activeBlocks) {
      if (other == block || other.isRemoved) continue;

      // Check if 'other' is in front of 'block' (higher z means closer to viewer)
      // A block is blocked if there's another block that:
      // 1. Is in the same x column or adjacent
      // 2. Is in front (higher z)
      // 3. Is at same or higher y level
      if (other.z > block.z) {
        // Check if it overlaps in x and y visibility
        if (other.x == block.x && other.y >= block.y) {
          return true;
        }
        // Also check diagonal blocking for isometric view
        if (other.x == block.x - 1 && other.z == block.z + 1 && other.y >= block.y) {
          return true;
        }
      }
      // Check if there's a block directly on top
      if (other.x == block.x && other.z == block.z && other.y > block.y) {
        return true;
      }
    }
    return false;
  }

  /// Remove a block from the puzzle
  void removeBlock(TapBlock block) {
    block.isRemoved = true;
  }

  /// Check if the puzzle is complete
  bool isComplete() {
    return blocks.every((b) => b.isRemoved);
  }

  /// Get remaining block count
  int get remainingBlocks => blocks.where((b) => !b.isRemoved).length;

  /// Get total block count
  int get totalBlocks => blocks.length;
}
