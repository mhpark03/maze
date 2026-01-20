import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../widgets/game_board.dart';

enum ArrowMazeDifficulty { easy, medium, hard }

class GameScreen extends StatefulWidget {
  final ArrowMazeDifficulty difficulty;

  const GameScreen({
    super.key,
    this.difficulty = ArrowMazeDifficulty.easy,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().startGame(widget.difficulty.index);
    });
  }

  @override
  void dispose() {
    _adService.disposeRewardedAd();
    super.dispose();
  }

  void _showHintWithAd(GameState gameState, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.hintConfirmTitle,
          style: const TextStyle(color: Color(0xFF4ECDC4)),
        ),
        content: Text(
          l10n.hintConfirmMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _adService.showRewardedAd(
                onUserEarnedReward: () {
                  gameState.showHint();
                },
                onAdFailedToShow: () {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.adNotReady),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF2D2D44),
                    ),
                  );
                  gameState.showHint();
                },
              );
            },
            child: Text(
              l10n.watch,
              style: const TextStyle(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        foregroundColor: Colors.white,
        title: Text(
          l10n.arrowMaze,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(l10n),
            tooltip: l10n.howToPlay,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showHintWithAd(context.read<GameState>(), l10n),
            tooltip: l10n.hint,
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () => context.read<GameState>().resetLevel(),
            tooltip: l10n.newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    _buildInfoPanel(gameState, l10n),
                    _buildInstructions(gameState, l10n),
                    const Expanded(child: GameBoard()),
                  ],
                ),
                if (gameState.isLoading) _buildLoadingOverlay(l10n),
                if (gameState.isLevelComplete) _buildLevelCompleteOverlay(gameState, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoPanel(GameState gameState, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFFFFD93D),
            value: gameState.elapsedTimeString,
            label: l10n.time,
          ),
          _buildInfoItem(
            icon: Icons.close,
            iconColor: const Color(0xFFE74C3C),
            value: gameState.errorCount.toString(),
            label: l10n.errorCount(gameState.errorCount).split(':')[0],
          ),
          _buildInfoItem(
            icon: Icons.grid_view,
            iconColor: const Color(0xFF4ECDC4),
            value: '${GameState.gridSizes[gameState.currentDifficulty]}x${GameState.gridSizes[gameState.currentDifficulty]}',
            label: l10n.getDifficultyName(gameState.currentDifficulty),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(GameState gameState, AppLocalizations l10n) {
    String statusText;
    Color statusColor;

    int flyingCount = gameState.flyingArrows.length;
    bool hasCollided = gameState.flyingArrows.any((a) => a.collided);

    if (gameState.isAnimating) {
      if (hasCollided) {
        statusText = l10n.collision;
        statusColor = Colors.red;
      } else if (flyingCount > 1) {
        statusText = '${l10n.flying} ($flyingCount)';
        statusColor = Colors.white70;
      } else {
        statusText = l10n.flying;
        statusColor = gameState.flyingArrow?.color ?? Colors.white70;
      }
    } else {
      int remaining = gameState.level?.remainingPaths ?? 0;
      statusText = l10n.tapArrow(remaining);
      statusColor = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingOverlay(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF4ECDC4),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.loading,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay(GameState gameState, AppLocalizations l10n) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                color: Color(0xFFFFD93D),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cleared(l10n.getDifficultyName(gameState.currentDifficulty)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Time and stats row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(Icons.timer_outlined, gameState.elapsedTimeString, const Color(0xFFFFD93D)),
                  const SizedBox(width: 24),
                  _buildStatItem(Icons.close, gameState.errorCount.toString(), const Color(0xFFE74C3C)),
                  const SizedBox(width: 24),
                  _buildStatItem(Icons.lightbulb_outline, gameState.hintCount.toString(), const Color(0xFF4ECDC4)),
                ],
              ),
              if (gameState.errorCount == 0 && gameState.hintCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.perfect,
                    style: const TextStyle(
                      color: Color(0xFFFFD93D),
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                    onPressed: () => gameState.resetLevel(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D44),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.newGame,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(l10n.howToPlay, style: const TextStyle(color: Color(0xFF4ECDC4))),
        content: Text(
          '${l10n.help1}\n\n'
          '${l10n.help2}\n\n'
          '${l10n.help3}\n\n'
          '${l10n.help4}\n\n'
          '${l10n.help5}',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok, style: const TextStyle(color: Color(0xFF4ECDC4))),
          ),
        ],
      ),
    );
  }
}
