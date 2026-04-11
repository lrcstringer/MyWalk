import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart' show Habit;
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'fruit_library_view.dart';
import '../journal/journal_entry_composer.dart';
import '../kingdom_life/bible_project_browser_view.dart';

class FruitDetailView extends StatelessWidget {
  final FruitType fruit;

  const FruitDetailView({super.key, required this.fruit});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<FruitPortfolioProvider>().portfolio;
    final habits = context.watch<HabitProvider>().habits;
    final entry = portfolio?.entryFor(fruit);
    final taggedHabits = habits.where((h) => h.fruitTags.contains(fruit)).toList();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(
                fruit.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    fruit.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.5),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon + name
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fruit.color.withValues(alpha: 0.15),
                    border: Border.all(color: fruit.color.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Icon(fruit.icon, size: 26, color: fruit.color),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fruit.label,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite)),
                    Text(
                      fruit.greekWord,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.golden.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Definition
            Text(
              fruit.shortDescription,
              style: TextStyle(
                fontSize: 15,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Key verse — tappable → opens Bible viewer
            GestureDetector(
              onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: fruit.keyVerse.reference),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: fruit.color.withValues(alpha: 0.5), width: 3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fruit.keyVerse.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: MyWalkColor.softGold.withValues(alpha: 0.85),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\u2014 ${fruit.keyVerse.reference}',
                            style: TextStyle(
                              fontSize: 11,
                              color: MyWalkColor.softGold.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showMoreOnThisFruit(context),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_outlined, size: 11, color: fruit.color.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  'More on this fruit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fruit.color.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.chevron_right, size: 13, color: fruit.color.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            if (entry != null) _statsRow(entry),
            const SizedBox(height: 28),

            // CTA
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FruitLibraryView(initialFruit: fruit)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fruit.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: fruit.color),
                    const SizedBox(width: 8),
                    Text(
                      'Add a ${fruit.label} practice',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: fruit.color),
                    ),
                  ],
                ),
              ),
            ),

            // Linked practices chips
            if (taggedHabits.isNotEmpty) ...[
              const SizedBox(height: 12),
              _LinkedPracticesChips(habits: taggedHabits, fruit: fruit),
            ],

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalEntryComposer(
                    fruitTag: fruit,
                    sourceType: 'fruit',
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fruit.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, size: 16, color: fruit.color.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'Add a journal entry',
                      style: TextStyle(
                        fontSize: 14,
                        color: fruit.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOnThisFruit(BuildContext context) {
    final data = _fruitStudyDataFor(fruit);
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
                  Icon(fruit.icon, size: 20, color: fruit.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fruit.label,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: fruit.color,
                          ),
                        ),
                        Text(
                          fruit.greekWord,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: MyWalkColor.softGold.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // 1. Scripture
                  _scriptureBox(data.scripture),
                  const SizedBox(height: 20),
                  // 2. Statement in Brief
                  _sectionHeader('THE STATEMENT IN BRIEF'),
                  _bodyPara(data.statementInBrief),
                  const SizedBox(height: 16),
                  // 3. Central Point
                  _sectionHeader('THE CENTRAL POINT'),
                  _highlightBox('What the Spirit produces', data.centralPoint),
                  const SizedBox(height: 16),
                  // 4. Question
                  _sectionHeader('THE QUESTION IT ASKS YOU'),
                  _italicPara(data.question),
                  const SizedBox(height: 16),
                  // 5. Suggested Practices
                  _sectionHeader('SUGGESTED PRACTICES'),
                  ...data.practices.map((p) => _practiceItem(p)),
                  const SizedBox(height: 12),
                  _divider(),
                  const SizedBox(height: 16),
                  // 6. Audience and Context
                  _sectionHeader('AUDIENCE AND CONTEXT'),
                  _highlightBox(data.audienceContextTitle, data.audienceContext),
                  const SizedBox(height: 16),
                  // 7. Historical and Cultural Context
                  _sectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                  _bodyPara(data.historicalContext),
                  const SizedBox(height: 16),
                  // 8. Scholarly Interpretation
                  _sectionHeader('SCHOLARLY INTERPRETATION'),
                  _bodyPara(data.scholarlyInterpretation),
                  const SizedBox(height: 16),
                  // 9. Exegetical and Literary Notes
                  _sectionHeader('EXEGETICAL AND LITERARY NOTES'),
                  _bodyPara(data.exegeticalNotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scriptureBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fruit.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: fruit.color.withValues(alpha: 0.5), width: 3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: MyWalkColor.softGold.withValues(alpha: 0.9),
            height: 1.6,
          ),
        ),
      );

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold.withValues(alpha: 0.7),
            letterSpacing: 0.9,
          ),
        ),
      );

  Widget _highlightBox(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MyWalkColor.sage.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MyWalkColor.sage.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      );

  Widget _bodyPara(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
          height: 1.65,
        ),
      );

  Widget _italicPara(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
          height: 1.65,
        ),
      );

  Widget _practiceItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyWalkColor.sage.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07));

  Widget _statsRow(FruitPortfolioEntry entry) {
    return Row(
      children: [
        _stat('${entry.habitCount}', 'habits'),
        _statDivider(),
        _stat('${entry.weeklyCompletions}', 'this week'),
        _statDivider(),
        _stat('${entry.currentStreak}', 'wk streak'),
        _statDivider(),
        _stat('${entry.totalCompletions}', 'all-time'),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: MyWalkColor.softGold.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

// ── Fruit Study Data ───────────────────────────────────────────────────────────

class _FruitStudyData {
  final String scripture;
  final String statementInBrief;
  final String centralPoint;
  final String question;
  final List<String> practices;
  final String audienceContextTitle;
  final String audienceContext;
  final String historicalContext;
  final String scholarlyInterpretation;
  final String exegeticalNotes;

  const _FruitStudyData({
    required this.scripture,
    required this.statementInBrief,
    required this.centralPoint,
    required this.question,
    required this.practices,
    required this.audienceContextTitle,
    required this.audienceContext,
    required this.historicalContext,
    required this.scholarlyInterpretation,
    required this.exegeticalNotes,
  });
}

_FruitStudyData _fruitStudyDataFor(FruitType fruit) {
  switch (fruit) {
    case FruitType.love:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is love\u2026\u201d \u2014 Galatians 5:22a',
        statementInBrief:
            'The Spirit\u2019s first and governing fruit is love \u2014 not sentiment or affection but the self-giving, other-oriented posture that fulfils the entire Law. It is what the Torah aimed at producing, and what only the Spirit can.',
        centralPoint:
            'Love is not one virtue among nine. It is the root from which all other fruit grows. The Spirit\u2019s first work in the believer is to produce the kind of self-giving love that the Law commanded but could never empower.',
        question:
            'Where in my life is love \u2014 real, costly, self-giving love \u2014 most absent right now? What relationship or community would look different if the Spirit\u2019s love were genuinely flowing through me?',
        practices: [
          'Identify one person you find difficult to love and commit to one concrete act of genuine care toward them this week (Love)',
          'Examine your motives in one relationship \u2014 are you giving or consuming? Ask the Spirit to reshape you (Reflection)',
          'Pray each morning this week: \u2018Spirit, produce your love in me today \u2014 I cannot manufacture it\u2019 (Prayer)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul places love first in the list \u2014 and this is almost certainly deliberate. He has just told the Galatians that the entire Law is fulfilled in a single commandment: \u2018You shall love your neighbour as yourself\u2019 (5:14). The Galatian churches were tearing each other apart over circumcision and Torah observance, \u2018biting and devouring one another\u2019 (5:15). Love is the first fruit because it is the one the Galatians most conspicuously lack \u2014 and the one that would resolve the crisis destroying them.',
        historicalContext:
            'The Greek \u1f00\u03b3\u03ac\u03c0\u03b7 was an uncommon word in pre-Christian literature \u2014 it appears rarely in classical Greek and carries none of the erotic connotations of \u1f14\u03c1\u03c9\u03c2 or the friendship warmth of \u03c6\u03b9\u03bb\u03af\u03b1. The Septuagint used it to translate the Hebrew \u02bfah\u0103b\u00e2, giving it covenantal weight (Deut 6:5; Lev 19:18). By the time Paul writes, \u1f00\u03b3\u03ac\u03c0\u03b7 has become the defining Christian term for God\u2019s self-giving character and the believer\u2019s responsive ethic (Bruce 1982, 252; Fee 1994, 443\u201345). Paul\u2019s own extended definition appears in 1 Corinthians 13, written to another fractious community, and the parallels with the Galatian context \u2014 divisions, self-assertion, competitive spirituality \u2014 are striking (Longenecker 1990, 262).',
        scholarlyInterpretation:
            'That love heads the list is widely regarded as theologically intentional. Gordon Fee argues love is not simply first among equals but the \u2018primary fruit from which all others flow\u2019 \u2014 Paul\u2019s fruit list is hierarchical in a way his vice lists are not (Fee 1994, 443\u201346). J. Louis Martyn reads \u1f00\u03b3\u03ac\u03c0\u03b7 here as the \u2018new-creation\u2019 love that the cross of Christ has unleashed into the world through the Spirit \u2014 it is eschatological reality, not merely ethical aspiration (Martyn 1997, 530\u201332). Richard Hays notes that Paul\u2019s placement of love immediately after the command to \u2018love your neighbour\u2019 (5:14) creates a deliberate inclusio: the Spirit produces what the Law requires (Hays 2000, 327\u201328). Dunn emphasises the contrast with the \u2018works of the flesh\u2019: the flesh produces competitive self-assertion; the Spirit produces other-directed love (Dunn 1993, 308\u20139). Moo observes that Paul\u2019s understanding of love is theocentric \u2014 it originates in God\u2019s love for the believer (Rom 5:5, 8), is poured into the heart by the Spirit, and then flows outward through the believer into community (Moo 2013, 365\u201366).',
        exegeticalNotes:
            'The singular \u03ba\u03b1\u03c1\u03c0\u03cc\u03c2 (\u2018fruit\u2019) governing the entire list is theologically significant: Paul does not say \u2018fruits\u2019 (plural) but treats the nine qualities as a unified organic product of a single source \u2014 the Spirit. This contrasts deliberately with \u1f14\u03c1\u03b3\u03b1 \u03c4\u1fc6\u03c2 \u03c3\u03b1\u03c1\u03ba\u03cc\u03c2 (\u2018works of the flesh,\u2019 v. 19), where the plural emphasises fragmentation and disorder (Bruce 1982, 251; Fee 1994, 443). The word \u1f00\u03b3\u03ac\u03c0\u03b7 appears 75 times in Paul\u2019s letters, making it his most frequently used virtue term. Its position at the head of the list, combined with Paul\u2019s argument in 5:6 (faith working through love) and 5:14 (love as Law-fulfilment), establishes love as the interpretive key to the entire catalogue (Longenecker 1990, 261\u201362).',
      );

    case FruitType.joy:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 joy\u2026\u201d \u2014 Galatians 5:22b',
        statementInBrief:
            'The Spirit produces joy \u2014 not happiness dependent on circumstances but the deep, settled gladness that arises from the reality of God\u2019s presence, acceptance, and coming kingdom. It is a fruit, not an achievement.',
        centralPoint:
            'Joy is not something you produce by trying harder to be happy. It is the Spirit\u2019s own gladness taking root in you \u2014 a gladness that persists even in suffering because its source is God himself, not your circumstances.',
        question:
            'Is my spiritual life characterised by gladness \u2014 or by anxiety, performance, and fear? Where have I been trying to manufacture joy instead of receiving it from the Spirit?',
        practices: [
          'Begin each day this week by thanking God for three specific things before asking for anything (Gratitude)',
          'Notice one moment of genuine gladness each day and pause to recognise the Spirit\u2019s presence in it (Awareness)',
          'When anxiety arises this week, practise the discipline of returning to what is true about God rather than what is fearful about your situation (Trust)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul writes to churches in turmoil. The agitators have introduced anxiety about salvation: are you really saved without circumcision? Do you need to keep the Law to be secure? Into this climate of spiritual fear, Paul names joy as the Spirit\u2019s fruit \u2014 not the joy of having your theology sorted out, but the deep gladness that comes from the Spirit\u2019s own presence within you.',
        historicalContext:
            'The Greek \u03c7\u03b1\u03c1\u03ac and its cognates (\u03c7\u03b1\u03af\u03c1\u03c9, \u2018to rejoice\u2019) appear over 150 times in the New Testament, making joy one of the most pervasive themes of early Christian experience. In the Hebrew Bible, joy is associated with the presence of God (Ps 16:11; 21:6; Isa 61:10) and with salvation events (Exod 15; Neh 8:10). In Hellenistic philosophy, the Epicureans sought joy (\u1f21\u03b4\u03bf\u03bd\u03ae) through ataraxia (freedom from disturbance), and the Stoics pursued \u03b5\u1f50\u03c0\u03ac\u03b8\u03b5\u03b9\u03b1 (well-being) through rational acceptance. Paul\u2019s concept differs fundamentally from both: Christian joy is trinitarian \u2014 it originates in God the Father\u2019s saving action, is mediated by Christ\u2019s death and resurrection, and is sustained by the Spirit\u2019s indwelling presence (Fee 1994, 446\u201347; Moo 2013, 367).',
        scholarlyInterpretation:
            'Fee argues that Pauline joy is eschatological in character \u2014 it is the joy of the age to come breaking into the present through the Spirit (Fee 1994, 446\u201347). Paul himself writes from prison in Philippians with joy as a central theme, demonstrating that this fruit is not circumstance-dependent. Martyn connects joy to the apocalyptic framework of Galatians: the new creation has invaded the old, and joy is the believer\u2019s response to that invasion (Martyn 1997, 531). Bruce notes that joy naturally follows love: the self-giving love of the Spirit produces gladness, not burden (Bruce 1982, 252). Dunn reads joy alongside peace as the paired experiential marks of life in the Spirit, contrasting with the anxiety produced by legalistic religion (Dunn 1993, 309). Witherington observes that Paul\u2019s placement of joy immediately after love may reflect a traditional triad (love, joy, peace) rooted in early Christian worship and liturgical practice (Witherington 1998, 411).',
        exegeticalNotes:
            'The noun \u03c7\u03b1\u03c1\u03ac appears five times in Paul\u2019s letters to the Galatians\u2019 neighbouring churches (Phil 1:4, 25; 2:2, 29; 4:1) \u2014 always in contexts of communal relationship. Paul never treats joy as private emotion but as shared reality of the Spirit-filled community. The verbal cognate \u03c7\u03b1\u03af\u03c1\u03b5\u03c4\u03b5 (\u2018rejoice!\u2019) functions as an imperative in Philippians 3:1 and 4:4, suggesting that while joy is Spirit-produced, the believer\u2019s active participation in cultivating it through worship and gratitude is expected. The placement of \u03c7\u03b1\u03c1\u03ac between \u1f00\u03b3\u03ac\u03c0\u03b7 and \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 may reflect a deliberate triad describing the believer\u2019s orientation toward God (Longenecker 1990, 262; Schreiner 2010, 346).',
      );

    case FruitType.peace:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 peace\u2026\u201d \u2014 Galatians 5:22c',
        statementInBrief:
            'The Spirit produces peace \u2014 the deep wholeness and relational reconciliation that the Hebrew concept of shalom describes. It is both vertical (peace with God) and horizontal (peace with one another), and both are the Spirit\u2019s work.',
        centralPoint:
            'Peace is not the absence of conflict. It is the presence of wholeness \u2014 with God, with others, within yourself. The Spirit produces what human negotiation and compromise cannot: genuine reconciliation rooted in the cross.',
        question:
            'Where is peace most absent in my life right now \u2014 with God, with another person, within myself? What would it look like to stop manufacturing false peace and receive the Spirit\u2019s real peace?',
        practices: [
          'Identify one broken relationship and take one small step toward reconciliation this week (Reconciliation)',
          'Spend five minutes each day in silence, receiving peace rather than producing it (Stillness)',
          'Confess one source of inner turbulence to God honestly \u2014 anxiety, resentment, restlessness \u2014 and ask the Spirit for his peace (Confession)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'The Galatian churches were anything but peaceful \u2014 Paul has just warned them they are \u2018biting and devouring one another\u2019 (5:15). The dispute over circumcision had fractured communities along ethnic and theological lines. Peace here is not a personality trait or a preference for quiet \u2014 it is the Spirit\u2019s restoration of shalom in communities ripped apart by conflict.',
        historicalContext:
            'The Greek \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 translates the Hebrew shalom, which encompasses far more than absence of conflict \u2014 it denotes wholeness, completeness, material and relational well-being, and right ordering of all things (Isa 32:17; Ps 29:11; Num 6:24\u201326). In the Greco-Roman world, \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 was a political term \u2014 the Pax Romana was maintained by military force and imperial administration. Paul\u2019s concept of peace stands in contrast to both: it is neither the inner tranquillity of Stoic philosophy nor the enforced order of empire, but the reconciliation accomplished by Christ\u2019s death (Eph 2:14\u201316; Rom 5:1) and sustained by the Spirit in community (Fee 1994, 447\u201348; Bruce 1982, 252\u201353).',
        scholarlyInterpretation:
            'Fee argues that \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 in Paul has three dimensions: peace with God (the foundational reality established by justification, Rom 5:1), peace with others (the reconciliation of Jew and Gentile that is central to Galatians\u2019 argument), and peace as inner wholeness (Phil 4:7). All three are Spirit-produced (Fee 1994, 447\u201348). Martyn emphasises the communal dimension: in Galatians, peace is what the agitators are destroying, and the Spirit is what restores it \u2014 the fruit addresses the letter\u2019s crisis directly (Martyn 1997, 531\u201332). Dunn notes that love-joy-peace forms a natural triad describing the character of life \u2018in Christ,\u2019 each building on the preceding (Dunn 1993, 309). Hays reads peace as the practical antidote to 5:15 \u2014 communities that stop biting each other and begin bearing each other\u2019s burdens (6:2) are displaying the Spirit\u2019s fruit (Hays 2000, 328). Moo stresses the eschatological dimension: the peace the Spirit produces is a foretaste of the new-creation shalom that God will bring to completion (Moo 2013, 367\u201368).',
        exegeticalNotes:
            'Paul uses \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 43 times across his letters \u2014 more than any other NT author. It appears in every Pauline letter opening (\u2018grace and peace to you\u2019), giving it liturgical prominence. In Galatians specifically, \u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 appears at 1:3 (greeting), 5:22 (fruit), and 6:16 (closing benediction: \u2018peace and mercy be upon the Israel of God\u2019), forming a structural frame around the letter\u2019s argument. The triad \u1f00\u03b3\u03ac\u03c0\u03b7-\u03c7\u03b1\u03c1\u03ac-\u03b5\u1f30\u03c1\u03ae\u03bd\u03b7 likely reflects an early Christian formulaic grouping, paralleled in Romans 14:17 (\u2018the kingdom of God is\u2026 righteousness, peace, and joy in the Holy Spirit\u2019) and Romans 15:13 (\u2018the God of hope fill you with all joy and peace\u2019) (Longenecker 1990, 262; Schreiner 2010, 346).',
      );

    case FruitType.patience:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 patience\u2026\u201d \u2014 Galatians 5:22d',
        statementInBrief:
            'The Spirit produces patience \u2014 the long-suffering endurance that bears with others without retaliating, giving up, or demanding that they change on your timeline. It is God\u2019s own patience reproduced in his people.',
        centralPoint:
            'Patience is not passivity. It is the Spirit-empowered capacity to remain loving and engaged when others are slow, frustrating, or even hostile \u2014 because God has been exactly that patient with you.',
        question:
            'With whom am I most impatient right now \u2014 and what does that impatience reveal about what I believe I am owed? Where do I need God\u2019s patience to flow through me?',
        practices: [
          'Identify one person who tests your patience and pray for them specifically each day this week (Intercession)',
          'When frustration arises this week, pause and recall one instance of God\u2019s patience with you before responding (Self-awareness)',
          'Choose one situation where you would normally force a resolution and deliberately wait instead (Surrender)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul writes to communities in conflict. The temptation in such settings is to demand immediate resolution \u2014 to force the other side to comply, to retaliate against those who disagree, to give up on people who are slow to change. Patience \u2014 the capacity to endure provocation without retaliation \u2014 is what the Galatian situation most requires from its members toward one another.',
        historicalContext:
            'The Greek \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 is a compound of \u03bc\u03b1\u03ba\u03c1\u03cc\u03c2 (\u2018long\u2019) and \u03b8\u03c5\u03bc\u03cc\u03c2 (\u2018anger, passion\u2019) \u2014 literally \u2018long-temperedness\u2019 or \u2018slow to anger.\u2019 It translates the Hebrew \u02bferek \u02bfappayim, a phrase used to describe God\u2019s own character in the foundational self-revelation at Sinai: \u2018The LORD, the LORD, a God merciful and gracious, slow to anger\u2019 (Exod 34:6; cf. Num 14:18; Ps 86:15; 103:8). In the Septuagint, \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 appears repeatedly as a divine attribute before it ever becomes a human virtue. Paul\u2019s usage preserves this sequence: God\u2019s patience is the source; the believer\u2019s patience is the fruit (Bruce 1982, 253; Fee 1994, 448\u201349).',
        scholarlyInterpretation:
            'Fee emphasises that \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 in Paul is specifically patience with people rather than endurance of circumstances (which Paul expresses with \u1f51\u03c0\u03bf\u03bc\u03bf\u03bd\u03ae, a different word). The Spirit produces the capacity to bear with difficult people without retaliation \u2014 a virtue directly relevant to the Galatian conflict (Fee 1994, 448\u201349). Longenecker argues the word signals a shift in the list: love-joy-peace describe the believer\u2019s inner disposition toward God; patience-kindness-goodness describe outward conduct toward others (Longenecker 1990, 262\u201363). Martyn connects \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 to God\u2019s own patience in the apocalyptic drama: God has been patient with the old age while the new creation unfolds, and believers are to embody the same patience (Martyn 1997, 532). Moo notes the word\u2019s association with God\u2019s patience in delaying judgement (Rom 2:4; 9:22; 2 Pet 3:9, 15) and argues Paul expects the same quality in the believer\u2019s relationships (Moo 2013, 368). Schreiner stresses that patience is not natural temperament but Spirit-produced transformation \u2014 particularly remarkable because \u03b8\u03c5\u03bc\u03cc\u03c2 (\u2018rage\u2019) appears in the works-of-the-flesh list at 5:20 (Schreiner 2010, 347).',
        exegeticalNotes:
            'The compound \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 is morphologically the direct opposite of \u1f40\u03be\u03c5\u03b8\u03c5\u03bc\u03af\u03b1 (\u2018quick-temperedness,\u2019 from \u1f40\u03be\u03cd\u03c2, \u2018sharp\u2019). Its placement fourth in the list, immediately after the love-joy-peace triad, begins the relational section. Paul uses the cognate verb \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03ad\u03c9 in 1 Corinthians 13:4 (\u2018love is patient\u2019) \u2014 directly linking the first and fourth fruits. That \u03b8\u03c5\u03bc\u03cc\u03c2 (\u2018outbursts of anger\u2019) appears in the works of the flesh at 5:20 while \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 (\u2018long-temperedness\u2019) appears in the fruit of the Spirit creates a deliberate antithetical pairing across the two lists (Dunn 1993, 310; Longenecker 1990, 263).',
      );

    case FruitType.kindness:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 kindness\u2026\u201d \u2014 Galatians 5:22e',
        statementInBrief:
            'The Spirit produces kindness \u2014 not merely niceness or politeness but active, practical generosity toward others. It is the outward expression of love\u2019s character, treating people better than they deserve because God has treated you the same way.',
        centralPoint:
            'Kindness is not personality; it is fruit. It is what God\u2019s own goodness looks like when the Spirit reproduces it in ordinary human relationships \u2014 practical, tangible, unearned.',
        question:
            'Am I actually kind \u2014 or merely polite? Where is there a gap between the pleasant surface I present and the genuine, costly kindness the Spirit produces?',
        practices: [
          'Do one anonymous act of practical kindness this week for someone who will never know it was you (Service)',
          'Speak one word of genuine, specific encouragement to someone who is struggling (Encouragement)',
          'Examine one relationship where your \u2018kindness\u2019 is actually strategic or self-serving \u2014 and ask the Spirit for the real thing (Honesty)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul writes to churches riven by factional hostility. Kindness \u2014 treating others with practical, generous goodness even when they do not deserve it \u2014 is the Spirit\u2019s direct counter to the biting, devouring, and consuming that Paul has just warned against (5:15). It is the texture of love in daily interaction.',
        historicalContext:
            'The Greek \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 denotes goodness expressed as generous, gracious action toward others. In the LXX it translates Hebrew \u1e6d\u00f4b (\u2018goodness\u2019) when applied to God\u2019s character (Pss 25:7; 31:19; 145:7). Paul uses it in Romans 2:4 as a divine attribute \u2014 \u2018the kindness of God leads you to repentance\u2019 \u2014 and in Romans 11:22 contrasts God\u2019s \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 with his \u1f00\u03c0\u03bf\u03c4\u03bf\u03bc\u03af\u03b1 (\u2018severity\u2019). The word carried overtones of benevolent patronage in the Greco-Roman world: a \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c2 patron was one who treated dependents with generous goodwill beyond obligation (Moo 2013, 368\u201369; Dunn 1993, 310).',
        scholarlyInterpretation:
            'Fee argues that \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 is best understood as the outward face of \u1f00\u03b3\u03ac\u03c0\u03b7 \u2014 if love is the inner disposition, kindness is what it looks like in practice toward others (Fee 1994, 449). Longenecker pairs kindness with goodness (the next fruit) as near-synonyms distinguished by emphasis: kindness is the disposition, goodness is the action (Longenecker 1990, 263). Moo stresses the theocentric origin: God\u2019s kindness to sinners (Rom 2:4; Eph 2:7; Titus 3:4) is the model and source of the believer\u2019s kindness toward others (Moo 2013, 368\u201369). Witherington notes that in the Greco-Roman context, \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 would be recognised as a client-patron virtue, but Paul democratises it: all Spirit-filled believers are to embody it, not merely the powerful toward the weak (Witherington 1998, 412). Bruce observes the early Christian pun between \u03a7\u03c1\u03b9\u03c3\u03c4\u03cc\u03c2 (Christ) and \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c2 (kind/good) \u2014 noted by Tertullian and others \u2014 which may have made the word resonate with particular force in early communities (Bruce 1982, 253).',
        exegeticalNotes:
            'The noun \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 appears 10 times in the NT, all in Pauline letters. In 2 Corinthians 6:6 Paul lists it among the marks of authentic apostolic ministry (\u2018in kindness, in the Holy Spirit, in sincere love\u2019), pairing it with the Spirit and love in a triad that parallels the fruit list. The cognate adjective \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c2 appears in 1 Corinthians 13:4 (\u2018love is kind\u2019), again linking the first and fifth fruits through the 1 Corinthians 13 love-hymn. The placement of \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 between \u03bc\u03b1\u03ba\u03c1\u03bf\u03b8\u03c5\u03bc\u03af\u03b1 and \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 creates a triad of other-directed virtues describing how the Spirit-led person treats other people (Schreiner 2010, 347).',
      );

    case FruitType.goodness:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 goodness\u2026\u201d \u2014 Galatians 5:22f',
        statementInBrief:
            'The Spirit produces goodness \u2014 active moral excellence that expresses itself in generous, righteous conduct. It is what the Law aimed at but could never produce on its own. The Spirit accomplishes what Torah could not.',
        centralPoint:
            'Goodness is not merely avoiding evil. It is the Spirit\u2019s active production of moral beauty and generous action in the believer \u2014 a goodness that exceeds rule-keeping because it flows from a transformed character.',
        question:
            'Is my goodness the product of rule-keeping \u2014 or of the Spirit\u2019s transformation? Where is there moral effort without spiritual root in my life?',
        practices: [
          'Identify one area where you \u2018do the right thing\u2019 out of duty rather than desire \u2014 and ask the Spirit to transform the motive (Transformation)',
          'Do one good thing this week that no rule requires but that love demands (Initiative)',
          'Reflect on whether your moral life is driven by fear of getting it wrong or by desire for God\u2019s goodness (Reflection)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul writes to churches where moral confusion reigns. The agitators claimed that without Torah observance, Gentile believers would descend into moral chaos. Paul\u2019s answer is not that morality doesn\u2019t matter but that the Spirit \u2014 not the Law \u2014 produces genuine goodness. This fruit is his direct refutation of the charge that grace leads to licence.',
        historicalContext:
            'The Greek \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 is an extremely rare word \u2014 absent from classical Greek literature and appearing in only four NT passages (Rom 15:14; Gal 5:22; Eph 5:9; 2 Thess 1:11), all Pauline. It appears to be a Septuagintal coinage, possibly formed to translate a Hebrew term for active moral goodness. Its rarity suggests it may carry a specifically Jewish-Christian meaning that Paul develops from the OT concept of God\u2019s \u1e6d\u00f4b \u2014 God\u2019s active goodness that creates, blesses, and restores (Longenecker 1990, 263; Bruce 1982, 253). Jerome distinguished it from kindness: \u2018goodness can include severity for the sake of correction\u2019 (Commentary on Galatians, ad loc.).',
        scholarlyInterpretation:
            'The relationship between \u03c7\u03c1\u03b7\u03c3\u03c4\u03cc\u03c4\u03b7\u03c2 (kindness) and \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 (goodness) has generated scholarly discussion. Longenecker argues kindness is the gentler disposition, while goodness includes moral robustness \u2014 the willingness to confront evil and correct wrong (Longenecker 1990, 263). Fee observes that the word\u2019s rarity makes precise definition difficult, but its context alongside kindness and faithfulness suggests active moral integrity rather than passive innocence (Fee 1994, 449\u201350). Dunn reads the word as the \u2018fullness of moral character\u2019 \u2014 comprehensive righteousness produced by the Spirit in contrast to the selective rule-keeping of Torah observance (Dunn 1993, 310\u201311). Moo argues \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 denotes \u2018uprightness of heart and life\u2019 and represents Paul\u2019s positive answer to the charge that freedom from Law leads to libertinism: the Spirit produces a goodness Torah could not (Moo 2013, 369). Schreiner connects it to Paul\u2019s broader argument: the purpose of the Law is fulfilled not by keeping its letter but by walking in the Spirit, whose fruit includes the very goodness the Law demanded (Schreiner 2010, 347\u201348).',
        exegeticalNotes:
            'The suffix -\u03c3\u03cd\u03bd\u03b7 is used to form abstract nouns denoting quality or state (cf. \u03b4\u03b9\u03ba\u03b1\u03b9\u03bf\u03c3\u03cd\u03bd\u03b7, \u2018righteousness\u2019). The word \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 is likely Paul\u2019s own contribution to Greek theological vocabulary, constructed from the common adjective \u1f00\u03b3\u03b1\u03b8\u03cc\u03c2 (\u2018good\u2019) and shaped by the LXX\u2019s use of \u1f00\u03b3\u03b1\u03b8\u03cc\u03c2 to describe God\u2019s character. In Ephesians 5:9 Paul groups \u1f00\u03b3\u03b1\u03b8\u03c9\u03c3\u03cd\u03bd\u03b7 with \u03b4\u03b9\u03ba\u03b1\u03b9\u03bf\u03c3\u03cd\u03bd\u03b7 and \u1f00\u03bb\u03ae\u03b8\u03b5\u03b9\u03b1 (\u2018righteousness\u2019 and \u2018truth\u2019) as the \u2018fruit of light,\u2019 paralleling the Galatians fruit list with a light-darkness contrast. The word\u2019s virtual absence outside Paul confirms its distinctively Pauline theological weight (Bruce 1982, 253; Longenecker 1990, 263).',
      );

    case FruitType.faithfulness:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 faith\u2026\u201d \u2014 Galatians 5:22g',
        statementInBrief:
            'The Spirit produces \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 \u2014 which in this ethical context means faithfulness, reliability, and trustworthiness in relationships. The same faith that justifies also becomes a character trait: the Spirit-led person is someone others can depend on.',
        centralPoint:
            'The faith that saves also transforms. The Spirit takes the trust by which you entered relationship with God and grows it into the faithfulness by which you sustain relationships with others \u2014 reliability, integrity, keeping your word.',
        question:
            'Am I reliable? Can people depend on my word, my commitments, my presence? Where has my faithfulness grown thin \u2014 and what would it look like to ask the Spirit to strengthen it?',
        practices: [
          'Identify one commitment you have let slide \u2014 to a person, a group, a practice \u2014 and follow through on it this week (Faithfulness)',
          'Examine whether your reputation for reliability matches your self-image (Honesty)',
          'Pray for the Spirit to deepen your trustworthiness in the small, unseen commitments of daily life (Prayer)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'In a letter dominated by the word \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 \u2014 faith \u2014 Paul now names it as a fruit of the Spirit. This is striking: the Galatians have heard \u2018faith\u2019 throughout the letter as the means of justification (2:16; 3:2, 5, 7, 9, 11, 14, 22, 24, 26). Now Paul tells them faith is also a character quality the Spirit produces. It is both the door into the kingdom and the daily texture of life within it.',
        historicalContext:
            'The Greek \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 can mean either \u2018faith\u2019 (trust in God) or \u2018faithfulness\u2019 (trustworthiness, reliability). In classical Greek and in the Greco-Roman virtue tradition, \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 primarily meant fidelity and trustworthiness \u2014 a cardinal civic and personal virtue (BDAG, 818\u201320). In the Hebrew Bible, \u02bfem\u00fbn\u00e2 (\u2018faithfulness\u2019) is a defining attribute of God (Deut 7:9; Ps 36:5; Lam 3:22\u201323) and a quality expected of his covenant people. In Galatians, Paul has used \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 throughout the letter to denote saving faith (pistis Christou, whether \u2018faith in Christ\u2019 or \u2018faithfulness of Christ\u2019), but here in a virtue list the contextual meaning is almost certainly faithfulness as a character trait (Bruce 1982, 253\u201354; Fee 1994, 450).',
        scholarlyInterpretation:
            'Nearly all modern commentators read \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 in this context as \u2018faithfulness\u2019 rather than \u2018faith\u2019 (saving trust in God). Fee argues the ethical context requires this: in a list of interpersonal virtues (patience, kindness, goodness), \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 means reliability toward others (Fee 1994, 450). Longenecker concurs: \u2018fidelity\u2019 or \u2018trustworthiness\u2019 in one\u2019s dealings with others is the natural sense (Longenecker 1990, 263\u201364). Bruce notes the semantic range and suggests both dimensions may be present \u2014 the faith that trusts God produces the faithfulness that sustains human relationships (Bruce 1982, 253\u201354). Moo argues more carefully: while the primary sense is relational faithfulness, Paul\u2019s overall theology of \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 means the distinction is not sharp \u2014 the same Spirit who produces saving faith also produces daily faithfulness (Moo 2013, 369\u201370). Witherington observes that the classical virtue of \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 (trustworthiness, keeping faith) would be immediately recognisable to Gentile converts, giving this fruit cross-cultural ethical resonance (Witherington 1998, 413). N. T. Wright notes the Pauline paradox: \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 is both the instrument of justification (3:24) and the product of sanctification (5:22) \u2014 faith is received and then reproduced as character (Wright 2013, 1014\u201316).',
        exegeticalNotes:
            'The word \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 appears 22 times in Galatians \u2014 more than in any other Pauline letter relative to length \u2014 making it the letter\u2019s dominant theological term. Its appearance in the fruit list is therefore deeply resonant: the word that has structured the entire letter\u2019s argument about justification now reappears as an ethical quality produced by the Spirit. The shift from soteriological to ethical usage is controlled by context: in the vice-and-virtue list, \u03c0\u03af\u03c3\u03c4\u03b9\u03c2 sits among interpersonal virtues, not among theological declarations (Dunn 1993, 311). Some scholars note the possible wordplay with \u1f00\u03c0\u03b9\u03c3\u03c4\u03af\u03b1 (\u2018faithlessness\u2019), which though absent from the flesh list, is the implicit opposite (Schreiner 2010, 348).',
      );

    case FruitType.gentleness:
      return const _FruitStudyData(
        scripture: '\u201cBut the fruit of the Spirit is\u2026 gentleness\u2026\u201d \u2014 Galatians 5:23a',
        statementInBrief:
            'The Spirit produces gentleness \u2014 not weakness or timidity but the controlled strength that handles others, especially in conflict and correction, without harshness, arrogance, or self-righteousness. It is power held in check by love.',
        centralPoint:
            'Gentleness is strength under the Spirit\u2019s control. It is how the Spirit-led person exercises influence, corrects error, and handles disagreement \u2014 not with domination but with the same humility Christ displayed.',
        question:
            'How do I handle people when I have power over them \u2014 when I am right and they are wrong, when I could crush but could also restore? Is there gentleness in my correction, or only rightness?',
        practices: [
          'In one conversation this week where you are tempted to be harsh, deliberately choose a gentle tone (Gentleness)',
          'Reflect on how Jesus corrected people \u2014 and compare it honestly with how you do (Imitation)',
          'Ask someone close to you whether they experience you as gentle \u2014 and receive their honest answer (Feedback)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul will use this very word two verses later when instructing the Galatians on how to handle a fellow believer caught in sin: \u2018you who are spiritual, restore such a one in a spirit of gentleness\u2019 (6:1). The Spirit\u2019s fruit is not abstract \u2014 it is immediately applied to the hardest relational challenge the community faces: correction without condemnation.',
        historicalContext:
            'The Greek \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 describes the quality of one who is \u03c0\u03c1\u03b1\u0390\u03c2 \u2014 the same word used in the third Beatitude (Matt 5:5). In classical Greek, it described the controlled strength of a trained horse or the calmness of a person who does not fly into anger \u2014 power held in check, not the absence of power (Aristotle, Nicomachean Ethics 4.5 defines \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 as the mean between excessive anger and deficiency of spirit). Moses is described as \u03c0\u03c1\u03b1\u0390\u03c2 above all people (Num 12:3 LXX), and Jesus describes himself as \u03c0\u03c1\u03b1\u0390\u03c2 (Matt 11:29). In the ancient world it was a virtue of the strong, not the weak (Bruce 1982, 254; Fee 1994, 450\u201351).',
        scholarlyInterpretation:
            'Fee stresses that \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 is the opposite of self-assertion and self-aggrandisement \u2014 the very vices destroying the Galatian community (Fee 1994, 450\u201351). Longenecker connects it directly to 6:1, where Paul instructs the \u2018spiritual\u2019 to restore the fallen \u2018in a spirit of gentleness\u2019 \u2014 the fruit of 5:23 becomes the method of 6:1 (Longenecker 1990, 264). Moo argues \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 is the essential corrective to the self-righteous use of spiritual authority: those who are genuinely Spirit-led handle others gently (Moo 2013, 370). Dunn reads it as the antithesis of \u1f10\u03c1\u03b9\u03b8\u03b5\u03af\u03b1 (\u2018selfish ambition,\u2019 5:20 in the flesh list) \u2014 where the flesh asserts self, the Spirit produces a yielded, humble spirit (Dunn 1993, 311\u201312). Hays emphasises the christological grounding: Paul appeals to \u2018the gentleness and courtesy of Christ\u2019 in 2 Corinthians 10:1, making Christ himself the exemplar (Hays 2000, 328\u201329). Betz notes that in the Hellenistic moral tradition, \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 was a recognised virtue of good leadership \u2014 Paul appropriates it for community governance within the church (Betz 1979, 288).',
        exegeticalNotes:
            'The cognate noun \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 and adjective \u03c0\u03c1\u03b1\u0390\u03c2 are used interchangeably in Paul. The word\u2019s appearance in the fruit list and its immediate reuse in 6:1 (\u1f10\u03bd \u03c0\u03bd\u03b5\u03cd\u03bc\u03b1\u03c4\u03b9 \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c4\u03bf\u03c2, \u2018in a spirit of gentleness\u2019) create a tight literary connection between the theological list and its practical application. Paul uses \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 again in 1 Corinthians 4:21 (\u2018shall I come to you with a rod or in love and a spirit of gentleness?\u2019) \u2014 always in contexts where correction is needed and the manner of correction is at stake. The placement of \u03c0\u03c1\u03b1\u0390\u03c4\u03b7\u03c2 penultimately in the list, between faithfulness and self-control, positions it as the bridge between relational fidelity and personal discipline (Schreiner 2010, 348\u201349).',
      );

    case FruitType.selfControl:
      return const _FruitStudyData(
        scripture:
            '\u201cBut the fruit of the Spirit is\u2026 self-control. Against such things there is no law.\u201d \u2014 Galatians 5:23b',
        statementInBrief:
            'The Spirit produces self-control \u2014 the mastery of desires, impulses, and appetites that the Law attempted to impose externally but that the Spirit cultivates internally. The closing phrase \u2014 \u2018against such things there is no law\u2019 \u2014 is Paul\u2019s theological punchline: the Spirit renders the Law\u2019s supervisory role unnecessary.',
        centralPoint:
            'Self-control is the Spirit\u2019s answer to the Law\u2019s question. The Law said \u2018don\u2019t\u2019 from the outside; the Spirit produces \u2018I won\u2019t need to\u2019 from the inside. Against the fruit of the Spirit, the Law has nothing to say \u2014 because the Spirit fulfils everything the Law ever demanded.',
        question:
            'Where in my life am I relying on external rules and willpower to control behaviour that the Spirit wants to transform from the inside? What appetite or impulse do I need to bring honestly to the Spirit rather than merely managing on my own?',
        practices: [
          'Identify one area where you rely on willpower alone \u2014 and ask the Spirit to produce internal transformation rather than external management (Transformation)',
          'Practise one act of deliberate restraint this week \u2014 not as punishment but as a way of exercising the Spirit\u2019s gift (Discipline)',
          'Reflect on whether your self-control is anxious self-management or the Spirit\u2019s calm mastery (Reflection)',
        ],
        audienceContextTitle: 'Why this fruit matters to the Galatians',
        audienceContext:
            'Paul closes the list with the virtue the agitators feared most would be lost without the Law: self-control. Their argument was that without Torah, Gentile believers would inevitably slide into the vices of the flesh list (5:19\u201321). Paul\u2019s final fruit is his answer: the Spirit produces the very self-mastery that the Law aimed at but could not achieve. And then the devastating conclusion: \u2018Against such things there is no law.\u2019',
        historicalContext:
            'The Greek \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 (\u2018self-control, mastery\u2019) was one of the four cardinal virtues of Greek philosophy alongside wisdom, courage, and justice. Plato discussed it in the Republic and Phaedrus; Aristotle treated it in Nicomachean Ethics 7 as the capacity to resist desires that reason judges harmful. The Stoics elevated it to a defining virtue of the sage. By using \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1, Paul engages directly with Greco-Roman moral philosophy on its own terms \u2014 but relocates the source of self-mastery from reason and willpower to the indwelling Spirit (Betz 1979, 288\u201389; Witherington 1998, 413). In the LXX, \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 appears in the Wisdom of Sirach (18:30) and the Testaments of the Twelve Patriarchs as a mark of the righteous. Its placement at the end of Paul\u2019s list may be deliberate: the classical virtue tradition placed it last among the cardinal virtues as the capstone quality enabling all others (Fee 1994, 451\u201352).',
        scholarlyInterpretation:
            'Fee argues \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 is Paul\u2019s \u2018coup de gr\u00e2ce\u2019 against the agitators: they insisted the Law was necessary to restrain the flesh, but Paul demonstrates that the Spirit produces the very self-mastery the Law sought to impose (Fee 1994, 451\u201352). Martyn reads the closing formula \u2018against such things there is no law\u2019 as Paul\u2019s definitive conclusion to the entire Law-vs-Spirit argument of the letter: the Spirit renders Torah unnecessary as a moral guide because the Spirit produces everything Torah demanded and more (Martyn 1997, 532\u201333). Bruce notes the breadth of the closing statement: \u2018such things\u2019 (\u03c4\u1ff6\u03bd \u03c4\u03bf\u03b9\u03bf\u03cd\u03c4\u03c9\u03bd) indicates the list is not exhaustive but representative \u2014 the Spirit produces an open-ended abundance of character (Bruce 1982, 254\u201355). Longenecker emphasises that Paul\u2019s inclusion of a classical Greek virtue here signals his theological method: the gospel does not reject Greco-Roman moral insight but relocates its source in the Spirit (Longenecker 1990, 264\u201365). Moo stresses the contrast between \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 (Spirit-produced mastery over sinful desires) and the \u2018works of the flesh\u2019 \u2014 especially \u1f00\u03c3\u03ad\u03bb\u03b3\u03b5\u03b9\u03b1 (\u2018sensuality/licence\u2019) and \u03bc\u03ad\u03b8\u03b7 (\u2018drunkenness\u2019) \u2014 as antithetical pairs (Moo 2013, 370\u201371). Schreiner captures the theological arc: the fruit list begins with love (the governing virtue) and ends with self-control (the enabling virtue); together they produce the life the Law envisioned but could not create (Schreiner 2010, 349).',
        exegeticalNotes:
            'The noun \u1f10\u03b3\u03ba\u03c1\u03ac\u03c4\u03b5\u03b9\u03b1 appears only three times in the NT (Gal 5:23; Acts 24:25; 2 Pet 1:6), but the cognate verb \u1f10\u03b3\u03ba\u03c1\u03b1\u03c4\u03b5\u03cd\u03bf\u03bc\u03b1\u03b9 appears in 1 Corinthians 7:9 (sexual self-control) and 9:25 (athletic discipline), giving Pauline usage a broader base. The closing phrase \u03ba\u03b1\u03c4\u1f70 \u03c4\u1ff6\u03bd \u03c4\u03bf\u03b9\u03bf\u03cd\u03c4\u03c9\u03bd \u03bf\u1f50\u03ba \u1f14\u03c3\u03c4\u03b9\u03bd \u03bd\u03cc\u03bc\u03bf\u03c2 (\u2018against such things there is no law\u2019) is one of the most theologically compressed statements in the letter. The genitive \u03c4\u1ff6\u03bd \u03c4\u03bf\u03b9\u03bf\u03cd\u03c4\u03c9\u03bd (\u2018such things\u2019) is deliberately open-ended \u2014 as Bruce notes, it signals these nine are representative, not exhaustive (Bruce 1982, 254\u201355). The phrase \u03bf\u1f50\u03ba \u1f14\u03c3\u03c4\u03b9\u03bd \u03bd\u03cc\u03bc\u03bf\u03c2 can be read either as \u2018there is no law that condemns such behaviour\u2019 (the minimal reading) or as \u2018the Law has nothing to contribute here because the Spirit has already accomplished what the Law could not\u2019 (the maximal reading, favoured by Martyn 1997, 533 and Fee 1994, 452). The latter reading is more consonant with Galatians\u2019 argument: the Spirit is not supplementing the Law but superseding it as the guide for moral life.',
      );
  }
}

// ── Linked Practices Chips ────────────────────────────────────────────────────

class _LinkedPracticesChips extends StatelessWidget {
  final List<Habit> habits;
  final FruitType fruit;

  const _LinkedPracticesChips({required this.habits, required this.fruit});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = habits.take(maxVisible).toList();
    final overflow = habits.length - maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visible.map((h) => _chip(h.name)),
        if (overflow > 0)
          _chip('+$overflow more', dim: true),
      ],
    );
  }

  Widget _chip(String label, {bool dim = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fruit.color.withValues(alpha: dim ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fruit.color.withValues(alpha: dim ? 0.2 : 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fruit.color.withValues(alpha: dim ? 0.4 : 0.8),
        ),
      ),
    );
  }
}
