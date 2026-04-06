import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../bible/bible_browser_view.dart';

const _kAccent = Color(0xFF7DAEC8); // celestial blue

// ── Data ─────────────────────────────────────────────────────────────────────

class _IAmSaying {
  final String title;
  final String reference;
  final String imagePath;
  final String fullVerse;
  final String reflection;

  const _IAmSaying({
    required this.title,
    required this.reference,
    required this.imagePath,
    required this.fullVerse,
    required this.reflection,
  });
}

const _sayings = [
  _IAmSaying(
    title: 'The Bread of Life',
    reference: 'John 6:35',
    imagePath: 'assets/I Am/The Bread.png',
    fullVerse:
        '"I am the bread of life; whoever comes to me shall not hunger, and whoever believes in me shall never thirst."',
    reflection:
        'Jesus is not merely a teacher or guide \u2014 He is the very sustenance of the soul. As bread is essential to physical life, He is essential to eternal life. To come to Him in faith is to be fed in a way that nothing else can satisfy.',
  ),
  _IAmSaying(
    title: 'The Light of the World',
    reference: 'John 8:12',
    imagePath: 'assets/I Am/the light.png',
    fullVerse:
        '"I am the light of the world. Whoever follows me will not walk in darkness, but will have the light of life."',
    reflection:
        'Light reveals what is hidden, guides the way forward, and drives out darkness. Jesus claims to be the source of all spiritual illumination \u2014 the one who exposes truth, gives direction, and brings life to those who walk in His light.',
  ),
  _IAmSaying(
    title: 'The Door of the Sheep',
    reference: 'John 10:9',
    imagePath: 'assets/I Am/The gate.png',
    fullVerse:
        '"I am the door. If anyone enters by me, he will be saved and will go in and out and find pasture."',
    reflection:
        'There is only one way into the safety of God\u2019s fold, and it is through Jesus. He is not a door among many \u2014 He is the door. To enter through Him is to find salvation, freedom, and abundant provision.',
  ),
  _IAmSaying(
    title: 'The Good Shepherd',
    reference: 'John 10:11',
    imagePath: 'assets/I Am/the GoodShephard.png',
    fullVerse:
        '"I am the good shepherd. The good shepherd lays down his life for the sheep."',
    reflection:
        'The good shepherd knows His sheep by name, leads them to green pastures, and willingly lays down His life for them. This is not management from a distance \u2014 it is costly, personal love. Jesus fulfilled this completely on the cross.',
  ),
  _IAmSaying(
    title: 'The Resurrection and the Life',
    reference: 'John 11:25',
    imagePath: 'assets/I Am/the Resurrection.png',
    fullVerse:
        '"I am the resurrection and the life. Whoever believes in me, though he die, yet shall he live, and everyone who lives and believes in me shall never die."',
    reflection:
        'Standing before a tomb, Jesus made the most audacious claim in human history \u2014 that He himself is the source of resurrection and life. Death is not the final word for those who believe in Him. He does not merely bring resurrection; He is it.',
  ),
  _IAmSaying(
    title: 'The Way, Truth, and Life',
    reference: 'John 14:6',
    imagePath: 'assets/I Am/The Way.png',
    fullVerse:
        '"I am the way, and the truth, and the life. No one comes to the Father except through me."',
    reflection:
        'Three claims woven into one: Jesus is the way \u2014 the only path to the Father. He is the truth \u2014 the ultimate reality that every true thing reflects. He is the life \u2014 the source and sustainer of all living. This is perhaps the most comprehensive of all the I AM declarations.',
  ),
  _IAmSaying(
    title: 'The True Vine',
    reference: 'John 15:5',
    imagePath: 'assets/I Am/The Vine.png',
    fullVerse:
        '"I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing."',
    reflection:
        'A branch that is cut from the vine cannot survive, let alone bear fruit. Jesus calls us not merely to follow His example but to remain vitally connected to Him \u2014 drawing life from Him as a branch draws life from the vine. Fruitfulness flows from abiding.',
  ),
];

// ── View ─────────────────────────────────────────────────────────────────────

class IAmSayingsView extends StatelessWidget {
  const IAmSayingsView({super.key});

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
                    'assets/I Am/Header.png',
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
                          'The \u201cI AM\u201d Sayings of Jesus',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '\u2018Before Abraham was, I am.\u2019',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'John 8:58',
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seven times in the Gospel of John, Jesus begins a statement with the words \u201cI am\u201d \u2014 deliberately echoing the divine name God revealed to Moses at the burning bush. These are not metaphors or modest claims. They are declarations of identity.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In each saying, Jesus takes something essential to human life \u2014 bread, light, a gate, a shepherd, resurrection, a road, a vine \u2014 and says: that is what I am to you. Tap any saying to sit with it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── 2-column image grid ───────────────────────────────────────────
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
                  final saying = _sayings[i];
                  return _IAmCard(
                    saying: saying,
                    onTap: () => _showDetail(context, saying),
                  );
                },
                childCount: _sayings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, _IAmSaying saying) {
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.auto_awesome, size: 18, color: _kAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I am ${saying.title.toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          saying.reference,
                          style: TextStyle(
                            fontSize: 12,
                            color: _kAccent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
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
                  // Verse card — tappable → opens Bible viewer
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BibleBrowserView(initialReference: saying.reference),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: _kAccent.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        saying.fullVerse,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: MyWalkColor.softGold.withValues(alpha: 0.9),
                          height: 1.65,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reflection
                  Text(
                    'Reflection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kAccent.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    saying.reflection,
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.65,
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

class _IAmCard extends StatelessWidget {
  final _IAmSaying saying;
  final VoidCallback onTap;

  const _IAmCard({required this.saying, required this.onTap});

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
                  saying.imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                color: MyWalkColor.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I am\u2026',
                      style: TextStyle(
                        fontSize: 9,
                        color: _kAccent.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      saying.title,
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
                      saying.reference,
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
