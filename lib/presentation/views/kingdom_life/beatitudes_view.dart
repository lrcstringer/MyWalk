import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../domain/entities/beatitude.dart';
import '../../theme/app_theme.dart';
import 'beatitude_detail_view.dart';
import 'bible_project_browser_view.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudesView extends StatelessWidget {
  const BeatitudesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Artistic Header ──────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/beatitudes_golden_etched_separate/Beatitudes.jpg',
                    fit: BoxFit.cover,
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
                          'The Beatitudes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matthew 5:3\u201312',
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

          // ── Intro content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In the most famous sermon ever preached, Jesus opened with eight declarations that turned the world\u2019s values upside down. The Beatitudes are not rules to follow or achievements to unlock \u2014 they are a portrait of a life shaped by the Kingdom of God.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _BibleProjectVideoCard(),
                  const SizedBox(height: 20),
                  Text(
                    'They move from the inside out: beginning with humility before God, moving through surrender and desire, and flowing outward into mercy, peace and costly faithfulness in the world.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap any Beatitude to explore what Jesus meant, what it looks like in daily life, and how to grow into it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Learn more link
                  GestureDetector(
                    onTap: () => _showLearnMore(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn more about the Beatitudes',
                          style: TextStyle(
                            fontSize: 13,
                            color: MyWalkColor.golden.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: MyWalkColor.golden.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── 4 rows × 2 cards ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final b = kBeatitudes[i];
                  return _BeatitudeCard(
                    beatitude: b,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BeatitudeDetailView(beatitude: b),
                      ),
                    ),
                  );
                },
                childCount: kBeatitudes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLearnMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.self_improvement, size: 18, color: _kAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The Beatitudes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'The setting, structure and scholarship behind Matthew 5:3\u201312',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // ── Section 1 ──────────────────────────────────────────────
                  _lmSectionHeader('THE SETTING OF THE BEATITUDES'),
                  _lmPara('The Beatitudes (Matt 5:3\u201310) open the Sermon on the Mount, the first of Matthew\'s five great discourses (5\u20137; 10; 13; 18; 23\u201325). Matthew sets the scene deliberately: Jesus sees the crowds, ascends a mountain, sits down \u2014 the posture of a rabbinic teacher \u2014 and his disciples draw near. The mountain setting echoes Sinai and positions Jesus as the new Moses who does not merely transmit Torah but speaks on his own authority: \'But I say to you\u2026\' (5:22ff.).'),
                  _lmPara('The word makarios, translated \'blessed,\' is drawn from the wisdom literature of the OT (Ps 1:1; 2:12; 32:1\u20132; Prov 3:13) and the prophets (Isa 56:2). In the Hellenistic world it described the happiness of the gods \u2014 a state beyond ordinary human reach. Jesus applies it to people who, by every ordinary measure, appear to lack what flourishing requires: the poor, the grieving, the meek, the persecuted. This is the Beatitudes\' central provocation.'),
                  _lmPara('Each beatitude has a bipartite structure: a condition (those who\u2026) followed by a promise (for they shall\u2026). The promises operate on two tenses: some \u2014 \'theirs is the kingdom\' \u2014 are present; most \u2014 \'they shall be comforted,\' \'they shall inherit\' \u2014 are future. Scholars debate whether the future promises are purely eschatological or inaugurated \u2014 partially present now, fully realised at the end. The majority position is that Jesus announces a reality already breaking into the present through his own ministry, to be consummated at the eschaton.'),
                  _lmDivider(),

                  // ── Section 2 ──────────────────────────────────────────────
                  _lmSectionHeader('SCHOLARLY NOTE: THE SERMON IN MATTHEW AND LUKE'),
                  _lmPara('The relationship between Matthew\'s Sermon on the Mount (chs. 5\u20137) and Luke\'s Sermon on the Plain (6:20\u201349) has generated extensive scholarly debate. The prevailing explanation is that both evangelists drew on a common sayings source (Q), shaped according to each author\'s theological purposes. Luke\'s version is shorter and more socially direct: four beatitudes, addressed in the second person, accompanied by four corresponding woes. Matthew\'s is expanded, moves \'poor\' to \'poor in spirit,\' and presents a comprehensive account of Kingdom ethics structured around six antitheses.'),
                  _lmPara('The question of whether the Sermon was delivered as a single address is secondary to its function in Matthew\'s narrative. Most modern scholars \u2014 Luz, Betz, Davies and Allison \u2014 regard it as a Matthean composition gathering material from various points in Jesus\'s ministry into a unified discourse. This does not diminish its authority. Matthew\'s editorial arrangement is itself an act of Spirit-guided interpretation, presenting the vision of Kingdom life that Jesus both taught and embodied as a coherent whole.'),
                  _lmDivider(),

                  // ── Works Cited ────────────────────────────────────────────
                  const _BeatitudesWorksCitedExpansion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lmSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _kAccent.withValues(alpha: 0.85),
          ),
        ),
      );

  Widget _lmPara(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.65,
          ),
        ),
      );

  Widget _lmDivider() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Divider(color: Colors.white.withValues(alpha: 0.07)),
      );
}

// ── Bible Project Video Card ──────────────────────────────────────────────────

class _BibleProjectVideoCard extends StatefulWidget {
  const _BibleProjectVideoCard();

  @override
  State<_BibleProjectVideoCard> createState() => _BibleProjectVideoCardState();
}

class _BibleProjectVideoCardState extends State<_BibleProjectVideoCard> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  static const _videoUrl =
      'https://stream.mux.com/83STGVxtcO01902cUvy00g1SJzT4xju2no7DTh9pCZJvRE/high.mp4';

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
              'Watch a 5 min. intro to the Sermon on the Mount',
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

// ── Beatitude Card ────────────────────────────────────────────────────────────

class _BeatitudeCard extends StatelessWidget {
  final BeatitudeModel beatitude;
  final VoidCallback onTap;

  const _BeatitudeCard({required this.beatitude, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: MyWalkColor.golden.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Image.asset(
                  beatitude.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                color: MyWalkColor.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beatitude.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      beatitude.verseRef,
                      style: TextStyle(
                        fontSize: 10,
                        color: _kAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Works Cited ───────────────────────────────────────────────────────────────

class _BeatitudesWorksCitedExpansion extends StatelessWidget {
  const _BeatitudesWorksCitedExpansion();

  @override
  Widget build(BuildContext context) {
    const accent = _kAccent;
    const entries = [
      _WorksCitedEntry(
        author: 'Allison, Dale C.',
        title: 'The Sermon on the Mount: Inspiring the Moral Imagination.',
        publisher: 'New York: Crossroad, 1999.',
      ),
      _WorksCitedEntry(
        author: 'Betz, Hans Dieter.',
        title: 'The Sermon on the Mount.',
        publisher: 'Hermeneia. Minneapolis: Fortress Press, 1995.',
      ),
      _WorksCitedEntry(
        author: 'Davies, W. D., and Dale C. Allison Jr.',
        title: 'A Critical and Exegetical Commentary on the Gospel According to Saint Matthew. Vol. 1.',
        publisher: 'ICC. Edinburgh: T\u0026T Clark, 1988.',
      ),
      _WorksCitedEntry(
        author: 'France, R. T.',
        title: 'The Gospel of Matthew.',
        publisher: 'NICNT. Grand Rapids: Eerdmans, 2007.',
      ),
      _WorksCitedEntry(
        author: 'Hagner, Donald A.',
        title: 'Matthew 1\u201313.',
        publisher: 'WBC 33A. Dallas: Word Books, 1993.',
      ),
      _WorksCitedEntry(
        author: 'Luz, Ulrich.',
        title: 'Matthew 1\u20137: A Commentary.',
        publisher: 'Hermeneia. Minneapolis: Fortress Press, 2007.',
      ),
      _WorksCitedEntry(
        author: 'Wright, N. T.',
        title: 'Jesus and the Victory of God.',
        publisher: 'Minneapolis: Fortress Press, 1996.',
      ),
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        leading: Icon(Icons.menu_book_outlined, size: 16, color: accent.withValues(alpha: 0.6)),
        title: Text(
          'Works Cited',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent.withValues(alpha: 0.75),
          ),
        ),
        iconColor: accent.withValues(alpha: 0.5),
        collapsedIconColor: accent.withValues(alpha: 0.4),
        children: [
          const SizedBox(height: 4),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                      height: 1.55,
                    ),
                    children: [
                      TextSpan(
                        text: '${e.author} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '${e.title} ',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: e.publisher),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'Primary sources: Hebrew Bible / LXX; Mishnah (Pirqe Avot 1:2); Dead Sea Scrolls (1QH, 1QM); 2 Maccabees 6\u20137; Wisdom of Solomon; Sirach; Aristotle, Nicomachean Ethics; BDAG (3rd ed.); NA28/UBS5 Greek New Testament; WEB (World English Bible).',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WorksCitedEntry {
  final String author;
  final String title;
  final String publisher;
  const _WorksCitedEntry({
    required this.author,
    required this.title,
    required this.publisher,
  });
}
