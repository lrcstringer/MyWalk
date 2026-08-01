import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/beatitude.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';
import '../journal/journal_entry_composer.dart';
import 'beatitude_practices_view.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudeDetailView extends StatefulWidget {
  final BeatitudeModel beatitude;

  const BeatitudeDetailView({super.key, required this.beatitude});

  @override
  State<BeatitudeDetailView> createState() => _BeatitudeDetailViewState();
}

class _BeatitudeDetailViewState extends State<BeatitudeDetailView> {
  final Map<int, bool> _adding = {};

  BeatitudeModel get _beatitude => widget.beatitude;

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
            sourceType: 'beatitude_practice',
            categoryId: 'the_beatitudes',
            subcategoryId: null,
            categoryName: 'The Beatitudes',
            subcategoryName: _beatitude.title,
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
          const Positioned(
            top: 0, left: 0, right: 0, height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: MyWalkColor.warmGlow),
              ),
            ),
          ),
          CustomScrollView(
        slivers: [
          // ── Hero image app bar ───────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined,
                    color: MyWalkColor.softGold),
                onPressed: () => BibleProjectBrowserView.openOrPrompt(
                    context, reference: _beatitude.verseRef),
                tooltip: 'Bible',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _beatitude.imagePath,
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
                          _beatitude.title,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: MyWalkColor.warmWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => BibleProjectBrowserView.openOrPrompt(
                              context, reference: _beatitude.verseRef),
                          child: Text(
                            _beatitude.verseRef,
                            style: TextStyle(
                              fontSize: 13,
                              color: _kAccent.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: _kAccent.withValues(alpha: 0.4),
                            ),
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
                  // ── Promise badge ────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _kAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline,
                            size: 13, color: _kAccent.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'Promise: ${_beatitude.promise}',
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

                  // ── Scripture block ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => BibleProjectBrowserView.openOrPrompt(
                        context, reference: _beatitude.verseRef),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                              color: _kAccent.withValues(alpha: 0.5), width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“${_beatitude.verse}”',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color:
                                  MyWalkColor.warmWhite.withValues(alpha: 0.85),
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '— ${_beatitude.verseRef}',
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

                  // ── YOUR WHY ─────────────────────────────────────────────
                  _sectionHeader('YOUR WHY'),
                  Text(
                    _beatitude.yourWhy,
                    style: TextStyle(
                      fontSize: 15,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── WHAT THIS MEANS ──────────────────────────────────────
                  _sectionHeader('WHAT THIS MEANS'),
                  _bodyPara(_beatitude.whatThisMeans),
                  const SizedBox(height: 28),

                  // ── REFLECTION ───────────────────────────────────────────
                  _sectionHeader('REFLECTION'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _beatitude.reflectionQuestion,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── FRUIT CONNECTION ─────────────────────────────────────
                  _sectionHeader('FRUIT CONNECTION'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _beatitude.fruitConnection
                        .map((f) => _fruitChip(f))
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  _divider(),
                  const SizedBox(height: 20),

                  // ── SCHOLARLY SECTIONS ───────────────────────────────────

                  if (_beatitude.statementInBrief.isNotEmpty) ...[
                    _sectionHeader('THE STATEMENT IN BRIEF'),
                    _bodyPara(_beatitude.statementInBrief),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.centralPoint.isNotEmpty) ...[
                    _sectionHeader('THE CENTRAL POINT'),
                    _highlightBox(
                      _beatitude.centralPointTitle.isNotEmpty
                          ? _beatitude.centralPointTitle
                          : 'Central Point',
                      _beatitude.centralPoint,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.pdfQuestion.isNotEmpty) ...[
                    _sectionHeader('THE QUESTION IT ASKS YOU'),
                    _italicPara(_beatitude.pdfQuestion),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.pdfPractices.isNotEmpty) ...[
                    _sectionHeader('SUGGESTED PRACTICES'),
                    for (int i = 0; i < _beatitude.pdfPractices.length; i++) ...[
                      _practiceCard(i, _beatitude.pdfPractices[i]),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    _divider(),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.audienceContext.isNotEmpty) ...[
                    _sectionHeader('AUDIENCE AND CONTEXT'),
                    _bodyPara(_beatitude.audienceContext),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.historicalContext.isNotEmpty) ...[
                    _sectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                    _bodyPara(_beatitude.historicalContext),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.scholarlyInterpretation.isNotEmpty) ...[
                    _sectionHeader('SCHOLARLY INTERPRETATION'),
                    _bodyPara(_beatitude.scholarlyInterpretation),
                    const SizedBox(height: 20),
                  ],

                  if (_beatitude.exegeticalNotes.isNotEmpty) ...[
                    _sectionHeader('EXEGETICAL AND LITERARY NOTES'),
                    _bodyPara(_beatitude.exegeticalNotes),
                    const SizedBox(height: 28),
                  ],

                  _divider(),
                  const SizedBox(height: 12),

                  // ── Browse curated practices ─────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BeatitudePracticesView(beatitude: _beatitude),
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
                            'Browse all ${_beatitude.title} practices',
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

                  // ── Journal entry CTA ────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalEntryComposer(
                          habitName: 'The Beatitudes: ${_beatitude.title}',
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
        ],
      ),
    );
  }

  // ── Practice card ─────────────────────────────────────────────────────────

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        valueColor: AlwaysStoppedAnimation(
                            _kAccent.withValues(alpha: 0.6)),
                      ),
                    )
                  else
                    Icon(Icons.add,
                        size: 14, color: _kAccent.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    isAdding ? 'Adding…' : 'Add this practice',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kAccent
                          .withValues(alpha: isAdding ? 0.5 : 0.85),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: _kAccent.withValues(alpha: 0.7),
          ),
        ),
      );

  Widget _highlightBox(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: _kAccent.withValues(alpha: 0.2), width: 0.5),
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

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07));
}
