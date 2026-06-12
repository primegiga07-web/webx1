import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../auth_theme.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _initialized = false;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Can be used to show page load progress if needed
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final adUnitId = Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('AdMob Banner failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
      final gameUrl = args['gameUrl']!;
      _controller.loadRequest(Uri.parse(gameUrl));
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final gameTitle = args['gameTitle'] ?? 'Game';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AuthTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          gameTitle,
          style: const TextStyle(
            fontFamily: AuthTheme.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18.0,
            color: AuthTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AuthTheme.textDark),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
            _buildAdBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Elegant fallback during loading or when ad server is unreachable
    return Container(
      height: 50.0,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Text(
          'Google AdMob Test Banner Ad',
          style: TextStyle(
            fontFamily: AuthTheme.fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 11.0,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
