import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/parable.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';
import '../journal/journal_entry_composer.dart';

const _kAccent = Color(0xFFC8A96E); // warm parchment gold

class ParableDetailView extends StatefulWidget {
  final ParableModel parable;

  const ParableDetailView({super.key, required this.parable});

  @override
  State<ParableDetailView> createState() => _ParableDetailViewState();
}

class _ParableDetailViewState extends State<ParableDetailView> {
  final Map<int, bool> _adding = {};

  ParableModel get _parable => widget.parable;

  String _habitName(String text) {
    const sep = ' — ';
    final idx = text.indexOf(sep);
    if (idx > 0 && idx <= 60) return text.substring(0, idx);
    return text.length > 60 ? '${text.substring(0, 57)}...' : text;
  }

  Future<void> _addPractice(int index, String practiceText) async {
    if (_adding[index] == true) return;
    setState(() => _adding[index] = true);

    try {
      await context.read<HabitProvider>().addHabit(
            name: _habitName(practiceText),
            category: HabitCategory.custom,
            trackingType: HabitTrackingType.checkIn,
            purpose: practiceText,
            dailyTarget: 1.0,
            targetUnit: '',
            sourceType: 'parable_practice',
            categoryId: 'the_parables',
            subcategoryId: null,
            categoryName: 'The Parables',
            subcategoryName: _parable.title,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Practice added to Today.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _adding[index] = false);
      }
    } catch (_) {
      if (mounted) setState(() => _adding[index] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          CustomScrollView(
            slivers: [
          // ── Hero image app bar ─────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined, color: MyWalkColor.softGold),
                onPressed: () => BibleProjectBrowserView.openOrPrompt(context, reference: _parable.reference),
                tooltip: 'Bible',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_parable.imagePath != null)
                    Image.asset(
                      _parable.imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  else
                    Container(
                      color: _kAccent.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(_parable.icon, size: 64, color: _kAccent.withValues(alpha: 0.3)),
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
                          _parable.title,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: MyWalkColor.warmWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: _parable.reference),
                              child: Text(
                                _parable.reference,
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
                                _parable.theme,
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

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Text(
                    _parable.summary,
                    style: TextStyle(
                      fontSize: 15,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scripture verse block
                  if (_parable.verse.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: _parable.reference),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“${_parable.verse}”',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '— ${_parable.reference}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _kAccent.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Statement in Brief
                  if (_parable.statementInBrief.isNotEmpty) ...[
                    _sectionHeader('THE STATEMENT IN BRIEF'),
                    _bodyPara(_parable.statementInBrief),
                    const SizedBox(height: 20),
                  ],

                  // Central Point
                  if (_parable.centralPoint.isNotEmpty) ...[
                    _sectionHeader('THE CENTRAL POINT'),
                    _highlightBox(
                      _parable.centralPointTitle.isNotEmpty
                          ? _parable.centralPointTitle
                          : 'Central Point',
                      _parable.centralPoint,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Question It Asks You
                  if (_parable.pdfQuestion.isNotEmpty) ...[
                    _sectionHeader('THE QUESTION IT ASKS YOU'),
                    _italicPara(_parable.pdfQuestion),
                    const SizedBox(height: 20),
                  ],

                  // Suggested Practices
                  if (_parable.pdfPractices.isNotEmpty) ...[
                    _sectionHeader('SUGGESTED PRACTICES'),
                    for (int i = 0; i < _parable.pdfPractices.length; i++) ...[
                      _practiceCard(i, _parable.pdfPractices[i]),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    _divider(),
                    const SizedBox(height: 20),
                  ],

                  // Audience and Context
                  if (_parable.audienceContext.isNotEmpty) ...[
                    _sectionHeader('AUDIENCE AND CONTEXT'),
                    _bodyPara(_parable.audienceContext),
                    const SizedBox(height: 20),
                  ],

                  // Historical and Cultural Context
                  if (_parable.historicalContext.isNotEmpty) ...[
                    _sectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                    _bodyPara(_parable.historicalContext),
                    const SizedBox(height: 20),
                  ],

                  // Scholarly Interpretation
                  if (_parable.scholarlyInterpretation.isNotEmpty) ...[
                    _sectionHeader('SCHOLARLY INTERPRETATION'),
                    _bodyPara(_parable.scholarlyInterpretation),
                    const SizedBox(height: 20),
                  ],

                  // Exegetical and Literary Notes
                  if (_parable.exegeticalNotes.isNotEmpty) ...[
                    _sectionHeader('EXEGETICAL AND LITERARY NOTES'),
                    _bodyPara(_parable.exegeticalNotes),
                    const SizedBox(height: 28),
                  ],

                  _divider(),
                  const SizedBox(height: 20),

                  // Journal entry CTA
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalEntryComposer(
                          habitName: 'Parable: ${_parable.title}',
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
        ],
      ),
    );
  }

  Widget _practiceCard(int index, String text) {
    final isAdding = _adding[index] == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isAdding ? null : () => _addPractice(index, text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: isAdding ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _kAccent.withValues(alpha: isAdding ? 0.1 : 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdding)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(_kAccent.withValues(alpha: 0.6)),
                      ),
                    )
                  else
                    Icon(Icons.add, size: 14, color: _kAccent.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    isAdding ? 'Adding…' : 'Add this practice',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kAccent.withValues(alpha: isAdding ? 0.5 : 0.85),
                      fontWeight: FontWeight.w500,
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

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07));
}
