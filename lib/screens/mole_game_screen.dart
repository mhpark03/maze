import 'package:flutter/material.dart';
import '../models/mole_game.dart';

class MoleGameScreen extends StatefulWidget {
  const MoleGameScreen({super.key});

  @override
  State<MoleGameScreen> createState() => _MoleGameScreenState();
}

class _MoleGameScreenState extends State<MoleGameScreen> {
  late MoleGame game;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    game = MoleGame();
    game.onUpdate = () => setState(() {});
    game.onGameEnd = _showGameOverDialog;
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  void _startGame() {
    game.start();
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
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 64),
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
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildScoreBoard(),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                '두더지 잡기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '두더지를 탭하세요!',
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
          _buildStatCard('시간', '${game.timeLeft}초', Icons.timer),
          _buildStatCard('최고', highScore.toString(), Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16213E)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5D3A1A), width: 4),
        ),
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => _buildHole(index),
        ),
      ),
    );
  }

  Widget _buildHole(int index) {
    final hasMole = game.holes[index];

    return GestureDetector(
      onTap: () {
        if (game.isPlaying && hasMole) {
          game.whack(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3D2314),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: hasMole
              ? Container(
                  key: const ValueKey('mole'),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B6914),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5D4A1A),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👀', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            Text('👃', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  key: const ValueKey('empty'),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1810),
                    shape: BoxShape.circle,
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
        onTap: game.isPlaying ? null : _startGame,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: game.isPlaying
                ? const Color(0xFF16213E)
                : const Color(0xFFE94560),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            game.isPlaying ? '게임 진행 중...' : '게임 시작',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
