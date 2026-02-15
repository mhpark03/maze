import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'game/game_state.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'screens/game_selection_screen.dart';
import 'services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService().initialize();

  // 계정 정지 중에도 코드 레벨에서 테스트 기기를 강제 지정합니다.
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ["7e423abc-74c5-4cb7-9e7b-578adadeb80d"]),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ArrowMazeApp());
}

class ArrowMazeApp extends StatelessWidget {
  const ArrowMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Arrow Maze',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4ECDC4),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const GameSelectionScreen(),
          );
        },
      ),
    );
  }
}
