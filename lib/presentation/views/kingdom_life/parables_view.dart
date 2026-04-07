import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';

const _kAccent = Color(0xFFC8A96E); // warm parchment gold

// ── Data ─────────────────────────────────────────────────────────────────────

class _Parable {
  final String title;
  final String reference;
  final String theme;
  final String? imagePath; // null = icon fallback
  final IconData icon;
  final String summary;

  const _Parable({
    required this.title,
    required this.reference,
    required this.theme,
    this.imagePath,
    required this.icon,
    required this.summary,
  });
}

class _ParableGroup {
  final String heading;
  final List<_Parable> parables;
  const _ParableGroup({required this.heading, required this.parables});
}

const _groups = [
  _ParableGroup(
    heading: 'The Kingdom',
    parables: [
      _Parable(
        title: 'The Sower',
        reference: 'Matthew 13:1\u201323',
        theme: 'The Word',
        imagePath: 'assets/parables/The Kingdom/The Sower.png',
        icon: Icons.grass_rounded,
        summary: 'Seed falls on four soils. What kind of heart receives God\u2019s word and lets it take root?',
      ),
      _Parable(
        title: 'The Mustard Seed',
        reference: 'Matthew 13:31\u201332',
        theme: 'Kingdom Growth',
        imagePath: 'assets/parables/The Kingdom/the Mustard Seed.png',
        icon: Icons.eco_rounded,
        summary: 'The smallest seed becomes the greatest plant. The Kingdom begins unseen and grows beyond imagining.',
      ),
      _Parable(
        title: 'The Hidden Treasure and the Pearl',
        reference: 'Matthew 13:44\u201346',
        theme: 'Wholehearted Commitment',
        imagePath: 'assets/parables/The Kingdom/The Hidden Treasure.png',
        icon: Icons.circle_rounded,
        summary: 'A man sells everything for a field; a merchant for one pearl. Is the Kingdom worth everything to you?',
      ),
      _Parable(
        title: 'The Net',
        reference: 'Matthew 13:47\u201350',
        theme: 'Final Judgment',
        imagePath: 'assets/parables/The Kingdom/The Net.png',
        icon: Icons.water_rounded,
        summary: 'All kinds of fish are gathered, then sorted. The final separation belongs to God \u2014 not us.',
      ),
      _Parable(
        title: 'The Leaven',
        reference: 'Matthew 13:33',
        theme: 'Transformation',
        imagePath: 'assets/parables/The Kingdom/The Leaven.png',
        icon: Icons.blur_circular_rounded,
        summary: 'A little yeast works through all the dough. The Kingdom transforms everything it enters from the inside out.',
      ),
      _Parable(
        title: 'The Wheat and the Weeds',
        reference: 'Matthew 13:24\u201330',
        theme: 'Patience',
        imagePath: 'assets/parables/The Kingdom/WheatandWeeds (2).png',
        icon: Icons.grain_rounded,
        summary: 'Good seed and weeds grow together until harvest. God is patient, and the final judgment is His alone.',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Grace and Forgiveness',
    parables: [
      _Parable(
        title: 'The Prodigal Son',
        reference: 'Luke 15:11\u201332',
        theme: 'God\u2019s Welcome',
        imagePath: 'assets/parables/Grace & Forgiveness/The Prodigal Son.png',
        icon: Icons.favorite_rounded,
        summary: 'A father runs to meet his returning son \u2014 a portrait of God\u2019s extravagant, undeserved welcome.',
      ),
      _Parable(
        title: 'The Lost Sheep',
        reference: 'Luke 15:3\u20137',
        theme: 'God\u2019s Pursuit',
        imagePath: 'assets/parables/Grace & Forgiveness/The Lost Sheep 1.png',
        icon: Icons.search_rounded,
        summary: 'The shepherd leaves the ninety-nine to find the one. Heaven rejoices over one who returns.',
      ),
      _Parable(
        title: 'The Lost Coin',
        reference: 'Luke 15:8\u201310',
        theme: 'God\u2019s Joy',
        imagePath: 'assets/parables/Grace & Forgiveness/The Lost Coin.png',
        icon: Icons.radio_button_checked_rounded,
        summary: 'A woman searches until she finds what was lost. Every single person matters to God.',
      ),
      _Parable(
        title: 'The Unmerciful Servant',
        reference: 'Matthew 18:23\u201335',
        theme: 'Forgiving Others',
        imagePath: 'assets/parables/Grace & Forgiveness/The Unmerciful Servant.png',
        icon: Icons.balance_rounded,
        summary: 'Forgiven an unpayable debt, a servant refuses to forgive a small one. What has God forgiven you?',
      ),
      _Parable(
        title: 'The Pharisee and the Tax Collector',
        reference: 'Luke 18:9\u201314',
        theme: 'Humility',
        imagePath: 'assets/parables/Grace & Forgiveness/The Pharaisee and the Tax Collector.png',
        icon: Icons.volunteer_activism_rounded,
        summary: 'Two men pray. One leaves justified. God opposes the proud but gives grace to the humble.',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Neighbour Love and Service',
    parables: [
      _Parable(
        title: 'The Good Samaritan',
        reference: 'Luke 10:25\u201337',
        theme: 'Love of Neighbour',
        imagePath: 'assets/parables/Neighbour Love and Service/The Good Samaitan.png',
        icon: Icons.handshake_rounded,
        summary: 'A despised outsider shows mercy where the religious pass by. Who is my neighbour?',
      ),
      _Parable(
        title: 'The Sheep and the Goats',
        reference: 'Matthew 25:31\u201346',
        theme: 'Serving the Least',
        imagePath: 'assets/parables/Neighbour Love and Service/The Sheep & The Goats.png',
        icon: Icons.people_rounded,
        summary: 'The King separates those who served the least \u2014 and Him \u2014 from those who did not.',
      ),
      _Parable(
        title: 'The Rich Man and Lazarus',
        reference: 'Luke 16:19\u201331',
        theme: 'Eternal Consequences',
        imagePath: 'assets/parables/Neighbour Love and Service/The Rich Man & Lazarus.png',
        icon: Icons.swap_vert_rounded,
        summary: 'A great reversal awaits. What we do with wealth and indifference has eternal consequences.',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Stewardship and Faithfulness',
    parables: [
      _Parable(
        title: 'The Talents',
        reference: 'Matthew 25:14\u201330',
        theme: 'Faithfulness',
        imagePath: 'assets/parables/Stewardship and Faithfulness/The Talents.png',
        icon: Icons.workspace_premium_rounded,
        summary: 'What we do with what God entrusts to us shapes the life we\u2019re building together with Him.',
      ),
      _Parable(
        title: 'The Ten Minas',
        reference: 'Luke 19:11\u201327',
        theme: 'Fruitfulness',
        imagePath: 'assets/parables/Stewardship and Faithfulness/The Ten Minas.png',
        icon: Icons.trending_up_rounded,
        summary: 'A nobleman gives equal gifts and expects a return. Every follower is called to fruitfulness.',
      ),
      _Parable(
        title: 'The Unjust Steward',
        reference: 'Luke 16:1\u201313',
        theme: 'Eternal Wisdom',
        imagePath: 'assets/parables/Stewardship and Faithfulness/The Unjust Steward.png',
        icon: Icons.calculate_rounded,
        summary: 'A manager acts shrewdly for his future. Jesus calls us to be equally strategic about eternity.',
      ),
      _Parable(
        title: 'The Rich Fool',
        reference: 'Luke 12:16\u201321',
        theme: 'True Wealth',
        imagePath: 'assets/parables/Stewardship and Faithfulness/The Rich Fool.png',
        icon: Icons.savings_rounded,
        summary: 'Bigger barns, no eternity. What does it mean to be rich toward God rather than yourself?',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Prayer and Persistence',
    parables: [
      _Parable(
        title: 'The Persistent Widow',
        reference: 'Luke 18:1\u20138',
        theme: 'Persevering Prayer',
        imagePath: 'assets/parables/Prayer and Persistence/The Persistent Widow.png',
        icon: Icons.record_voice_over_rounded,
        summary: 'A widow keeps coming. God hears those who cry to Him day and night \u2014 and He will act.',
      ),
      _Parable(
        title: 'The Friend at Midnight',
        reference: 'Luke 11:5\u20138',
        theme: 'Boldness in Prayer',
        imagePath: 'assets/parables/Prayer and Persistence/The Friend at Midnight.png',
        icon: Icons.nights_stay_rounded,
        summary: 'Shameless persistence in asking unlocks what reluctance alone would not. Keep asking.',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Readiness and Watchfulness',
    parables: [
      _Parable(
        title: 'The Ten Virgins',
        reference: 'Matthew 25:1\u201313',
        theme: 'Readiness',
        imagePath: 'assets/parables/Readiness and Watchfulness/The Ten Virgins.png',
        icon: Icons.lightbulb_rounded,
        summary: 'Five prepared, five not. Stay ready \u2014 you do not know the day or the hour.',
      ),
      _Parable(
        title: 'The Thief in the Night',
        reference: 'Matthew 24:42\u201344',
        theme: 'Watchfulness',
        imagePath: 'assets/parables/Readiness and Watchfulness/The Thief in the Night.png',
        icon: Icons.visibility_rounded,
        summary: 'No one knows when the Son of Man is coming. Watchfulness is not optional.',
      ),
      _Parable(
        title: 'The Faithful and Unfaithful Servants',
        reference: 'Matthew 24:45\u201351',
        theme: 'Faithful Service',
        imagePath: 'assets/parables/Readiness and Watchfulness/The Faithful and Unfaithful Servants.png',
        icon: Icons.manage_accounts_rounded,
        summary: 'The master returns and finds either faithful service or self-indulgence. What will He find in you?',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Invitation and Response',
    parables: [
      _Parable(
        title: 'The Great Banquet',
        reference: 'Luke 14:15\u201324',
        theme: 'Receiving the Call',
        imagePath: 'assets/parables/Invitation and Response/The Great Banquet.png',
        icon: Icons.dinner_dining_rounded,
        summary: 'The invited make excuses; the outsiders fill the seats. No one who rejects God\u2019s call should assume they belong at His table.',
      ),
      _Parable(
        title: 'The Wedding Banquet',
        reference: 'Matthew 22:1\u201314',
        theme: 'Worthy Response',
        imagePath: 'assets/parables/Invitation and Response/The Wedding Banquet.png',
        icon: Icons.celebration_rounded,
        summary: 'A king\u2019s feast is refused and rejected. The invitation is opened wide \u2014 but being found without the right garment is still fatal.',
      ),
      _Parable(
        title: 'The Two Sons',
        reference: 'Matthew 21:28\u201332',
        theme: 'True Obedience',
        imagePath: 'assets/parables/Invitation and Response/The Two Sons.png',
        icon: Icons.people_alt_rounded,
        summary: 'One says yes and does nothing; one says no and repents. Actions, not words, define obedience.',
      ),
      _Parable(
        title: 'The Wicked Tenants',
        reference: 'Matthew 21:33\u201346',
        theme: 'Bearing Fruit',
        imagePath: 'assets/parables/Invitation and Response/The Wicked Tenants.png',
        icon: Icons.agriculture_rounded,
        summary: 'Tenants refuse to return what belongs to the owner. The Kingdom will be given to those who bear its fruit.',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Grace and Reward',
    parables: [
      _Parable(
        title: 'The Workers in the Vineyard',
        reference: 'Matthew 20:1\u201316',
        theme: 'God\u2019s Generosity',
        imagePath: 'assets/parables/Grace & Reward/Workers.png',
        icon: Icons.agriculture_rounded,
        summary: 'All receive the same wage regardless of hours worked. God\u2019s generosity is not governed by human fairness.',
      ),
      _Parable(
        title: 'The Two Debtors',
        reference: 'Luke 7:41\u201343',
        theme: 'Love and Forgiveness',
        imagePath: 'assets/parables/Grace & Reward/TwoDebtors.png',
        icon: Icons.favorite_border_rounded,
        summary: 'The one forgiven most loves most. Do you understand how much you have been forgiven?',
      ),
    ],
  ),
  _ParableGroup(
    heading: 'Counting the Cost',
    parables: [
      _Parable(
        title: 'The Wise and Foolish Builders',
        reference: 'Matthew 7:24\u201327',
        theme: 'Foundation',
        imagePath: 'assets/parables/Counting the Cost/FoolishBuilder.png',
        icon: Icons.foundation_rounded,
        summary: 'Two builders, one storm. A life built on Jesus\u2019s words stands; anything else does not.',
      ),
      _Parable(
        title: 'The Lowest Seat at the Feast',
        reference: 'Luke 14:7\u201311',
        theme: 'Humility',
        imagePath: 'assets/parables/Counting the Cost/The Lowest Seat at the Feast.png',
        icon: Icons.chair_rounded,
        summary: 'The one who humbles himself will be exalted. Kingdom values invert the world\u2019s social order.',
      ),
    ],
  ),
];

// ── View ─────────────────────────────────────────────────────────────────────

class ParablesView extends StatelessWidget {
  const ParablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ───────────────────────────────────────────────────
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
                    'assets/parables/Header.png',
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
                          'The Parables of Jesus',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '\u2018With what can we compare the kingdom of God, or what parable shall we use for it?\u2019',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Mark 4:30',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kAccent,
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

          // ── Intro ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jesus taught in parables \u2014 short stories drawn from everyday life that carried the deepest truths about God and His kingdom. He did not explain everything plainly. He invited people to lean in, to search, to ask.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Thirty-one parables, grouped by theme. Tap any to sit with it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Grouped grids ─────────────────────────────────────────────────
          for (final group in _groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.heading,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = group.parables[i];
                    return _ParableCard(
                      parable: p,
                      onTap: () => _showDetail(context, p),
                    );
                  },
                  childCount: group.parables.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, _Parable p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(p.icon, size: 18, color: _kAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: p.reference),
                              child: Text(
                                p.reference,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kAccent.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _kAccent.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                p.theme,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _kAccent.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  Text(
                    p.summary,
                    style: TextStyle(
                      fontSize: 15,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                      height: 1.7,
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
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _ParableCard extends StatelessWidget {
  final _Parable parable;
  final VoidCallback onTap;

  const _ParableCard({required this.parable, required this.onTap});

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
                child: parable.imagePath != null
                    ? Image.asset(
                        parable.imagePath!,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : Container(
                        color: _kAccent.withValues(alpha: 0.08),
                        child: Center(
                          child: Icon(parable.icon, size: 36, color: _kAccent.withValues(alpha: 0.5)),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                color: MyWalkColor.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parable.title,
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
                      parable.reference,
                      style: TextStyle(
                        fontSize: 10,
                        color: _kAccent.withValues(alpha: 0.7),
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
