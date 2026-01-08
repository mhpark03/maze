import 'dart:math';

enum BubbleColor { red, blue, green, yellow, purple, empty }

class BubbleGame {
  final int rows;
  final int cols;
  late List<List<BubbleColor>> grid;
  final Random _random = Random();

  int score = 0;
  bool isGameOver = false;

  void Function()? onUpdate;
  void Function()? onGameOver;

  BubbleGame({this.rows = 10, this.cols = 8}) {
    _initGrid();
  }

  void _initGrid() {
    score = 0;
    isGameOver = false;
    grid = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (_) => row < 6 ? _randomColor() : BubbleColor.empty,
      ),
    );
  }

  BubbleColor _randomColor() {
    final colors = [
      BubbleColor.red,
      BubbleColor.blue,
      BubbleColor.green,
      BubbleColor.yellow,
      BubbleColor.purple,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void reset() {
    _initGrid();
    onUpdate?.call();
  }

  bool pop(int row, int col) {
    if (isGameOver) return false;
    if (row < 0 || row >= rows || col < 0 || col >= cols) return false;
    if (grid[row][col] == BubbleColor.empty) return false;

    final color = grid[row][col];
    final connected = _findConnected(row, col, color);

    if (connected.length >= 2) {
      // 연결된 버블 제거
      for (final pos in connected) {
        grid[pos.$1][pos.$2] = BubbleColor.empty;
      }

      // 점수 계산 (연결된 개수의 제곱)
      score += connected.length * connected.length * 10;

      // 버블 떨어뜨리기
      _dropBubbles();

      // 빈 열 정리
      _compactColumns();

      // 게임 오버 체크
      _checkGameOver();

      onUpdate?.call();
      return true;
    }

    return false;
  }

  Set<(int, int)> _findConnected(int row, int col, BubbleColor color) {
    final connected = <(int, int)>{};
    final toCheck = <(int, int)>[(row, col)];

    while (toCheck.isNotEmpty) {
      final current = toCheck.removeLast();
      final r = current.$1;
      final c = current.$2;

      if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
      if (connected.contains((r, c))) continue;
      if (grid[r][c] != color) continue;

      connected.add((r, c));

      toCheck.add((r - 1, c)); // 위
      toCheck.add((r + 1, c)); // 아래
      toCheck.add((r, c - 1)); // 왼쪽
      toCheck.add((r, c + 1)); // 오른쪽
    }

    return connected;
  }

  void _dropBubbles() {
    for (int col = 0; col < cols; col++) {
      int writeRow = rows - 1;
      for (int row = rows - 1; row >= 0; row--) {
        if (grid[row][col] != BubbleColor.empty) {
          if (row != writeRow) {
            grid[writeRow][col] = grid[row][col];
            grid[row][col] = BubbleColor.empty;
          }
          writeRow--;
        }
      }
    }
  }

  void _compactColumns() {
    // 빈 열을 왼쪽으로 정리
    int writeCol = 0;
    for (int col = 0; col < cols; col++) {
      bool hasContent = false;
      for (int row = 0; row < rows; row++) {
        if (grid[row][col] != BubbleColor.empty) {
          hasContent = true;
          break;
        }
      }

      if (hasContent) {
        if (col != writeCol) {
          for (int row = 0; row < rows; row++) {
            grid[row][writeCol] = grid[row][col];
            grid[row][col] = BubbleColor.empty;
          }
        }
        writeCol++;
      }
    }
  }

  void _checkGameOver() {
    // 더 이상 터뜨릴 수 있는 버블이 없으면 게임 오버
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (grid[row][col] != BubbleColor.empty) {
          final connected = _findConnected(row, col, grid[row][col]);
          if (connected.length >= 2) {
            return; // 아직 터뜨릴 수 있음
          }
        }
      }
    }

    isGameOver = true;
    onGameOver?.call();
  }

  int getConnectedCount(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return 0;
    if (grid[row][col] == BubbleColor.empty) return 0;
    return _findConnected(row, col, grid[row][col]).length;
  }
}
