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
                    'assets/fruit/Header.png',
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
                  // ── Setting ──────────────────────────────────────────────
                  _lmSectionHeader('The Setting'),
                  _lmPara(
                    'Paul\u2019s Letter to the Galatians is addressed to churches being pressured by \u2018agitators\u2019 \u2014 Jewish-Christian teachers insisting that Gentile converts must be circumcised and observe the Mosaic Law to be fully saved. The fruit of the Spirit (5:22\u201323) stands at the centre of the letter\u2019s practical section.',
                  ),
                  _lmPara(
                    'Paul has just listed the \u2018works of the flesh\u2019 (5:19\u201321) and warned that those who practise such things \u2018will not inherit the Kingdom of God.\u2019 The fruit of the Spirit is his positive counterpart: this is what life in the Spirit actually produces.',
                  ),
                  _lmPara(
                    'The contrast between \u2018works\u2019 (\u1f14\u03c1\u03b3\u03b1, plural) and \u2018fruit\u2019 (\u03ba\u03b1\u03c1\u03c0\u03cc\u03c2, singular) is theologically deliberate. The flesh produces fragmented, competing acts of self-assertion; the Spirit produces a unified, organic character. The singular \u2018fruit\u2019 insists that these nine qualities are not a checklist of independent virtues but a single, integrated character \u2014 the character of Christ himself, reproduced in the believer by the Spirit.',
                  ),
                  _lmPara(
                    'The argument climaxes in the closing phrase: \u2018against such things there is no law\u2019 (5:23b). The agitators insisted the Law was necessary to restrain moral chaos. Paul answers: the Spirit produces everything the Law aimed at \u2014 and more.',
                  ),
                  _lmPara(
                    'The nine qualities are commonly grouped into three triads: (1) love, joy, peace \u2014 the believer\u2019s disposition toward God; (2) patience, kindness, goodness \u2014 the believer\u2019s conduct toward others; (3) faithfulness, gentleness, self-control \u2014 the believer\u2019s governance of the self. The list is explicitly not exhaustive \u2014 the closing phrase \u2018such things\u2019 indicates representative rather than comprehensive enumeration.',
                  ),
                  const SizedBox(height: 8),
                  _lmDivider(),
                  const SizedBox(height: 8),
                  _lmSectionHeader('The Nine Fruits'),
                  _lmPara('Tap each fruit to explore it in depth.'),
                  const SizedBox(height: 8),
                  // ── 9 Expandable fruit sections ──────────────────────────
                  _FruitExpansion(
                    number: 1,
                    name: 'Love',
                    greek: '\u1f00\u03b3\u03ac\u03c0\u03b7 (agap\u0113)',
                    reference: 'Galatians 5:22a',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul places love first \u2014 and this is almost certainly deliberate. He has just told the Galatians that the entire Law is fulfilled in a single commandment: \u2018You shall love your neighbour as yourself\u2019 (5:14). The Galatian churches were tearing each other apart over circumcision and Torah observance, \u2018biting and devouring one another\u2019 (5:15). Love is the first fruit because it is the one the Galatians most conspicuously lack \u2014 and the one that would resolve the crisis destroying them.',
                    centralPoint:
                        'Love is not one virtue among nine. It is the root from which all other fruit grows. The Spirit\u2019s first work in the believer is to produce the kind of self-giving love that the Law commanded but could never empower.',
                    question:
                        'Where in my life is love \u2014 real, costly, self-giving love \u2014 most absent right now? What relationship or community would look different if the Spirit\u2019s love were genuinely flowing through me?',
                    practices: [
                      'Identify one person you find difficult to love and commit to one concrete act of genuine care toward them this week.',
                      'Examine your motives in one relationship \u2014 are you giving or consuming? Ask the Spirit to reshape you.',
                      'Pray each morning this week: \u2018Spirit, produce your love in me today \u2014 I cannot manufacture it.\u2019',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is love\u2026\u201d \u2014 Galatians 5:22a',
                  ),
                  _FruitExpansion(
                    number: 2,
                    name: 'Joy',
                    greek: '\u03c7\u03b1\u03c1\u03ac (chara)',
                    reference: 'Galatians 5:22b',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul writes to churches in turmoil. The agitators have introduced anxiety about salvation: are you really saved without circumcision? Do you need to keep the Law to be secure? Into this climate of spiritual fear, Paul names joy as the Spirit\u2019s fruit \u2014 not the joy of having your theology sorted out, but the deep gladness that comes from the Spirit\u2019s own presence within you.',
                    centralPoint:
                        'Joy is not something you produce by trying harder to be happy. It is the Spirit\u2019s own gladness taking root in you \u2014 a gladness that persists even in suffering because its source is God himself, not your circumstances.',
                    question:
                        'Is my spiritual life characterised by gladness \u2014 or by anxiety, performance, and fear? Where have I been trying to manufacture joy instead of receiving it from the Spirit?',
                    practices: [
                      'Begin each day this week by thanking God for three specific things before asking for anything.',
                      'Notice one moment of genuine gladness each day and pause to recognise the Spirit\u2019s presence in it.',
                      'When anxiety arises this week, practise returning to what is true about God rather than what is fearful about your situation.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 joy\u2026\u201d \u2014 Galatians 5:22b',
                  ),
                  _FruitExpansion(
                    number: 3,
                    name: 'Peace',
                    greek: '\u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 (eir\u0113n\u0113)',
                    reference: 'Galatians 5:22c',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'The Galatian churches were anything but peaceful \u2014 Paul has just warned them they are \u2018biting and devouring one another\u2019 (5:15). The dispute over circumcision had fractured communities along ethnic and theological lines. Peace here is not a personality trait or a preference for quiet \u2014 it is the Spirit\u2019s restoration of shalom in communities ripped apart by conflict.',
                    centralPoint:
                        'Peace is not the absence of conflict. It is the presence of wholeness \u2014 with God, with others, within yourself. The Spirit produces what human negotiation and compromise cannot: genuine reconciliation rooted in the cross.',
                    question:
                        'Where is peace most absent in my life right now \u2014 with God, with another person, within myself? What would it look like to stop manufacturing false peace and receive the Spirit\u2019s real peace?',
                    practices: [
                      'Identify one broken relationship and take one small step toward reconciliation this week.',
                      'Spend five minutes each day in silence, receiving peace rather than producing it.',
                      'Confess one source of inner turbulence to God honestly \u2014 anxiety, resentment, restlessness \u2014 and ask the Spirit for his peace.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 peace\u2026\u201d \u2014 Galatians 5:22c',
                  ),
                  _FruitExpansion(
                    number: 4,
                    name: 'Patience',
                    greek: '\u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 (makrothymia)',
                    reference: 'Galatians 5:22d',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul writes to communities in conflict. The temptation in such settings is to demand immediate resolution \u2014 to force the other side to comply, to retaliate against those who disagree, to give up on people who are slow to change. Patience \u2014 the capacity to endure provocation without retaliation \u2014 is what the Galatian situation most requires from its members toward one another.',
                    centralPoint:
                        'Patience is not passivity. It is the Spirit-empowered capacity to remain loving and engaged when others are slow, frustrating, or even hostile \u2014 because God has been exactly that patient with you.',
                    question:
                        'With whom am I most impatient right now \u2014 and what does that impatience reveal about what I believe I am owed? Where do I need God\u2019s patience to flow through me?',
                    practices: [
                      'Identify one person who tests your patience and pray for them specifically each day this week.',
                      'When frustration arises this week, pause and recall one instance of God\u2019s patience with you before responding.',
                      'Choose one situation where you would normally force a resolution and deliberately wait instead.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 patience\u2026\u201d \u2014 Galatians 5:22d',
                  ),
                  _FruitExpansion(
                    number: 5,
                    name: 'Kindness',
                    greek: '\u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 (chr\u0113stot\u0113s)',
                    reference: 'Galatians 5:22e',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul writes to churches riven by factional hostility. Kindness \u2014 treating others with practical, generous goodness even when they do not deserve it \u2014 is the Spirit\u2019s direct counter to the biting, devouring, and consuming that Paul has just warned against (5:15). It is the texture of love in daily interaction.',
                    centralPoint:
                        'Kindness is not personality; it is fruit. It is what God\u2019s own goodness looks like when the Spirit reproduces it in ordinary human relationships \u2014 practical, tangible, unearned.',
                    question:
                        'Am I actually kind \u2014 or merely polite? Where is there a gap between the pleasant surface I present and the genuine, costly kindness the Spirit produces?',
                    practices: [
                      'Do one anonymous act of practical kindness this week for someone who will never know it was you.',
                      'Speak one word of genuine, specific encouragement to someone who is struggling.',
                      'Examine one relationship where your \u2018kindness\u2019 is actually strategic or self-serving \u2014 and ask the Spirit for the real thing.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 kindness\u2026\u201d \u2014 Galatians 5:22e',
                  ),
                  _FruitExpansion(
                    number: 6,
                    name: 'Goodness',
                    greek: '\u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 (agath\u014ds\u0233n\u0113)',
                    reference: 'Galatians 5:22f',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul writes to churches where moral confusion reigns. The agitators claimed that without Torah observance, Gentile believers would descend into moral chaos. Paul\u2019s answer is not that morality doesn\u2019t matter but that the Spirit \u2014 not the Law \u2014 produces genuine goodness. This fruit is his direct refutation of the charge that grace leads to licence.',
                    centralPoint:
                        'Goodness is not merely avoiding evil. It is the Spirit\u2019s active production of moral beauty and generous action in the believer \u2014 a goodness that exceeds rule-keeping because it flows from a transformed character.',
                    question:
                        'Is my goodness the product of rule-keeping \u2014 or of the Spirit\u2019s transformation? Where is there moral effort without spiritual root in my life?',
                    practices: [
                      'Identify one area where you \u2018do the right thing\u2019 out of duty rather than desire \u2014 and ask the Spirit to transform the motive.',
                      'Do one good thing this week that no rule requires but that love demands.',
                      'Reflect on whether your moral life is driven by fear of getting it wrong or by desire for God\u2019s goodness.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 goodness\u2026\u201d \u2014 Galatians 5:22f',
                  ),
                  _FruitExpansion(
                    number: 7,
                    name: 'Faithfulness',
                    greek: '\u03c0\u03af\u03c3\u03c4\u03b9\u03c2 (pistis)',
                    reference: 'Galatians 5:22g',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'In a letter dominated by the word \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 \u2014 faith \u2014 Paul now names it as a fruit of the Spirit. The Galatians have heard \u2018faith\u2019 throughout the letter as the means of justification. Now Paul tells them faith is also a character quality the Spirit produces. It is both the door into the kingdom and the daily texture of life within it.',
                    centralPoint:
                        'The faith that saves also transforms. The Spirit takes the trust by which you entered relationship with God and grows it into the faithfulness by which you sustain relationships with others \u2014 reliability, integrity, keeping your word.',
                    question:
                        'Am I reliable? Can people depend on my word, my commitments, my presence? Where has my faithfulness grown thin \u2014 and what would it look like to ask the Spirit to strengthen it?',
                    practices: [
                      'Identify one commitment you have let slide \u2014 to a person, a group, a practice \u2014 and follow through on it this week.',
                      'Examine whether your reputation for reliability matches your self-image.',
                      'Pray for the Spirit to deepen your trustworthiness in the small, unseen commitments of daily life.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 faith\u2026\u201d \u2014 Galatians 5:22g',
                  ),
                  _FruitExpansion(
                    number: 8,
                    name: 'Gentleness',
                    greek: '\u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 (praut\u0113s)',
                    reference: 'Galatians 5:23a',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul will use this very word two verses later when instructing the Galatians on how to handle a fellow believer caught in sin: \u2018you who are spiritual, restore such a one in a spirit of gentleness\u2019 (6:1). The Spirit\u2019s fruit is not abstract \u2014 it is immediately applied to the hardest relational challenge the community faces: correction without condemnation.',
                    centralPoint:
                        'Gentleness is strength under the Spirit\u2019s control. It is how the Spirit-led person exercises influence, corrects error, and handles disagreement \u2014 not with domination but with the same humility Christ displayed.',
                    question:
                        'How do I handle people when I have power over them \u2014 when I am right and they are wrong, when I could crush but could also restore? Is there gentleness in my correction, or only rightness?',
                    practices: [
                      'In one conversation this week where you are tempted to be harsh, deliberately choose a gentle tone.',
                      'Reflect on how Jesus corrected people \u2014 and compare it honestly with how you do.',
                      'Ask someone close to you whether they experience you as gentle \u2014 and receive their honest answer.',
                    ],
                    scripture: '\u201cBut the fruit of the Spirit is\u2026 gentleness\u2026\u201d \u2014 Galatians 5:23a',
                  ),
                  _FruitExpansion(
                    number: 9,
                    name: 'Self-Control',
                    greek: '\u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 (enkrateia)',
                    reference: 'Galatians 5:23b',
                    contextTitle: 'Why this fruit matters to the Galatians',
                    contextBody:
                        'Paul closes the list with the virtue the agitators feared most would be lost without the Law: self-control. Their argument was that without Torah, Gentile believers would inevitably slide into the vices of the flesh list (5:19\u201321). Paul\u2019s final fruit is his answer: the Spirit produces the very self-mastery that the Law aimed at but could not achieve. And then the devastating conclusion: \u2018Against such things there is no law.\u2019',
                    centralPoint:
                        'Self-control is the Spirit\u2019s answer to the Law\u2019s question. The Law said \u2018don\u2019t\u2019 from the outside; the Spirit produces \u2018I won\u2019t need to\u2019 from the inside. Against the fruit of the Spirit, the Law has nothing to say \u2014 because the Spirit fulfils everything the Law ever demanded.',
                    question:
                        'Where in my life am I relying on external rules and willpower to control behaviour that the Spirit wants to transform from the inside? What appetite or impulse do I need to bring honestly to the Spirit rather than merely managing on my own?',
                    practices: [
                      'Identify one area where you rely on willpower alone \u2014 and ask the Spirit to produce internal transformation rather than external management.',
                      'Practise one act of deliberate restraint this week \u2014 not as punishment but as a way of exercising the Spirit\u2019s gift.',
                      'Reflect on whether your self-control is anxious self-management or the Spirit\u2019s calm mastery.',
                    ],
                    scripture:
                        '\u201cBut the fruit of the Spirit is\u2026 self-control. Against such things there is no law.\u201d \u2014 Galatians 5:23b',
                  ),
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

// ── Fruit Expansion Tile ──────────────────────────────────────────────────────

class _FruitExpansion extends StatelessWidget {
  final int number;
  final String name;
  final String greek;
  final String reference;
  final String contextTitle;
  final String contextBody;
  final String centralPoint;
  final String question;
  final List<String> practices;
  final String scripture;

  const _FruitExpansion({
    required this.number,
    required this.name,
    required this.greek,
    required this.reference,
    required this.contextTitle,
    required this.contextBody,
    required this.centralPoint,
    required this.question,
    required this.practices,
    required this.scripture,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MyWalkColor.sage.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.sage,
                ),
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
            ),
          ),
          subtitle: Text(
            '$greek  \u00b7  $reference',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MyWalkColor.softGold.withValues(alpha: 0.55),
            ),
          ),
          iconColor: MyWalkColor.softGold,
          collapsedIconColor: MyWalkColor.softGold.withValues(alpha: 0.4),
          children: [
            // Context highlight box
            _HighlightBox(title: contextTitle, body: contextBody),
            const SizedBox(height: 12),
            // Central point
            const _SubHeading('What the Spirit produces'),
            _BodyText(centralPoint),
            const SizedBox(height: 12),
            // Question
            const _SubHeading('The question it asks you'),
            _ItalicText(question),
            const SizedBox(height: 12),
            // Practices
            const _SubHeading('Suggested practices'),
            ...practices.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MyWalkColor.sage.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _BodyText(p)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            // Scripture
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyWalkColor.golden.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                      color: MyWalkColor.golden.withValues(alpha: 0.45),
                      width: 3),
                ),
              ),
              child: Text(
                scripture,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.85),
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final String title;
  final String body;
  const _HighlightBox({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: MyWalkColor.sage.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.sage.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ]),
    );
  }
}

class _SubHeading extends StatelessWidget {
  final String text;
  const _SubHeading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold.withValues(alpha: 0.6),
            letterSpacing: 1.0,
          ),
        ),
      );
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
          height: 1.6,
        ),
      );
}

class _ItalicText extends StatelessWidget {
  final String text;
  const _ItalicText(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
          height: 1.6,
        ),
      );
}
