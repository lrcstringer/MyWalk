import 'package:flutter/material.dart';
import '../../../domain/entities/beatitude.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';
import '../journal/journal_entry_composer.dart';
import 'beatitude_practices_view.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudeDetailView extends StatelessWidget {
  final BeatitudeModel beatitude;

  const BeatitudeDetailView({super.key, required this.beatitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ───────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 220,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined, color: MyWalkColor.softGold),
                onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
                tooltip: 'Bible',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    beatitude.imagePath,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.55),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.6, 1.0],
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
                        Text(
                          beatitude.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          beatitude.verseRef,
                          style: TextStyle(
                            fontSize: 13,
                            color: _kAccent.withValues(alpha: 0.9),
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

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promise badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline, size: 13, color: _kAccent.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'Promise: ${beatitude.promise}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kAccent.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verse quote — tappable → opens Bible browser
                  GestureDetector(
                    onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: beatitude.verseRef),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
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
                                  '\u201c${beatitude.verse}\u201d',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                                    height: 1.65,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\u2014 ${beatitude.verseRef}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showBeatitudeDetail(context),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.menu_book_outlined, size: 11, color: _kAccent.withValues(alpha: 0.6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'More on this Beatitude',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _kAccent.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(Icons.chevron_right, size: 13, color: _kAccent.withValues(alpha: 0.5)),
                                        ],
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
                  ),
                  const SizedBox(height: 28),

                  // Your Why
                  _sectionLabel('Your Why'),
                  const SizedBox(height: 8),
                  Text(
                    beatitude.yourWhy,
                    style: TextStyle(
                      fontSize: 15,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // What This Means
                  _sectionLabel('What This Means'),
                  const SizedBox(height: 8),
                  Text(
                    beatitude.whatThisMeans,
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Reflection Question
                  _sectionLabel('Reflection'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      beatitude.reflectionQuestion,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Fruit Connection
                  _sectionLabel('Fruit Connection'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: beatitude.fruitConnection
                        .map((f) => _fruitChip(f))
                        .toList(),
                  ),
                  const SizedBox(height: 28),

                  // Add a practice CTA
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BeatitudePracticesView(beatitude: beatitude),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: _kAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Add a ${beatitude.title} practice',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Journal entry CTA
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalEntryComposer(
                          habitName: 'The Beatitudes: ${beatitude.title}',
                          sourceType: 'beatitude',
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _kAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note,
                              size: 16,
                              color: _kAccent.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text(
                            'Add a journal entry',
                            style: TextStyle(
                              fontSize: 14,
                              color: _kAccent.withValues(alpha: 0.7),
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: _kAccent.withValues(alpha: 0.8),
        ),
      );

  Widget _fruitChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _kAccent.withValues(alpha: 0.85),
          ),
        ),
      );

  void _showBeatitudeDetail(BuildContext context) {
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
                  Icon(Icons.self_improvement, size: 20, color: _kAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beatitude.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _kAccent,
                          ),
                        ),
                        Text(
                          beatitude.verseRef,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.6),
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
                  _detailScriptureBox('\u201c${beatitude.verse}\u201d \u2014 ${beatitude.verseRef}'),
                  const SizedBox(height: 20),
                  // 2. Statement in Brief
                  if (beatitude.statementInBrief.isNotEmpty) ...[
                    _detailSectionHeader('THE STATEMENT IN BRIEF'),
                    _detailBodyPara(beatitude.statementInBrief),
                    const SizedBox(height: 16),
                  ],
                  // 3. Central Point
                  if (beatitude.centralPoint.isNotEmpty) ...[
                    _detailSectionHeader('THE CENTRAL POINT'),
                    _detailHighlightBox(
                      beatitude.centralPointTitle.isNotEmpty
                          ? beatitude.centralPointTitle
                          : 'Central Point',
                      beatitude.centralPoint,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 4. Question It Asks You
                  if (beatitude.pdfQuestion.isNotEmpty) ...[
                    _detailSectionHeader('THE QUESTION IT ASKS YOU'),
                    _detailItalicPara(beatitude.pdfQuestion),
                    const SizedBox(height: 16),
                  ],
                  // 5. Suggested Practices
                  if (beatitude.pdfPractices.isNotEmpty) ...[
                    _detailSectionHeader('SUGGESTED PRACTICES'),
                    ...beatitude.pdfPractices.map((p) => _detailPracticeItem(p)),
                    const SizedBox(height: 12),
                    _detailDivider(),
                    const SizedBox(height: 16),
                  ],
                  // 6. Audience and Context
                  if (beatitude.audienceContext.isNotEmpty) ...[
                    _detailSectionHeader('AUDIENCE AND CONTEXT'),
                    _detailBodyPara(beatitude.audienceContext),
                    const SizedBox(height: 16),
                  ],
                  // 7. Historical and Cultural Context
                  if (beatitude.historicalContext.isNotEmpty) ...[
                    _detailSectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                    _detailBodyPara(beatitude.historicalContext),
                    const SizedBox(height: 16),
                  ],
                  // 8. Scholarly Interpretation
                  if (beatitude.scholarlyInterpretation.isNotEmpty) ...[
                    _detailSectionHeader('SCHOLARLY INTERPRETATION'),
                    _detailBodyPara(beatitude.scholarlyInterpretation),
                    const SizedBox(height: 16),
                  ],
                  // 9. Exegetical and Literary Notes
                  if (beatitude.exegeticalNotes.isNotEmpty) ...[
                    _detailSectionHeader('EXEGETICAL AND LITERARY NOTES'),
                    _detailBodyPara(beatitude.exegeticalNotes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailScriptureBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
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

  Widget _detailSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kAccent.withValues(alpha: 0.7),
            letterSpacing: 0.9,
          ),
        ),
      );

  Widget _detailHighlightBox(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kAccent.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kAccent.withValues(alpha: 0.9),
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

  Widget _detailBodyPara(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
          height: 1.65,
        ),
      );

  Widget _detailItalicPara(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
          height: 1.65,
        ),
      );

  Widget _detailPracticeItem(String text) => Padding(
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
                  color: _kAccent.withValues(alpha: 0.6),
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

  Widget _detailDivider() => Divider(color: Colors.white.withValues(alpha: 0.07));
}

