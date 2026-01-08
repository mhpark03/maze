import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/maze.dart';
import '../widgets/maze_widget.dart';

enum Difficulty { easy, medium, hard }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Maze maze;
  Difficulty difficulty = Difficulty.medium;
  int moves = 0;
  int elapsedSeconds = 0;
  Timer? timer;
  bool isGameWon = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeMaze();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeMaze() {
    final size = _getMazeSize();
    maze = Maze(rows: size.$1, cols: size.$2);
    moves = 0;
    elapsedSeconds = 0;
    isGameWon = false;
  }

  (int, int) _getMazeSize() {
    switch (difficulty) {
      case Difficulty.easy:
        return (25, 25);
      case Difficulty.medium:
        return (35, 35);
      case Difficulty.hard:
        return (51, 51);
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameWon) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  void _movePlayer(Position direction) {
    if (isGameWon) return;

    setState(() {
      if (maze.movePlayer(direction)) {
        moves++;
        if (maze.isGameWon) {
          isGameWon = true;
          timer?.cancel();
          _showWinDialog();
        }
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '축하합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFFD700), fontSize: 28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 16),
            Text(
              '미로를 탈출했습니다!',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              '이동 횟수: $moves',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '소요 시간: ${_formatTime(elapsedSeconds)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _newGame();
            },
            child: const Text(
              '새 게임',
              style: TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _newGame() {
    setState(() {
      _initializeMaze();
    });
    _startTimer();
  }

  void _resetGame() {
    setState(() {
      maze.reset();
      moves = 0;
      elapsedSeconds = 0;
      isGameWon = false;
    });
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _changeDifficulty(Difficulty newDifficulty) {
    if (difficulty != newDifficulty) {
      setState(() {
        difficulty = newDifficulty;
        _initializeMaze();
      });
      _startTimer();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.keyW:
          _movePlayer(const Position(-1, 0));
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.keyS:
          _movePlayer(const Position(1, 0));
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _movePlayer(const Position(0, -1));
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _movePlayer(const Position(0, 1));
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyR:
          _resetGame();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyN:
          _newGame();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F0F23),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildDifficultySelector(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: MazeWidget(
                        maze: maze,
                        onMove: _movePlayer,
                      ),
                    ),
                  ),
                ),
                _buildControls(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '미로찾기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '골든 스타를 찾아가세요!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildStatCard('이동', moves.toString(), Icons.directions_walk),
              const SizedBox(width: 12),
              _buildStatCard('시간', _formatTime(elapsedSeconds), Icons.timer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16213E)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDifficultyButton('쉬움', Difficulty.easy),
          const SizedBox(width: 8),
          _buildDifficultyButton('보통', Difficulty.medium),
          const SizedBox(width: 8),
          _buildDifficultyButton('어려움', Difficulty.hard),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(String label, Difficulty level) {
    final isSelected = difficulty == level;
    return GestureDetector(
      onTap: () => _changeDifficulty(level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE94560) : const Color(0xFF16213E),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 방향 버튼 한 줄 배치 (화면 폭에 맞게 간격 분배)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.arrow_back, () => _movePlayer(const Position(0, -1))),
              _buildControlButton(Icons.arrow_upward, () => _movePlayer(const Position(-1, 0))),
              _buildControlButton(Icons.arrow_downward, () => _movePlayer(const Position(1, 0))),
              _buildControlButton(Icons.arrow_forward, () => _movePlayer(const Position(0, 1))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton('리셋', Icons.refresh, _resetGame),
              const SizedBox(width: 16),
              _buildActionButton('새 미로', Icons.casino, _newGame),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6B5B95)),
        ),
        child: Icon(icon, color: const Color(0xFF6B5B95), size: 28),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0F3460)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
