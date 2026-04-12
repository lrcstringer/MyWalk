import 'package:flutter/material.dart';
import '../../../domain/entities/parable.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';
import '../journal/journal_entry_composer.dart';

const _kAccent = Color(0xFFC8A96E); // warm parchment gold

class ParableDetailView extends StatelessWidget {
  final ParableModel parable;

  const ParableDetailView({super.key, required this.parable});

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
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined, color: MyWalkColor.softGold),
                onPressed: () => BibleProjectBrowserView.openOrPrompt(context, reference: parable.reference),
                tooltip: 'Bible',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (parable.imagePath != null)
                    Image.asset(
                      parable.imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  else
                    Container(
                      color: _kAccent.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(parable.icon, size: 64, color: _kAccent.withValues(alpha: 0.3)),
                      ),
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
                          parable.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: parable.reference),
                              child: Text(
                                parable.reference,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _kAccent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _kAccent.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                parable.theme,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _kAccent.withValues(alpha: 0.85),
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
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Text(
                    parable.summary,
                    style: TextStyle(
                      fontSize: 15,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verse block — tappable → opens Bible browser
                  if (parable.verse.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: parable.reference),
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
                                    '\u201c${parable.verse}\u201d',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                                      height: 1.65,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\u2014 ${parable.reference}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _kAccent.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (parable.statementInBrief.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showParableDetail(context),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.menu_book_outlined, size: 11, color: _kAccent.withValues(alpha: 0.6)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'More on this parable',
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Journal entry CTA
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalEntryComposer(
                          habitName: 'Parable: ${parable.title}',
                          sourceType: 'parable',
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note, size: 16, color: _kAccent.withValues(alpha: 0.7)),
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

  void _showParableDetail(BuildContext context) {
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
                  Icon(parable.icon, size: 20, color: _kAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parable.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _kAccent,
                          ),
                        ),
                        Text(
                          parable.reference,
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
                  _scriptureBox('\u201c${parable.verse}\u201d \u2014 ${parable.reference}'),
                  const SizedBox(height: 20),
                  // 2. Statement in Brief
                  if (parable.statementInBrief.isNotEmpty) ...[
                    _sectionHeader('THE STATEMENT IN BRIEF'),
                    _bodyPara(parable.statementInBrief),
                    const SizedBox(height: 16),
                  ],
                  // 3. Central Point
                  if (parable.centralPoint.isNotEmpty) ...[
                    _sectionHeader('THE CENTRAL POINT'),
                    _highlightBox(
                      parable.centralPointTitle.isNotEmpty ? parable.centralPointTitle : 'Central Point',
                      parable.centralPoint,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 4. Question It Asks You
                  if (parable.pdfQuestion.isNotEmpty) ...[
                    _sectionHeader('THE QUESTION IT ASKS YOU'),
                    _italicPara(parable.pdfQuestion),
                    const SizedBox(height: 16),
                  ],
                  // 5. Suggested Practices
                  if (parable.pdfPractices.isNotEmpty) ...[
                    _sectionHeader('SUGGESTED PRACTICES'),
                    ...parable.pdfPractices.map((p) => _practiceItem(p)),
                    const SizedBox(height: 12),
                    _divider(),
                    const SizedBox(height: 16),
                  ],
                  // 6. Audience and Context
                  if (parable.audienceContext.isNotEmpty) ...[
                    _sectionHeader('AUDIENCE AND CONTEXT'),
                    _bodyPara(parable.audienceContext),
                    const SizedBox(height: 16),
                  ],
                  // 7. Historical and Cultural Context
                  if (parable.historicalContext.isNotEmpty) ...[
                    _sectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                    _bodyPara(parable.historicalContext),
                    const SizedBox(height: 16),
                  ],
                  // 8. Scholarly Interpretation
                  if (parable.scholarlyInterpretation.isNotEmpty) ...[
                    _sectionHeader('SCHOLARLY INTERPRETATION'),
                    _bodyPara(parable.scholarlyInterpretation),
                    const SizedBox(height: 16),
                  ],
                  // 9. Exegetical and Literary Notes
                  if (parable.exegeticalNotes.isNotEmpty) ...[
                    _sectionHeader('EXEGETICAL AND LITERARY NOTES'),
                    _bodyPara(parable.exegeticalNotes),
                  ],
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

  Widget _sectionHeader(String text) => Padding(
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

  Widget _highlightBox(String title, String body) => Container(
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

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07));
}
