import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  /// Returns true if ads are supported on the current platform (Android/iOS only)
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  bool get isBannerAdReady => _isBannerAdReady;
  BannerAd? get bannerAd => _bannerAd;
  bool get isRewardedAdReady => _isRewardedAdReady;

  String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8361977398389047/7175944409';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8361977398389047/7175944409';
      }
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8361977398389047/4214012791';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8361977398389047/4214012791';
      }
    }
    return '';
  }

  Future<void> initialize() async {
    if (!isSupported) return;
    await MobileAds.instance.initialize();
  }

  void loadBannerAd({required Function() onAdLoaded}) {
    if (!isSupported) return;
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }

  void loadRewardedAd() {
    if (!isSupported) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd({
    required Function() onUserEarnedReward,
    Function()? onAdDismissed,
    Function()? onAdFailedToShow,
  }) {
    if (!isSupported) {
      // On unsupported platforms, grant reward directly
      onUserEarnedReward();
      onAdDismissed?.call();
      return;
    }
    if (_rewardedAd == null) {
      onAdFailedToShow?.call();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        loadRewardedAd();
        onAdFailedToShow?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );
  }

  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
