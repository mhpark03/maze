import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

// Top-level function for compute()
GameLevel _generateLevelIsolate(int gridSize) {
  return LevelGenerator()._generateLevelSync(gridSize);
}

class LevelGenerator {
  final Random _random = Random();

  // Async generation for UI responsiveness
  Future<GameLevel> generateLevelAsync(int gridSize) async {
    return compute(_generateLevelIsolate, gridSize);
  }

  // Sync generation (used by isolate)
  GameLevel _generateLevelSync(int gridSize) {
    // Try multiple attempts to get a good level
    GameLevel? bestLevel;
    int bestPathCount = 0;

    for (int attempt = 0; attempt < 5; attempt++) {
      GameLevel? level = _tryGenerateLevel(gridSize);
      if (level != null && level.paths.isNotEmpty) {
        // Ensure the level is solvable
        level = _ensureSolvable(level);
        if (level.paths.length > bestPathCount) {
          bestPathCount = level.paths.length;
          bestLevel = level;
        }
        // If we got a good enough level, use it
        if (level.paths.length >= _getMinPathCount(gridSize) * 0.7) {
          return level;
        }
      }
    }

    // Return the best level we found
    if (bestLevel != null && bestLevel.paths.isNotEmpty) {
      return bestLevel;
    }

    return GameLevel(gridSize: gridSize, paths: []);
  }

  // Legacy sync method
  GameLevel generateLevel(int gridSize) {
    return _generateLevelSync(gridSize);
  }

  // Ensure the level is solvable by removing blocking paths
  GameLevel _ensureSolvable(GameLevel level) {
    List<ArrowPath> paths = List.from(level.paths);

    // First check if already solvable
    if (_isLevelSolvable(paths, level.gridSize)) {
      return level;
    }

    // Find paths involved in deadlock cycles
    List<int> deadlockedIndices = _findDeadlockedPaths(paths, level.gridSize);

    // Keep removing deadlocked paths until solvable (no arbitrary limit)
    int maxIterations = paths.length; // Safety limit to prevent infinite loop
    int iterations = 0;

    while (deadlockedIndices.isNotEmpty && iterations < maxIterations) {
      iterations++;

      // Find which deadlocked path blocks the most other deadlocked paths
      int bestToRemove = _findBestPathToRemove(paths, deadlockedIndices, level.gridSize);
      paths.removeAt(bestToRemove);

      // Re-check solvability
      if (_isLevelSolvable(paths, level.gridSize)) {
        break;
      }

      // Update deadlocked paths list (indices shift after removal)
      deadlockedIndices = _findDeadlockedPaths(paths, level.gridSize);
    }

    return GameLevel(gridSize: level.gridSize, paths: paths);
  }

  // Find paths that are stuck in deadlock (can't escape even after simulation)
  List<int> _findDeadlockedPaths(List<ArrowPath> paths, int gridSize) {
    if (paths.isEmpty) return [];

    // Simulate solving and find which paths can't be removed
    List<bool> canSolve = List.filled(paths.length, false);
    List<bool> removed = List.filled(paths.length, false);

    bool madeProgress = true;
    while (madeProgress) {
      madeProgress = false;
      for (int i = 0; i < paths.length; i++) {
        if (removed[i]) continue;
        if (_canPathEscapeSimulation(paths[i], paths, removed, gridSize)) {
          removed[i] = true;
          canSolve[i] = true;
          madeProgress = true;
        }
      }
    }

    // Return indices of paths that couldn't be solved
    List<int> deadlocked = [];
    for (int i = 0; i < paths.length; i++) {
      if (!canSolve[i]) {
        deadlocked.add(i);
      }
    }
    return deadlocked;
  }

  // Find which path to remove to break the most deadlocks
  int _findBestPathToRemove(List<ArrowPath> paths, List<int> deadlockedIndices, int gridSize) {
    int bestIndex = deadlockedIndices[0];
    int bestScore = 0;

    for (int idx in deadlockedIndices) {
      // Count how many other deadlocked paths this path blocks
      int blocksCount = 0;
      for (int otherIdx in deadlockedIndices) {
        if (idx == otherIdx) continue;
        if (_doesPathBlock(paths[idx], paths[otherIdx], gridSize)) {
          blocksCount++;
        }
      }

      // Prefer removing shorter paths that block more others
      int pathLength = paths[idx].cells.length;
      int score = blocksCount * 10 - pathLength;

      if (score > bestScore || (score == bestScore && pathLength < paths[bestIndex].cells.length)) {
        bestScore = score;
        bestIndex = idx;
      }
    }

    return bestIndex;
  }

  // Check if the level is solvable (simulate solving)
  bool _isLevelSolvable(List<ArrowPath> paths, int gridSize) {
    if (paths.isEmpty) return true;

    // Create a simulation copy
    List<bool> removed = List.filled(paths.length, false);
    int remaining = paths.length;

    // Try to solve by repeatedly finding escapable paths
    bool madeProgress = true;
    while (madeProgress && remaining > 0) {
      madeProgress = false;

      for (int i = 0; i < paths.length; i++) {
        if (removed[i]) continue;

        // Check if this path can escape (considering only non-removed paths)
        if (_canPathEscapeSimulation(paths[i], paths, removed, gridSize)) {
          removed[i] = true;
          remaining--;
          madeProgress = true;
        }
      }
    }

    return remaining == 0;
  }

  // Check if a path can escape in simulation (ignoring removed paths)
  bool _canPathEscapeSimulation(ArrowPath path, List<ArrowPath> allPaths, List<bool> removed, int gridSize) {
    PathCell endCell = path.endCell;
    Direction dir = path.direction;

    int checkRow = endCell.row;
    int checkCol = endCell.col;

    for (int step = 0; step < gridSize; step++) {
      checkRow += dir.delta.dy.toInt();
      checkCol += dir.delta.dx.toInt();

      if (checkRow < 0 || checkRow >= gridSize ||
          checkCol < 0 || checkCol >= gridSize) {
        return true; // Can escape the grid
      }

      for (int i = 0; i < allPaths.length; i++) {
        if (removed[i]) continue;
        if (allPaths[i].id == path.id) continue;
        if (allPaths[i].occupiesCell(checkRow, checkCol)) {
          return false; // Blocked by another path
        }
      }
    }
    return true;
  }

  GameLevel? _tryGenerateLevel(int gridSize) {
    List<ArrowPath> paths = [];
    int pathCount = _getPathCount(gridSize);

    // Use 2D grid for O(1) lookup instead of Set
    List<List<bool>> occupied = List.generate(
      gridSize, (_) => List.filled(gridSize, false));

    List<Color> colors = List.from(GameColors.allColors)..shuffle(_random);

    int pathId = 0;
    int maxAttempts = gridSize <= 10 ? 3000 : (gridSize <= 30 ? 8000 : 15000);
    int attempts = 0;

    // First, create some paths from edges that can easily escape
    _createEdgePaths(paths, occupied, colors, gridSize, pathId);
    pathId = paths.length;

    while (paths.length < pathCount && attempts < maxAttempts) {
      attempts++;

      // Pick a random starting position
      int startRow = _random.nextInt(gridSize);
      int startCol = _random.nextInt(gridSize);

      if (occupied[startRow][startCol]) continue;

      // Path length based on grid size
      int minLength = _getMinPathLength(gridSize);
      int maxLength = _getMaxPathLength(gridSize);
      int pathLength = minLength + _random.nextInt(maxLength - minLength + 1);

      ArrowPath? path = _buildComplexPath(
        gridSize,
        startRow,
        startCol,
        pathLength,
        occupied,
        colors[paths.length % colors.length],
        pathId,
      );

      if (path != null) {
        // Check for duplicate cells within the path itself
        Set<(int, int)> pathCells = {};
        bool hasDuplicate = false;
        for (var cell in path.cells) {
          if (pathCells.contains((cell.row, cell.col))) {
            hasDuplicate = true;
            break;
          }
          pathCells.add((cell.row, cell.col));
        }

        if (hasDuplicate) continue;

        // Verify no cells overlap with occupied grid
        bool hasOverlap = false;
        for (var cell in path.cells) {
          if (occupied[cell.row][cell.col]) {
            hasOverlap = true;
            break;
          }
        }

        if (!hasOverlap) {
          // Check for mutual blocking (deadlock)
          bool wouldDeadlock = _wouldCreateMutualBlock(path, paths, gridSize);

          // Ensure at least one path can escape after adding
          List<ArrowPath> allPaths = [...paths, path];
          bool hasEscapePath = allPaths.any((p) => _canPathEscape(p, allPaths, gridSize));

          if (!wouldDeadlock && hasEscapePath) {
            paths.add(path);
            // Mark all path cells as occupied
            for (var cell in path.cells) {
              occupied[cell.row][cell.col] = true;
            }
            // Mark buffer zone around end cell (arrow head) to prevent visual overlap
            _markEndBuffer(occupied, path.endCell, gridSize);
            pathId++;
          }
        }
      }
    }

    if (paths.isEmpty) return null;

    // Final safety check: remove any paths that overlap or have internal duplicates
    Set<(int, int)> usedCells = {};
    List<ArrowPath> cleanPaths = [];

    for (var path in paths) {
      // Check for internal duplicates first
      Set<(int, int)> pathCellSet = {};
      bool hasInternalDuplicate = false;
      for (var cell in path.cells) {
        if (pathCellSet.contains((cell.row, cell.col))) {
          hasInternalDuplicate = true;
          break;
        }
        pathCellSet.add((cell.row, cell.col));
      }

      if (hasInternalDuplicate) continue;

      // Check for overlap with already added paths
      bool hasOverlap = false;
      for (var cell in path.cells) {
        if (usedCells.contains((cell.row, cell.col))) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        cleanPaths.add(path);
        for (var cell in path.cells) {
          usedCells.add((cell.row, cell.col));
        }
      }
    }

    return GameLevel(gridSize: gridSize, paths: cleanPaths);
  }

  // Check if adding this path would create a mutual block (two arrows facing each other)
  bool _wouldCreateMutualBlock(ArrowPath newPath, List<ArrowPath> existingPaths, int gridSize) {
    // Check if the new path directly blocks any existing path that also blocks the new path
    for (var existingPath in existingPaths) {
      bool newBlocksExisting = _doesPathBlock(newPath, existingPath, gridSize);
      bool existingBlocksNew = _doesPathBlock(existingPath, newPath, gridSize);

      if (newBlocksExisting && existingBlocksNew) {
        return true; // Mutual block detected
      }
    }
    return false;
  }

  // Check if pathA blocks pathB (pathB's exit leads into pathA)
  bool _doesPathBlock(ArrowPath pathA, ArrowPath pathB, int gridSize) {
    PathCell endCell = pathB.endCell;
    Direction dir = pathB.direction;

    int checkRow = endCell.row;
    int checkCol = endCell.col;

    for (int step = 0; step < gridSize; step++) {
      checkRow += dir.delta.dy.toInt();
      checkCol += dir.delta.dx.toInt();

      if (checkRow < 0 || checkRow >= gridSize ||
          checkCol < 0 || checkCol >= gridSize) {
        return false; // Exits grid, no block
      }

      if (pathA.occupiesCell(checkRow, checkCol)) {
        return true; // pathA blocks pathB
      }
    }
    return false;
  }

  int _getPathCount(int gridSize) {
    if (gridSize <= 10) return 20 + _random.nextInt(8);    // 20-27 paths
    if (gridSize <= 30) return 120 + _random.nextInt(40);  // 120-159 paths
    return 180 + _random.nextInt(60);                       // 180-239 paths (for 50x50)
  }

  int _getMinPathCount(int gridSize) {
    if (gridSize <= 10) return 15;
    if (gridSize <= 30) return 80;
    return 120;
  }

  int _getMinPathLength(int gridSize) {
    if (gridSize <= 10) return 3;
    if (gridSize <= 30) return 5;
    return 6;
  }

  int _getMaxPathLength(int gridSize) {
    if (gridSize <= 10) return 10;
    if (gridSize <= 30) return 20;
    return 30;
  }

  // Mark buffer zone around end cell (only exit direction cell)
  void _markEndBuffer(List<List<bool>> occupied, PathCell endCell, int gridSize) {
    Direction dir = endCell.exitDirection;

    // Only mark cell in exit direction (reduced buffer for denser packing)
    int r = endCell.row + dir.delta.dy.toInt();
    int c = endCell.col + dir.delta.dx.toInt();
    if (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
      occupied[r][c] = true;
    }
  }

  // Check if a path can escape (exit direction doesn't hit any other path)
  bool _canPathEscape(ArrowPath path, List<ArrowPath> allPaths, int gridSize) {
    PathCell endCell = path.endCell;
    Direction dir = path.direction;

    int checkRow = endCell.row;
    int checkCol = endCell.col;

    for (int step = 0; step < gridSize; step++) {
      checkRow += dir.delta.dy.toInt();
      checkCol += dir.delta.dx.toInt();

      if (checkRow < 0 || checkRow >= gridSize ||
          checkCol < 0 || checkCol >= gridSize) {
        return true; // Can escape the grid
      }

      for (var other in allPaths) {
        if (other.id == path.id) continue;
        if (other.occupiesCell(checkRow, checkCol)) {
          return false; // Blocked by another path
        }
      }
    }
    return true;
  }

  ArrowPath? _buildComplexPath(
    int gridSize,
    int startRow,
    int startCol,
    int targetLength,
    List<List<bool>> occupied,
    Color color,
    int id,
  ) {
    List<PathCell> cells = [];
    // Local occupied tracking for this path
    List<List<bool>> pathOccupied = List.generate(
      gridSize, (_) => List.filled(gridSize, false));
    pathOccupied[startRow][startCol] = true;

    int currentRow = startRow;
    int currentCol = startCol;
    Direction? prevExitDir;
    int turnCount = 0;
    int maxTurns = targetLength ~/ 2;  // Allow more turns
    int cellsSinceLastTurn = 0;
    int minCellsBeforeTurn = 2;  // Allow turns after 2 cells

    for (int i = 0; i < targetLength; i++) {
      List<Direction> validDirs = _getValidDirs(
        currentRow, currentCol, gridSize, occupied, pathOccupied,
        prevExitDir, cellsSinceLastTurn < minCellsBeforeTurn,
      );

      if (validDirs.isEmpty) {
        if (i >= 2 && prevExitDir != null) {
          // Verify cell is not occupied
          if (occupied[currentRow][currentCol]) {
            return null;
          }
          // Only reject if self-blocking, otherwise accept
          if (!_wouldSelfBlockGrid(currentRow, currentCol, prevExitDir, pathOccupied, gridSize)) {
            cells.add(PathCell(
              row: currentRow,
              col: currentCol,
              entryDirection: prevExitDir.opposite,
              exitDirection: prevExitDir,
            ));
          }
          break;
        }
        return null;
      }

      Direction nextDir;
      bool canTurn = cellsSinceLastTurn >= minCellsBeforeTurn && turnCount < maxTurns;

      if (prevExitDir != null && validDirs.contains(prevExitDir)) {
        if (canTurn && _random.nextDouble() < 0.25) {
          List<Direction> turnDirs = _get90DegreeTurns(prevExitDir)
              .where((d) => validDirs.contains(d)).toList();
          if (turnDirs.isNotEmpty) {
            nextDir = turnDirs[_random.nextInt(turnDirs.length)];
            turnCount++;
            cellsSinceLastTurn = 0;
          } else {
            nextDir = prevExitDir;
            cellsSinceLastTurn++;
          }
        } else {
          nextDir = prevExitDir;
          cellsSinceLastTurn++;
        }
      } else if (prevExitDir != null) {
        List<Direction> turnDirs = _get90DegreeTurns(prevExitDir)
            .where((d) => validDirs.contains(d)).toList();
        nextDir = turnDirs.isNotEmpty
            ? turnDirs[_random.nextInt(turnDirs.length)]
            : validDirs[_random.nextInt(validDirs.length)];
        turnCount++;
        cellsSinceLastTurn = 0;
      } else {
        nextDir = validDirs[_random.nextInt(validDirs.length)];
        cellsSinceLastTurn = 1;
      }

      Direction entryDir = (i == 0) ? nextDir.opposite : prevExitDir!.opposite;

      // Verify current cell is not occupied before adding
      if (occupied[currentRow][currentCol]) {
        return null;  // Cell already occupied, reject path
      }

      cells.add(PathCell(
        row: currentRow,
        col: currentCol,
        entryDirection: entryDir,
        exitDirection: nextDir,
      ));

      currentRow += nextDir.delta.dy.toInt();
      currentCol += nextDir.delta.dx.toInt();
      if (currentRow >= 0 && currentRow < gridSize &&
          currentCol >= 0 && currentCol < gridSize) {
        // Double check before marking
        if (occupied[currentRow][currentCol]) {
          return null;  // Next cell already occupied, reject path
        }
        pathOccupied[currentRow][currentCol] = true;
      }
      prevExitDir = nextDir;
    }

    // Add final cell (only if we haven't already added it in the break case)
    if (cells.length >= 2 && prevExitDir != null) {
      // Check if the last cell is already at this position (break case)
      PathCell lastAddedCell = cells.last;
      bool alreadyAdded = lastAddedCell.row == currentRow && lastAddedCell.col == currentCol;

      if (!alreadyAdded &&
          currentRow >= 0 && currentRow < gridSize &&
          currentCol >= 0 && currentCol < gridSize &&
          !occupied[currentRow][currentCol]) {

        // Exit direction MUST be same as travel direction (prevExitDir)
        // If it would self-block, don't add this cell
        if (!_wouldSelfBlockGrid(currentRow, currentCol, prevExitDir, pathOccupied, gridSize)) {
          cells.add(PathCell(
            row: currentRow,
            col: currentCol,
            entryDirection: prevExitDir.opposite,
            exitDirection: prevExitDir,  // Always same as travel direction
          ));
        }
      }
    }

    if (cells.length < 3) return null;

    // Final self-block check - if self-blocking, reject the path entirely
    PathCell lastCell = cells.last;
    if (_wouldSelfBlockGrid(lastCell.row, lastCell.col, lastCell.exitDirection, pathOccupied, gridSize)) {
      return null;  // Reject path that would self-block
    }

    return ArrowPath(cells: cells, color: color, id: id);
  }

  // Get 90 degree turn directions (perpendicular)
  List<Direction> _get90DegreeTurns(Direction current) {
    switch (current) {
      case Direction.up:
      case Direction.down:
        return [Direction.left, Direction.right];
      case Direction.left:
      case Direction.right:
        return [Direction.up, Direction.down];
    }
  }

  // Get valid directions using 2D grid for O(1) lookup
  List<Direction> _getValidDirs(
    int row,
    int col,
    int gridSize,
    List<List<bool>> occupied,
    List<List<bool>> pathOccupied,
    Direction? prevExitDir,
    bool forceForward,
  ) {
    List<Direction> valid = [];

    for (var dir in Direction.values) {
      if (prevExitDir != null && dir == prevExitDir.opposite) continue;
      if (forceForward && prevExitDir != null && dir != prevExitDir) continue;

      int newRow = row + dir.delta.dy.toInt();
      int newCol = col + dir.delta.dx.toInt();

      if (newRow < 0 || newRow >= gridSize ||
          newCol < 0 || newCol >= gridSize) {
        continue;
      }

      if (occupied[newRow][newCol]) continue;
      if (pathOccupied[newRow][newCol]) continue;

      valid.add(dir);
    }

    if (valid.isEmpty && forceForward && prevExitDir != null) {
      return _getValidDirs(row, col, gridSize, occupied, pathOccupied, prevExitDir, false);
    }

    return valid;
  }

  // Create paths from edges that can easily escape
  void _createEdgePaths(List<ArrowPath> paths, List<List<bool>> occupied,
      List<Color> colors, int gridSize, int startId) {
    int pathId = startId;
    int edgePaths = gridSize <= 10 ? 4 : (gridSize <= 30 ? 8 : 12);

    // Create paths pointing outward from each edge
    List<_EdgeStart> edgeStarts = [];

    // Top edge - paths pointing up
    for (int col = 1; col < gridSize - 1; col += 3) {
      edgeStarts.add(_EdgeStart(0, col, Direction.up));
    }
    // Bottom edge - paths pointing down
    for (int col = 1; col < gridSize - 1; col += 3) {
      edgeStarts.add(_EdgeStart(gridSize - 1, col, Direction.down));
    }
    // Left edge - paths pointing left
    for (int row = 1; row < gridSize - 1; row += 3) {
      edgeStarts.add(_EdgeStart(row, 0, Direction.left));
    }
    // Right edge - paths pointing right
    for (int row = 1; row < gridSize - 1; row += 3) {
      edgeStarts.add(_EdgeStart(row, gridSize - 1, Direction.right));
    }

    edgeStarts.shuffle(_random);

    for (var start in edgeStarts) {
      if (paths.length >= edgePaths) break;
      if (occupied[start.row][start.col]) continue;

      // Create a simple straight path from edge
      int pathLength = 3 + _random.nextInt(3); // 3-5 cells
      List<PathCell> cells = [];
      int row = start.row;
      int col = start.col;
      Direction inwardDir = start.exitDir.opposite;

      bool valid = true;
      for (int i = 0; i < pathLength; i++) {
        if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
          valid = false;
          break;
        }
        if (occupied[row][col]) {
          valid = false;
          break;
        }
        cells.add(PathCell(
          row: row,
          col: col,
          entryDirection: inwardDir,
          exitDirection: start.exitDir,
        ));
        row += inwardDir.delta.dy.toInt();
        col += inwardDir.delta.dx.toInt();
      }

      if (valid && cells.length >= 3) {
        // Reverse cells so arrow points outward (toward edge)
        cells = cells.reversed.toList();
        for (int i = 0; i < cells.length; i++) {
          cells[i] = PathCell(
            row: cells[i].row,
            col: cells[i].col,
            entryDirection: cells[i].exitDirection.opposite,
            exitDirection: cells[i].entryDirection.opposite,
          );
        }

        ArrowPath path = ArrowPath(
          cells: cells,
          color: colors[paths.length % colors.length],
          id: pathId++,
        );

        paths.add(path);
        for (var cell in cells) {
          occupied[cell.row][cell.col] = true;
        }
        _markEndBuffer(occupied, cells.last, gridSize);
      }
    }
  }

  // Check if exit direction would self-block (using 2D grid)
  bool _wouldSelfBlockGrid(
    int endRow,
    int endCol,
    Direction exitDir,
    List<List<bool>> pathOccupied,
    int gridSize,
  ) {
    int checkRow = endRow;
    int checkCol = endCol;

    while (true) {
      checkRow += exitDir.delta.dy.toInt();
      checkCol += exitDir.delta.dx.toInt();

      if (checkRow < 0 || checkRow >= gridSize ||
          checkCol < 0 || checkCol >= gridSize) {
        return false;
      }

      if (pathOccupied[checkRow][checkCol]) {
        return true;
      }
    }
  }
}

// Helper class for edge path generation
class _EdgeStart {
  final int row;
  final int col;
  final Direction exitDir;

  _EdgeStart(this.row, this.col, this.exitDir);
}
