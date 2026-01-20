import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'models/maze.dart';
import 'widgets/maze_widget.dart';

enum MazeDifficulty { easy, medium, hard }

class MazeScreen extends StatefulWidget {
  final MazeDifficulty difficulty;

  const MazeScreen({
    super.key,
    this.difficulty = MazeDifficulty.medium,
  });

  @override
  State<MazeScreen> createState() => _MazeScreenState();
}

class _MazeScreenState extends State<MazeScreen> {
  late Maze maze;
  late MazeDifficulty difficulty;
  int moves = 0;
  int elapsedSeconds = 0;
  Timer? timer;
  bool isGameWon = false;
  final FocusNode _focusNode = FocusNode();
  List<Position>? hintPath;

  @override
  void initState() {
    super.initState();
    difficulty = widget.difficulty;
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
    hintPath = null;
  }

  (int, int) _getMazeSize() {
    switch (difficulty) {
      case MazeDifficulty.easy:
        return (25, 25);
      case MazeDifficulty.medium:
        return (35, 35);
      case MazeDifficulty.hard:
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
          hintPath = null;
          _showWinDialog();
        }
      }
    });
  }

  void _showWinDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.purple.withValues(alpha: 0.5), width: 2),
        ),
        title: Text(
          l10n.mazeCongratulations,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.mazeEscaped,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.mazeMoves(moves),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              l10n.mazeTime(_formatTime(elapsedSeconds)),
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
            child: Text(
              l10n.newGame,
              style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
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

  void _useHint() {
    if (isGameWon) return;

    setState(() {
      hintPath = maze.findPathToEnd();
    });
    HapticFeedback.mediumImpact();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout();
            } else {
              return _buildPortraitLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        title: Text(
          l10n.mazeName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.purple.shade100,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRulesDialog,
            tooltip: l10n.rules,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: !isGameWon ? _useHint : null,
            tooltip: l10n.hint,
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: _newGame,
            tooltip: l10n.newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildInfoPanel(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: MazeWidget(
                    maze: maze,
                    onMove: _movePlayer,
                    hintPath: hintPath,
                  ),
                ),
              ),
            ),
            _buildControls(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.mazeName,
                            style: TextStyle(
                              color: Colors.purple.shade100,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLandscapeInfoBox(l10n.mazeMovesLabel, moves.toString()),
                    const SizedBox(height: 8),
                    _buildLandscapeInfoBox(l10n.mazeTimeLabel, _formatTime(elapsedSeconds)),
                    const Spacer(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttonSize = (constraints.maxWidth / 2.5).clamp(45.0, 60.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLandscapeControlButton(
                              Icons.arrow_back,
                              () => _movePlayer(const Position(0, -1)),
                              buttonSize,
                            ),
                            _buildLandscapeControlButton(
                              Icons.arrow_upward,
                              () => _movePlayer(const Position(-1, 0)),
                              buttonSize,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MazeWidget(
                    maze: maze,
                    onMove: _movePlayer,
                    hintPath: hintPath,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildCircleButton(
                          icon: Icons.help_outline,
                          onPressed: _showRulesDialog,
                        ),
                        const SizedBox(width: 4),
                        _buildCircleButton(
                          icon: Icons.lightbulb_outline,
                          onPressed: !isGameWon ? _useHint : null,
                          color: !isGameWon ? Colors.amber : Colors.white30,
                        ),
                        const SizedBox(width: 4),
                        _buildCircleButton(
                          icon: Icons.replay,
                          onPressed: _newGame,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isGameWon) _buildCompactResultMessage(),
                    const Spacer(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttonSize = (constraints.maxWidth / 2.5).clamp(45.0, 60.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLandscapeControlButton(
                              Icons.arrow_downward,
                              () => _movePlayer(const Position(1, 0)),
                              buttonSize,
                            ),
                            _buildLandscapeControlButton(
                              Icons.arrow_forward,
                              () => _movePlayer(const Position(0, 1)),
                              buttonSize,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade800,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white70),
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }

  Widget _buildLandscapeInfoBox(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final labelSize = (availableWidth * 0.1).clamp(12.0, 16.0);
        final valueSize = (availableWidth * 0.18).clamp(20.0, 32.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: availableWidth * 0.08,
            vertical: availableWidth * 0.05,
          ),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: labelSize,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandscapeControlButton(IconData icon, VoidCallback onPressed, double size) {
    return _MazeHoldButton(
      icon: icon,
      onPressed: onPressed,
      size: size,
    );
  }

  Widget _buildCompactResultMessage() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          const SizedBox(height: 4),
          Text(
            l10n.win,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                icon: Icons.directions_walk,
                iconColor: Colors.purple,
                value: moves.toString(),
                label: l10n.mazeMovesLabel,
              ),
              _buildInfoItem(
                icon: Icons.timer,
                iconColor: Colors.orange,
                value: _formatTime(elapsedSeconds),
                label: l10n.mazeTimeLabel,
              ),
            ],
          ),
          if (isGameWon) ...[
            const SizedBox(height: 12),
            _buildResultMessage(),
          ],
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

  Widget _buildResultMessage() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.win,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(Icons.arrow_back, () => _movePlayer(const Position(0, -1))),
          _buildControlButton(Icons.arrow_upward, () => _movePlayer(const Position(-1, 0))),
          _buildControlButton(Icons.arrow_downward, () => _movePlayer(const Position(1, 0))),
          _buildControlButton(Icons.arrow_forward, () => _movePlayer(const Position(0, 1))),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return _MazeHoldButton(
      icon: icon,
      onPressed: onPressed,
      size: 56,
    );
  }

  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.mazeRulesTitle,
          style: const TextStyle(color: Colors.purple),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleSection(
                l10n.mazeRulesObjective,
                l10n.mazeRulesObjectiveDesc,
              ),
              const SizedBox(height: 12),
              _buildRuleSection(
                l10n.mazeRulesControls,
                l10n.mazeRulesControlsDesc,
              ),
              const SizedBox(height: 12),
              _buildRuleSection(
                l10n.mazeRulesButtons,
                l10n.mazeRulesButtonsDesc,
              ),
              const SizedBox(height: 12),
              _buildRuleSection(
                l10n.mazeRulesTips,
                l10n.mazeRulesTipsDesc,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _MazeHoldButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Duration initialDelay;
  final Duration repeatInterval;

  const _MazeHoldButton({
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.initialDelay = const Duration(milliseconds: 200),
    this.repeatInterval = const Duration(milliseconds: 80),
  });

  @override
  State<_MazeHoldButton> createState() => _MazeHoldButtonState();
}

class _MazeHoldButtonState extends State<_MazeHoldButton> {
  bool _isPressed = false;

  void _startHold() {
    _isPressed = true;
    widget.onPressed();
    _scheduleRepeat();
  }

  void _scheduleRepeat() async {
    await Future.delayed(widget.initialDelay);
    while (_isPressed && mounted) {
      widget.onPressed();
      await Future.delayed(widget.repeatInterval);
    }
  }

  void _stopHold() {
    _isPressed = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: () => _stopHold(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
        ),
        child: Icon(widget.icon, color: Colors.purple, size: widget.size * 0.5),
      ),
    );
  }
}
