import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fruit/fruit_portfolio_view.dart';
import '../kingdom_life/beatitudes_view.dart';
import '../kingdom_life/parables_view.dart';
import '../kingdom_life/i_am_sayings_view.dart';
import '../kingdom_life/how_to_pray_view.dart';
import '../kingdom_life/how_to_read_bible_view.dart';
import '../kingdom_life/blue_letter_bible_browser_view.dart';
import '../kingdom_life/women_of_valor_view.dart';
import '../shared/mywalk_paywall_view.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/appbar_actions.dart';
import '../help/kingdom_life_help_view.dart';

class KingdomLifeView extends StatefulWidget {
  const KingdomLifeView({super.key});

  @override
  State<KingdomLifeView> createState() => _KingdomLifeViewState();
}

class _KingdomLifeViewState extends State<KingdomLifeView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset < 20;
    if (shouldShow != _showScrollHint) {
      setState(() => _showScrollHint = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 240,
            pinned: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'MyWalk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              ...standardAppBarActions(context, helpView: const KingdomLifeHelpView()),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/Kingdom2.webp',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.45),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kingdom Life',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Grow in character. Live the Kingdom Way.',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyWalkColor.softGold,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Free row ────────────────────────────────────────
                      Row(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/fruit/Header.webp',
                              title: 'Fruit of the Spirit',
                              subtitle: 'Galatians 5:22-23',
                              imageFit: BoxFit.cover,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const FruitPortfolioView())),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/praying.webp',
                              title: 'How to Pray',
                              subtitle: 'Matthew 6:9\u201313',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const HowToPrayView())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/readbible2.png',
                              title: 'How to Read the Bible',
                              subtitle: 'A BibleProject guide',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const HowToReadBibleView())),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const _BlueLLetterBibleCard(),

                      // ── Premium upsell (non-premium only) ────────────────
                      if (!context.watch<StoreProvider>().isPremium) ...[
                        const SizedBox(height: 12),
                        _PremiumUpsellCard(cardWidth: cardWidth),
                      ],

                      // ── Premium divider ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: MyWalkColor.golden.withValues(alpha: 0.18),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 11, color: MyWalkColor.golden.withValues(alpha: 0.45)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: MyWalkColor.golden.withValues(alpha: 0.45),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(Icons.star_rounded, size: 11, color: MyWalkColor.golden.withValues(alpha: 0.45)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: MyWalkColor.golden.withValues(alpha: 0.18),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Premium grid ─────────────────────────────────────
                      Builder(builder: (ctx) {
                        final isPremium = ctx.watch<StoreProvider>().isPremium;
                        void openOrPaywall(Widget screen) {
                          if (isPremium) {
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
                          } else {
                            showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: MyWalkColor.charcoal,
                              builder: (_) => const MyWalkPaywallView(
                                contextTitle: 'Upgrade for full Kingdom Life access',
                              ),
                            );
                          }
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _KingdomCard(
                                imagePath: 'assets/beatitudes_golden_etched_separate/Beatitudes.jpg',
                                title: 'The Beatitudes',
                                subtitle: 'Matthew 5:3-12',
                                locked: !isPremium,
                                onTap: () => openOrPaywall(const BeatitudesView()),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _KingdomCard(
                                imagePath: 'assets/parables/Header.webp',
                                title: 'The Parables of Jesus',
                                subtitle: 'Mark 4:30',
                                locked: !isPremium,
                                onTap: () => openOrPaywall(const ParablesView()),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _KingdomCard(
                                imagePath: 'assets/Women/womenofvalor.webp',
                                title: 'Women of Valor',
                                subtitle: 'Proverbs 31:10',
                                locked: !isPremium,
                                onTap: () => openOrPaywall(const WomenOfValorView()),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _KingdomCard(
                                imagePath: 'assets/I Am/Header.webp',
                                title: 'The \u201cI AM\u201d Sayings of Jesus',
                                subtitle: 'Gospel of John',
                                locked: !isPremium,
                                onTap: () => openOrPaywall(const IAmSayingsView()),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Bottom gradient fade
      Align(
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MyWalkColor.charcoal.withValues(alpha: 0),
                  MyWalkColor.charcoal,
                ],
              ),
            ),
          ),
        ),
      ),

      // Scroll hint chevron — fades out once user scrolls
      Positioned(
        bottom: 72,
        left: 0,
        right: 0,
        child: AnimatedOpacity(
          opacity: _showScrollHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const IgnorePointer(
            child: _BouncingChevron(),
          ),
        ),
      ),
    ]),
    );
  }
}

class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron();

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 28,
          color: MyWalkColor.softGold.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// ── Kingdom card ───────────────────────────────────────────────────────────────

// ── Premium Upsell Card ────────────────────────────────────────────────────────

class _PremiumUpsellCard extends StatelessWidget {
  final double cardWidth;
  const _PremiumUpsellCard({required this.cardWidth});

  static const _features = [
    (Icons.menu_book_rounded, 'Bible in a Year — 52-week daily reading plan'),
    (Icons.psychology, 'Scripture Memorisation'),
    (Icons.format_list_bulleted, 'The Beatitudes — Matthew 5:3–12'),
    (Icons.auto_stories, 'The Parables of Jesus'),
    (Icons.favorite_border, 'Women of Valor — Proverbs 31'),
    (Icons.record_voice_over_outlined, 'The \u201cI AM\u201d Sayings of Jesus'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyWalkColor.golden.withValues(alpha: 0.10),
            MyWalkColor.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MyWalkColor.golden.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MyWalkColor.golden.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: MyWalkColor.golden.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              const Text(
                'Go Deeper with Premium',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock a full suite of Kingdom Life study tools — work through the entire Bible in a year, memorise scripture, and explore the Beatitudes, the Parables of Jesus, the \u201cI AM\u201d sayings, and Women of Valor in depth.',
            style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Feature list
          for (final (icon, label) in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: MyWalkColor.golden.withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: MyWalkColor.charcoal,
                builder: (_) => const MyWalkPaywallView(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blue Letter Bible card (Free) ─────────────────────────────────────────────

class _BlueLLetterBibleCard extends StatelessWidget {
  const _BlueLLetterBibleCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, BlueLLetterBibleBrowserView.route()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              MyWalkColor.golden.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: MyWalkColor.golden.withValues(alpha: 0.10),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/Stacked BLB Logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search the Bible with Blue Letter Bible',
                    style: TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'blueletterbible.org',
                    style: TextStyle(
                      color: MyWalkColor.softGold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: MyWalkColor.softGold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _KingdomCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final BoxFit imageFit;
  final bool locked;

  const _KingdomCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageFit = BoxFit.cover,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(imagePath, fit: imageFit, alignment: Alignment.topCenter),
              // Dark gradient over bottom half
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC1A1A2E),
                      Color(0xF01A1A2E),
                    ],
                    stops: [0.35, 0.70, 1.0],
                  ),
                ),
              ),
              // Text at bottom
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: MyWalkColor.softGold.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // PRO badge — top-right when locked
              if (locked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: MyWalkColor.golden,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
