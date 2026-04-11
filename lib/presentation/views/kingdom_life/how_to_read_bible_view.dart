import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';

const _kAccent = Color(0xFFC49A6C); // warm amber — parchment / scripture

class HowToReadBibleView extends StatelessWidget {
  const HowToReadBibleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/readbible2.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.6),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Text(
                      'How to Read the Bible',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Bible has remained one of the most influential books for close on 1\u2009700 years, and in partial form, close on 1\u2009900 years. Its stories, poetry and history have influenced religions, cultures, philosophy, the arts and inspired some of the most enduring characters and plots in some of the greatest literature ever written. For over 30% of the world\u2019s population (and 70% of people in the Global South) it is considered no less than God\u2019s Holy Word. Watch the videos and delve into the themes, literary styles, settings and content of the Bible.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To start, watch Episode\u00a01, \u201cWhat Is the Bible?\u201d and then access the rest of the videos below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _BibleVideoCard(),
                  const SizedBox(height: 32),
                  const _BibleGuideCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Episode 1 Video Card ───────────────────────────────────────────────────────

class _BibleVideoCard extends StatefulWidget {
  const _BibleVideoCard();

  @override
  State<_BibleVideoCard> createState() => _BibleVideoCardState();
}

class _BibleVideoCardState extends State<_BibleVideoCard> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  static const _videoUrl =
      'https://stream.mux.com/hRgtUaEhBl97k3Y3j9GyVG794KP43ULDBu9gL6tGoa8/high.mp4';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle_outline, size: 14, color: _kAccent),
            const SizedBox(width: 6),
            Text(
              'Episode\u00a01: \u201cWhat Is the Bible?\u201d',
              style: TextStyle(
                fontSize: 12,
                color: _kAccent.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MyWalkColor.golden.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _hasError
                  ? _buildOffline()
                  : (_initialized ? _buildPlayer() : _buildLoading()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset('assets/BP_logo_wht.webp', height: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'BibleProject is the author and owner of this video content. To find more BibleProject resources, visit bibleproject.com.',
                style: TextStyle(
                  fontSize: 10,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOffline() => Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 32, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Video unavailable offline',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
              child: const Text('Watch on BibleProject',
                  style: TextStyle(fontSize: 12, color: MyWalkColor.golden)),
            ),
          ],
        ),
      );

  Widget _buildLoading() => Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_kAccent),
            strokeWidth: 2,
          ),
        ),
      );

  Widget _buildPlayer() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return GestureDetector(
          onTap: () =>
              value.isPlaying ? _controller.pause() : _controller.play(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              if (!value.isPlaying)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: _kAccent,
                    bufferedColor: Colors.white.withValues(alpha: 0.3),
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── BibleProject Guide Card (webpage) ─────────────────────────────────────────

class _BibleGuideCard extends StatefulWidget {
  const _BibleGuideCard();

  @override
  State<_BibleGuideCard> createState() => _BibleGuideCardState();
}

class _BibleGuideCardState extends State<_BibleGuideCard> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  static const _guideUrl = 'https://bibleproject.com/videos/what-is-bible/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_guideUrl));
  }

  @override
  Widget build(BuildContext context) {
    final webHeight = MediaQuery.of(context).size.height * 0.65;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More about \u201cWhat Is the Bible?\u201d',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.warmWhite,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: webHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MyWalkColor.golden.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (_hasError)
                  _buildOffline()
                else
                  WebViewWidget(
                    controller: _controller,
                    gestureRecognizers: {
                      Factory<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                if (_isLoading && !_hasError)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(_kAccent),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset('assets/BP_logo_wht.webp', height: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'BibleProject is the author and owner of this webpage content. To find more BibleProject resources, visit bibleproject.com.',
                style: TextStyle(
                  fontSize: 10,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOffline() => Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 32, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Webpage unavailable offline',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
              child: const Text('Open on BibleProject',
                  style: TextStyle(fontSize: 12, color: MyWalkColor.golden)),
            ),
          ],
        ),
      );
}
