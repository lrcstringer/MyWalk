import 'package:flutter/material.dart';
import '../fruit/fruit_portfolio_view.dart';
import '../kingdom_life/beatitudes_view.dart';
import '../kingdom_life/parables_view.dart';
import '../../theme/app_theme.dart';

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
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/Kingdom2.png',
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
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _KingdomCard(
                          imagePath: 'assets/TheFruit.png',
                          title: 'Fruit of the Spirit',
                          subtitle: 'Galatians 5:22-23',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const FruitPortfolioView())),
                        ),
                      ),
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
                      SizedBox(
                        width: cardWidth,
                        child: _KingdomCard(
                          imagePath: 'assets/parables/The return of the prodigal son.jpg',
                          title: 'The Parables of Jesus',
                          subtitle: 'Mark 4:30',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ParablesView())),
                        ),
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

class _KingdomCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _KingdomCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(imagePath, fit: BoxFit.cover),
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
    );
  }
}
