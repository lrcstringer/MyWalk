import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../theme/app_theme.dart';
import 'fruit_detail_view.dart';
import 'fruit_library_view.dart';

class FruitPortfolioView extends StatelessWidget {
  const FruitPortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FruitPortfolioProvider>();
    final portfolio = provider.portfolio;

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
                    'assets/fruit/Header.webp',
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
                          'The Fruit of the Spirit',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Galatians 5:22\u201323',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyWalkColor.sage.withValues(alpha: 0.9),
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
                  // John 15:8
                  Text(
                    '\u201cThis is to my Father\u2019s glory, that you bear much fruit, showing yourselves to be my disciples.\u201d',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2014 John 15:8',
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.softGold.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Galatians 5:22-23
                  Text(
                    '\u201cThe fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control.\u201d',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2014 Galatians 5:22\u201323',
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.softGold.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'These nine qualities are not habits to master \u2014 they are the natural fruit of a life connected to the vine \u2014 what the Holy Spirit produces in you as you walk with God day by day, love others and trust His Word. Like fruit on a branch, they are not forced.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap any fruit to explore what it means, how to recognise the fruit growing in you, and what practices may help create the conditions for the Spirit\u2019s work in your life.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
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
                          'Learn more about the Fruit of the Spirit',
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

          // ── Fruit grid ───────────────────────────────────────────────────
          if (provider.isLoading && portfolio == null)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: MyWalkColor.golden)),
            )
          else if (portfolio == null)
            const SliverFillRemaining(child: Center(child: _EmptyState()))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 100,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final fruit = FruitType.values[i];
                    final entry = portfolio.entryFor(fruit);
                    return _FruitTile(
                      fruit: fruit,
                      entry: entry,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FruitDetailView(fruit: fruit)),
                      ),
                    );
                  },
                  childCount: FruitType.values.length,
                ),
              ),
            ),

            // Weekly summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _WeeklySummary(portfolio: portfolio),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
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
                  Icon(Icons.eco, size: 18, color: MyWalkColor.sage),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The Fruit of the Spirit',
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
                'Galatians 5:22\u201323 \u2014 a scholarly study',
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
                  // ── THE SETTING OF THE FRUIT OF THE SPIRIT ──────────────
                  _lmSectionHeader('THE SETTING OF THE FRUIT OF THE SPIRIT'),
                  _lmPara(
                    'Paul\u2019s Letter to the Galatians is addressed to churches being pressured by \u2018agitators\u2019 \u2014 Jewish-Christian teachers insisting that Gentile converts must be circumcised and observe the Mosaic Law to be fully saved. The fruit of the Spirit (5:22\u201323) stands at the centre of the letter\u2019s practical section (5:13\u20136:10), framed by the call to \u2018walk by the Spirit\u2019 (5:16, 25) and to \u2018sow to the Spirit\u2019 (6:8).',
                  ),
                  _lmPara(
                    'Paul has just listed the \u2018works of the flesh\u2019 (5:19\u201321) and warned that those who practise such things \u2018will not inherit the Kingdom of God.\u2019 The fruit of the Spirit is his positive counterpart: this is what life in the Spirit actually produces. The contrast between \u2018works\u2019 (\u1f14\u03c1\u03b3\u03b1, plural) and \u2018fruit\u2019 (\u03ba\u03b1\u03c1\u03c0\u03cc\u03c2, singular) is theologically deliberate. The flesh produces fragmented, competing acts of self-assertion; the Spirit produces a unified, organic character. The singular \u2018fruit\u2019 insists that these nine qualities are not a checklist of independent virtues but a single, integrated character \u2014 the character of Christ himself, reproduced in the believer by the Spirit.',
                  ),
                  _lmPara(
                    'The argument climaxes in the closing phrase: \u2018against such things there is no law\u2019 (5:23b). The agitators insisted the Law was necessary to restrain moral chaos. Paul answers: the Spirit produces everything the Law aimed at \u2014 and more. The nine qualities are commonly grouped into three triads: (1) love, joy, peace \u2014 the believer\u2019s disposition toward God; (2) patience, kindness, goodness \u2014 the believer\u2019s conduct toward others; (3) faithfulness, gentleness, self-control \u2014 the believer\u2019s governance of the self. The list is explicitly not exhaustive \u2014 the closing phrase \u2018such things\u2019 indicates representative rather than comprehensive enumeration.',
                  ),
                  const SizedBox(height: 8),
                  _lmDivider(),
                  const SizedBox(height: 16),
                  // ── SCHOLARLY NOTE ON STRUCTURE ──────────────────────────
                  _lmSectionHeader('SCHOLARLY NOTE ON STRUCTURE'),
                  _lmPara(
                    'The nine qualities in Galatians 5:22\u201323 are commonly grouped into three triads by most commentators (Longenecker, Bruce, Moo), though the text itself provides no explicit markers. Fee (God\u2019s Empowering Presence, 1994) cautions against over-systematising the list: the triadic grouping is a reading aid, not a theological claim. Betz (Hermeneia, 1979) notes that ancient catalogues of virtues (and vices) were common in Stoic and Jewish literature, but Paul\u2019s list differs in one crucial respect: these qualities are not achieved by moral effort but received as the Spirit\u2019s gift and product of life in Christ. Martyn (Anchor Bible, 1997) emphasises that the singular \u03ba\u03b1\u03c1\u03c0\u03cc\u03c2 (fruit) stands over against the plural \u1f14\u03c1\u03b3\u03b1 (works) as Paul\u2019s sharpest rhetorical contrast: the flesh multiplies chaotic acts; the Spirit produces one unified life.',
                  ),
                  const SizedBox(height: 8),
                  _lmDivider(),
                  const SizedBox(height: 16),
                  // ── Works Cited in the Module ────────────────────────────
                  const _WorksCitedExpansion(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lmSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold,
            letterSpacing: 0.8,
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

  Widget _lmDivider() => Divider(
        color: MyWalkColor.golden.withValues(alpha: 0.15),
        height: 1,
      );
}

// ── Fruit Tile ─────────────────────────────────────────────────────────────────

class _FruitTile extends StatelessWidget {
  final FruitType fruit;
  final FruitPortfolioEntry entry;
  final VoidCallback onTap;

  const _FruitTile({
    required this.fruit,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = entry.habitCount > 0 && entry.weeklyCompletions > 0;
    final isDormant = entry.habitCount > 0 && entry.weeklyCompletions == 0;

    final double imageOpacity = isActive ? 1.0 : isDormant ? 0.7 : 0.45;
    final double borderWidth = isActive ? 2.0 : 1.5;
    final double borderOpacity = isActive ? 0.9 : isDormant ? 0.6 : 0.35;
    final double fgOpacity = isActive ? 1.0 : isDormant ? 0.9 : 0.7;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fruit.color.withValues(alpha: borderOpacity),
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Opacity(
                opacity: imageOpacity,
                child: Image.asset(fruit.imagePath, fit: BoxFit.cover),
              ),
              // Gradient scrim for text legibility
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              // Icon — top left
              Positioned(
                top: 7,
                left: 8,
                child: Icon(
                  fruit.icon,
                  size: 18,
                  color: Colors.white.withValues(alpha: fgOpacity),
                  shadows: const [
                    Shadow(blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
              // Weekly count badge — top right
              if (entry.weeklyCompletions > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: fruit.color.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.weeklyCompletions}\u00d7',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Fruit name — bottom left
              Positioned(
                bottom: 7,
                left: 8,
                right: 8,
                child: Text(
                  fruit.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                    color: Colors.white.withValues(alpha: fgOpacity),
                    shadows: const [
                      Shadow(
                          blurRadius: 6,
                          color: Colors.black54,
                          offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekly Summary ─────────────────────────────────────────────────────────────

class _WeeklySummary extends StatelessWidget {
  final FruitPortfolio portfolio;

  const _WeeklySummary({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final activeFruits = portfolio.activeFruits.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Your habits and practices this week touched on $activeFruits ${activeFruits == 1 ? 'fruit' : 'fruits'}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: MyWalkColor.softGold.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined,
              size: 48, color: MyWalkColor.sage.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          const Text(
            "Your habits aren't connected to the fruit yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 8),
          Text(
            'Want to add some purpose?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.softGold.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FruitLibraryView()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse the fruit library',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Works Cited Expansion ─────────────────────────────────────────────────────

class _WorksCitedExpansion extends StatelessWidget {
  const _WorksCitedExpansion();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          title: const Text(
            'Works Cited in the Module',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
            ),
          ),
          iconColor: MyWalkColor.softGold,
          collapsedIconColor: MyWalkColor.softGold,
          children: [
            _entry('Betz, Hans Dieter. Galatians. Hermeneia. Philadelphia: Fortress, 1979.'),
            _entry('Bruce, F. F. The Epistle to the Galatians. NIGTC. Grand Rapids: Eerdmans, 1982.'),
            _entry('Dunn, James D. G. The Epistle to the Galatians. BNTC. London: A&C Black, 1993.'),
            _entry('Fee, Gordon D. God\u2019s Empowering Presence. Peabody: Hendrickson, 1994.'),
            _entry('Hays, Richard B. \u201cThe Letter to the Galatians.\u201d NIB, vol.\u00a011. Nashville: Abingdon, 2000.'),
            _entry('Longenecker, Richard N. Galatians. WBC\u00a041. Dallas: Word, 1990.'),
            _entry('Martyn, J. Louis. Galatians. Anchor Bible 33A. New York: Doubleday, 1997.'),
            _entry('Moo, Douglas J. Galatians. BECNT. Grand Rapids: Baker Academic, 2013.'),
            _entry('Schreiner, Thomas R. Galatians. ZECNT. Grand Rapids: Zondervan, 2010.'),
            _entry('Witherington, Ben, III. Grace in Galatia. Grand Rapids: Eerdmans, 1998.'),
            _entry('Wright, N.\u00a0T. Paul and the Faithfulness of God. 2 vols. Minneapolis: Fortress, 2013.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: MyWalkColor.sage.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A NOTE ON PRIMARY SOURCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.softGold.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ancient sources referenced in the commentary include: Aristotle (Nicomachean Ethics), Plato (Republic; Phaedrus), the Wisdom of Sirach, the Testaments of the Twelve Patriarchs, Jerome (Commentary on Galatians), and Tertullian. Greek lexical references cite BDAG (Bauer, Danker, Arndt, and Gingrich, A Greek-English Lexicon of the New Testament, 3rd ed., 2000). The Greek New Testament is cited from the Nestle-Aland 28th edition / UBS 5th edition. Scripture quotations are from the World English Bible (WEB), a public-domain translation.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
            height: 1.55,
          ),
        ),
      );
}

