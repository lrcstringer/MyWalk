import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';

enum _OStep { welcome, gratitude, habitPick, habitConfig, summary, celebrate }

class _OnbCat {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final HabitCategory category;
  final HabitTrackingType defaultTracking;
  final String defaultName;
  final String defaultUnit;
  final double defaultGoal;

  const _OnbCat({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.category,
    required this.defaultTracking,
    required this.defaultName,
    required this.defaultUnit,
    required this.defaultGoal,
  });
}

class OnboardingFlow extends StatefulWidget {
  final Future<void> Function() onComplete;
  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _OStep _step = _OStep.welcome;

  // Gratitude
  final _gratCtrl = TextEditingController();

  // Habit config (held locally; written to Firestore on "Begin My Walk")
  _OnbCat? _pickedCat;
  final _habitNameCtrl = TextEditingController();
  HabitTrackingType _trackingType = HabitTrackingType.checkIn;
  double _dailyGoal = 1.0;
  String _targetUnit = 'time';
  Set<int> _activeDays = {1, 2, 3, 4, 5, 6, 7};
  bool _habitCreated = false;

  bool _processing = false;

  static final _categories = <_OnbCat>[
    _OnbCat(
      name: 'Exercise',
      subtitle: 'Movement, sport, a daily walk',
      icon: Icons.fitness_center_rounded,
      iconBg: const Color(0xFF2A2A1A),
      iconColor: MyWalkColor.golden,
      category: HabitCategory.exercise,
      defaultTracking: HabitTrackingType.timed,
      defaultName: 'Daily Exercise',
      defaultUnit: 'min',
      defaultGoal: 20,
    ),
    _OnbCat(
      name: 'Creativity',
      subtitle: 'Write, draw, make music, create',
      icon: Icons.edit_rounded,
      iconBg: const Color(0xFF2A2A1A),
      iconColor: MyWalkColor.softGold,
      category: HabitCategory.custom,
      defaultTracking: HabitTrackingType.timed,
      defaultName: 'Daily Creativity',
      defaultUnit: 'min',
      defaultGoal: 30,
    ),
    _OnbCat(
      name: "God's Word",
      subtitle: 'Bible reading, devotions, study',
      icon: Icons.menu_book_rounded,
      iconBg: const Color(0xFF2A2A1A),
      iconColor: MyWalkColor.golden,
      category: HabitCategory.scripture,
      defaultTracking: HabitTrackingType.checkIn,
      defaultName: 'Daily Bible Reading',
      defaultUnit: 'time',
      defaultGoal: 1,
    ),
    _OnbCat(
      name: 'Prayer',
      subtitle: 'Daily time talking with God',
      icon: Icons.self_improvement_rounded,
      iconBg: const Color(0xFF2A2A1A),
      iconColor: MyWalkColor.golden,
      category: HabitCategory.prayer,
      defaultTracking: HabitTrackingType.checkIn,
      defaultName: 'Daily Prayer',
      defaultUnit: 'time',
      defaultGoal: 1,
    ),
    _OnbCat(
      name: 'Breaking Patterns',
      subtitle:
          'Overcoming bad/persistent habits, optionally with support partners and our Freedom Path activities guide',
      icon: Icons.shield_rounded,
      iconBg: const Color(0xFF2A1A1A),
      iconColor: Color(0xFFE05252),
      category: HabitCategory.abstain,
      defaultTracking: HabitTrackingType.abstain,
      defaultName: 'Breaking the Pattern',
      defaultUnit: 'day',
      defaultGoal: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hp = context.read<HabitProvider>();
      if (hp.habits.isEmpty) hp.loadHabits();
    });
  }

  @override
  void dispose() {
    _gratCtrl.dispose();
    _habitNameCtrl.dispose();
    super.dispose();
  }

  int get _dotIndex => switch (_step) {
        _OStep.welcome => 1,
        _OStep.gratitude => 2,
        _OStep.habitPick || _OStep.habitConfig => 3,
        _OStep.summary => 4,
        _OStep.celebrate => 5,
      };

  void _goBack() {
    setState(() {
      _step = switch (_step) {
        _OStep.gratitude => _OStep.welcome,
        _OStep.habitPick => _OStep.gratitude,
        _OStep.habitConfig => _OStep.habitPick,
        _OStep.summary => _OStep.habitConfig,
        _ => _step,
      };
    });
  }

  void _pickCategory(_OnbCat cat) {
    _pickedCat = cat;
    _trackingType = cat.defaultTracking;
    _dailyGoal = cat.defaultGoal;
    _targetUnit = cat.defaultUnit;
    _habitNameCtrl.text = cat.defaultName;
    _activeDays = {1, 2, 3, 4, 5, 6, 7};
    setState(() => _step = _OStep.habitConfig);
  }

  Future<void> _submitGratitude() async {
    setState(() => _processing = true);
    try {
      final hp = context.read<HabitProvider>();
      if (hp.habits.isEmpty) await hp.loadHabits();
      final candidates = hp.habits.where((h) => h.category == HabitCategory.gratitude);
      if (candidates.isNotEmpty) {
        final note = _gratCtrl.text.trim();
        await hp.checkInGratitude(candidates.first, note: note.isEmpty ? null : note);
      }
    } catch (_) {
      // Don't block onboarding on check-in failure.
    }
    if (mounted) {
      setState(() {
        _processing = false;
        _step = _OStep.habitPick;
      });
    }
  }

  // Validates habit config and advances to summary. Habit is NOT written yet.
  void _confirmHabitConfig() {
    if (_habitNameCtrl.text.trim().isEmpty || _pickedCat == null) return;
    setState(() => _step = _OStep.summary);
  }

  // Creates the habit in Firestore and advances to celebrate.
  Future<void> _beginMyWalk() async {
    if (_habitCreated) {
      setState(() => _step = _OStep.celebrate);
      return;
    }
    setState(() => _processing = true);
    try {
      final hp = context.read<HabitProvider>();
      await hp.addHabit(
        name: _habitNameCtrl.text.trim(),
        category: _pickedCat!.category,
        trackingType: _trackingType,
        purpose: _pickedCat!.category.defaultPurpose,
        dailyTarget: _dailyGoal,
        targetUnit: _targetUnit,
        activeDays: _activeDays,
      );
      _habitCreated = true;
    } catch (_) {
      // Proceed even if the habit write fails.
      _habitCreated = true;
    }
    if (mounted) {
      setState(() {
        _processing = false;
        _step = _OStep.celebrate;
      });
    }
  }

  Future<void> _enterMyWalk() async {
    setState(() => _processing = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ── Layout helpers ──────────────────────────────────────────────────────────

  Widget _shell({required Widget child, required Key key}) {
    final showBack = _step != _OStep.welcome && _step != _OStep.celebrate;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 28,
                  ),
                )
              else
                const SizedBox(width: 28),
              Expanded(child: Center(child: _dotRow())),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Expanded(child: child),
      ],
    );
  }

  Widget _dotRow() {
    final active = _dotIndex;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 10 : 7,
          height: isActive ? 10 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() => switch (_step) {
        _OStep.welcome => _welcomeView(),
        _OStep.gratitude => _gratitudeView(),
        _OStep.habitPick => _habitPickView(),
        _OStep.habitConfig => _habitConfigView(),
        _OStep.summary => _summaryView(),
        _OStep.celebrate => _celebrateView(),
      };

  // ── Step views ──────────────────────────────────────────────────────────────

  Widget _welcomeView() {
    return _shell(
      key: const ValueKey('welcome'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MyWalk works\na bit differently.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            _featureRow(
              Icons.volunteer_activism_rounded,
              'Start with gratitude',
              'Every day begins with a moment of thankfulness — a simple prayer of thanks.',
            ),
            const SizedBox(height: 18),
            _featureRow(
              Icons.directions_walk_rounded,
              'One practice at a time',
              'Pick one activity to build momentum. You can always add more later.',
            ),
            const SizedBox(height: 18),
            _featureRow(
              Icons.groups_rounded,
              'Walk with others',
              'Join a Circle to stay accountable and encourage each other daily.',
            ),
            const Spacer(),
            _primaryButton(
              label: "Let's go",
              onPressed: () => setState(() => _step = _OStep.gratitude),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MyWalkColor.golden.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MyWalkColor.golden, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite)),
              const SizedBox(height: 3),
              Text(body,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gratitudeView() {
    return _shell(
      key: const ValueKey('gratitude'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Every journey\nstarts with gratitude.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'What are you thankful for today?',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              child: TextField(
                controller: _gratCtrl,
                maxLines: 5,
                minLines: 4,
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Something you\'re grateful for...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const Spacer(),
            _primaryButton(
              label: 'Thank you, Lord',
              loading: _processing,
              onPressed: _processing ? null : _submitGratitude,
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitPickView() {
    return _shell(
      key: const ValueKey('habitPick'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One small activity\nto start.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: MyWalkColor.warmWhite,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick something simple — you\'re not committing to forever. You can change or delete this any time.',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () => _pickCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: MyWalkColor.cardBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cat.iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(cat.icon, color: cat.iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: MyWalkColor.warmWhite)),
                              const SizedBox(height: 3),
                              Text(cat.subtitle,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.4),
                                      height: 1.4)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitConfigView() {
    if (_pickedCat == null) return const SizedBox.shrink();
    final isAbstain =
        _pickedCat!.defaultTracking == HabitTrackingType.abstain;
    return _shell(
      key: const ValueKey('habitConfig'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _pickedCat!.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_pickedCat!.icon,
                      color: _pickedCat!.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  _pickedCat!.name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.warmWhite),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _label('Activity name'),
            const SizedBox(height: 8),
            TextField(
              controller: _habitNameCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 16),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('e.g. Morning walk'),
            ),
            if (!isAbstain) ...[
              const SizedBox(height: 20),
              _label('How do you want to track it?'),
              const SizedBox(height: 8),
              _trackingToggle(),
              const SizedBox(height: 20),
              _label('Daily goal'),
              const SizedBox(height: 8),
              _goalRow(),
            ],
            const SizedBox(height: 20),
            _label('Active days'),
            const SizedBox(height: 8),
            _daysRow(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_habitNameCtrl.text.trim().isEmpty || _processing)
                    ? null
                    : _confirmHabitConfig,
                style: _buttonStyle(),
                child: const Text('Set this activity',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingToggle() {
    const types = [
      (HabitTrackingType.checkIn, 'Yes / No'),
      (HabitTrackingType.timed, 'Timed'),
      (HabitTrackingType.count, 'Count'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: types.map((t) {
          final selected = _trackingType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _trackingType = t.$1;
                switch (t.$1) {
                  case HabitTrackingType.timed:
                    _targetUnit = 'min';
                    _dailyGoal = _pickedCat?.defaultGoal ?? 20;
                  case HabitTrackingType.count:
                    _targetUnit = 'times';
                    _dailyGoal = 5;
                  default:
                    _targetUnit = 'time';
                    _dailyGoal = 1;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? MyWalkColor.golden : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? MyWalkColor.charcoal
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _goalRow() {
    final isCheckIn = _trackingType == HabitTrackingType.checkIn;
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            isCheckIn ? 'Complete once per day' : 'Daily target',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const Spacer(),
          if (!isCheckIn) ...[
            GestureDetector(
              onTap: () {
                if (_dailyGoal > 1) setState(() => _dailyGoal -= 1);
              },
              child: Icon(Icons.remove_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.4), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              _dailyGoal.toInt().toString(),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite),
            ),
            const SizedBox(width: 6),
            Text(
              _targetUnit,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _dailyGoal += 1),
              child: Icon(Icons.add_circle_outline_rounded,
                  color: MyWalkColor.golden, size: 22),
            ),
          ] else
            Icon(Icons.check_rounded, color: MyWalkColor.golden, size: 20),
        ],
      ),
    );
  }

  Widget _daysRow() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // Swift day convention: 1=Sun … 7=Sat
    const days = [1, 2, 3, 4, 5, 6, 7];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = days[i];
        final active = _activeDays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            if (active && _activeDays.length > 1) {
              _activeDays = Set.from(_activeDays)..remove(day);
            } else {
              _activeDays = Set.from(_activeDays)..add(day);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? MyWalkColor.golden : MyWalkColor.cardBackground,
              border: Border.all(
                color: active ? MyWalkColor.golden : MyWalkColor.cardBorder,
                width: active ? 0 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? MyWalkColor.charcoal
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _summaryView() {
    final days = _activeDays.length == 7
        ? 'Every day'
        : '${_activeDays.length} days/week';
    final habitSubtitle = switch (_trackingType) {
      HabitTrackingType.timed => '$days — ${_dailyGoal.toInt()} $_targetUnit',
      HabitTrackingType.count => '$days — ${_dailyGoal.toInt()}× $_targetUnit',
      HabitTrackingType.abstain => '$days — Streak',
      _ => '$days — Yes / No',
    };

    return _shell(
      key: const ValueKey('summary'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Walk',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite),
            ),
            const SizedBox(height: 8),
            Text(
              "Here's what your daily walk looks like.",
              style: TextStyle(
                  fontSize: 15, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 28),
            _summaryCard(
              icon: Icons.volunteer_activism_rounded,
              iconColor: MyWalkColor.golden,
              title: 'Daily Gratitude',
              subtitle: 'Every day — Yes / No',
            ),
            const SizedBox(height: 12),
            _summaryCard(
              icon: _pickedCat?.icon ?? Icons.check_circle_rounded,
              iconColor: _pickedCat?.iconColor ?? MyWalkColor.golden,
              title: _habitNameCtrl.text.trim(),
              subtitle: habitSubtitle,
            ),
            const Spacer(),
            _primaryButton(
              label: 'Begin My Walk',
              loading: _processing,
              onPressed: _processing ? null : _beginMyWalk,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: MyWalkColor.golden, size: 20),
        ],
      ),
    );
  }

  Widget _celebrateView() {
    final name = AuthService.shared.givenName ?? 'friend';
    return _shell(
      key: const ValueKey('celebrate'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_walk_rounded,
                color: MyWalkColor.golden, size: 48),
            const SizedBox(height: 20),
            Text(
              'Your walk is set.\nRemain steadfast, $name.',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: MyWalkColor.golden.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.groups_rounded,
                        color: MyWalkColor.golden, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Want to walk with others?',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: MyWalkColor.warmWhite)),
                        const SizedBox(height: 4),
                        Text(
                          "Join a Circle once you're inside the app. Walk together, stay accountable, and encourage each other.",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _primaryButton(
              label: 'Enter MyWalk',
              loading: _processing,
              onPressed: _processing ? null : _enterMyWalk,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────

  Widget _primaryButton({
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: _buttonStyle(),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: MyWalkColor.charcoal),
              )
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
        backgroundColor: MyWalkColor.golden,
        foregroundColor: MyWalkColor.charcoal,
        disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.25),
        disabledForegroundColor: MyWalkColor.charcoal.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: MyWalkColor.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: MyWalkColor.golden.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
