import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import 'models/car_escape_models.dart';
import 'car_escape_generator.dart';
import 'widgets/car_escape_board.dart';

class CarEscapeScreen extends StatefulWidget {
  final CarEscapeDifficulty difficulty;

  const CarEscapeScreen({super.key, required this.difficulty});

  @override
  State<CarEscapeScreen> createState() => _CarEscapeScreenState();
}

class _CarEscapeScreenState extends State<CarEscapeScreen> {
  CarJamPuzzle? _puzzle;
  bool _isLoading = true;
  int _totalCars = 0;
  int _clearedCars = 0;
  int _hintCount = 0;
  int? _hintCarId;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00';
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _adService.disposeRewardedAd();
    super.dispose();
  }

  Future<void> _generatePuzzle() async {
    setState(() {
      _isLoading = true;
    });

    final puzzle = await CarEscapeGenerator.generate(widget.difficulty);

    setState(() {
      _puzzle = puzzle;
      _totalCars = puzzle.cars.length;
      _clearedCars = 0;
      _hintCount = 0;
      _hintCarId = null;
      _isLoading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsed);
        });
      }
    });
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onCarTap(GridCar car) {}

  void _onCarExited(GridCar car) {
    if (_puzzle == null) return;

    setState(() {
      _puzzle!.removeCar(car.id);
      _clearedCars++;
      _hintCarId = null;
    });

    if (_puzzle!.isComplete) {
      _stopwatch.stop();
      _timer?.cancel();
      _showWinDialog();
    }
  }

  void _showHintWithAd(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.hintConfirmTitle,
          style: const TextStyle(color: Colors.green),
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
                  _showHint();
                },
                onAdFailedToShow: () {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.adNotReady),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF2D2D44),
                    ),
                  );
                  _showHint();
                },
              );
            },
            child: Text(
              l10n.watch,
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showHint() {
    if (_puzzle == null || _puzzle!.activeCars.isEmpty) return;

    for (var car in _puzzle!.activeCars) {
      if (_puzzle!.canCarExit(car)) {
        setState(() {
          _hintCarId = car.id;
          _hintCount++;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _hintCarId == car.id) {
            setState(() {
              _hintCarId = null;
            });
          }
        });
        return;
      }
    }
  }

  void _showWinDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          l10n.carEscapeCongratulations,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.carEscapeCleared,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.carEscapeMoves(_totalCars),
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.time}: $_elapsedTime',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.hint}: $_hintCount',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.close, style: const TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generatePuzzle();
            },
            child: Text(l10n.newGame, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          l10n.carEscapeRulesTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleSection(l10n.carEscapeRulesObjective, l10n.carEscapeRulesObjectiveDesc),
              const SizedBox(height: 16),
              _buildRuleSection(l10n.carEscapeRulesControls, l10n.carEscapeRulesControlsDesc),
              const SizedBox(height: 16),
              _buildRuleSection(l10n.carEscapeRulesTips, l10n.carEscapeRulesTipsDesc),
              const SizedBox(height: 16),
              _buildTurnIcons(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIcons() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.carEscapeTurnTypes,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTurnIcon(Icons.arrow_upward, l10n.carEscapeStraight),
            _buildTurnIcon(Icons.turn_left, l10n.carEscapeLeft),
            _buildTurnIcon(Icons.turn_right, l10n.carEscapeRight),
            _buildTurnIcon(Icons.u_turn_left, l10n.carEscapeUturn),
          ],
        ),
      ],
    );
  }

  Widget _buildTurnIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRuleSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          l10n.carEscape,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: _showRulesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white70),
            onPressed: () => _showHintWithAd(l10n),
            tooltip: l10n.hint,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _generatePuzzle,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loading,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoCard(
                          icon: Icons.directions_car,
                          label: l10n.carEscapeMovesLabel,
                          value: '$_clearedCars / $_totalCars',
                        ),
                        _buildInfoCard(
                          icon: Icons.timer,
                          label: l10n.time,
                          value: _elapsedTime,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _puzzle != null
                        ? CarEscapeBoard(
                            puzzle: _puzzle!,
                            onCarTap: _onCarTap,
                            onCarExited: _onCarExited,
                            hintCarId: _hintCarId,
                          )
                        : const SizedBox(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.carEscapeInstruction,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
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
}
