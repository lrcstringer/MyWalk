import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../utils/category_icons.dart';
import '../../providers/habit_provider.dart';
import '../../providers/habit_category_provider.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/accountability_partnership.dart';
import '../../providers/accountability_provider.dart';
import '../shared/fruit_tag_chip.dart';

class EditHabitView extends StatefulWidget {
  final Habit habit;
  final ScrollController? scrollController;
  const EditHabitView({super.key, required this.habit, this.scrollController});

  @override
  State<EditHabitView> createState() => _EditHabitViewState();
}

class _EditHabitViewState extends State<EditHabitView> {
  late final TextEditingController _nameController;
  late final TextEditingController _aliasController;
  late final TextEditingController _purposeController;
  late final TextEditingController _triggerController;
  late final TextEditingController _copingController;
  late final TextEditingController _fruitPurposeController;
  late final QuillController _notesController;
  final FocusNode _notesFocusNode = FocusNode();
  final ScrollController _notesScrollController = ScrollController();
  late final TextEditingController _referenceUrlController;
  late double _dailyTarget;
  late String _targetUnit;
  late Set<int> _activeDays;
  late List<FruitType> _fruitTags;
  late bool _hasPrayerItems;
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  String _newPin = '';
  bool _clearPin = false;
  String? _categoryId;
  String? _subcategoryId;
  String? _categoryName;
  String? _subcategoryName;
  late bool _reminderEnabled;
  late int _reminderHour;
  late int _reminderMinute;
  bool _deleting = false;

  static const _copingSuggestions = ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse', 'Journal it out'];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _aliasController = TextEditingController(text: h.displayAlias ?? '');
    _purposeController = TextEditingController(text: h.purposeStatement);
    _triggerController = TextEditingController(text: h.trigger);
    _copingController = TextEditingController(text: h.copingPlan);
    _fruitPurposeController = TextEditingController(text: h.fruitPurposeStatement ?? '');
    if (h.notes.isNotEmpty) {
      try {
        _notesController = QuillController(
          document: Document.fromJson(jsonDecode(h.notes) as List),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _notesController = QuillController.basic();
      }
    } else {
      _notesController = QuillController.basic();
    }
    _referenceUrlController = TextEditingController(text: h.referenceUrl);
    _dailyTarget = h.dailyTarget;
    _targetUnit = h.targetUnit;
    _activeDays = h.activeDaySet;
    _fruitTags = List.from(h.fruitTags);
    _hasPrayerItems = h.hasPrayerItems;
    _categoryId = h.categoryId;
    _subcategoryId = h.subcategoryId;
    _categoryName = h.categoryName;
    _subcategoryName = h.subcategoryName;
    _reminderEnabled = h.reminderEnabled;
    _reminderHour = h.reminderHour;
    _reminderMinute = h.reminderMinute;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _purposeController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    _fruitPurposeController.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    _notesScrollController.dispose();
    _referenceUrlController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _nameEmpty => _nameController.text.trim().isEmpty;

  void _save() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;
    final isPremium = context.read<StoreProvider>().isPremium;
    final fruitPurpose = _fruitPurposeController.text.trim();
    final plainNotes = _notesController.document.toPlainText().trim();
    final notesJson = plainNotes.isEmpty
        ? ''
        : jsonEncode(_notesController.document.toDelta().toJson());
    final refUrl = _referenceUrlController.text.trim();
    final updated = widget.habit.copyWith(
      name: !widget.habit.isBuiltIn ? trimmed : null,
      purposeStatement: isPremium ? _purposeController.text : null,
      dailyTarget: _dailyTarget,
      targetUnit: _targetUnit,
      activeDays: (_activeDays.toList()..sort()).join(','),
      trigger: _triggerController.text,
      copingPlan: _copingController.text,
      fruitTags: _fruitTags,
      fruitPurposeStatement: fruitPurpose.isEmpty ? null : fruitPurpose,
      categoryId: _categoryId,
      subcategoryId: _subcategoryId,
      categoryName: _categoryName,
      subcategoryName: _subcategoryName,
      notes: notesJson,
      referenceUrl: refUrl,
      hasPrayerItems: _hasPrayerItems,
      reminderEnabled: _reminderEnabled,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      displayAlias: _aliasController.text.trim().isEmpty
          ? null
          : _aliasController.text.trim(),
      pin: _clearPin
          ? null
          : _newPin.length == 4
              ? _newPin
              : widget.habit.pin,
    );
    context.read<HabitProvider>().updateHabit(updated);
    // Update portfolio habit counts for changed tags.
    context.read<FruitPortfolioProvider>().onHabitTagsChanged(
      widget.habit.fruitTags,
      _fruitTags,
    );
    Navigator.pop(context);
  }

  IconData _categoryIcon() {
    switch (widget.habit.category) {
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      default: return Icons.auto_awesome;
    }
  }

  List<String> _triggerChips() {
    switch (widget.habit.category) {
      case HabitCategory.exercise: return ['After my morning coffee', 'Before work', 'During lunch break', 'After dinner'];
      case HabitCategory.scripture: return ['First thing in the morning', 'Before bed', 'During lunch', 'After prayer'];
      case HabitCategory.rest: return ['At 10pm', 'After dinner', 'When I feel tired'];
      case HabitCategory.fasting: return ['After morning prayer', 'On Wednesdays', 'Weekly'];
      case HabitCategory.study: return ['After dinner', 'Morning routine', 'Lunch break'];
      case HabitCategory.service: return ['After church', 'On weekends', 'When I see a need'];
      case HabitCategory.connection: return ['Sunday afternoon', 'After dinner', 'During commute'];
      default: return ['In the morning', 'After lunch', 'Before bed'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    final isAbstain = widget.habit.trackingType == HabitTrackingType.abstain;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text('Edit Practice',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
        ),
        leadingWidth: 80,
        actions: const [],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          SingleChildScrollView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _headerSection(),
          if (_categoryId != null) ...[
            const SizedBox(height: 16),
            _categoryChipsRow(),
          ],
          const SizedBox(height: 24),
          _sectionHeader('ABOUT THIS PRACTICE', MyWalkColor.sage),
          _nameSection(),
          const SizedBox(height: 20),
          _purposeSection(isPremium),
          const SizedBox(height: 20),
          _fruitSection(),
          const SizedBox(height: 20),
          _notesSection(),
          const SizedBox(height: 20),
          _referenceUrlSection(),
          const SizedBox(height: 28),
          _sectionHeader('SCHEDULE & TRACKING', MyWalkColor.eventPurple),
          if (widget.habit.trackingType == HabitTrackingType.timed) ...[
            _timedTargetSection(),
            const SizedBox(height: 20),
          ],
          if (widget.habit.trackingType == HabitTrackingType.count) ...[
            _countTargetSection(),
            const SizedBox(height: 20),
          ],
          _dayOfWeekSection(isAbstain),
          const SizedBox(height: 20),
          _reminderSection(),
          const SizedBox(height: 20),
          if (isAbstain) _copingSection() else _triggerSection(),
          const SizedBox(height: 20),
          if (isAbstain) ...[
            _partnerSection(),
            const SizedBox(height: 20),
            _recoveryPathTeaserCard(),
            const SizedBox(height: 20),
          ],
          _prayerListToggle(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameEmpty ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          if (!widget.habit.isBuiltIn) ...[
            const SizedBox(height: 40),
            Row(children: [
              Expanded(child: _archiveButton()),
              const SizedBox(width: 12),
              Expanded(child: _deleteSection()),
            ]),
          ],
          const SizedBox(height: 40),
        ]),
      ),
        if (_deleting)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xCC1A1A2E),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: MyWalkColor.warmWhite,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Deleting...',
                      style: TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: color.withValues(alpha: 0.18),
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fruitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPIRITUAL GROWTH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What fruit is this habit cultivating?',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FruitType.values.map((fruit) {
            return FruitTagChip(
              fruit: fruit,
              isSelected: _fruitTags.contains(fruit),
              onTap: () => setState(() {
                if (_fruitTags.contains(fruit)) {
                  _fruitTags = _fruitTags.where((f) => f != fruit).toList();
                } else {
                  _fruitTags = [..._fruitTags, fruit];
                  if (_fruitPurposeController.text.isEmpty) {
                    _fruitPurposeController.text = FruitPurposeStatements.defaultFor(
                      widget.habit.category,
                      fruit,
                    );
                  }
                }
              }),
            );
          }).toList(),
        ),
        if (_fruitTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Spiritual purpose (optional)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _fruitPurposeController,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Why does this practice matter to you spiritually?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _notesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Personal notes, reminders, or reflections for this habit.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MyWalkColor.golden.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuillSimpleToolbar(
                  controller: _notesController,
                  config: QuillSimpleToolbarConfig(
                    color: Colors.transparent,
                    multiRowsDisplay: false,
                    showDividers: false,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showListCheck: false,
                    showUndo: true,
                    showRedo: true,
                    showHeaderStyle: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSmallButton: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showAlignmentButtons: false,
                    showLeftAlignment: false,
                    showCenterAlignment: false,
                    showRightAlignment: false,
                    showJustifyAlignment: false,
                    showIndent: false,
                    showQuote: false,
                    showCodeBlock: false,
                    showDirection: false,
                    iconTheme: QuillIconTheme(
                      iconButtonUnselectedData: IconButtonData(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                      ),
                      iconButtonSelectedData: IconButtonData(
                        color: MyWalkColor.golden,
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: MyWalkColor.golden.withValues(alpha: 0.12),
                ),
                QuillEditor.basic(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  scrollController: _notesScrollController,
                  config: QuillEditorConfig(
                    placeholder: 'Add personal notes…',
                    minHeight: 100,
                    maxHeight: 200,
                    scrollable: true,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Support/Prayer Partner section ──────────────────────────────────────

  Widget _partnerSection() {
    final accountability = context.watch<AccountabilityProvider>();
    final partnership = accountability.partnershipForHabit(widget.habit.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPORT/PRAYER PARTNER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Invite someone to walk with you on this habit.',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.07), width: 0.5),
          ),
          child: partnership == null
              ? _inviteRow(accountability)
              : _partnershipRow(partnership, accountability),
        ),
      ],
    );
  }

  Widget _inviteRow(AccountabilityProvider accountability) {
    return GestureDetector(
      onTap: accountability.isLoading
          ? null
          : () async {
              try {
                final result = await accountability.createInvite(
                  habitId: widget.habit.id,
                  habitName: widget.habit.name,
                  habitLabel: widget.habit.subcategoryId == 'breaking_habits'
                      ? 'Breaking Patterns: ${widget.habit.name}'
                      : null,
                );
                if (!mounted) return;
                await _sharePartnerLink(result.shareUrl, result.shortCode, widget.habit.name);
              } catch (e) {
                debugPrint('createInvite failed: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Could not create invite. Try again.')),
                );
              }
            },
      child: Row(children: [
        Icon(Icons.person_add_rounded,
            size: 16,
            color: MyWalkColor.sage.withValues(alpha: 0.8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            accountability.isLoading
                ? 'Creating invite…'
                : 'Invite a support partner',
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.sage.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500),
          ),
        ),
        if (!accountability.isLoading)
          Icon(Icons.chevron_right_rounded,
              size: 18,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
      ]),
    );
  }

  Widget _partnershipRow(
      AccountabilityPartnership partnership,
      AccountabilityProvider accountability) {
    final isPending = partnership.status == PartnershipStatus.pending;
    final isActive = partnership.status == PartnershipStatus.active;
    final partnerName = isActive
        ? (partnership.partnerDisplayName ?? 'Partner')
        : null;

    return Row(children: [
      Icon(
        isActive ? Icons.handshake_rounded : Icons.hourglass_top_rounded,
        size: 16,
        color: isActive
            ? MyWalkColor.sage
            : MyWalkColor.warmWhite.withValues(alpha: 0.35),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isActive
                ? 'Walking with $partnerName'
                : 'Waiting for partner…',
            style: TextStyle(
                fontSize: 14,
                color: isActive
                    ? MyWalkColor.warmWhite
                    : MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500),
          ),
          if (isPending) ...[
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () async {
                try {
                  final result = await accountability.createInvite(
                    habitId: widget.habit.id,
                    habitName: widget.habit.name,
                    habitLabel: widget.habit.subcategoryId == 'breaking_habits'
                        ? 'Breaking Patterns: ${widget.habit.name}'
                        : null,
                  );
                  if (!mounted) return;
                  await _sharePartnerLink(result.shareUrl, result.shortCode, widget.habit.name);
                } catch (e) {
                  debugPrint('createInvite (resend) failed: $e');
                }
              },
              child: Text('Resend invite',
                  style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.sage.withValues(alpha: 0.7))),
            ),
          ],
        ]),
      ),
      if (isActive || isPending)
        GestureDetector(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: MyWalkColor.charcoal,
                title: Text(
                    isActive ? 'End partnership?' : 'Cancel invite?',
                    style: const TextStyle(
                        color: MyWalkColor.warmWhite, fontSize: 16)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Keep',
                        style: TextStyle(color: MyWalkColor.softGold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(isActive ? 'End' : 'Cancel',
                        style: const TextStyle(color: MyWalkColor.warmCoral)),
                  ),
                ],
              ),
            );
            if (confirmed != true || !mounted) return;
            if (isActive) {
              await accountability.endPartnership(partnership.id);
            } else {
              await accountability.cancelPartnership(partnership.id);
            }
          },
          child: Icon(Icons.close_rounded,
              size: 16,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
        ),
    ]);
  }

  Future<void> _sharePartnerLink(String url, String shortCode, String habitName) async {
    await Share.share(
      'Please walk with me on my $habitName journey.\n\n'
      'If you already have MyWalk on your mobile:\n\n'
      '1) Tap this link: $url\n\n'
      'Or\n\n'
      '2) Tap on the Notifications Bell at the top on the app screen and then on the "Have an Invite Code?" card and enter this code: $shortCode\n\n\n'
      'If you don\'t have MyWalk installed on your mobile:\n\n'
      'Download it from the Google Play Store or Apple Store.\n\n'
      'Then either:\n\n'
      '1) Come back to this email and tap this link: $url\n\n'
      'Or\n\n'
      '2) Tap on the Notifications Bell at the top on the app screen and then on the "Have an Invite Code?" card and enter this code: $shortCode',
    );
  }

  // ── Recovery Path teaser card ─────────────────────────────────────────────

  Widget _recoveryPathTeaserCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FA0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6B4FA0).withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4FA0).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.route_rounded,
              size: 16, color: Color(0xFFB39DDB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recovery Path',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB39DDB))),
            const SizedBox(height: 3),
            Text(
              'A guided programme to understand your patterns, anchor to your values, and build guardrails.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _referenceUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFERENCE LINK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Attach an article, video, or resource that inspires this habit.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _referenceUrlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: MyWalkColor.cardBackground,
            hintText: 'https://…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: MyWalkColor.sage, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Icon(Icons.link_rounded,
                size: 18, color: MyWalkColor.softGold.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _prayerListToggle() {
    return GestureDetector(
      onTap: () => setState(() => _hasPrayerItems = !_hasPrayerItems),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasPrayerItems
                ? MyWalkColor.golden.withValues(alpha: 0.3)
                : MyWalkColor.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Icon(Icons.format_list_bulleted_rounded,
              size: 18,
              color: _hasPrayerItems
                  ? MyWalkColor.golden
                  : Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prayer List',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _hasPrayerItems
                          ? MyWalkColor.warmWhite
                          : Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text('Track up to 10 prayer items with status on the detail screen.',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
            ]),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 22,
            decoration: BoxDecoration(
              color: _hasPrayerItems
                  ? MyWalkColor.golden
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _hasPrayerItems
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _archiveButton() {
    return GestureDetector(
      onTap: _confirmArchive,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.softGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.softGold.withValues(alpha: 0.25), width: 0.5),
        ),
        child: const Center(
          child: Text(
            'Archive',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: MyWalkColor.softGold),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Archive habit?',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '"${widget.habit.name}" will be hidden from your active habits. '
          'Your history and progress are preserved — you can restore it any time from Settings.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: MyWalkColor.softGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final accountabilityProv = context.read<AccountabilityProvider>();
      final habitProv = context.read<HabitProvider>();
      final habit = widget.habit;
      Navigator.pop(context); // dismiss EditHabitView
      Navigator.pop(context); // dismiss HabitDetailView
      await accountabilityProv
          .endPartnershipsForHabit(habit.id, reason: 'archived')
          .catchError((_) {});
      await habitProv.archiveHabit(habit);
    }
  }

  Widget _deleteSection() {
    return GestureDetector(
      onTap: _confirmDelete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.warmCoral.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.25), width: 0.5),
        ),
        child: const Center(
          child: Text(
            'Delete Practice',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: MyWalkColor.warmCoral),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final habitName = widget.habit.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Practice',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Deleting "$habitName" is permanent and cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: MyWalkColor.warmCoral, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _deleting = true);
      final accountabilityProv = context.read<AccountabilityProvider>();
      final habitProv = context.read<HabitProvider>();
      final habit = widget.habit;
      await accountabilityProv
          .endPartnershipsForHabit(habit.id, reason: 'deleted')
          .catchError((_) {});
      await habitProv.deleteHabit(habit);
      if (!mounted) return;
      Navigator.pop(context); // dismiss EditHabitView
      Navigator.pop(context); // dismiss HabitDetailView
    }
  }

  Widget _headerSection() {
    final isAbstain = widget.habit.trackingType == HabitTrackingType.abstain;
    return Row(children: [
      Icon(_categoryIcon(), size: 18,
          color: isAbstain ? MyWalkColor.warmCoral : MyWalkColor.golden),
      const SizedBox(width: 10),
      Text(widget.habit.subcategoryName?.isNotEmpty == true
              ? widget.habit.subcategoryName!
              : (widget.habit.categoryName?.isNotEmpty == true
                  ? widget.habit.categoryName!
                  : widget.habit.category.rawValue),
          style: TextStyle(
            fontSize: 15,
            color: MyWalkColor.softGold.withValues(alpha: 0.7),
          )),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _trackingLabel(widget.habit.trackingType),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.5)),
        ),
      ),
    ]);
  }

  String _trackingLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.timed: return 'Timed';
      case HabitTrackingType.count: return 'Count';
      case HabitTrackingType.abstain: return 'Abstain';
      case HabitTrackingType.checkIn: return 'Check-in';
    }
  }

  Widget _nameSection() {
    final isBreaking = widget.habit.subcategoryId == 'breaking_habits';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Practice Name',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      if (widget.habit.isBuiltIn)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_nameController.text,
              style: TextStyle(fontSize: 16, color: MyWalkColor.warmWhite.withValues(alpha: 0.6))),
        )
      else
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 16, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Practice name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      if (isBreaking) ...[
        const SizedBox(height: 16),
        Text('How it appears on your Today card (optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        TextField(
          controller: _aliasController,
          style: const TextStyle(fontSize: 16, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'e.g. "My battle" · Leave blank to use the practice name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Useful if you prefer a private name that others won\'t recognise.',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 20),
        Text('Privacy PIN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(
          widget.habit.pin?.isNotEmpty == true
              ? 'A PIN is set. Enter 4 new digits to change it, or use the button below to remove it.'
              : 'Enter 4 digits to lock this card on the Today screen (optional).',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 8),
        _editPinRow(),
        if (widget.habit.pin?.isNotEmpty == true && !_clearPin) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              _clearPin = true;
              for (final c in _pinControllers) {
                c.clear();
              }
              _newPin = '';
            }),
            child: Text('Remove PIN',
                style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmCoral.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500)),
          ),
        ],
        if (_clearPin)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Text('PIN will be removed on save.',
                    style: TextStyle(
                        fontSize: 11, color: MyWalkColor.warmCoral.withValues(alpha: 0.7))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _clearPin = false),
                  child: Text('Undo',
                      style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
      ],
    ]);
  }

  Widget _editPinRow() {
    final borderSide = BorderSide(
      color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
      width: 0.75,
    );
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
            child: TextField(
              controller: _pinControllers[i],
              focusNode: _pinFocusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: MyWalkColor.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: borderSide,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: borderSide,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: MyWalkColor.eventPurple, width: 1.5),
                ),
              ),
              onChanged: (v) {
                if (v.length == 1 && i < 3) {
                  _pinFocusNodes[i + 1].requestFocus();
                } else if (v.isEmpty && i > 0) {
                  _pinFocusNodes[i - 1].requestFocus();
                }
                setState(() {
                  _newPin = _pinControllers.map((c) => c.text).join();
                  if (_newPin.isNotEmpty) _clearPin = false;
                });
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _purposeSection(bool isPremium) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your Why',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      TextField(
        controller: _purposeController,
        maxLines: 4,
        style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Why does this matter to you and to God?',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: MyWalkColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }

  Widget _timedTargetSection() {
    const minuteOptions = [15.0, 30.0, 45.0, 60.0];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Goal (minutes)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(
        children: minuteOptions.map((mins) {
          final selected = _dailyTarget == mins;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: mins != minuteOptions.last ? 12 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _dailyTarget = mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${mins.toInt()}',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                        )),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _countTargetSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Goal',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(children: [
        Text('${_dailyTarget.toInt()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
        const SizedBox(width: 12),
        Column(children: [
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget + 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_up, color: MyWalkColor.golden),
          ),
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget - 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_down, color: MyWalkColor.golden),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: _targetUnit),
            onChanged: (v) => _targetUnit = v,
            style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Unit',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _dayOfWeekSection(bool isAbstain) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final label = isAbstain ? 'Track days' : 'Active days';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = i + 1;
          final selected = _activeDays.contains(day);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _activeDays.remove(day);
              } else {
                _activeDays.add(day);
              }
            }),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                border: Border.all(color: selected ? MyWalkColor.golden : MyWalkColor.cardBorder, width: 0.5),
              ),
              child: Center(
                child: Text(dayLabels[i],
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? MyWalkColor.charcoal : Colors.white.withValues(alpha: 0.4),
                    )),
              ),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _reminderSection() {
    final timeLabel = TimeOfDay(hour: _reminderHour, minute: _reminderMinute)
        .format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _reminderEnabled = !_reminderEnabled),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _reminderEnabled
                    ? MyWalkColor.golden.withValues(alpha: 0.3)
                    : MyWalkColor.cardBorder,
                width: 0.5,
              ),
            ),
            child: Row(children: [
              Icon(Icons.notifications_outlined,
                  size: 18,
                  color: _reminderEnabled
                      ? MyWalkColor.golden
                      : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Remind me',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _reminderEnabled
                              ? MyWalkColor.warmWhite
                              : Colors.white.withValues(alpha: 0.6))),
                  const SizedBox(height: 2),
                  Text('A gentle nudge on your active days.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                ]),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 22,
                decoration: BoxDecoration(
                  color: _reminderEnabled
                      ? MyWalkColor.golden
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _reminderEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (_reminderEnabled) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
              );
              if (picked != null) {
                setState(() {
                  _reminderHour = picked.hour;
                  _reminderMinute = picked.minute;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.access_time,
                    size: 16, color: MyWalkColor.softGold.withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                Text('Reminder time',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                const Spacer(),
                Text(timeLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: MyWalkColor.warmWhite)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _triggerSection() {
    final chips = _triggerChips();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When will you do this?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            final selected = _triggerController.text == chip;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _triggerController.text = chip),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(chip,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _triggerController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or type your own trigger\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: MyWalkColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }

  Widget _categoryChipsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_categoryName != null)
          _editChip(
            label: _categoryName!,
            onTap: () => _openSubcategoryPicker(startOnCategories: true),
          ),
        if (_subcategoryName != null && _subcategoryName!.isNotEmpty)
          _editChip(
            label: _subcategoryName!,
            onTap: () => _openSubcategoryPicker(startOnCategories: false),
          ),
      ],
    );
  }

  Widget _editChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.9)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 11, color: MyWalkColor.golden.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _openSubcategoryPicker({required bool startOnCategories}) async {
    final catProvider = context.read<HabitCategoryProvider>();
    final result = await showModalBottomSheet<
        ({String categoryId, String subcategoryId, String categoryName, String subcategoryName})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubcategoryPickerSheet(
        initialCategoryId: startOnCategories ? null : _categoryId,
        catProvider: catProvider,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _categoryId = result.categoryId;
        _subcategoryId = result.subcategoryId;
        _categoryName = result.categoryName;
        _subcategoryName = result.subcategoryName;
      });
    }
  }

  Widget _copingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When I feel tempted, I will\u2026',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _copingSuggestions.map((s) {
            final selected = _copingController.text == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _copingController.text = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.warmCoral : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _copingController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or write your own plan\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: MyWalkColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }
}

// ── SubcategoryPickerSheet ────────────────────────────────────────────────────

typedef _CategoryResult = ({
  String categoryId,
  String subcategoryId,
  String categoryName,
  String subcategoryName
});

class SubcategoryPickerSheet extends StatefulWidget {
  final String? initialCategoryId;
  final HabitCategoryProvider catProvider;

  const SubcategoryPickerSheet({
    super.key,
    required this.initialCategoryId,
    required this.catProvider,
  });

  @override
  State<SubcategoryPickerSheet> createState() => _SubcategoryPickerSheetState();
}

class _SubcategoryPickerSheetState extends State<SubcategoryPickerSheet> {
  HabitCategoryModel? _selectedCategory;
  // 1 = category grid, 2 = subcategory grid
  late int _step;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      final cat = widget.catProvider.categoryById(widget.initialCategoryId!);
      if (cat != null) {
        _selectedCategory = cat;
        _step = 2;
      } else {
        _step = 1;
      }
    } else {
      _step = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, sc) => Column(
        children: [
          _sheetHandle(),
          _sheetAppBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: _step == 1 ? _categoryGrid() : _subcategoryGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (_step == 2)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: MyWalkColor.warmWhite),
              onPressed: () => setState(() => _step = 1),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              _step == 1 ? 'Choose a Category' : (_selectedCategory?.name ?? ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid() {
    final categories = widget.catProvider.categories;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: categories.map((cat) => GestureDetector(
        onTap: () {
          if (cat.isCustom) {
            Navigator.pop<_CategoryResult>(context, (
              categoryId: cat.id,
              subcategoryId: 'custom',
              categoryName: cat.name,
              subcategoryName: '',
            ));
          } else {
            setState(() {
              _selectedCategory = cat;
              _step = 2;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconForKey(cat.iconKey), size: 24, color: MyWalkColor.golden),
              const SizedBox(height: 8),
              Text(
                cat.name,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _subcategoryGrid() {
    final cat = _selectedCategory!;
    final subcategories = widget.catProvider.subcategoriesFor(cat.id);

    return Column(
      children: subcategories.map((sub) {
        return GestureDetector(
          onTap: () => Navigator.pop<_CategoryResult>(context, (
            categoryId: cat.id,
            subcategoryId: sub.id,
            categoryName: cat.name,
            subcategoryName: sub.isCustom ? '' : sub.name,
          )),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconForKey(sub.iconKey), size: 20, color: MyWalkColor.golden),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MyWalkColor.warmWhite,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
                if (sub.yourWhy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    sub.yourWhy,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ],
                if (sub.keyVerseRef != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.format_quote,
                          size: 12, color: MyWalkColor.golden.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        sub.keyVerseRef!,
                        style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.golden.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
