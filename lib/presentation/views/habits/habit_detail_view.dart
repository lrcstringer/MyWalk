import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import 'edit_habit_view.dart';
import 'habit_week_card.dart';
import 'heatmap_view.dart';
import '../kingdom_life/bible_project_browser_view.dart';

class HabitDetailView extends StatefulWidget {
  final Habit habit;
  final ScrollController? scrollController;

  const HabitDetailView({super.key, required this.habit, this.scrollController});

  @override
  State<HabitDetailView> createState() => _HabitDetailViewState();
}

class _HabitDetailViewState extends State<HabitDetailView> {
  late Habit _liveHabit;
  late HabitProvider _habitProvider;
  QuillController? _notesController;
  bool _showMonth = false;

  // Canonical getter used everywhere in the view — always the freshest data.
  Habit get _habit => _liveHabit;

  Color get _accentColor => _habit.trackingType == HabitTrackingType.abstain
      ? MyWalkColor.sage
      : MyWalkColor.golden;

  @override
  void initState() {
    super.initState();
    _liveHabit = widget.habit;
    _rebuildNotesController(_liveHabit.notes);
    _habitProvider = context.read<HabitProvider>();
    _habitProvider.addListener(_onHabitProviderChanged);
  }

  @override
  void dispose() {
    _habitProvider.removeListener(_onHabitProviderChanged);
    _notesController?.dispose();
    super.dispose();
  }

  /// Called whenever HabitProvider notifies. Looks up this habit by ID and,
  /// if any editable field changed (e.g. after saving from EditHabitView),
  /// updates [_liveHabit] and rebuilds the notes controller when needed.
  void _onHabitProviderChanged() {
    if (!mounted) return;
    final updated = _habitProvider.habits.firstWhere(
      (h) => h.id == _liveHabit.id,
      orElse: () => _liveHabit,
    );
    if (identical(updated, _liveHabit)) return;
    setState(() {
      if (updated.notes != _liveHabit.notes) {
        _rebuildNotesController(updated.notes);
      }
      _liveHabit = updated;
    });
  }

  void _rebuildNotesController(String notes) {
    _notesController?.dispose();
    _notesController = null;
    if (notes.isNotEmpty) {
      try {
        _notesController = QuillController(
          document: Document.fromJson(jsonDecode(notes) as List),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } catch (_) {
        // Corrupt notes JSON — leave controller null so the section is hidden.
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    final verse = ScriptureLibrary.completionVerse(_habit.category, DateTime.now(), isPremium: isPremium);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: Text(
          _habit.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17, color: MyWalkColor.warmWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: MyWalkColor.softGold.withValues(alpha: 0.8)),
            onPressed: () => _showEdit(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _historySection(),
          const SizedBox(height: 20),
          if (_habit.trigger.isNotEmpty || _habit.copingPlan.isNotEmpty) ...[
            _anchoringSection(),
            const SizedBox(height: 20),
          ],
          _purposeSection(),
          if (_habit.hasPrayerItems) ...[
            const SizedBox(height: 20),
            _prayerItemsSection(),
          ],
          if (_notesController != null) ...[
            const SizedBox(height: 20),
            _notesDisplaySection(),
          ],
          if (_habit.referenceUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            _referenceUrlRow(),
          ],
          const SizedBox(height: 20),
          _verseSection(verse),
          const SizedBox(height: 20),
          _habitInfoSection(),
        ],
      ),
        ],
      ),
    );
  }



  Widget _historySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _rangePill('Week', !_showMonth,
                () => setState(() => _showMonth = false)),
            const SizedBox(width: 8),
            _rangePill('Month', _showMonth,
                () => setState(() => _showMonth = true)),
          ],
        ),
        const SizedBox(height: 10),
        _showMonth ? _monthSection() : HabitWeekCard(habit: _habit),
      ],
    );
  }

  Widget _rangePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? _accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _accentColor : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _monthSection() {
    final accent = _accentColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2823),
            Color.lerp(const Color(0xFF221F1B), accent, 0.07)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 4 Weeks',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.softGold,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            color: accent.withValues(alpha: 0.18),
            thickness: 0.5,
            height: 1,
          ),
          const SizedBox(height: 12),
          HeatmapView(habit: _habit, weekCount: 4),
        ],
      ),
    );
  }

  Widget _anchoringSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_habit.trigger.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.access_time,
                  size: 13, color: MyWalkColor.golden.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text('Trigger',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.golden.withValues(alpha: 0.7))),
            ]),
            const SizedBox(height: 4),
            Text(_habit.trigger,
                style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
          ],
          if (_habit.trigger.isNotEmpty && _habit.copingPlan.isNotEmpty)
            const SizedBox(height: 10),
          if (_habit.copingPlan.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.shield_outlined,
                  size: 13, color: MyWalkColor.warmCoral.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text('Coping Plan',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmCoral.withValues(alpha: 0.7))),
            ]),
            const SizedBox(height: 4),
            Text(_habit.copingPlan,
                style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
          ],
        ],
      ),
    );
  }

  // ── Prayer Items ────────────────────────────────────────────────────────────

  void _savePrayerItems(List<PrayerItem> items) {
    _habitProvider.updateHabit(_habit.copyWith(prayerItems: items));
  }

  void _addPrayerItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Add Prayer Item',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'What would you like to pray for?',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.inputBackground,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final updated = [..._habit.prayerItems, PrayerItem.create(text)];
              _savePrayerItems(updated);
            },
            child: const Text('Add', style: TextStyle(color: MyWalkColor.golden)),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _cyclePrayerItemStatus(PrayerItem item) {
    final next = switch (item.status) {
      PrayerItemStatus.praying => PrayerItemStatus.unanswered,
      PrayerItemStatus.unanswered => PrayerItemStatus.answered,
      PrayerItemStatus.answered => PrayerItemStatus.praying,
    };
    final answeredAt = next == PrayerItemStatus.answered
        ? DateTime.now().toIso8601String()
        : null;
    final updated = _habit.prayerItems
        .map((p) => p.id == item.id
            ? p.copyWith(status: next, answeredAt: answeredAt)
            : p)
        .toList();
    _savePrayerItems(updated);
  }

  void _deletePrayerItem(String id) {
    final updated = _habit.prayerItems.where((p) => p.id != id).toList();
    _savePrayerItems(updated);
  }

  Widget _prayerItemsSection() {
    final active = _habit.prayerItems
        .where((p) => p.status != PrayerItemStatus.answered)
        .toList();
    final answered = _habit.prayerItems
        .where((p) => p.status == PrayerItemStatus.answered)
        .toList();
    final canAdd = _habit.prayerItems.length < 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Prayer List',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.softGold)),
          const Spacer(),
          if (canAdd)
            GestureDetector(
              onTap: _addPrayerItem,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 16, color: MyWalkColor.golden.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text('Add',
                    style: TextStyle(
                        fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.8))),
              ]),
            )
          else
            Text('10/10',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        if (_habit.prayerItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Text('Tap Add to record your first prayer item.',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.35))),
          ),
        ] else ...[
          if (active.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...active.map((item) => _prayerItemRow(item)),
          ],
          if (answered.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('ANSWERED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: MyWalkColor.sage.withValues(alpha: 0.6))),
            ),
            ...answered.map((item) => _prayerItemRow(item)),
          ],
        ],
      ]),
    );
  }

  Widget _prayerItemRow(PrayerItem item) {
    final isAnswered = item.status == PrayerItemStatus.answered;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.text,
                style: TextStyle(
                    fontSize: 14,
                    color: isAnswered
                        ? Colors.white.withValues(alpha: 0.4)
                        : MyWalkColor.warmWhite,
                    decoration: isAnswered ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white.withValues(alpha: 0.3))),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _cyclePrayerItemStatus(item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(item.status).withValues(alpha: 0.35)),
                ),
                child: Text(item.status.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(item.status))),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _deletePrayerItem(item.id),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.close_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.25)),
          ),
        ),
      ]),
    );
  }

  Color _statusColor(PrayerItemStatus status) {
    switch (status) {
      case PrayerItemStatus.praying:
        return MyWalkColor.golden;
      case PrayerItemStatus.unanswered:
        return MyWalkColor.warmCoral;
      case PrayerItemStatus.answered:
        return MyWalkColor.sage;
    }
  }

  Widget _notesDisplaySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold),
          ),
          const SizedBox(height: 10),
          QuillEditor.basic(
            controller: _notesController!,
            config: QuillEditorConfig(
              scrollable: false,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceUrlRow() {
    final url = _habit.referenceUrl;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: MyWalkDecorations.card,
        child: Row(
          children: [
            Icon(Icons.link_rounded,
                size: 16, color: MyWalkColor.softGold.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.softGold.withValues(alpha: 0.9),
                  decoration: TextDecoration.underline,
                  decorationColor: MyWalkColor.softGold.withValues(alpha: 0.4),
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _purposeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Why',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
          const SizedBox(height: 8),
          Text(
            _habit.purposeStatement,
            style: TextStyle(
                fontSize: 15, color: MyWalkColor.warmWhite, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _verseSection(Scripture verse) {
    return GestureDetector(
      onTap: () => BibleProjectBrowserView.openOrPrompt(context, reference: verse.reference),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              '\u201C${verse.text}\u201D',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.softGold.withValues(alpha: 0.6),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  verse.reference,
                  style: TextStyle(fontSize: 11, color: MyWalkColor.golden.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.menu_book_outlined,
                    size: 10, color: MyWalkColor.golden.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitInfoSection() {
    final activedays = _habit.activeDaySet.toList()..sort();
    const dayNames = {1: 'Sun', 2: 'Mon', 3: 'Tue', 4: 'Wed', 5: 'Thu', 6: 'Fri', 7: 'Sat'};
    final activeDaysSummary = activedays.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(
        children: [
          _infoRow('Tracking type', _habit.trackingType.name[0].toUpperCase() + _habit.trackingType.name.substring(1)),
          if (_habit.activeDaySet.length < 7) ...[
            const SizedBox(height: 8),
            _infoRow('Active days', activeDaysSummary),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold)),
      ],
    );
  }



  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (ctx, sc) => EditHabitView(habit: _habit, scrollController: sc),
      ),
    );
  }
}
