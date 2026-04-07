import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/circle_habits_provider.dart';
import '../../providers/circle_notification_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/services/week_id_service.dart';
import '../../theme/app_theme.dart';

class CircleHabitsTab extends StatelessWidget {
  final String circleId;
  final bool isAdmin;
  const CircleHabitsTab({super.key, required this.circleId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Consumer<CircleHabitsProvider>(
      builder: (context, provider, _) {
        final uid = AuthService.shared.userId ?? '';
        final habits = provider.habitsFor(circleId);
        final isLoading = provider.isLoading(circleId);
        final today = WeekIdService.todayStr();

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: isAdmin
              ? FloatingActionButton.small(
                  onPressed: () => _showCreateSheet(context),
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  child: const Icon(Icons.add),
                )
              : null,
          body: isLoading && habits.isEmpty
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (habits.isEmpty)
                        _emptyState()
                      else
                        ...habits.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CircleHabitCard(
                            habit: h, circleId: circleId, uid: uid,
                            today: today, isAdmin: isAdmin),
                        )),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.check_circle_outline_rounded, size: 40,
            color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('No circle habits yet.',
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text(isAdmin
            ? 'Tap + to create a shared habit for your circle.'
            : 'Your admin hasn\'t created any habits yet.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CreateCircleHabitSheet(circleId: circleId),
    );
  }
}

// ─── Circle Habit Card ────────────────────────────────────────────────────────

class _CircleHabitCard extends StatelessWidget {
  final CircleHabit habit;
  final String circleId;
  final String uid;
  final String today;
  final bool isAdmin;

  const _CircleHabitCard({
    required this.habit, required this.circleId,
    required this.uid, required this.today, required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CircleHabitsProvider>();
    final summary = provider.summaryFor(circleId, habit.id, today);
    final hasCompleted = summary?.hasCompleted(uid) ?? false;
    final completedCount = summary?.completedCount ?? 0;
    final totalMembers = summary?.totalMembers ?? 0;
    final completionRate = summary?.completionRate ?? 0.0;

    final scheduled = habit.isScheduledFor(DateTime.now().weekday % 7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCompleted
            ? MyWalkColor.sage.withValues(alpha: 0.06)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCompleted
              ? MyWalkColor.sage.withValues(alpha: 0.2)
              : MyWalkColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(habit.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite)),
          ),
          if (isAdmin)
            GestureDetector(
              onTap: () => _showAdminMenu(context),
              child: Icon(Icons.more_horiz_rounded, size: 18,
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
        ]),
        if (habit.description != null) ...[
          const SizedBox(height: 4),
          Text(habit.description!,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ],
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
              completionRate >= 0.8 ? MyWalkColor.golden : MyWalkColor.sage),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Text('$completedCount${totalMembers > 0 ? '/$totalMembers' : ''} completed today',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
          const Spacer(),
          if (!hasCompleted && scheduled)
            GestureDetector(
              onTap: () => _logCompletion(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: MyWalkColor.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MyWalkColor.sage.withValues(alpha: 0.3)),
                ),
                child: Text(
                  habit.trackingType == CircleHabitTrackingType.count
                      ? 'Log Count'
                      : habit.trackingType == CircleHabitTrackingType.timed
                          ? 'Log Time'
                          : 'Done Today',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: MyWalkColor.sage),
                ),
              ),
            )
          else if (hasCompleted)
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: MyWalkColor.sage),
              const SizedBox(width: 4),
              const Text('Done', style: TextStyle(fontSize: 12, color: MyWalkColor.sage)),
            ])
          else
            Text('Not scheduled today',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
      ]),
    );
  }

  void _logCompletion(BuildContext context) {
    if (habit.trackingType == CircleHabitTrackingType.checkIn) {
      context.read<CircleHabitsProvider>().complete(
          circleId: circleId, habitId: habit.id, value: 1, uid: uid);
      return;
    }
    _showValueDialog(context);
  }

  void _showValueDialog(BuildContext context) {
    final isCount = habit.trackingType == CircleHabitTrackingType.count;
    final label = isCount ? 'Count' : 'Minutes';
    final hint = isCount ? 'e.g. 5' : 'e.g. 30';
    final target = habit.targetValue;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: Text('Log $label',
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (target != null) ...[
            Text('Target: $target $label',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(context);
              context.read<CircleHabitsProvider>().complete(
                  circleId: circleId,
                  habitId: habit.id,
                  value: v,
                  uid: uid);
            },
            child: const Text('Log',
                style: TextStyle(
                    color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: MyWalkColor.golden),
            title: const Text('Edit Habit',
                style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: MyWalkColor.charcoal,
                builder: (_) =>
                    EditCircleHabitSheet(circleId: circleId, habit: habit),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.pause_circle_outline_rounded,
                color: Colors.white.withValues(alpha: 0.5)),
            title: Text('Deactivate',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeactivate(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: MyWalkColor.warmCoral),
            title: const Text('Delete Permanently',
                style: TextStyle(color: MyWalkColor.warmCoral, fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Deactivate Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text('Hide "${habit.name}" from your circle? History is kept.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context.read<CircleHabitsProvider>().deactivate(circleId, habit.id);
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Failed to deactivate habit')));
              }
            },
            child: const Text('Deactivate',
                style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Delete Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text(
            'Permanently delete "${habit.name}"? All history will be lost.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context.read<CircleHabitsProvider>().deleteHabit(circleId, habit.id);
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Failed to delete habit')));
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Circle Habit Sheet ──────────────────────────────────────────────────

class EditCircleHabitSheet extends StatefulWidget {
  final String circleId;
  final CircleHabit habit;
  const EditCircleHabitSheet(
      {super.key, required this.circleId, required this.habit});

  @override
  State<EditCircleHabitSheet> createState() => _EditCircleHabitSheetState();
}

class _EditCircleHabitSheetState extends State<EditCircleHabitSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _purposeController;
  late CircleHabitTrackingType _tracking;
  late CircleHabitFrequency _frequency;
  late List<int> _specificDays;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _descController = TextEditingController(text: h.description ?? '');
    _purposeController = TextEditingController(text: h.purposeStatement ?? '');
    _tracking = h.trackingType;
    _frequency = h.frequency;
    _specificDays = List<int>.from(h.specificDays ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Edit Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Save',
                    style: TextStyle(
                        color: MyWalkColor.golden,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Habit Name'),
          const SizedBox(height: 6),
          TextField(
              controller: _nameController,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('e.g. Morning Prayer')),
          const SizedBox(height: 14),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('What is this habit about?')),
          const SizedBox(height: 14),
          _label('Tracking Type'),
          const SizedBox(height: 8),
          _trackingSelector(),
          const SizedBox(height: 14),
          _label('Frequency'),
          const SizedBox(height: 8),
          _frequencySelector(),
          if (_frequency == CircleHabitFrequency.specificDays) ...[
            const SizedBox(height: 10),
            _label('Active Days'),
            const SizedBox(height: 8),
            _daySelector(),
          ],
          const SizedBox(height: 14),
          _label('Purpose Statement (optional)'),
          const SizedBox(height: 6),
          TextField(
              controller: _purposeController,
              maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration:
                  _inputDec('Why is this habit important for your circle?')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
        ]),
      ),
    );
  }

  Widget _daySelector() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: List.generate(7, (i) {
        final selected = _specificDays.contains(i);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _specificDays.remove(i);
              } else {
                _specificDays
                  ..add(i)
                  ..sort();
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? MyWalkColor.sage.withValues(alpha: 0.15)
                    : MyWalkColor.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected
                        ? MyWalkColor.sage.withValues(alpha: 0.5)
                        : Colors.transparent),
              ),
              child: Center(
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? MyWalkColor.sage
                            : Colors.white.withValues(alpha: 0.4))),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _trackingSelector() {
    return Row(
        children: CircleHabitTrackingType.values.map((t) {
      final selected = _tracking == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tracking = t),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? MyWalkColor.golden.withValues(alpha: 0.12)
                  : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected
                      ? MyWalkColor.golden.withValues(alpha: 0.4)
                      : Colors.transparent),
            ),
            child: Center(
                child: Text(_trackingLabel(t),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? MyWalkColor.golden
                            : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _frequencySelector() {
    return Row(
        children: CircleHabitFrequency.values.map((f) {
      final selected = _frequency == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _frequency = f),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? MyWalkColor.sage.withValues(alpha: 0.12)
                  : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected
                      ? MyWalkColor.sage.withValues(alpha: 0.4)
                      : Colors.transparent),
            ),
            child: Center(
                child: Text(_frequencyLabel(f),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? MyWalkColor.sage
                            : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.inputBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  String _trackingLabel(CircleHabitTrackingType t) {
    switch (t) {
      case CircleHabitTrackingType.checkIn: return 'Check-In';
      case CircleHabitTrackingType.timed: return 'Timed';
      case CircleHabitTrackingType.count: return 'Count';
    }
  }

  String _frequencyLabel(CircleHabitFrequency f) {
    switch (f) {
      case CircleHabitFrequency.daily: return 'Daily';
      case CircleHabitFrequency.weekly: return 'Weekly';
      case CircleHabitFrequency.specificDays: return 'Specific';
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name required.');
      return;
    }
    if (_frequency == CircleHabitFrequency.specificDays && _specificDays.isEmpty) {
      setState(() => _error = 'Select at least one active day.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<CircleHabitsProvider>().updateHabit(
        circleId: widget.circleId,
        habitId: widget.habit.id,
        name: name,
        trackingType: _tracking,
        frequency: _frequency,
        specificDays: _frequency == CircleHabitFrequency.specificDays
            ? _specificDays
            : null,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        purposeStatement: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        anchorVerse: widget.habit.anchorVerse,
        targetValue: widget.habit.targetValue,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}

// ─── Create Circle Habit Sheet ────────────────────────────────────────────────

class CreateCircleHabitSheet extends StatefulWidget {
  final String circleId;
  const CreateCircleHabitSheet({super.key, required this.circleId});

  @override
  State<CreateCircleHabitSheet> createState() => _CreateCircleHabitSheetState();
}

class _CreateCircleHabitSheetState extends State<CreateCircleHabitSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _purposeController = TextEditingController();
  CircleHabitTrackingType _tracking = CircleHabitTrackingType.checkIn;
  CircleHabitFrequency _frequency = CircleHabitFrequency.daily;
  List<int> _specificDays = [];
  bool _notifyMembers = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('New Circle Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Create',
                    style: TextStyle(color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Habit Name'),
          const SizedBox(height: 6),
          TextField(controller: _nameController,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('e.g. Morning Prayer')),
          const SizedBox(height: 14),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextField(controller: _descController, maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('What is this habit about?')),
          const SizedBox(height: 14),
          _label('Tracking Type'),
          const SizedBox(height: 8),
          _trackingSelector(),
          const SizedBox(height: 14),
          _label('Frequency'),
          const SizedBox(height: 8),
          _frequencySelector(),
          if (_frequency == CircleHabitFrequency.specificDays) ...[
            const SizedBox(height: 10),
            _label('Active Days'),
            const SizedBox(height: 8),
            _daySelector(),
          ],
          const SizedBox(height: 14),
          _label('Purpose Statement (optional)'),
          const SizedBox(height: 6),
          TextField(controller: _purposeController, maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('Why is this habit important for your circle?')),
          const SizedBox(height: 14),
          _notifyRow(),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden, foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Habit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _trackingSelector() {
    return Row(children: CircleHabitTrackingType.values.map((t) {
      final selected = _tracking == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tracking = t),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? MyWalkColor.golden.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? MyWalkColor.golden.withValues(alpha: 0.4) : Colors.transparent),
            ),
            child: Center(child: Text(_trackingLabel(t),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: selected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _frequencySelector() {
    return Row(children: CircleHabitFrequency.values.map((f) {
      final selected = _frequency == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _frequency = f),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? MyWalkColor.sage.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? MyWalkColor.sage.withValues(alpha: 0.4) : Colors.transparent),
            ),
            child: Center(child: Text(_frequencyLabel(f),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: selected ? MyWalkColor.sage : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
    filled: true, fillColor: MyWalkColor.inputBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  String _trackingLabel(CircleHabitTrackingType t) {
    switch (t) {
      case CircleHabitTrackingType.checkIn: return 'Check-In';
      case CircleHabitTrackingType.timed: return 'Timed';
      case CircleHabitTrackingType.count: return 'Count';
    }
  }

  String _frequencyLabel(CircleHabitFrequency f) {
    switch (f) {
      case CircleHabitFrequency.daily: return 'Daily';
      case CircleHabitFrequency.weekly: return 'Weekly';
      case CircleHabitFrequency.specificDays: return 'Specific';
    }
  }

  Widget _daySelector() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: List.generate(7, (i) {
        final selected = _specificDays.contains(i);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _specificDays.remove(i);
              } else {
                _specificDays
                  ..add(i)
                  ..sort();
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? MyWalkColor.sage.withValues(alpha: 0.15)
                    : MyWalkColor.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected
                        ? MyWalkColor.sage.withValues(alpha: 0.5)
                        : Colors.transparent),
              ),
              child: Center(
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? MyWalkColor.sage
                            : Colors.white.withValues(alpha: 0.4))),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _notifyRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: MyWalkColor.cardBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.notifications_outlined, size: 18, color: MyWalkColor.softGold),
      const SizedBox(width: 10),
      const Expanded(
        child: Text('Notify members',
            style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
      ),
      Switch(
        value: _notifyMembers,
        onChanged: (v) => setState(() => _notifyMembers = v),
        activeTrackColor: MyWalkColor.golden,
        activeThumbColor: Colors.white,
      ),
    ]),
  );

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Name required.'); return; }
    if (_frequency == CircleHabitFrequency.specificDays && _specificDays.isEmpty) {
      setState(() => _error = 'Select at least one active day.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final notifProvider = _notifyMembers
        ? context.read<CircleNotificationProvider>()
        : null;
    try {
      await context.read<CircleHabitsProvider>().createHabit(
        circleId: widget.circleId, name: name, trackingType: _tracking,
        frequency: _frequency,
        specificDays: _frequency == CircleHabitFrequency.specificDays
            ? _specificDays
            : null,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        purposeStatement: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
      );
      notifProvider?.sendAnnouncement(
        circleId: widget.circleId,
        message: 'New circle habit: $name — check the Habits tab.',
      ).catchError((_) {});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}
