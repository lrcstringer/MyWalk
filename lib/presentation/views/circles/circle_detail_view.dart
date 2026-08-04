import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/store_provider.dart';
import '../../providers/prayer_list_provider.dart';
import '../../providers/circle_habits_provider.dart';
import '../../providers/encouragement_provider.dart';
import '../../providers/milestone_share_provider.dart';
import '../../providers/circle_habit_milestone_provider.dart';
import '../../providers/weekly_pulse_provider.dart';
import '../../providers/circle_events_provider.dart';
import '../../providers/group_prayer_list_provider.dart';
import '../../providers/scripture_thread_provider.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import 'circle_sunday_summary_view.dart';
import 'gratitude_wall_view.dart' show GratitudeWallWidget;
import 'circle_prayer_tab.dart';
import 'scripture_threads_tab.dart';
import 'circle_habits_tab.dart';
import 'activity_tab.dart';
import 'events_tab.dart';
import 'circle_settings_view.dart';
import 'announcement_compose_view.dart';
import '../shared/appbar_actions.dart';
import '../shared/notification_bell.dart';

class CircleDetailView extends StatefulWidget {
  final String circleId;
  const CircleDetailView({super.key, required this.circleId});

  @override
  State<CircleDetailView> createState() => _CircleDetailViewState();
}

class _CircleDetailViewState extends State<CircleDetailView> {
  CircleDetails? _detail;
  bool _isLoading = true;
  String? _error;
  bool _wasOffline = false;
  bool _isLeaving = false;
  // ignore: unused_field
  CircleHeatmap? _heatmap;
  // ignore: unused_field
  bool _heatmapFailed = false;
  // ignore: unused_field
  CollectiveMilestones? _milestones;
  // ignore: unused_field
  bool _milestonesFailed = false;

  final Map<int, int> _lastVisitedMs = {};

  static const _sections = [
    ('Prayer',        Icons.volunteer_activism_rounded,   MyWalkColor.sage),
    ('Scripture',     Icons.menu_book_rounded,            MyWalkColor.golden),
    ('Group Practices', Icons.check_circle_outline_rounded, MyWalkColor.warmCoral),
    ('Encouragement',  Icons.favorite_rounded,             MyWalkColor.softGold),
    ('Meetups',        Icons.event_rounded,                MyWalkColor.eventPurple),
  ];

  @override
  void initState() {
    super.initState();
    _loadDetail();
    // _loadHeatmap();    // Overview tab removed — preserved for future use
    // _loadMilestones(); // Overview tab removed — preserved for future use
    _loadProviders();
    _loadLastVisitedAt();
  }

  Future<void> _loadLastVisitedAt() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    bool anyExists = false;
    final map = <int, int>{};
    for (var i = 0; i < _sections.length; i++) {
      final ms = prefs.getInt('circle_tab_visited_${widget.circleId}_$i');
      if (ms != null) { map[i] = ms; anyExists = true; }
    }
    if (!anyExists) {
      // First open: treat all sections as visited now so old content doesn't badge.
      for (var i = 0; i < _sections.length; i++) {
        map[i] = nowMs;
        prefs.setInt('circle_tab_visited_${widget.circleId}_$i', nowMs);
      }
    }
    if (mounted) setState(() => _lastVisitedMs.addAll(map));
  }

  Future<void> _persistVisit(int index, int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('circle_tab_visited_${widget.circleId}_$index', ms);
  }

  bool _sectionHasNew(BuildContext context, int index) {
    if (_lastVisitedMs.isEmpty) return false;
    final lastMs = _lastVisitedMs[index] ?? 0;
    DateTime? latestAt;
    switch (index) {
      case 0:
        final items = context.watch<PrayerListProvider>().activeFor(widget.circleId);
        latestAt = _maxIsoDate(items.map((r) => r.createdAt));
      case 1:
        final threads = context.watch<ScriptureThreadProvider>().threadsFor(widget.circleId);
        latestAt = _maxIsoDate(threads.where((t) => t.isOpen).map((t) => t.createdAt));
      case 2:
        final habits = context.watch<CircleHabitsProvider>().habitsFor(widget.circleId);
        latestAt = _maxIsoDate(habits.map((h) => h.createdAt));
      case 3:
        final enc = context.watch<EncouragementProvider>().receivedFor(widget.circleId);
        latestAt = _maxIsoDate(enc.map((e) => e.createdAt));
      case 4:
        final events = context.watch<CircleEventsProvider>().eventsFor(widget.circleId);
        latestAt = _maxIsoDate(events.map((e) => e.createdAt));
      default:
        return false;
    }
    if (latestAt == null) return false;
    return latestAt.millisecondsSinceEpoch > lastMs;
  }

  DateTime? _maxIsoDate(Iterable<String> isoStrings) {
    DateTime? max;
    for (final s in isoStrings) {
      try {
        final dt = DateTime.parse(s);
        if (max == null || dt.isAfter(max)) max = dt;
      } catch (_) {}
    }
    return max;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadProviders() {
    final uid = AuthService.shared.userId ?? '';
    context.read<PrayerListProvider>().load(widget.circleId);
    context.read<GroupPrayerListProvider>().load(widget.circleId);
    context.read<CircleHabitsProvider>().load(widget.circleId);
    context.read<EncouragementProvider>().load(widget.circleId);
    context.read<MilestoneShareProvider>().load(widget.circleId);
    context.read<CircleHabitMilestoneProvider>().load(widget.circleId);
    context.read<WeeklyPulseProvider>().load(widget.circleId, uid);
    context.read<CircleEventsProvider>().load(widget.circleId);
  }

  Future<bool> _isOffline() async {
    final r = await Connectivity().checkConnectivity();
    return r.every((c) => c == ConnectivityResult.none);
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await context.read<CircleRepository>().getCircleDetail(widget.circleId);
      if (mounted) {
        setState(() { _detail = detail; _isLoading = false; });
        // Start Scripture stream early so badge dot is live before user taps in.
        final isAdmin = detail.members.any(
            (m) => m.userId == AuthService.shared.userId && m.isAdmin);
        context.read<ScriptureThreadProvider>().watchThreads(
          widget.circleId, isAdmin: isAdmin);
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        // Circle was deleted — pop back; circles list will refresh automatically.
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final offline = await _isOffline();
      if (mounted) {
        setState(() {
          _wasOffline = offline;
          _error = offline
              ? 'No internet connection. Connect to load group data.'
              : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _loadHeatmap() async {
    final isPremium = context.read<StoreProvider>().isPremium;
    try {
      final heatmap = await context.read<CircleRepository>().getCircleHeatmap(
        widget.circleId, weekCount: isPremium ? 52 : 1);
      if (mounted) setState(() => _heatmap = heatmap);
    } catch (_) {
      if (mounted) setState(() => _heatmapFailed = true);
    }
  }

  // ignore: unused_element
  Future<void> _loadMilestones() async {
    try {
      final milestones = await context.read<CircleRepository>().getCircleMilestones(widget.circleId);
      if (mounted) setState(() => _milestones = milestones);
    } catch (_) {
      if (mounted) setState(() => _milestonesFailed = true);
    }
  }

  Future<void> _leaveCircle() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<CircleRepository>();
    if (await _isOffline()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect and try again.')),
      );
      return;
    }
    setState(() => _isLeaving = true);
    try {
      await repo.leaveCircle(widget.circleId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLeaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
    }
    if (_detail == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            _wasOffline ? Icons.wifi_off_rounded : Icons.warning_amber_rounded,
            size: 32, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error ?? 'Failed to load',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadDetail,
              child: const Text('Retry', style: TextStyle(color: MyWalkColor.golden))),
        ]),
      );
    }
    return _buildHomeScreen(_detail!);
  }

  Widget _buildHomeScreen(CircleDetails detail) {
    // Pre-compute all watched data at the build-context level.
    final prayerProvider = context.watch<PrayerListProvider>();
    final prayerCount = prayerProvider.activeFor(widget.circleId).length
        + prayerProvider.individualFor(widget.circleId).length;
    final threadCount = context.watch<ScriptureThreadProvider>()
        .threadsFor(widget.circleId).where((t) => t.isOpen).length;
    final habitCount = context.watch<CircleHabitsProvider>()
        .habitsFor(widget.circleId).length;
    final receivedCount = context.watch<EncouragementProvider>()
        .receivedFor(widget.circleId).length;
    final events = context.watch<CircleEventsProvider>().eventsFor(widget.circleId);

    final stats = [
      prayerCount > 0
          ? '$prayerCount active ${prayerCount == 1 ? "request" : "requests"}'
          : 'No requests yet',
      threadCount > 0
          ? '$threadCount open ${threadCount == 1 ? "thread" : "threads"}'
          : 'Start a discussion',
      habitCount > 0
          ? '$habitCount ${habitCount == 1 ? "practice" : "practices"}'
          : 'No practices yet',
      receivedCount > 0
          ? '$receivedCount received · Gratitude Wall'
          : 'Wall · Personal notes',
      _nextEventStat(events),
    ];

    final hasNew = List.generate(_sections.length, (i) => _sectionHasNew(context, i));
    final badgeCounts = <int?>[null, null, null, null, null];

    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: DeepSpaceBackground()),
        ),
        SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            pinned: true,
            elevation: 0,
            leadingWidth: 100,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_rounded, size: 14, color: MyWalkColor.golden),
                    SizedBox(width: 3),
                    Text('Groups',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
                  ],
                ),
              ),
            ),
            actions: [
              bibleBrowserAction(context, MyWalkColor.warmWhite.withValues(alpha: 0.7)),
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 20, color: MyWalkColor.softGold),
                tooltip: 'Settings',
                onPressed: () => _showGroupSettings(detail),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _HeroHeader(detail: detail),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SectionCard(
                    label: _sections[i].$1,
                    icon: _sections[i].$2,
                    accent: _sections[i].$3,
                    stat: stats[i],
                    hasNew: hasNew[i],
                    badgeCount: badgeCounts[i],
                    onTap: () => _pushSection(context, i, detail),
                  ),
                ),
                childCount: _sections.length,
              ),
            ),
          ),
        ],
      ),
    ),
    Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MyWalkColor.sage.withValues(alpha: 0.14),
                MyWalkColor.sage.withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.28, 0.50],
            ),
          ),
        ),
      ),
    ),
  ],
);
  }

  String _nextEventStat(List<CircleEvent> events) {
    final now = DateTime.now();
    final count = events.where((e) => e.eventDateTime.isAfter(now)).length;
    if (count == 0) return 'No upcoming meetups';
    return '$count upcoming ${count == 1 ? "meetup" : "meetups"}';
  }

  Future<void> _pushSection(BuildContext context, int index, CircleDetails detail) async {
    final isAdmin = detail.members.any(
        (m) => m.userId == AuthService.shared.userId && m.isAdmin);

    final ms = DateTime.now().millisecondsSinceEpoch;
    setState(() => _lastVisitedMs[index] = ms);
    _persistVisit(index, ms);

    final section = _sections[index];
    Widget body;
    switch (index) {
      case 0:
        body = CirclePrayerTab(
          circleId: widget.circleId, isAdmin: isAdmin, members: detail.members);
      case 1:
        body = ScriptureThreadsTab(
          circleId: widget.circleId, settings: detail.settings, isAdmin: isAdmin);
      case 2:
        body = CircleHabitsTab(circleId: widget.circleId, isAdmin: isAdmin);
      case 3:
        body = ActivityTab(circleId: widget.circleId, members: detail.members);
      case 4:
        body = EventsTab(
          circleId: widget.circleId, isAdmin: isAdmin, settings: detail.settings);
      default:
        return;
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _SectionScreenWrapper(
        circleName: detail.name,
        sectionName: section.$1,
        accent: section.$3,
        body: body,
      ),
    ));
  }

  // ignore: unused_element
  void _showSundaySummary(CircleDetails detail) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CircleSundaySummaryView(circleId: widget.circleId, circleName: detail.name),
    );
  }

  void _openSettings(CircleDetails detail) async {
    final result = await Navigator.push<Object?>(context, MaterialPageRoute(
      builder: (_) => CircleSettingsView(
        circleId: widget.circleId,
        circleName: detail.name,
        circleDescription: detail.description,
        inviteCode: detail.inviteCode,
        settings: detail.settings,
        members: detail.members,
        currentUserId: AuthService.shared.userId ?? '',
      ),
    ));
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.pop(context);
    } else {
      _loadDetail();
    }
  }

  void _showGroupSettings(CircleDetails detail) {
    final isAdmin = detail.members
        .any((m) => m.userId == AuthService.shared.userId && m.isAdmin);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GroupSettingsSheet(
        detail: detail,
        isAdmin: isAdmin,
        isLeaving: _isLeaving,
        onEditSettings: () {
          Navigator.pop(context);
          _openSettings(detail);
        },
        onAnnounceTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AnnouncementComposeView(
              circleId: widget.circleId, circleName: detail.name),
          ));
        },
        onInviteTap: () {
          Navigator.pop(context);
          _showInviteSheet(detail);
        },
        onLeaveTap: () {
          Navigator.pop(context);
          _confirmLeave();
        },
      ),
    );
  }

  void _showInviteSheet(CircleDetails detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _InviteSheet(
        inviteCode: detail.inviteCode,
        circleName: detail.name,
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Leave Group', style: TextStyle(color: MyWalkColor.warmWhite)),
        content: Text(
          "You'll no longer receive prayer requests or see this group's progress.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _leaveCircle(); },
            child: const Text('Leave', style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final CircleDetails detail;
  const _HeroHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle name in serif
          Text(detail.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 27,
              color: MyWalkColor.warmWhite,
              letterSpacing: -0.4, height: 1.15)),
          const SizedBox(height: 14),
          // Meta: avatars left, member count right
          Row(
            children: [
              _AvatarRow(members: detail.members, memberCount: detail.memberCount),
              const Spacer(),
              Text(
                '${detail.memberCount} '
                '${detail.memberCount == 1 ? "member" : "members"}',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.45))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Avatar Row ───────────────────────────────────────────────────────────────

class _AvatarRow extends StatelessWidget {
  final List<CircleMember> members;
  final int memberCount;
  const _AvatarRow({required this.members, required this.memberCount});

  static const _avatarColors = [
    MyWalkColor.sage,
    MyWalkColor.golden,
    MyWalkColor.warmCoral,
    MyWalkColor.softGold,
    MyWalkColor.eventPurple,
  ];

  static const _maxShow = 5;
  static const _stride = 22.0;
  static const _size = 32.0;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final shown = members.take(_maxShow).toList();
    final extra = memberCount - shown.length;
    final totalSlots = shown.length + (extra > 0 ? 1 : 0);
    final stackWidth = totalSlots > 0 ? totalSlots * _stride + (_size - _stride) : _size;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (totalSlots > 0) SizedBox(
          width: stackWidth,
          height: _size,
          child: Stack(
            children: [
              ...shown.asMap().entries.map((e) {
                final color = _avatarColors[e.key % _avatarColors.length];
                return Positioned(
                  left: e.key * _stride,
                  child: Container(
                    width: _size, height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.2),
                      border: Border.all(color: MyWalkColor.charcoal, width: 2),
                    ),
                    child: Center(child: Text(_initials(e.value.displayName),
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: color))),
                  ),
                );
              }),
              if (extra > 0)
                Positioned(
                  left: shown.length * _stride,
                  child: Container(
                    width: _size, height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(color: MyWalkColor.charcoal, width: 2),
                    ),
                    child: Center(child: Text('+$extra',
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55)))),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final String stat;
  final bool hasNew;
  final int? badgeCount;
  final VoidCallback onTap;

  const _SectionCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.stat,
    required this.hasNew,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount != null && badgeCount! > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              accent.withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 14),
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
              ),
              const SizedBox(width: 14),
              // Label + stat
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: MyWalkColor.warmWhite, letterSpacing: -0.1)),
                      const SizedBox(height: 3),
                      Text(stat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accent.withValues(alpha: 0.72)),
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              // Badge pill or new-content dot
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: showBadge
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          height: 20,
                          constraints: const BoxConstraints(minWidth: 20),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('$badgeCount',
                            style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF0C0C18)))),
                        )
                      : hasNew
                          ? Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            )
                          : const SizedBox(width: 7),
                ),
              ),
              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.chevron_right_rounded, size: 18,
                    color: Colors.white.withValues(alpha: 0.28)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Screen Wrapper ───────────────────────────────────────────────────

class _SectionScreenWrapper extends StatelessWidget {
  final String circleName;
  final String sectionName;
  final Color accent;
  final Widget body;

  const _SectionScreenWrapper({
    required this.circleName,
    required this.sectionName,
    required this.accent,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        elevation: 0,
        leadingWidth: 180,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_rounded, size: 14, color: MyWalkColor.golden),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(circleName,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.golden),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
        title: Text(sectionName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16, color: MyWalkColor.warmWhite)),
        centerTitle: true,
        actions: [
          bibleBrowserAction(context, MyWalkColor.warmWhite.withValues(alpha: 0.7)),
          const NotificationBell(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: accent.withValues(alpha: 0.55)),
        ),
      ),
      body: Stack(
        children: [
          body,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.14),
                      accent.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.50],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

// ignore: unused_element
class _OverviewTab extends StatelessWidget {
  final String circleId;
  final CircleDetails detail;
  final CircleHeatmap? heatmap;
  final bool heatmapFailed;
  final CollectiveMilestones? milestones;
  final bool milestonesFailed;
  final VoidCallback onSummaryTap;
  final VoidCallback onLeaveTap;
  final bool isLeaving;

  const _OverviewTab({
    required this.circleId,
    required this.detail,
    required this.heatmap,
    required this.heatmapFailed,
    required this.milestones,
    required this.milestonesFailed,
    required this.onSummaryTap,
    required this.onLeaveTap,
    required this.isLeaving,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _collaborativeHeatmapSection(isPremium),
        const SizedBox(height: 16),
        _collectiveMilestonesSection(context),
        const SizedBox(height: 16),
        GratitudeWallWidget(circleId: circleId),
        const SizedBox(height: 16),
        _sectionHeader('Actions'),
        const SizedBox(height: 8),
        _actionRow(
          icon: Icons.wb_sunny_rounded, iconColor: MyWalkColor.golden,
          iconBg: MyWalkColor.golden.withValues(alpha: 0.12),
          title: 'Weekly Summary', subtitle: "See your group's faithfulness this week",
          onTap: onSummaryTap,
        ),
        const SizedBox(height: 16),
        _sectionHeader('Members (${detail.members.length})'),
        const SizedBox(height: 8),
        ...detail.members.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _memberRow(context, m),
        )),
        const SizedBox(height: 16),
        _leaveButton(),
      ],
    );
  }

  Widget _collaborativeHeatmapSection(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.grid_view_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          Text('Group Activity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
          const Spacer(),
          Text('${detail.memberCount} members',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        ]),
        const SizedBox(height: 6),
        Text(
          'When members have a strong day, this glows. The more the group gives, the brighter it gets.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45), height: 1.4),
        ),
        const SizedBox(height: 12),
        if (heatmapFailed)
          Text('Could not load activity data.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (heatmap == null)
          const SizedBox(height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: MyWalkColor.golden))))
        else
          _CircleHeatmapGrid(heatmap: heatmap!, isPremium: isPremium),
        if (!isPremium) ...[
          const SizedBox(height: 8),
          Text('Upgrade to see your full 52-week group history.',
              style: TextStyle(fontSize: 11, color: MyWalkColor.golden.withValues(alpha: 0.5))),
        ],
      ]),
    );
  }

  Widget _collectiveMilestonesSection(BuildContext context) {
    final ms = milestones;
    final habitMilestones = context
        .watch<CircleHabitMilestoneProvider>()
        .milestonesFor(circleId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          Text('Group Milestones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
        ]),
        const SizedBox(height: 10),
        if (milestonesFailed)
          Text('Could not load milestones.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (ms == null)
          const SizedBox(height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: MyWalkColor.golden))))
        else ...[
          if (ms.totalGivingDays > 0 || ms.totalHours > 0 || ms.totalGratitudeDays > 0)
            _milestoneTotalsRow(ms),
          const SizedBox(height: 10),
          if (ms.milestones.isEmpty && habitMilestones.isEmpty)
            Text('Keep going — your first group milestone is on its way.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), height: 1.4))
          else ...[
            ...ms.milestones.take(3).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _milestoneTile(m),
            )),
            ...habitMilestones.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _habitMilestoneTile(m),
            )),
          ],
        ],
      ]),
    );
  }

  Widget _habitMilestoneTile(CircleHabitMilestone m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.groups_rounded, size: 16, color: MyWalkColor.golden),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Group activity milestone!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 2),
          Text(m.displayLabel,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
        ])),
      ]),
    );
  }

  Widget _milestoneTotalsRow(CollectiveMilestones ms) {
    final items = <_TotalItem>[];
    if (ms.totalGivingDays > 0) items.add(_TotalItem('${ms.totalGivingDays}', 'giving days'));
    if (ms.totalHours >= 1) {
      final h = ms.totalHours.floor();
      items.add(_TotalItem('$h', h == 1 ? 'hour' : 'hours'));
    }
    if (ms.totalGratitudeDays > 0) items.add(_TotalItem('${ms.totalGratitudeDays}', 'gratitude days'));
    return Row(
      children: items.map((item) => Expanded(
        child: Column(children: [
          Text(item.value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
          Text(item.label,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
        ]),
      )).toList(),
    );
  }

  Widget _milestoneTile(CollectiveMilestone m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, size: 16, color: MyWalkColor.golden),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 2),
          Text(m.message,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2));
  }

  Widget _actionRow({
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
          ])),
          Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  Widget _memberRow(BuildContext context, CircleMember m) {
    final currentUid = AuthService.shared.userId ?? '';
    final isSelf = m.userId == currentUid;
    final isAdmin = m.isAdmin;
    final color = isAdmin ? MyWalkColor.golden : MyWalkColor.sage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: MyWalkDecorations.card,
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
          child: Icon(Icons.person_rounded, size: 14, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isSelf ? 'You' : m.displayName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
          Text(isAdmin ? 'Admin' : 'Member',
              style: TextStyle(fontSize: 11,
                  color: isAdmin ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4))),
        ])),
      ]),
    );
  }

  Widget _leaveButton() {
    return GestureDetector(
      onTap: isLeaving ? null : onLeaveTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.logout_rounded, size: 16, color: MyWalkColor.warmCoral),
          const SizedBox(width: 10),
          const Expanded(child: Text('Leave Group',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmCoral))),
          if (isLeaving)
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.warmCoral)),
        ]),
      ),
    );
  }
}

// ─── Supporting types ─────────────────────────────────────────────────────────

class _TotalItem {
  final String value;
  final String label;
  const _TotalItem(this.value, this.label);
}

// ─── Collaborative heatmap grid ───────────────────────────────────────────────

class _CircleHeatmapGrid extends StatelessWidget {
  final CircleHeatmap heatmap;
  final bool isPremium;

  const _CircleHeatmapGrid({required this.heatmap, required this.isPremium});

  static const _tileSize = 10.0;
  static const _gap = 2.0;
  static const _stride = _tileSize + _gap;
  static const _dayLabelWidth = 14.0;
  static const _monthRowHeight = 13.0;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthAbbrs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Map<String, double> _intensityMap() => {for (final d in heatmap.days) d.date: d.intensity};

  List<List<DateTime>> _buildWeeks() {
    final weekCount = isPremium ? 52 : 1;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));
    return List.generate(weekCount, (i) {
      final weekStart = currentWeekStart.add(Duration(days: (i - (weekCount - 1)) * 7));
      return List.generate(7, (d) => weekStart.add(Duration(days: d)));
    });
  }

  Color _cellColor(double intensity) {
    if (intensity <= 0.0) return MyWalkColor.surfaceOverlay;
    if (intensity <= 0.25) return MyWalkColor.golden.withValues(alpha: 0.15);
    if (intensity <= 0.65) return MyWalkColor.golden.withValues(alpha: 0.50);
    return MyWalkColor.golden.withValues(alpha: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final map = _intensityMap();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (weeks.length == 1) {
      return Row(
        children: weeks.first.map((date) {
          final isFuture = date.isAfter(todayStart);
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final intensity = isFuture ? 0.0 : (map[key] ?? 0.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFuture ? Colors.white.withValues(alpha: 0.02) : _cellColor(intensity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _monthRowHeight + 1),
          child: Column(
            children: List.generate(7, (i) => SizedBox(
              width: _dayLabelWidth, height: _stride,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_dayLabels[i],
                    style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.35))),
              ),
            )),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _monthRowHeight,
                  child: Row(
                    children: List.generate(weeks.length, (i) {
                      final sunday = weeks[i].first;
                      final showMonth = i == 0 || sunday.month != weeks[i - 1].first.month;
                      return SizedBox(
                        width: _stride,
                        child: showMonth
                            ? Text(_monthAbbrs[sunday.month - 1],
                                style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.4)))
                            : null,
                      );
                    }),
                  ),
                ),
                ...List.generate(7, (dayIndex) => Row(
                  children: weeks.map((week) {
                    final date = week[dayIndex];
                    final isFuture = date.isAfter(todayStart);
                    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final intensity = isFuture ? 0.0 : (map[key] ?? 0.0);
                    return Padding(
                      padding: const EdgeInsets.only(right: _gap, bottom: _gap),
                      child: Container(
                        width: _tileSize, height: _tileSize,
                        decoration: BoxDecoration(
                          color: isFuture ? Colors.white.withValues(alpha: 0.02) : _cellColor(intensity),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: !isFuture && intensity > 0.65
                              ? [BoxShadow(color: MyWalkColor.golden.withValues(alpha: 0.35), blurRadius: 3)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Group Settings Sheet ─────────────────────────────────────────────────────

class _GroupSettingsSheet extends StatelessWidget {
  final CircleDetails detail;
  final bool isAdmin;
  final bool isLeaving;
  final VoidCallback onEditSettings;
  final VoidCallback onAnnounceTap;
  final VoidCallback onInviteTap;
  final VoidCallback onLeaveTap;

  const _GroupSettingsSheet({
    required this.detail,
    required this.isAdmin,
    required this.isLeaving,
    required this.onEditSettings,
    required this.onAnnounceTap,
    required this.onInviteTap,
    required this.onLeaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onEditSettings,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: MyWalkDecorations.card,
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyWalkColor.softGold.withValues(alpha: 0.12)),
                  child: const Icon(Icons.tune_rounded, size: 16, color: MyWalkColor.softGold),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Edit Group Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: MyWalkColor.warmWhite))),
                Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAnnounceTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: MyWalkDecorations.card,
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyWalkColor.softGold.withValues(alpha: 0.12)),
                  child: const Icon(Icons.campaign_rounded, size: 16, color: MyWalkColor.softGold),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Make an Announcement',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: MyWalkColor.warmWhite))),
                Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onInviteTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: MyWalkDecorations.card,
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyWalkColor.sage.withValues(alpha: 0.12)),
                  child: const Icon(Icons.person_add_rounded, size: 16, color: MyWalkColor.sage),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Send Join Invite',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: MyWalkColor.warmWhite))),
                Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Members (${detail.members.length})'.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        ...detail.members.map((m) {
          final isSelf = m.userId == AuthService.shared.userId;
          final color = m.isAdmin ? MyWalkColor.golden : MyWalkColor.sage;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: MyWalkDecorations.card,
              child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
                  child: Icon(Icons.person_rounded, size: 14, color: color)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isSelf ? 'You' : m.displayName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
                  Text(m.isAdmin ? 'Admin' : 'Member',
                      style: TextStyle(fontSize: 11,
                          color: m.isAdmin ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4))),
                ])),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: isLeaving ? null : onLeaveTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.logout_rounded, size: 16, color: MyWalkColor.warmCoral),
              const SizedBox(width: 10),
              const Expanded(child: Text('Leave Group',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: MyWalkColor.warmCoral))),
              if (isLeaving)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.warmCoral)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Invite Sheet ─────────────────────────────────────────────────────────────

class _InviteSheet extends StatelessWidget {
  final String inviteCode;
  final String circleName;

  const _InviteSheet({required this.inviteCode, required this.circleName});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Invite Someone',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 6),
          Text('Share this code with anyone you want to invite:',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Text(
                  inviteCode,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: MyWalkColor.golden, letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invite code copied'),
                  backgroundColor: MyWalkColor.cardBackground,
                  duration: Duration(seconds: 2),
                ));
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyWalkColor.golden.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.copy_rounded, size: 18, color: MyWalkColor.golden),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final text = 'Join my Group "$circleName" on MyWalk!\n\n'
                    'Tap to join: https://mywalk.faith/join?code=$inviteCode\n\n'
                    'Or enter invite code "$inviteCode" manually in the app.';
                Share.share(text);
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Share Invite Link',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
