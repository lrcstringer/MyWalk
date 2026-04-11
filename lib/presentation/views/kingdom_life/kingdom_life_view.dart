import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fruit/fruit_portfolio_view.dart';
import '../kingdom_life/beatitudes_view.dart';
import '../kingdom_life/parables_view.dart';
import '../kingdom_life/i_am_sayings_view.dart';
import '../kingdom_life/how_to_pray_view.dart';
import '../kingdom_life/women_of_valor_view.dart';
import '../bible_reading/bible_reading_grid_view.dart';
import '../../../domain/entities/bible_reading_plan.dart';
import '../../providers/bible_reading_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/appbar_actions.dart';
import '../help/kingdom_life_help_view.dart';

class KingdomLifeView extends StatelessWidget {
  const KingdomLifeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
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
              infoIconAction(context, const KingdomLifeHelpView()),
              ...standardAppBarActions(context),
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
                          const SizedBox(width: 12),
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/beatitudes_golden_etched_separate/Beatitudes.jpg',
                              title: 'The Beatitudes',
                              subtitle: 'Matthew 5:3-12',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const BeatitudesView())),
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
                        ],
                      ),

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
                      const _BibleReadingPlanKingdomCard(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/Women/womenofvalor.webp',
                              title: 'Women of Valor',
                              subtitle: 'Proverbs 31:10',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const WomenOfValorView())),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/parables/Header.webp',
                              title: 'The Parables of Jesus',
                              subtitle: 'Mark 4:30',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ParablesView())),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _KingdomCard(
                              imagePath: 'assets/I Am/Header.webp',
                              title: 'The \u201cI AM\u201d Sayings of Jesus',
                              subtitle: 'Gospel of John',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const IAmSayingsView())),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bible Reading Plan Kingdom card ───────────────────────────────────────────

class _BibleReadingPlanKingdomCard extends StatelessWidget {
  const _BibleReadingPlanKingdomCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BibleReadingProvider>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BibleReadingGridView()),
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MyWalkColor.golden.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: MyWalkColor.golden,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bible in a Year',
                        style: TextStyle(
                          color: MyWalkColor.warmWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Daily reading plan · 52 weeks',
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
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // State-specific body
            _BiblePlanCardBody(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _BiblePlanCardBody extends StatelessWidget {
  final BibleReadingProvider provider;
  const _BiblePlanCardBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (provider.status) {
      case BibleReadingPlanStatus.notStarted:
        return Text(
          'Read through all 66 books in one year — Psalms, New Testament, Torah, Historical, Prophetic, and Wisdom literature. Tap to begin.',
          style: TextStyle(
            color: MyWalkColor.softGold.withValues(alpha: 0.75),
            fontSize: 12,
            height: 1.5,
          ),
        );
      case BibleReadingPlanStatus.pending:
        final days = provider.daysUntilLive ?? 0;
        return Row(
          children: [
            const Icon(Icons.schedule, color: MyWalkColor.golden, size: 14),
            const SizedBox(width: 6),
            Text(
              days == 0
                  ? 'Begins this Sunday'
                  : 'Begins in $days ${days == 1 ? 'day' : 'days'}',
              style: const TextStyle(color: MyWalkColor.softGold, fontSize: 12),
            ),
          ],
        );
      case BibleReadingPlanStatus.active:
        final weekIndex = provider.currentWeekIndex ?? 0;
        final daysRead = provider.totalDaysRead;
        final progress = daysRead / 364.0;
        final streak = provider.state?.streakDays ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week ${weekIndex + 1} of 52',
                  style: const TextStyle(
                    color: MyWalkColor.softGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (streak > 0)
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: MyWalkColor.golden, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '$streak day streak',
                        style: TextStyle(
                          color: MyWalkColor.softGold.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: MyWalkColor.golden.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(MyWalkColor.golden),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$daysRead of 364 days read',
              style: TextStyle(
                color: MyWalkColor.softGold.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        );
    }
  }
}

// ── Kingdom card ───────────────────────────────────────────────────────────────

class _KingdomCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final BoxFit imageFit;

  const _KingdomCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageFit = BoxFit.cover,
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
            ],
          ),
          ),
        ),
      ),
    );
  }
}
