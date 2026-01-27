import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../services/ad_service.dart';
import 'game_screen.dart';
import '../maze/maze_screen.dart';
import '../parking_jam/parking_screen.dart';
import '../parking_jam/models/parking_models.dart';
import '../car_escape/car_escape_screen.dart';
import '../car_escape/models/car_escape_models.dart';
import '../tap_master/tap_master_screen.dart';
import '../tap_master/models/tap_master_models.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.loadBannerAd(onAdLoaded: () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _adService.disposeBannerAd();
    super.dispose();
  }

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
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate tile size to fit all 6 tiles on screen (3 rows x 2 cols)
                  final padding = 16.0;
                  final spacing = 12.0;
                  final availableWidth = constraints.maxWidth - (padding * 2) - spacing;
                  final availableHeight = constraints.maxHeight - (padding * 2) - (spacing * 2);
                  final tileWidth = availableWidth / 2;
                  final tileHeight = availableHeight / 3;
                  // Use the smaller ratio to ensure tiles fit both dimensions
                  final aspectRatio = tileWidth / tileHeight;

                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                      children: [
                        _buildGameTile(
                          context: context,
                          title: l10n.arrowMaze,
                          icon: Icons.arrow_forward,
                          color: const Color(0xFF4ECDC4),
                          onTap: () => _showArrowMazeDifficultyDialog(context, l10n),
                        ),
                        _buildGameTile(
                          context: context,
                          title: l10n.maze,
                          icon: Icons.grid_4x4,
                          color: Colors.purple,
                          onTap: () => _showMazeDifficultyDialog(context, l10n),
                        ),
                        _buildGameTile(
                          context: context,
                          title: l10n.parkingJam,
                          icon: Icons.local_parking,
                          color: Colors.orange,
                          onTap: () => _showParkingJamDifficultyDialog(context, l10n),
                        ),
                        _buildGameTile(
                          context: context,
                          title: l10n.carEscape,
                          icon: Icons.directions_car,
                          color: Colors.green,
                          onTap: () => _showCarEscapeDifficultyDialog(context, l10n),
                        ),
                        _buildGameTile(
                          context: context,
                          title: l10n.tapMaster,
                          icon: Icons.touch_app,
                          color: const Color(0xFFFF6B6B),
                          onTap: () => _showTapMasterDifficultyDialog(context, l10n),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_adService.isBannerAdReady && _adService.bannerAd != null)
              Container(
                color: const Color(0xFF1A1A2E),
                width: _adService.bannerAd!.size.width.toDouble(),
                height: _adService.bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _adService.bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate sizes based on tile dimensions
        final tileSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final iconContainerSize = tileSize * 0.35;
        final iconSize = iconContainerSize * 0.55;
        final fontSize = tileSize * 0.1;
        final spacing = tileSize * 0.06;
        final borderRadius = tileSize * 0.08;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D2D44),
                  color.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: iconSize, color: color),
                ),
                SizedBox(height: spacing),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize.clamp(12.0, 20.0),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  void _showParkingJamDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.selectDifficulty, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildParkingJamDifficultyOption(
              context: context,
              title: '${l10n.easy} (10x10)',
              difficulty: ParkingDifficulty.easy,
            ),
            _buildParkingJamDifficultyOption(
              context: context,
              title: '${l10n.normal} (15x15)',
              difficulty: ParkingDifficulty.medium,
            ),
            _buildParkingJamDifficultyOption(
              context: context,
              title: '${l10n.hard} (20x20)',
              difficulty: ParkingDifficulty.hard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingJamDifficultyOption({
    required BuildContext context,
    required String title,
    required ParkingDifficulty difficulty,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      leading: const Icon(Icons.local_parking, color: Colors.orange),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParkingScreen(difficulty: difficulty),
          ),
        );
      },
    );
  }

  void _showCarEscapeDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.selectDifficulty, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCarEscapeDifficultyOption(
              context: context,
              title: '${l10n.easy} (5x5, 4 ${l10n.carEscapeIntersections})',
              difficulty: CarEscapeDifficulty.easy,
            ),
            _buildCarEscapeDifficultyOption(
              context: context,
              title: '${l10n.normal} (8x8, 6 ${l10n.carEscapeIntersections})',
              difficulty: CarEscapeDifficulty.medium,
            ),
            _buildCarEscapeDifficultyOption(
              context: context,
              title: '${l10n.hard} (12x12, 12 ${l10n.carEscapeIntersections})',
              difficulty: CarEscapeDifficulty.hard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarEscapeDifficultyOption({
    required BuildContext context,
    required String title,
    required CarEscapeDifficulty difficulty,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      leading: const Icon(Icons.directions_car, color: Colors.green),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarEscapeScreen(difficulty: difficulty),
          ),
        );
      },
    );
  }

  void _showTapMasterDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(l10n.selectDifficulty, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTapMasterDifficultyOption(
              context: context,
              title: '${l10n.easy} (3×3×6)',
              difficulty: TapMasterDifficulty.easy,
            ),
            _buildTapMasterDifficultyOption(
              context: context,
              title: '${l10n.normal} (5×5×10)',
              difficulty: TapMasterDifficulty.medium,
            ),
            _buildTapMasterDifficultyOption(
              context: context,
              title: '${l10n.hard} (7×7×14)',
              difficulty: TapMasterDifficulty.hard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: const TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  Widget _buildTapMasterDifficultyOption({
    required BuildContext context,
    required String title,
    required TapMasterDifficulty difficulty,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      leading: const Icon(Icons.touch_app, color: Color(0xFFFF6B6B)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TapMasterScreen(difficulty: difficulty),
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
