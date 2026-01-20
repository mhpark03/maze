import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Arrow Maze strings
      'appTitle': 'Arrow Maze',
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'restart': 'Restart',
      'collision': 'Collision! Arrow returning to position',
      'flying': 'Arrow is flying...',
      'tapArrow': 'Tap an arrow (Remaining: {count})',
      'loading': 'Generating level...',
      'cleared': '{difficulty} Cleared!',
      'errorCount': 'Errors: {count}',
      'perfect': 'Perfect!',
      'nextLevel': 'Next Level',
      'selectDifficulty': 'Select Difficulty',
      'close': 'Close',
      'howToPlay': 'How to Play',
      'help1': '• Tap an arrow to make it fly in its direction',
      'help2': '• If a flying arrow hits another arrow, it returns to its position',
      'help3': '• Error count increases with each collision',
      'help4': '• Clear by removing all arrows!',
      'help5': '• Clear without errors for Perfect!',
      'ok': 'OK',
      'language': 'Language',
      'time': 'Time',
      'hintUsed': 'Hints: {count}',
      'noHint': 'No escapable arrow found',
      // Maze strings
      'maze': 'Maze',
      'mazeName': 'Maze',
      'mazeRulesTitle': 'How to Play',
      'mazeRulesObjective': 'Objective',
      'mazeRulesObjectiveDesc': 'Find your way from the start (purple circle) to the goal (gold circle).',
      'mazeRulesControls': 'Controls',
      'mazeRulesControlsDesc': 'Use arrow buttons or drag the player to move through the maze.',
      'mazeRulesButtons': 'Buttons',
      'mazeRulesButtonsDesc': '• Hint: Shows the path to the goal\n• New Game: Generate a new maze',
      'mazeRulesTips': 'Tips',
      'mazeRulesTipsDesc': 'The path you\'ve traveled is shown in light purple. Try to escape with fewer moves!',
      'mazeCongratulations': 'Congratulations!',
      'mazeEscaped': 'You escaped the maze!',
      'mazeMoves': 'Moves: {count}',
      'mazeTime': 'Time: {time}',
      'mazeMovesLabel': 'Moves',
      'mazeTimeLabel': 'Time',
      'newGame': 'New Game',
      'hint': 'Hint',
      'rules': 'Rules',
      'win': 'You Win!',
      'confirm': 'OK',
      'selectGame': 'Select Game',
      'arrowMaze': 'Arrow Maze',
      'adNotReady': 'Ad not ready. Showing hint for free.',
      'hintConfirmTitle': 'Use Hint',
      'hintConfirmMessage': 'Watch an ad to get a hint?',
      'watch': 'Watch',
      'cancel': 'Cancel',
      // Parking Jam strings
      'parkingJam': 'Parking Escape',
      'parkingCongratulations': 'Congratulations!',
      'parkingCleared': 'All cars have exited!',
      'parkingCars': 'Cars: {count}',
      'parkingCarsLabel': 'Cars',
      'parkingInstruction': 'Tap a car to make it exit in its facing direction',
      'parkingRulesTitle': 'How to Play',
      'parkingRulesObjective': 'Objective',
      'parkingRulesObjectiveDesc': 'Clear all cars from the parking lot by tapping them in the correct order.',
      'parkingRulesControls': 'Controls',
      'parkingRulesControlsDesc': 'Tap a car to make it exit. Each car moves in the direction of its arrow.',
      'parkingRulesTips': 'Tips',
      'parkingRulesTipsDesc': 'A car can only exit if there are no other cars blocking its path. Find the right order to clear all cars!',
    },
    'ko': {
      // Arrow Maze strings
      'appTitle': '화살표 미로',
      'easy': '쉬움',
      'normal': '보통',
      'hard': '어려움',
      'restart': '다시 시작',
      'collision': '충돌! 화살표가 원위치로 돌아갑니다',
      'flying': '화살표가 날아갑니다...',
      'tapArrow': '화살표를 탭하세요 (남은 화살표: {count})',
      'loading': '레벨 생성 중...',
      'cleared': '{difficulty} 클리어!',
      'errorCount': '오류 횟수: {count}',
      'perfect': '완벽!',
      'nextLevel': '다음 난이도',
      'selectDifficulty': '난이도 선택',
      'close': '닫기',
      'howToPlay': '게임 방법',
      'help1': '• 화살표를 탭하면 화살표 방향으로 날아갑니다',
      'help2': '• 날아가는 화살표가 다른 화살표와 부딪히면 원위치로 돌아갑니다',
      'help3': '• 충돌할 때마다 오류 카운트가 증가합니다',
      'help4': '• 모든 화살표를 제거하면 클리어!',
      'help5': '• 오류 없이 클리어하면 완벽!',
      'ok': '확인',
      'language': '언어',
      'time': '시간',
      'hintUsed': '힌트: {count}회',
      'noHint': '탈출 가능한 화살표가 없습니다',
      // Maze strings
      'maze': '미로찾기',
      'mazeName': '미로찾기',
      'mazeRulesTitle': '게임 방법',
      'mazeRulesObjective': '목표',
      'mazeRulesObjectiveDesc': '시작점(보라색 원)에서 도착점(금색 원)까지 길을 찾으세요.',
      'mazeRulesControls': '조작 방법',
      'mazeRulesControlsDesc': '방향 버튼을 누르거나 플레이어를 드래그하여 미로를 이동하세요.',
      'mazeRulesButtons': '버튼',
      'mazeRulesButtonsDesc': '• 힌트: 도착점까지의 경로를 보여줍니다\n• 새 게임: 새로운 미로를 생성합니다',
      'mazeRulesTips': '팁',
      'mazeRulesTipsDesc': '지나온 길은 연한 보라색으로 표시됩니다. 적은 이동으로 탈출해 보세요!',
      'mazeCongratulations': '축하합니다!',
      'mazeEscaped': '미로를 탈출했습니다!',
      'mazeMoves': '이동 횟수: {count}',
      'mazeTime': '시간: {time}',
      'mazeMovesLabel': '이동',
      'mazeTimeLabel': '시간',
      'newGame': '새 게임',
      'hint': '힌트',
      'rules': '규칙',
      'win': '승리!',
      'confirm': '확인',
      'selectGame': '게임 선택',
      'arrowMaze': '화살표 미로',
      'adNotReady': '광고가 준비되지 않았습니다. 무료로 힌트를 제공합니다.',
      'hintConfirmTitle': '힌트 사용',
      'hintConfirmMessage': '광고를 시청하고 힌트를 받으시겠습니까?',
      'watch': '시청',
      'cancel': '취소',
      // Parking Jam strings
      'parkingJam': '주차장 탈출',
      'parkingCongratulations': '축하합니다!',
      'parkingCleared': '모든 차량이 탈출했습니다!',
      'parkingCars': '차량: {count}대',
      'parkingCarsLabel': '차량',
      'parkingInstruction': '차량을 탭하면 바라보는 방향으로 출발합니다',
      'parkingRulesTitle': '게임 방법',
      'parkingRulesObjective': '목표',
      'parkingRulesObjectiveDesc': '올바른 순서로 차량을 탭하여 주차장의 모든 차량을 빼내세요.',
      'parkingRulesControls': '조작 방법',
      'parkingRulesControlsDesc': '차량을 탭하면 출발합니다. 각 차량은 화살표 방향으로 이동합니다.',
      'parkingRulesTips': '팁',
      'parkingRulesTipsDesc': '차량은 앞에 다른 차가 없어야만 출발할 수 있습니다. 올바른 순서를 찾아 모든 차량을 빼내세요!',
    },
    'ja': {
      // Arrow Maze strings
      'appTitle': '矢印迷路',
      'easy': '簡単',
      'normal': '普通',
      'hard': '難しい',
      'restart': 'やり直し',
      'collision': '衝突！矢印が元の位置に戻ります',
      'flying': '矢印が飛んでいます...',
      'tapArrow': '矢印をタップしてください (残り: {count})',
      'loading': 'レベル生成中...',
      'cleared': '{difficulty} クリア！',
      'errorCount': 'エラー回数: {count}',
      'perfect': '完璧！',
      'nextLevel': '次のレベル',
      'selectDifficulty': '難易度選択',
      'close': '閉じる',
      'howToPlay': '遊び方',
      'help1': '• 矢印をタップすると、その方向に飛んでいきます',
      'help2': '• 飛んでいる矢印が他の矢印にぶつかると、元の位置に戻ります',
      'help3': '• 衝突するたびにエラーカウントが増加します',
      'help4': '• すべての矢印を除去するとクリア！',
      'help5': '• エラーなしでクリアすると完璧！',
      'ok': 'OK',
      'language': '言語',
      'time': '時間',
      'hintUsed': 'ヒント: {count}回',
      'noHint': '脱出可能な矢印がありません',
      // Maze strings
      'maze': '迷路',
      'mazeName': '迷路',
      'mazeRulesTitle': '遊び方',
      'mazeRulesObjective': '目標',
      'mazeRulesObjectiveDesc': 'スタート（紫の丸）からゴール（金の丸）まで道を見つけてください。',
      'mazeRulesControls': '操作方法',
      'mazeRulesControlsDesc': '方向ボタンを押すか、プレイヤーをドラッグして迷路を移動します。',
      'mazeRulesButtons': 'ボタン',
      'mazeRulesButtonsDesc': '• ヒント：ゴールまでの経路を表示します\n• 新しいゲーム：新しい迷路を生成します',
      'mazeRulesTips': 'ヒント',
      'mazeRulesTipsDesc': '通った道は薄紫色で表示されます。少ない移動で脱出してみましょう！',
      'mazeCongratulations': 'おめでとうございます！',
      'mazeEscaped': '迷路を脱出しました！',
      'mazeMoves': '移動回数: {count}',
      'mazeTime': '時間: {time}',
      'mazeMovesLabel': '移動',
      'mazeTimeLabel': '時間',
      'newGame': '新しいゲーム',
      'hint': 'ヒント',
      'rules': 'ルール',
      'win': '勝利！',
      'confirm': 'OK',
      'selectGame': 'ゲーム選択',
      'arrowMaze': '矢印迷路',
      'adNotReady': '広告の準備ができていません。ヒントを無料で表示します。',
      'hintConfirmTitle': 'ヒントを使う',
      'hintConfirmMessage': '広告を見てヒントを取得しますか？',
      'watch': '視聴',
      'cancel': 'キャンセル',
      // Parking Jam strings
      'parkingJam': '駐車場脱出',
      'parkingCongratulations': 'おめでとうございます！',
      'parkingCleared': 'すべての車が脱出しました！',
      'parkingCars': '車: {count}台',
      'parkingCarsLabel': '車',
      'parkingInstruction': '車をタップすると向いている方向に出発します',
      'parkingRulesTitle': '遊び方',
      'parkingRulesObjective': '目標',
      'parkingRulesObjectiveDesc': '正しい順序で車をタップして、駐車場のすべての車を出してください。',
      'parkingRulesControls': '操作方法',
      'parkingRulesControlsDesc': '車をタップすると出発します。各車は矢印の方向に移動します。',
      'parkingRulesTips': 'ヒント',
      'parkingRulesTipsDesc': '車は前に他の車がない場合のみ出発できます。正しい順序を見つけてすべての車を出してください！',
    },
    'zh': {
      // Arrow Maze strings
      'appTitle': '箭头迷宫',
      'easy': '简单',
      'normal': '普通',
      'hard': '困难',
      'restart': '重新开始',
      'collision': '碰撞！箭头返回原位',
      'flying': '箭头飞行中...',
      'tapArrow': '点击箭头 (剩余: {count})',
      'loading': '生成关卡中...',
      'cleared': '{difficulty} 通关！',
      'errorCount': '错误次数: {count}',
      'perfect': '完美！',
      'nextLevel': '下一关',
      'selectDifficulty': '选择难度',
      'close': '关闭',
      'howToPlay': '游戏方法',
      'help1': '• 点击箭头，箭头会向其指向的方向飞去',
      'help2': '• 飞行中的箭头碰到其他箭头会返回原位',
      'help3': '• 每次碰撞错误计数增加',
      'help4': '• 移除所有箭头即可通关！',
      'help5': '• 无错误通关即为完美！',
      'ok': '确定',
      'language': '语言',
      'time': '时间',
      'hintUsed': '提示: {count}次',
      'noHint': '没有可逃脱的箭头',
      // Maze strings
      'maze': '迷宫',
      'mazeName': '迷宫',
      'mazeRulesTitle': '游戏方法',
      'mazeRulesObjective': '目标',
      'mazeRulesObjectiveDesc': '从起点（紫色圆圈）找到通往终点（金色圆圈）的路。',
      'mazeRulesControls': '操作方法',
      'mazeRulesControlsDesc': '按方向按钮或拖动玩家在迷宫中移动。',
      'mazeRulesButtons': '按钮',
      'mazeRulesButtonsDesc': '• 提示：显示到终点的路径\n• 新游戏：生成新迷宫',
      'mazeRulesTips': '提示',
      'mazeRulesTipsDesc': '走过的路会以浅紫色显示。尝试用更少的步数逃脱！',
      'mazeCongratulations': '恭喜！',
      'mazeEscaped': '你逃出了迷宫！',
      'mazeMoves': '移动次数: {count}',
      'mazeTime': '时间: {time}',
      'mazeMovesLabel': '移动',
      'mazeTimeLabel': '时间',
      'newGame': '新游戏',
      'hint': '提示',
      'rules': '规则',
      'win': '胜利！',
      'confirm': '确定',
      'selectGame': '选择游戏',
      'arrowMaze': '箭头迷宫',
      'adNotReady': '广告未准备好。免费显示提示。',
      'hintConfirmTitle': '使用提示',
      'hintConfirmMessage': '观看广告获取提示？',
      'watch': '观看',
      'cancel': '取消',
      // Parking Jam strings
      'parkingJam': '停车场逃脱',
      'parkingCongratulations': '恭喜！',
      'parkingCleared': '所有车辆已逃脱！',
      'parkingCars': '车辆: {count}',
      'parkingCarsLabel': '车辆',
      'parkingInstruction': '点击车辆，它会朝着箭头方向出发',
      'parkingRulesTitle': '游戏方法',
      'parkingRulesObjective': '目标',
      'parkingRulesObjectiveDesc': '按正确的顺序点击车辆，将停车场的所有车辆移出。',
      'parkingRulesControls': '操作方法',
      'parkingRulesControlsDesc': '点击车辆即可出发。每辆车都会朝箭头方向移动。',
      'parkingRulesTips': '提示',
      'parkingRulesTipsDesc': '只有前方没有其他车辆时，车辆才能出发。找到正确的顺序，移出所有车辆！',
    },
  };

  // Arrow Maze getters
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get easy => _localizedValues[locale.languageCode]!['easy']!;
  String get normal => _localizedValues[locale.languageCode]!['normal']!;
  String get hard => _localizedValues[locale.languageCode]!['hard']!;
  String get restart => _localizedValues[locale.languageCode]!['restart']!;
  String get collision => _localizedValues[locale.languageCode]!['collision']!;
  String get flying => _localizedValues[locale.languageCode]!['flying']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get perfect => _localizedValues[locale.languageCode]!['perfect']!;
  String get nextLevel => _localizedValues[locale.languageCode]!['nextLevel']!;
  String get selectDifficulty => _localizedValues[locale.languageCode]!['selectDifficulty']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get howToPlay => _localizedValues[locale.languageCode]!['howToPlay']!;
  String get help1 => _localizedValues[locale.languageCode]!['help1']!;
  String get help2 => _localizedValues[locale.languageCode]!['help2']!;
  String get help3 => _localizedValues[locale.languageCode]!['help3']!;
  String get help4 => _localizedValues[locale.languageCode]!['help4']!;
  String get help5 => _localizedValues[locale.languageCode]!['help5']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;

  // Maze getters
  String get maze => _localizedValues[locale.languageCode]!['maze']!;
  String get mazeName => _localizedValues[locale.languageCode]!['mazeName']!;
  String get mazeRulesTitle => _localizedValues[locale.languageCode]!['mazeRulesTitle']!;
  String get mazeRulesObjective => _localizedValues[locale.languageCode]!['mazeRulesObjective']!;
  String get mazeRulesObjectiveDesc => _localizedValues[locale.languageCode]!['mazeRulesObjectiveDesc']!;
  String get mazeRulesControls => _localizedValues[locale.languageCode]!['mazeRulesControls']!;
  String get mazeRulesControlsDesc => _localizedValues[locale.languageCode]!['mazeRulesControlsDesc']!;
  String get mazeRulesButtons => _localizedValues[locale.languageCode]!['mazeRulesButtons']!;
  String get mazeRulesButtonsDesc => _localizedValues[locale.languageCode]!['mazeRulesButtonsDesc']!;
  String get mazeRulesTips => _localizedValues[locale.languageCode]!['mazeRulesTips']!;
  String get mazeRulesTipsDesc => _localizedValues[locale.languageCode]!['mazeRulesTipsDesc']!;
  String get mazeCongratulations => _localizedValues[locale.languageCode]!['mazeCongratulations']!;
  String get mazeEscaped => _localizedValues[locale.languageCode]!['mazeEscaped']!;
  String get mazeMovesLabel => _localizedValues[locale.languageCode]!['mazeMovesLabel']!;
  String get mazeTimeLabel => _localizedValues[locale.languageCode]!['mazeTimeLabel']!;
  String get newGame => _localizedValues[locale.languageCode]!['newGame']!;
  String get hint => _localizedValues[locale.languageCode]!['hint']!;
  String get time => _localizedValues[locale.languageCode]!['time']!;
  String hintUsed(int count) => _localizedValues[locale.languageCode]!['hintUsed']!.replaceAll('{count}', count.toString());
  String get noHint => _localizedValues[locale.languageCode]!['noHint']!;
  String get rules => _localizedValues[locale.languageCode]!['rules']!;
  String get win => _localizedValues[locale.languageCode]!['win']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get selectGame => _localizedValues[locale.languageCode]!['selectGame']!;
  String get arrowMaze => _localizedValues[locale.languageCode]!['arrowMaze']!;
  String get adNotReady => _localizedValues[locale.languageCode]!['adNotReady']!;
  String get hintConfirmTitle => _localizedValues[locale.languageCode]!['hintConfirmTitle']!;
  String get hintConfirmMessage => _localizedValues[locale.languageCode]!['hintConfirmMessage']!;
  String get watch => _localizedValues[locale.languageCode]!['watch']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;

  // Parking Jam getters
  String get parkingJam => _localizedValues[locale.languageCode]!['parkingJam']!;
  String get parkingCongratulations => _localizedValues[locale.languageCode]!['parkingCongratulations']!;
  String get parkingCleared => _localizedValues[locale.languageCode]!['parkingCleared']!;
  String get parkingCarsLabel => _localizedValues[locale.languageCode]!['parkingCarsLabel']!;
  String get parkingInstruction => _localizedValues[locale.languageCode]!['parkingInstruction']!;
  String get parkingRulesTitle => _localizedValues[locale.languageCode]!['parkingRulesTitle']!;
  String get parkingRulesObjective => _localizedValues[locale.languageCode]!['parkingRulesObjective']!;
  String get parkingRulesObjectiveDesc => _localizedValues[locale.languageCode]!['parkingRulesObjectiveDesc']!;
  String get parkingRulesControls => _localizedValues[locale.languageCode]!['parkingRulesControls']!;
  String get parkingRulesControlsDesc => _localizedValues[locale.languageCode]!['parkingRulesControlsDesc']!;
  String get parkingRulesTips => _localizedValues[locale.languageCode]!['parkingRulesTips']!;
  String get parkingRulesTipsDesc => _localizedValues[locale.languageCode]!['parkingRulesTipsDesc']!;

  String parkingCars(int count) =>
      _localizedValues[locale.languageCode]!['parkingCars']!.replaceAll('{count}', count.toString());

  // Methods with parameters
  String tapArrow(int count) =>
      _localizedValues[locale.languageCode]!['tapArrow']!.replaceAll('{count}', count.toString());

  String cleared(String difficulty) =>
      _localizedValues[locale.languageCode]!['cleared']!.replaceAll('{difficulty}', difficulty);

  String errorCount(int count) =>
      _localizedValues[locale.languageCode]!['errorCount']!.replaceAll('{count}', count.toString());

  String mazeMoves(int count) =>
      _localizedValues[locale.languageCode]!['mazeMoves']!.replaceAll('{count}', count.toString());

  String mazeTime(String time) =>
      _localizedValues[locale.languageCode]!['mazeTime']!.replaceAll('{time}', time);

  String getDifficultyName(int difficulty) {
    final names = [easy, normal, hard];
    if (difficulty >= 0 && difficulty < names.length) {
      return names[difficulty];
    }
    return '';
  }

  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
    Locale('zh'),
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'ko': return '한국어';
      case 'ja': return '日本語';
      case 'zh': return '中文';
      default: return code;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ko', 'ja', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
