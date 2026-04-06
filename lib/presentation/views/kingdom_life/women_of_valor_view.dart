import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const _kAccent = Color(0xFFB89AC8); // soft violet-rose

class WomenOfValorView extends StatelessWidget {
  const WomenOfValorView({super.key});

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
                    'assets/Women/womenofvalor.png',
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
                          'Women of Valor',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '\u2018A woman of valor, who can find? She is worth far more than rubies.\u2019',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Proverbs 31:10',
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scripture is filled with women whose faith, courage and obedience shaped the story of God\u2019s redemption. They are not footnotes \u2014 they are central figures in the unfolding of His purposes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'From the bravery of Deborah to the faithfulness of Ruth, from the boldness of Esther to the surrender of Mary \u2014 these women modelled what it looks like to trust God when the stakes are highest.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The Hebrew phrase \u2018eshet chayil\u2019 \u2014 woman of valor \u2014 appears in Proverbs 31 and was spoken over Ruth by Boaz (Ruth 3:11). It describes not a narrow domestic ideal but a woman of strength, dignity, wisdom and deep reverence for God.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
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
                      '\u2018Strength and dignity are her clothing, and she smiles at the future. She opens her mouth in wisdom, and the teaching of kindness is on her tongue.\u2019\n\n\u2014 Proverbs 31:25\u201326',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.softGold.withValues(alpha: 0.88),
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
