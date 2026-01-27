import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import 'models/tap_master_models.dart';
import 'tap_master_generator.dart';
import 'widgets/tap_master_board.dart';

class TapMasterScreen extends StatefulWidget {
  final TapMasterDifficulty difficulty;

  const TapMasterScreen({super.key, required this.difficulty});

  @override
  State<TapMasterScreen> createState() => _TapMasterScreenState();
}

class _TapMasterScreenState extends State<TapMasterScreen> {
  TapMasterPuzzle? _puzzle;
  bool _isLoading = true;
  int _tapCount = 0;
  int _hintCount = 0;
  Timer? _timer;
  Timer? _hintTimer;
  final Stopwatch _stopwatch = Stopwatch();
  String _elapsedTime = '00:00';
  final AdService _adService = AdService();
  Set<TapBlock> _tappableBlocks = {};
  TapBlock? _hintBlock;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _generatePuzzle() async {
    setState(() => _isLoading = true);
    _stopwatch.reset();
    _timer?.cancel();

    final puzzle = await TapMasterGenerator.generate(widget.difficulty);

    setState(() {
      _puzzle = puzzle;
      _isLoading = false;
      _tapCount = 0;
      _hintCount = 0;
      _elapsedTime = '00:00';
      _updateTappableBlocks();
    });

    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final seconds = _stopwatch.elapsed.inSeconds;
          final mins = (seconds ~/ 60).toString().padLeft(2, '0');
          final secs = (seconds % 60).toString().padLeft(2, '0');
          _elapsedTime = '$mins:$secs';
        });
      }
    });
  }

  void _updateTappableBlocks() {
    if (_puzzle == null) return;
    _tappableBlocks = _puzzle!.getTappableBlocks().toSet();
  }

  void _onBlockTap(TapBlock block) {
    if (_puzzle == null) return;

    // Clear hint when block is tapped
    _hintTimer?.cancel();

    setState(() {
      _puzzle!.removeBlock(block);
      _tapCount++;
      _hintBlock = null;
      _updateTappableBlocks();
    });

    if (_puzzle!.isComplete()) {
      _stopwatch.stop();
      _timer?.cancel();
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.congratulations,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              '${loc.moves}: $_tapCount',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${loc.time}: $_elapsedTime',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_hintCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${loc.hints}: $_hintCount',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(loc.home),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generatePuzzle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: Text(loc.playAgain),
          ),
        ],
      ),
    );
  }

  void _showHintConfirmDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.hint,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          loc.watchAdForHint,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAdForHint();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
            ),
            child: Text(loc.watchAd),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdForHint() {
    _adService.showRewardedAd(
      onUserEarnedReward: () {
        _showHint();
      },
      onAdFailedToShow: () {
        // Give hint anyway if ad fails
        _showHint();
      },
    );
  }

  void _showHint() {
    if (_puzzle == null || _tappableBlocks.isEmpty) return;

    // Cancel any existing hint timer
    _hintTimer?.cancel();

    // Select a random tappable block as hint
    final tappableList = _tappableBlocks.toList();
    final hintBlock = tappableList[DateTime.now().millisecondsSinceEpoch % tappableList.length];

    setState(() {
      _hintCount++;
      _hintBlock = hintBlock;
    });

    // Show a snackbar indicating which block to tap
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.tapHighlightedBlock),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF4ECDC4),
      ),
    );

    // Clear hint after 5 seconds
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hintBlock = null;
        });
      }
    });
  }

  void _showRulesDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.howToPlay,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            loc.tapMasterRules,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF6B6B), size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.tapMaster,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRulesDialog,
            tooltip: loc.howToPlay,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _isLoading ? null : _showHintConfirmDialog,
            tooltip: loc.hint,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _generatePuzzle,
            tooltip: loc.newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B6B),
                ),
              )
            : Column(
                children: [
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactInfoCard(
                          Icons.timer,
                          loc.time,
                          _elapsedTime,
                        ),
                        _buildCompactInfoCard(
                          Icons.touch_app,
                          loc.taps,
                          '$_tapCount',
                        ),
                        _buildCompactInfoCard(
                          Icons.grid_view,
                          loc.remaining,
                          '${_puzzle!.remainingBlocks}/${_puzzle!.totalBlocks}',
                        ),
                      ],
                    ),
                  ),
                  // Game board
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TapMasterBoard(
                        puzzle: _puzzle!,
                        onBlockTap: _onBlockTap,
                        tappableBlocks: _tappableBlocks,
                        hintBlock: _hintBlock,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
