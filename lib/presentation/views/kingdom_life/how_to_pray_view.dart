import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';

const _kAccent = Color(0xFF7EA8C4); // soft blue — prayer / serenity

class HowToPrayView extends StatelessWidget {
  const HowToPrayView({super.key});

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
                    'assets/crossfeet.webp',
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
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to Pray',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matthew 6:9\u201313',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyWalkColor.golden.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                  const _LordsPrayerBlock(),
                  const SizedBox(height: 32),
                  Text(
                    'Prayer is central to a Christian\u2019s daily walk. It is both a discipline and a joy to pray. Watch the following short video on how Jesus said we should pray.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _LordsPrayerVideoCard(),
                  const SizedBox(height: 32),
                  const _LordsPrayerGuideCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lord's Prayer Text Block ──────────────────────────────────────────────────

class _LordsPrayerBlock extends StatelessWidget {
  const _LordsPrayerBlock();

  static const _lines = [
    'Our Father in heaven,',
    'hallowed be your name.',
    'Your kingdom come,',
    'your will be done,',
    'on earth as it is in heaven.',
    'Give us this day our daily bread,',
    'and forgive us our debts,',
    'as we also have forgiven our debtors.',
    'And lead us not into temptation,',
    'but deliver us from evil.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyWalkColor.golden.withValues(alpha: 0.07),
            MyWalkColor.golden.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: MyWalkColor.golden.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Decorative top rule
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 0.5,
                  color: MyWalkColor.golden.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.circle,
                  size: 5,
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: MyWalkColor.golden.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lead-in
          Text(
            'Pray then like this:',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: MyWalkColor.golden.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Prayer lines
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 17,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.92),
                  height: 1.7,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Reference
          Text(
            'Matthew 6:9\u201313',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: MyWalkColor.golden.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Decorative bottom rule
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 0.5,
                  color: MyWalkColor.golden.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.circle,
                  size: 5,
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: MyWalkColor.golden.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Lord's Prayer Video Card ──────────────────────────────────────────────────

class _LordsPrayerVideoCard extends StatefulWidget {
  const _LordsPrayerVideoCard();

  @override
  State<_LordsPrayerVideoCard> createState() => _LordsPrayerVideoCardState();
}

class _LordsPrayerVideoCardState extends State<_LordsPrayerVideoCard> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  static const _videoUrl =
      'https://stream.mux.com/Ok02b3DgDhHj1pqIXldDtkGTMrkrygpUlJpxaCzqq6K4/high.mp4';

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
              'Watch a 5 min. intro to The Lord\u2019s Prayer',
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
              child: _hasError ? _buildOffline() : (_initialized ? _buildPlayer() : _buildLoading()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/BP_logo_wht.webp',
                height: 16,
              ),
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
            Icon(Icons.wifi_off_rounded, size: 32, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Video unavailable offline',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
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

// ── Lord's Prayer Guide Card (webpage) ────────────────────────────────────────

class _LordsPrayerGuideCard extends StatefulWidget {
  const _LordsPrayerGuideCard();

  @override
  State<_LordsPrayerGuideCard> createState() => _LordsPrayerGuideCardState();
}

class _LordsPrayerGuideCardState extends State<_LordsPrayerGuideCard> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  static const _guideUrl = 'https://bibleproject.com/guides/the-lords-prayer/';

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
        Text(
          'More about \u201cThe Lord\u2019s Prayer\u201d',
          style: const TextStyle(
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
