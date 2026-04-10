import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'help_widgets.dart';

class KingdomLifeHelpView extends StatelessWidget {
  const KingdomLifeHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9B7ED4); // purple/spiritual
    const golden = MyWalkColor.golden;
    const sage = MyWalkColor.sage;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Kingdom Life — Help'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            const HelpHero(
              icon: Icons.auto_stories_outlined,
              accentColor: accent,
              title: 'Kingdom Life',
              subtitle:
                  'Biblical content to deepen your faith\nand grow in godly character.',
            ),

            // ── Features ──────────────────────────────────────────────────
            const HelpSectionTitle(title: 'Available content'),
            HelpFeatureGrid(
              cards: const [
                HelpFeatureCard(
                  icon: Icons.spa_outlined,
                  iconColor: sage,
                  iconBg: Color(0x267A9E7E),
                  title: 'Fruit of the Spirit',
                  description:
                      'Explore all 9 fruits from Galatians 5 and how to cultivate them.',
                ),
                HelpFeatureCard(
                  icon: Icons.person_outlined,
                  iconColor: MyWalkColor.warmCoral,
                  iconBg: Color(0x1AD4836B),
                  title: 'Women of Valor',
                  description:
                      'Wisdom and character from Proverbs 31 — free for all.',
                ),
                HelpFeatureCard(
                  icon: Icons.volunteer_activism_outlined,
                  iconColor: accent,
                  iconBg: Color(0x1A9B7ED4),
                  title: 'How to Pray',
                  description:
                      'A step-by-step guide rooted in the Lord\'s Prayer (Matthew 6:9–13).',
                ),
                HelpFeatureCard(
                  icon: Icons.star_outline,
                  iconColor: golden,
                  iconBg: Color(0x26D4A843),
                  title: 'Premium Content',
                  description:
                      'The Beatitudes, Parables of Jesus, and the I AM Sayings — unlock with premium.',
                ),
              ],
            ),

            // ── Content map ───────────────────────────────────────────────
            const HelpSectionTitle(title: 'Content map'),
            _ContentMap(),

            // ── Steps ─────────────────────────────────────────────────────
            const HelpSectionTitle(title: 'How to use'),
            const HelpStep(
              number: 1,
              icon: Icons.touch_app_outlined,
              accentColor: accent,
              title: 'Tap any content card',
              description:
                  'Each card opens a dedicated screen with teachings, scripture, and reflections.',
            ),
            const HelpStep(
              number: 2,
              icon: Icons.lock_open_outlined,
              accentColor: sage,
              title: 'Free content — always available',
              description:
                  'Fruit of the Spirit, Women of Valor, and How to Pray are free for every user.',
            ),
            const HelpStep(
              number: 3,
              icon: Icons.star_outline,
              accentColor: golden,
              title: 'Unlock premium content',
              description:
                  'The Beatitudes, Parables, and I AM Sayings are premium. Tap any premium card to upgrade.',
              isLast: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ContentMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Free section
          _ContentSection(
            label: 'FREE',
            labelColor: MyWalkColor.sage,
            items: const [
              _ContentItem(
                icon: Icons.spa_outlined,
                color: MyWalkColor.sage,
                title: 'Fruit of the Spirit',
                ref: 'Galatians 5:22–23',
              ),
              _ContentItem(
                icon: Icons.person_outlined,
                color: MyWalkColor.warmCoral,
                title: 'Women of Valor',
                ref: 'Proverbs 31:10',
              ),
              _ContentItem(
                icon: Icons.volunteer_activism_outlined,
                color: Color(0xFF9B7ED4),
                title: 'How to Pray',
                ref: 'Matthew 6:9–13',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Premium section
          _ContentSection(
            label: 'PREMIUM',
            labelColor: MyWalkColor.golden,
            items: const [
              _ContentItem(
                icon: Icons.format_list_numbered_outlined,
                color: MyWalkColor.golden,
                title: 'The Beatitudes',
                ref: 'Matthew 5:3–12',
              ),
              _ContentItem(
                icon: Icons.auto_stories_outlined,
                color: MyWalkColor.golden,
                title: 'Parables of Jesus',
                ref: 'Mark 4:30',
              ),
              _ContentItem(
                icon: Icons.brightness_7_outlined,
                color: MyWalkColor.golden,
                title: 'I AM Sayings',
                ref: 'Gospel of John',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String label;
  final Color labelColor;
  final List<_ContentItem> items;

  const _ContentSection({
    required this.label,
    required this.labelColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: labelColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...items.expand((item) => [
                item,
                if (item != items.last)
                  Divider(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.07),
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                  ),
              ]),
        ],
      ),
    );
  }
}

class _ContentItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String ref;

  const _ContentItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ref,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
            size: 18,
          ),
        ],
      ),
    );
  }
}
