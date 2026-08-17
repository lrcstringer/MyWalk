import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/bible_reading_plan_data.dart';
import '../../../domain/entities/bible_reading_plan.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../providers/bible_reading_provider.dart';
import '../../providers/journal_provider.dart';
import '../../theme/app_theme.dart';
import '../bible/bible_browser_view.dart';
import '../journal/journal_entry_composer.dart';

class BibleReadingDayModal extends StatelessWidget {
  final int weekIndex;
  final int dayIndex;

  const BibleReadingDayModal({
    super.key,
    required this.weekIndex,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BibleReadingProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final dayPlan = BibleReadingPlanData.weeks[weekIndex][dayIndex];
    final state = provider.state;
    final dayName = BibleReadingPlanData.dayNames[dayIndex];
    final isActive = provider.isActive;
    final isCurrent = provider.currentWeekIndex == weekIndex &&
        provider.currentDayIndex == dayIndex;

    // Journal entries for this specific day — use allEntries so an active
    // search query in the journal tab cannot hide entries here.
    final dayKey = '${weekIndex}_$dayIndex';
    final linkedEntries = journalProvider.allEntries
        .where((e) =>
            e.sourceType == 'bible_reading_plan' &&
            e.habitId == dayKey)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MyWalkColor.softGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week ${weekIndex + 1} — $dayName',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: MyWalkColor.warmWhite,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCurrent)
                            const Text(
                              "Today's reading",
                              style: TextStyle(
                                color: MyWalkColor.golden,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Journal pill
                    GestureDetector(
                      onTap: () => _openJournal(context, weekIndex, dayIndex, dayName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MyWalkColor.golden.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MyWalkColor.golden.withValues(alpha: 0.35),
                            width: 0.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note,
                                color: MyWalkColor.golden, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Create Journal Entry',
                              style: TextStyle(
                                color: MyWalkColor.golden,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MyWalkColor.cardBorder),
              // Sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    ...BibleReadingSection.ordered
                        .where((s) => dayPlan.refsForSection(s).isNotEmpty)
                        .map((s) => _SectionTile(
                              weekIndex: weekIndex,
                              dayIndex: dayIndex,
                              section: s,
                              dayPlan: dayPlan,
                              state: state,
                              provider: provider,
                              interactive: isActive,
                            )),
                    if (linkedEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _JournalSection(entries: linkedEntries),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openJournal(BuildContext context, int w, int d, String dayName) {
    final dayKey = '${w}_$d';
    final title = 'Bible Reading — Week ${w + 1}, $dayName';
    final dayPlan = BibleReadingPlanData.weeks[w][d];
    final readings = BibleReadingSection.ordered
        .where((s) => dayPlan.refsForSection(s).isNotEmpty)
        .map((s) => dayPlan.refsForSection(s).map((r) => r.label).join(', '))
        .join('\n');
    final prefill = '$title\n\n$readings';

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JournalEntryComposer(
          habitId: dayKey,
          habitName: prefill,
          sourceType: 'bible_reading_plan',
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── Section accent colours ────────────────────────────────────────────────────

extension _SectionAccent on BibleReadingSection {
  Color get accent {
    switch (this) {
      case BibleReadingSection.psalms:       return MyWalkColor.softGold;
      case BibleReadingSection.newTestament: return const Color(0xFF6B9FD4);
      case BibleReadingSection.torah:        return const Color(0xFFD4956A);
      case BibleReadingSection.historical:   return MyWalkColor.sage;
      case BibleReadingSection.prophetic:    return const Color(0xFF9B8EC8);
      case BibleReadingSection.wisdom:       return MyWalkColor.warmCoral;
    }
  }
}

// ── Section tile ───────────────────────────────────────────────────────────────

class _SectionTile extends StatefulWidget {
  final int weekIndex;
  final int dayIndex;
  final BibleReadingSection section;
  final BibleReadingDayPlan dayPlan;
  final BibleReadingPlanState? state;
  final BibleReadingProvider provider;
  final bool interactive;

  const _SectionTile({
    required this.weekIndex,
    required this.dayIndex,
    required this.section,
    required this.dayPlan,
    required this.state,
    required this.provider,
    required this.interactive,
  });

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
    // If the section is already done when the widget first appears (e.g. modal
    // re-opened), run the check animation after the first frame so we don't
    // call forward() during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDone = widget.state?.isSectionDone(
            widget.weekIndex,
            widget.dayIndex,
            widget.section,
          ) ??
          false;
      if (isDone && _checkAnim.status == AnimationStatus.dismissed) {
        _checkAnim.forward();
      }
    });
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.state?.isSectionDone(
          widget.weekIndex,
          widget.dayIndex,
          widget.section,
        ) ??
        false;
    final refs = widget.dayPlan.refsForSection(widget.section);
    final accent = widget.section.accent;
    final stripeColor = isDone ? MyWalkColor.sage : accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: stripeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stripeColor.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent stripe
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.section.label,
                            style: TextStyle(
                              color: isDone ? MyWalkColor.sage : accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.interactive)
                          isDone
                              ? ScaleTransition(
                                  scale: _checkScale,
                                  child: GestureDetector(
                                    onTap: () => _toggle(isDone),
                                    child: const Icon(Icons.check_circle,
                                        color: MyWalkColor.sage, size: 22),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => _toggle(isDone),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.35),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_rounded,
                                            size: 13, color: accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Done',
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Reading refs (tappable)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: refs
                          .map((r) => _RefChip(ref: r, accent: accent))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(bool currentDone) async {
    final newDone = !currentDone;
    if (newDone) _checkAnim.forward();
    try {
      await widget.provider.setSectionDone(
        widget.weekIndex,
        widget.dayIndex,
        widget.section,
        newDone,
      );
    } catch (_) {
      // Plan was reset while modal was open — doc no longer exists.
      // Revert the optimistic animation so the UI stays consistent.
      if (newDone && mounted) _checkAnim.reverse();
    }
  }
}

// ── Reading reference chip ────────────────────────────────────────────────────

class _RefChip extends StatelessWidget {
  final BibleReadingRef ref;
  final Color accent;
  const _RefChip({required this.ref, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BibleBrowserView(
            initialBook: ref.bookNum,
            initialChapter: ref.chapter,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 12, color: accent),
            const SizedBox(width: 5),
            Text(
              ref.label,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linked journal entries ────────────────────────────────────────────────────

class _JournalSection extends StatelessWidget {
  final List<JournalEntry> entries;
  const _JournalSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal entries',
          style: TextStyle(
            color: MyWalkColor.softGold.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((e) => _JournalEntryTile(entry: e)),
      ],
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  final JournalEntry entry;
  const _JournalEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final preview = JournalEntry.extractPlainText(entry.text);
    final date = entry.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => JournalEntryComposer(initialEntry: entry),
          fullscreenDialog: true,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.habitName != null)
                    Text(
                      entry.habitName!,
                      style: const TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      style: TextStyle(
                        color: MyWalkColor.softGold.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(
                color: MyWalkColor.softGold.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
