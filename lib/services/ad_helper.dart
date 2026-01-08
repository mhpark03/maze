import 'dart:io';

class AdHelper {
  // 테스트용 배너 광고 ID (실제 배포시 변경 필요)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // 테스트 배너 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // 테스트 배너 ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
