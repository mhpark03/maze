import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import 'game_screen.dart';
import '../maze/maze_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          l10n.selectGame,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white70),
            onPressed: () => _showLanguageDialog(context, l10n),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameCard(
                context: context,
                title: l10n.arrowMaze,
                icon: Icons.arrow_forward,
                color: const Color(0xFF4ECDC4),
                onTap: () => _showArrowMazeDifficultyDialog(context, l10n),
              ),
              const SizedBox(height: 24),
              _buildGameCard(
                context: context,
                title: l10n.maze,
                icon: Icons.grid_4x4,
                color: Colors.purple,
                onTap: () => _showMazeDifficultyDialog(context, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArrowMazeDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.selectDifficulty, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildArrowMazeDifficultyOption(
              context: context,
              title: '${l10n.easy} (${GameState.gridSizes[0]}x${GameState.gridSizes[0]})',
              difficulty: ArrowMazeDifficulty.easy,
            ),
            _buildArrowMazeDifficultyOption(
              context: context,
              title: '${l10n.normal} (${GameState.gridSizes[1]}x${GameState.gridSizes[1]})',
              difficulty: ArrowMazeDifficulty.medium,
            ),
            _buildArrowMazeDifficultyOption(
              context: context,
              title: '${l10n.hard} (${GameState.gridSizes[2]}x${GameState.gridSizes[2]})',
              difficulty: ArrowMazeDifficulty.hard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Color(0xFF4ECDC4))),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowMazeDifficultyOption({
    required BuildContext context,
    required String title,
    required ArrowMazeDifficulty difficulty,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      leading: const Icon(Icons.arrow_forward, color: Color(0xFF4ECDC4)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(difficulty: difficulty),
          ),
        );
      },
    );
  }

  void _showMazeDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.selectDifficulty, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMazeDifficultyOption(
              context: context,
              title: '${l10n.easy} (25x25)',
              difficulty: MazeDifficulty.easy,
            ),
            _buildMazeDifficultyOption(
              context: context,
              title: '${l10n.normal} (35x35)',
              difficulty: MazeDifficulty.medium,
            ),
            _buildMazeDifficultyOption(
              context: context,
              title: '${l10n.hard} (51x51)',
              difficulty: MazeDifficulty.hard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Color(0xFF4ECDC4))),
          ),
        ],
      ),
    );
  }

  Widget _buildMazeDifficultyOption({
    required BuildContext context,
    required String title,
    required MazeDifficulty difficulty,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      leading: const Icon(Icons.grid_4x4, color: Colors.purple),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MazeScreen(difficulty: difficulty),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    final localeProvider = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.language, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var locale in AppLocalizations.supportedLocales)
              ListTile(
                title: Text(
                  AppLocalizations.getLanguageName(locale.languageCode),
                  style: const TextStyle(color: Colors.white70),
                ),
                leading: Icon(
                  localeProvider.locale.languageCode == locale.languageCode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF4ECDC4),
                ),
                onTap: () {
                  localeProvider.setLocale(locale);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Color(0xFF4ECDC4))),
          ),
        ],
      ),
    );
  }
}
