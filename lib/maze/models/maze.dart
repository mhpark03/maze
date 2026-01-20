import 'dart:math';

enum CellType { wall, path, start, end, player }

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  Position operator +(Position other) => Position(row + other.row, col + other.col);
}

class Maze {
  final int rows;
  final int cols;
  late List<List<CellType>> grid;
  late Position startPos;
  late Position endPos;
  late Position playerPos;
  final Set<Position> visitedPath = {};

  Maze({required this.rows, required this.cols}) {
    _generateMaze();
  }

  void _generateMaze() {
    grid = List.generate(rows, (_) => List.filled(cols, CellType.wall));

    final random = Random();

    _carve(1, 1, random);

    startPos = const Position(1, 1);
    grid[startPos.row][startPos.col] = CellType.start;

    endPos = Position(rows - 2, cols - 2);
    _ensurePathToEnd();
    grid[endPos.row][endPos.col] = CellType.end;

    playerPos = startPos;
  }

  void _carve(int row, int col, Random random) {
    grid[row][col] = CellType.path;

    final directions = [
      const Position(-2, 0),
      const Position(0, 2),
      const Position(2, 0),
      const Position(0, -2),
    ];

    directions.shuffle(random);

    for (final dir in directions) {
      final newRow = row + dir.row;
      final newCol = col + dir.col;

      if (_isValidCell(newRow, newCol) && grid[newRow][newCol] == CellType.wall) {
        grid[row + dir.row ~/ 2][col + dir.col ~/ 2] = CellType.path;
        _carve(newRow, newCol, random);
      }
    }
  }

  void _ensurePathToEnd() {
    if (grid[endPos.row][endPos.col] == CellType.wall) {
      grid[endPos.row][endPos.col] = CellType.path;
    }
    final directions = [
      const Position(-1, 0),
      const Position(0, -1),
      const Position(1, 0),
      const Position(0, 1),
    ];

    bool hasPath = false;
    for (final dir in directions) {
      final checkRow = endPos.row + dir.row;
      final checkCol = endPos.col + dir.col;
      if (_isInBounds(checkRow, checkCol) &&
          grid[checkRow][checkCol] == CellType.path) {
        hasPath = true;
        break;
      }
    }

    if (!hasPath) {
      if (endPos.row > 1) {
        grid[endPos.row - 1][endPos.col] = CellType.path;
      }
      if (endPos.col > 1) {
        grid[endPos.row][endPos.col - 1] = CellType.path;
      }
    }
  }

  bool _isValidCell(int row, int col) {
    return row > 0 && row < rows - 1 && col > 0 && col < cols - 1;
  }

  bool _isInBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  bool canMoveTo(Position pos) {
    if (!_isInBounds(pos.row, pos.col)) return false;
    final cell = grid[pos.row][pos.col];
    return cell != CellType.wall;
  }

  bool movePlayer(Position direction) {
    final newPos = playerPos + direction;
    if (canMoveTo(newPos)) {
      visitedPath.add(playerPos);
      playerPos = newPos;
      return true;
    }
    return false;
  }

  bool get isGameWon => playerPos == endPos;

  CellType getCell(int row, int col) {
    if (row == playerPos.row && col == playerPos.col) {
      return CellType.player;
    }
    return grid[row][col];
  }

  void reset() {
    playerPos = startPos;
    visitedPath.clear();
  }

  void regenerate() {
    _generateMaze();
    visitedPath.clear();
  }

  List<Position>? findPathToEnd() {
    final queue = <List<Position>>[];
    final visited = <Position>{};

    queue.add([playerPos]);
    visited.add(playerPos);

    final directions = [
      const Position(-1, 0),
      const Position(1, 0),
      const Position(0, -1),
      const Position(0, 1),
    ];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == endPos) {
        return path;
      }

      for (final dir in directions) {
        final next = current + dir;
        if (!visited.contains(next) && canMoveTo(next)) {
          visited.add(next);
          queue.add([...path, next]);
        }
      }
    }

    return null;
  }
}
