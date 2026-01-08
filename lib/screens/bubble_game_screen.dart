import 'package:flutter/material.dart';
import '../models/bubble_game.dart';

class BubbleGameScreen extends StatefulWidget {
  const BubbleGameScreen({super.key});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

class _BubbleGameScreenState extends State<BubbleGameScreen> {
  late BubbleGame game;
  int highScore = 0;
  int? hoveredRow;
  int? hoveredCol;

  @override
  void initState() {
    super.initState();
    game = BubbleGame();
    game.onUpdate = () => setState(() {});
    game.onGameOver = _showGameOverDialog;
  }

  void _showGameOverDialog() {
    if (game.score > highScore) {
      highScore = game.score;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '게임 종료!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFFD700), fontSize: 28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bubble_chart, color: Color(0xFF00D9FF), size: 64),
            const SizedBox(height: 16),
            Text(
              '점수: ${game.score}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '최고 점수: $highScore',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              game.reset();
            },
            child: const Text(
              '다시 하기',
              style: TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor(BubbleColor color) {
    switch (color) {
      case BubbleColor.red:
        return Colors.red;
      case BubbleColor.blue:
        return Colors.blue;
      case BubbleColor.green:
        return Colors.green;
      case BubbleColor.yellow:
        return Colors.amber;
      case BubbleColor.purple:
        return Colors.purple;
      case BubbleColor.empty:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildScoreBoard(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildGameGrid(),
              ),
            ),
            _buildControls(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '버블 팝',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '같은 색 버블을 터뜨리세요!',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('점수', game.score.toString(), Icons.star),
          _buildStatCard('최고', highScore.toString(), Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16213E), width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / game.cols;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (int row = 0; row < game.rows; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int col = 0; col < game.cols; col++)
                      _buildBubble(row, col, cellSize),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBubble(int row, int col, double size) {
    final color = game.grid[row][col];
    final isEmpty = color == BubbleColor.empty;
    final connectedCount = isEmpty ? 0 : game.getConnectedCount(row, col);
    final canPop = connectedCount >= 2;

    return GestureDetector(
      onTap: () {
        if (!isEmpty && canPop) {
          game.pop(row, col);
        }
      },
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        child: isEmpty
            ? null
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getBubbleColor(color),
                  boxShadow: [
                    BoxShadow(
                      color: _getBubbleColor(color).withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      _getBubbleColor(color).withOpacity(0.8),
                      _getBubbleColor(color),
                      _getBubbleColor(color).withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: size * 0.3,
                    height: size * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => game.reset(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '새 게임',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
