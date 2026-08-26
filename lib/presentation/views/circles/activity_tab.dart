import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/encouragement_provider.dart';
import '../../providers/milestone_share_provider.dart';
import '../../providers/weekly_pulse_provider.dart';
import '../../providers/group_prayer_list_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../journal/journal_entry_composer.dart';
import 'gratitude_wall_view.dart' show GratitudeWallWidget;

String _relativeTime(String dateString) {
  final date = DateTime.tryParse(dateString);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[(date.weekday - 1) % 7];
}

class ActivityTab extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;
  const ActivityTab({super.key, required this.circleId, required this.members});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  int _gratitudeVersion = 0;
  String get circleId => widget.circleId;
  List<CircleMember> get members => widget.members;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EncouragementProvider>().load(circleId);
      context.read<MilestoneShareProvider>().load(circleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.shared.userId ?? '';
    return Consumer2<EncouragementProvider, MilestoneShareProvider>(
      builder: (context, encProvider, shareProvider, _) {
        final received = encProvider.receivedFor(circleId);
        final sent = encProvider.sentFor(circleId);
        final shares = shareProvider.sharesFor(circleId);
        final isLoading = encProvider.isLoading(circleId) && received.isEmpty && sent.isEmpty;

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _showSendSheet(context),
            backgroundColor: MyWalkColor.softGold,
            foregroundColor: MyWalkColor.charcoal,
            child: const Icon(Icons.favorite_rounded),
          ),
          body: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: DeepSpaceBackground(),
                ),
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              else
                RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => Future.wait([
                    encProvider.load(circleId),
                    shareProvider.load(circleId),
                  ]),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      _sectionHeader('This Week'),
                      const SizedBox(height: 8),
                      _HeatmapSection(circleId: circleId, members: members),
                      const SizedBox(height: 20),
                      _gratitudeHeader(context),
                      const SizedBox(height: 8),
                      GratitudeWallWidget(key: ValueKey(_gratitudeVersion), circleId: circleId, showHeader: false),
                      const SizedBox(height: 20),
                      if (shares.isEmpty && received.isEmpty && sent.isEmpty)
                        _emptyState()
                      else ...[
                        if (shares.isNotEmpty) ...[
                          _sectionHeader('Milestones'),
                          const SizedBox(height: 8),
                          ...shares.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MilestoneCard(share: s, uid: uid, circleId: circleId),
                          )),
                          const SizedBox(height: 8),
                        ],
                        if (received.isNotEmpty) ...[
                          _sectionHeader('Received (${received.length})'),
                          const SizedBox(height: 8),
                          ...received.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EncouragementCard(
                              enc: e, uid: uid, circleId: circleId,
                              isReceived: true, members: members),
                          )),
                          const SizedBox(height: 8),
                        ],
                        if (sent.isNotEmpty) ...[
                          _sectionHeader('Sent (${sent.length})'),
                          const SizedBox(height: 8),
                          ...sent.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EncouragementCard(
                              enc: e, uid: uid, circleId: circleId,
                              isReceived: false, members: members),
                          )),
                        ],
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

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      Icon(Icons.favorite_border_rounded, size: 40, color: MyWalkColor.softGold.withValues(alpha: 0.5)),
      const SizedBox(height: 12),
      Text('Nothing here yet.',
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
      const SizedBox(height: 6),
      Text('Tap ♥ to encourage someone in your group.',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
    ]),
  );

  Widget _sectionHeader(String title) => Row(
    children: [
      Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: MyWalkColor.softGold, letterSpacing: 1.2)),
      const SizedBox(width: 8),
      Expanded(
        child: Divider(
          color: MyWalkColor.softGold.withValues(alpha: 0.25),
          height: 1,
          thickness: 0.5,
        ),
      ),
    ],
  );

  Widget _gratitudeHeader(BuildContext context) => Row(children: [
    const Expanded(child: Text('GRATITUDE WALL',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold, letterSpacing: 1.2))),
    GestureDetector(
      onTap: () => _showGratitudeSheet(context),
      child: Row(children: [
        const Icon(Icons.add, size: 14, color: MyWalkColor.softGold),
        const SizedBox(width: 4),
        const Text('Share', style: TextStyle(
            fontSize: 12, color: MyWalkColor.softGold, fontWeight: FontWeight.w500)),
      ]),
    ),
  ]);

  void _showGratitudeSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => _GratitudeComposeSheet(circleId: circleId),
    ).then((success) {
      if (success == true && mounted) setState(() => _gratitudeVersion++);
    });
  }

  void _showSendSheet(BuildContext context) {
    final otherMembers = members.where((m) => m.userId != AuthService.shared.userId).toList();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => SendEncouragementSheet(circleId: circleId, members: otherMembers),
    );
  }
}


class _EncouragementCard extends StatelessWidget {
  final Encouragement enc;
  final String uid;
  final String circleId;
  final bool isReceived;
  final List<CircleMember> members;
  const _EncouragementCard(
      {required this.enc, required this.uid,
      required this.circleId, required this.isReceived,
      required this.members});

  @override
  Widget build(BuildContext context) {
    final senderLabel = enc.isAnonymous ? 'Anonymous' : (enc.senderDisplayName ?? 'Group Member');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isReceived && !enc.isRead) {
        context.read<EncouragementProvider>().markRead(circleId, enc.id);
      }
    });

    final recipientMember = members.firstWhere(
      (m) => m.userId == enc.recipientId,
      orElse: () => CircleMember(userId: '', role: 'member', joinedAt: ''),
    );
    final avatarName = isReceived
        ? (enc.isAnonymous ? null : enc.senderDisplayName)
        : recipientMember.displayName;
    final displayName = isReceived ? senderLabel : recipientMember.displayName;

    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.softGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.softGold.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header zone
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: MyWalkColor.softGold.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(color: MyWalkColor.softGold.withValues(alpha: 0.12), width: 0.5),
            ),
          ),
          child: Row(children: [
            MyWalkAvatar(name: avatarName, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(displayName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: MyWalkColor.softGold)),
            ),
            Text(_relativeTime(enc.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            if (isReceived && !enc.isRead) ...[
              const SizedBox(width: 6),
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.softGold)),
            ],
          ]),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(enc.displayMessage,
                style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite.withValues(alpha: 0.88), height: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push<void>(context, MaterialPageRoute(
                builder: (_) => JournalEntryComposer(
                  habitName: 'Encouragement',
                  sourceType: 'group_encouragement',
                  chipIcon: Icons.groups_rounded,
                ),
              )),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_note, size: 14,
                    color: MyWalkColor.softGold.withValues(alpha: 0.65)),
                const SizedBox(width: 4),
                Text('Create journal entry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: MyWalkColor.softGold.withValues(alpha: 0.65))),
              ]),
            ),
            if (enc.thankYouCount > 0) ...[
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.favorite, size: 12,
                    color: MyWalkColor.softGold.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('${enc.thankYouCount}',
                    style: TextStyle(fontSize: 11,
                        color: MyWalkColor.softGold.withValues(alpha: 0.7))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Heatmap Section ─────────────────────────────────────────────────────────

class _HeatmapSection extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;
  const _HeatmapSection({required this.circleId, required this.members});

  @override
  State<_HeatmapSection> createState() => _HeatmapSectionState();
}

class _HeatmapSectionState extends State<_HeatmapSection> {
  CircleHeatmap? _heatmap;
  CircleWeeklySummary? _summary;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read<CircleRepository>();
      final results = await Future.wait([
        repo.getCircleHeatmap(widget.circleId),
        repo.getSundaySummary(widget.circleId),
      ]);
      if (mounted) {
        setState(() {
          _heatmap = results[0] as CircleHeatmap;
          _summary = results[1] as CircleWeeklySummary;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _heatmap == null) return const SizedBox.shrink();
    final days = _heatmap!.days.take(7).toList();
    final activeCount = _summary?.activeMembers ?? 0;
    final totalCount = _summary?.totalMembers ?? widget.members.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: List.generate(days.length, (i) {
              final day = days[i];
              final date = DateTime.tryParse(day.date);
              final label = date != null ? _dayLabel(date.weekday) : '';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  child: Column(children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: MyWalkColor.warmCoral.withValues(
                            alpha: day.intensity > 0
                                ? (0.2 + day.intensity * 0.7).clamp(0.0, 0.9)
                                : 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 0.3)),
                  ]),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text('$activeCount of $totalCount members active this week',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
        ]),
      ),
      if (_summary != null && _summary!.topMembers.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Text('MEMBER ACTIVITY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: MyWalkColor.warmCoral, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ..._summary!.topMembers.map((m) {
          final member = widget.members.firstWhere(
              (cm) => cm.userId == m.userId,
              orElse: () => CircleMember(userId: '', role: 'member', joinedAt: ''));
          final name = member.displayName;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              child: Row(children: [
                MyWalkAvatar(name: name.isEmpty ? null : name, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name.isEmpty ? 'Member' : name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: MyWalkColor.warmWhite)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MyWalkColor.warmCoral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('🔥 ${m.streak} days',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmCoral)),
                ),
              ]),
            ),
          );
        }),
      ],
    ]);
  }

  static String _dayLabel(int weekday) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[(weekday - 1) % 7];
  }
}

// ─── Send Encouragement Sheet ─────────────────────────────────────────────────

class SendEncouragementSheet extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;
  const SendEncouragementSheet({super.key, required this.circleId, required this.members});

  @override
  State<SendEncouragementSheet> createState() => _SendEncouragementSheetState();
}

class _SendEncouragementSheetState extends State<SendEncouragementSheet> {
  final Set<String> _selectedMemberIds = {};
  String? _selectedPresetKey;
  final _customController = TextEditingController();
  bool _isAnonymous = false;
  bool _notifyViaInbox = true;
  bool _useCustom = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() { _customController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Send Encouragement',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leadingWidth: 72,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: const [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(height: 1, child: ColoredBox(color: MyWalkColor.softGold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Send To'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.members.map((m) {
              final selected = _selectedMemberIds.contains(m.userId);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedMemberIds.remove(m.userId);
                  } else {
                    _selectedMemberIds.add(m.userId);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.softGold.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? MyWalkColor.softGold.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Text(m.displayName,
                      style: TextStyle(fontSize: 13, color: selected ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.5))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _label('Message'),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _useCustom = !_useCustom),
              child: Text(_useCustom ? 'Use Preset' : 'Write Custom',
                  style: const TextStyle(fontSize: 12, color: MyWalkColor.softGold)),
            ),
          ]),
          const SizedBox(height: 8),
          if (!_useCustom) ...[
            ...Encouragement.presetEntries.map((e) {
              final selected = _selectedPresetKey == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedPresetKey = e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.softGold.withValues(alpha: 0.08) : MyWalkColor.inputBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? MyWalkColor.softGold.withValues(alpha: 0.3) : Colors.transparent),
                  ),
                  child: Text(e.value,
                      style: TextStyle(fontSize: 13,
                          color: selected ? MyWalkColor.warmWhite : Colors.white.withValues(alpha: 0.6))),
                ),
              );
            }),
          ] else ...[
            TextField(
              controller: _customController,
              maxLength: 200, maxLines: 3,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a personal message…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                filled: true, fillColor: MyWalkColor.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(children: [
              Icon(_isAnonymous ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: _isAnonymous ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('Send anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _notifyViaInbox = !_notifyViaInbox),
            child: Row(children: [
              Icon(_notifyViaInbox ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: _notifyViaInbox ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('Notify recipient in app',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.softGold,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Send Encouragement',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)));

  Future<void> _send() async {
    if (_selectedMemberIds.isEmpty) { setState(() => _error = 'Select at least one recipient.'); return; }
    final isCustom = _useCustom;
    final text = _customController.text.trim();
    if (isCustom && text.isEmpty) { setState(() => _error = 'Write a message.'); return; }
    if (!isCustom && _selectedPresetKey == null) { setState(() => _error = 'Select a message.'); return; }

    setState(() { _sending = true; _error = null; });
    try {
      final provider = context.read<EncouragementProvider>();
      for (final recipientId in _selectedMemberIds) {
        await provider.send(
          circleId: widget.circleId,
          recipientId: recipientId,
          messageType: isCustom ? EncouragementMessageType.custom : EncouragementMessageType.preset,
          presetKey: isCustom ? null : _selectedPresetKey,
          customText: isCustom ? text : null,
          isAnonymous: _isAnonymous,
          notifyViaInbox: _notifyViaInbox,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }
}


class _MilestoneCard extends StatelessWidget {
  final MilestoneShare share;
  final String uid;
  final String circleId;
  const _MilestoneCard({required this.share, required this.uid, required this.circleId});

  @override
  Widget build(BuildContext context) {
    final hasCelebrated = share.hasCelebrated(uid);
    final isAuthor = share.isAuthor(uid);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: MyWalkColor.softGold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: MyWalkColor.softGold.withValues(alpha: 0.1)),
            child: const Icon(Icons.star_rounded, size: 20, color: MyWalkColor.softGold)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(isAuthor ? 'You hit a milestone!' : '${share.userDisplayName} hit a milestone!',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
              ),
              Text(_relativeTime(share.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            ]),
            const SizedBox(height: 2),
            Text(share.displayLabel,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
            if (share.celebrationCount > 0) ...[
              const SizedBox(height: 4),
              Text('🎉 ${share.celebrationCount} celebrated',
                  style: TextStyle(fontSize: 11, color: MyWalkColor.softGold.withValues(alpha: 0.7))),
            ],
          ])),
          if (!isAuthor)
            GestureDetector(
              onTap: hasCelebrated ? null :
                  () => context.read<MilestoneShareProvider>().celebrate(circleId, share.id, uid),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasCelebrated
                      ? MyWalkColor.softGold.withValues(alpha: 0.1)
                      : MyWalkColor.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(hasCelebrated ? '🎉' : 'Celebrate',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: hasCelebrated ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.5))),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push<void>(context, MaterialPageRoute(
            builder: (_) => JournalEntryComposer(
              habitName: share.habitName,
              sourceType: 'group_milestone',
              chipIcon: Icons.groups_rounded,
            ),
          )),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.edit_note, size: 14,
                color: MyWalkColor.softGold.withValues(alpha: 0.65)),
            const SizedBox(width: 4),
            Text('Create journal entry',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: MyWalkColor.softGold.withValues(alpha: 0.65))),
          ]),
        ),
      ]),
      ),
    );
  }
}

// ─── Pulse (tab hidden — restore by adding Tab + _PulseView to ActivityTab) ───

// ignore: unused_element
class _PulseView extends StatelessWidget {
  final String circleId;
  final String uid;
  const _PulseView({required this.circleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyPulseProvider>(
      builder: (context, provider, _) {
        final pulse = provider.pulseFor(circleId);
        final myResponse = provider.myResponseFor(circleId);
        final hasResponded = provider.hasResponded(circleId);
        final isLoading = provider.isLoading(circleId);

        if (isLoading && pulse == null) {
          return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
        }

        return RefreshIndicator(
          color: MyWalkColor.golden,
          backgroundColor: MyWalkColor.cardBackground,
          onRefresh: () => provider.load(circleId, uid),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              if (!hasResponded)
                _CheckInBanner(circleId: circleId, uid: uid),
              if (hasResponded && myResponse != null) ...[
                _MyResponseCard(response: myResponse),
                const SizedBox(height: 16),
              ],
              if (pulse != null) ...[
                _PulseSummaryCard(pulse: pulse),
                const SizedBox(height: 16),
                if (pulse.responses.isNotEmpty)
                  ..._buildResponses(pulse.responses),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('No pulse data this week.',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildResponses(List<PulseResponse> responses) {
    return [
      Text('THIS WEEK',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
      const SizedBox(height: 8),
      ...responses.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ResponseCard(response: r),
      )),
    ];
  }
}

class _CheckInBanner extends StatelessWidget {
  final String circleId;
  final String uid;
  const _CheckInBanner({required this.circleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _softBlue.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How are you doing this week?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 4),
        Text('Your group wants to know. This helps them pray for you.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5), height: 1.4)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _showCheckIn(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _softBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _softBlue.withValues(alpha: 0.3)),
            ),
            child: const Center(child: Text('Check In',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _softBlue))),
          ),
        ),
      ]),
    );
  }

  void _showCheckIn(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => PulseCheckInSheet(circleId: circleId, uid: uid),
    );
  }
}

class _MyResponseCard extends StatelessWidget {
  final PulseResponse response;
  const _MyResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(response.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(children: [
        Icon(_statusIcon(response.status), size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your check-in this week',
              style: TextStyle(fontSize: 12, color: MyWalkColor.softGold)),
          Text(_statusLabel(response.status),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ])),
        if (response.isAnonymous)
          Text('Anonymous', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }
}

class _PulseSummaryCard extends StatelessWidget {
  final WeeklyPulse pulse;
  const _PulseSummaryCard({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${pulse.responseCount} check-ins this week',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        if (pulse.needsPrayerCount > 0) ...[
          const SizedBox(height: 6),
          Text('${pulse.needsPrayerCount} ${pulse.needsPrayerCount == 1 ? 'person needs' : 'people need'} prayer',
              style: const TextStyle(fontSize: 13, color: MyWalkColor.warmCoral)),
        ],
        const SizedBox(height: 12),
        ...PulseStatus.values.map((s) {
          final count = pulse.countFor(s);
          final frac = pulse.responseCount > 0 ? count / pulse.responseCount : 0.0;
          final color = _statusColor(s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 80,
                  child: Text(_statusLabel(s),
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)))),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac, minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 20,
                  child: Text('$count',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)))),
            ]),
          );
        }),
      ]),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final PulseResponse response;
  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final name = response.isAnonymous ? 'Anonymous' : (response.userDisplayName ?? 'Group Member');
    final color = _statusColor(response.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: MyWalkDecorations.card,
      child: Row(children: [
        Icon(_statusIcon(response.status), size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(name,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)))),
        Text(_statusLabel(response.status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ─── Pulse Check-In Sheet ─────────────────────────────────────────────────────

class PulseCheckInSheet extends StatefulWidget {
  final String circleId;
  final String uid;
  const PulseCheckInSheet({super.key, required this.circleId, required this.uid});

  @override
  State<PulseCheckInSheet> createState() => _PulseCheckInSheetState();
}

class _PulseCheckInSheetState extends State<PulseCheckInSheet> {
  PulseStatus? _selected;
  bool _isAnonymous = false;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('How are you doing this week?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 4),
          Text('Your group will see your check-in.',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          ...PulseStatus.values.map((s) {
            final selected = _selected == s;
            final color = _statusColor(s);
            return GestureDetector(
              onTap: () => setState(() => _selected = s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.1) : MyWalkColor.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? color.withValues(alpha: 0.4) : Colors.transparent),
                ),
                child: Row(children: [
                  Icon(_statusIcon(s), size: 18, color: selected ? color : Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 12),
                  Text(_statusLabel(s),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                          color: selected ? color : Colors.white.withValues(alpha: 0.7))),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(children: [
              Icon(_isAnonymous ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: _isAnonymous ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('Share anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden, foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Check In',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) { setState(() => _error = 'Select how you\'re doing.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<WeeklyPulseProvider>().submit(
        circleId: widget.circleId, status: _selected!,
        isAnonymous: _isAnonymous, uid: widget.uid);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return MyWalkColor.golden;
    case PulseStatus.steady: return MyWalkColor.sage;
    case PulseStatus.struggling: return MyWalkColor.softGold;
    case PulseStatus.needsPrayer: return MyWalkColor.warmCoral;
  }
}

IconData _statusIcon(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return Icons.sentiment_very_satisfied_rounded;
    case PulseStatus.steady: return Icons.sentiment_satisfied_rounded;
    case PulseStatus.struggling: return Icons.sentiment_dissatisfied_rounded;
    case PulseStatus.needsPrayer: return Icons.volunteer_activism_rounded;
  }
}

String _statusLabel(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return 'Encouraged';
    case PulseStatus.steady: return 'Steady';
    case PulseStatus.struggling: return 'Struggling';
    case PulseStatus.needsPrayer: return 'Need Prayer';
  }
}

// softBlue is not in the brand palette — use a local constant.
const _softBlue = Color(0xFF6B9BB8);

// ─── Gratitude Compose Sheet ──────────────────────────────────────────────────

class _GratitudeComposeSheet extends StatefulWidget {
  final String circleId;
  const _GratitudeComposeSheet({required this.circleId});

  @override
  State<_GratitudeComposeSheet> createState() => _GratitudeComposeSheetState();
}

class _GratitudeComposeSheetState extends State<_GratitudeComposeSheet> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Share Gratitude',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leadingWidth: 72,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: const [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(height: 1, child: ColoredBox(color: MyWalkColor.softGold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _controller,
            maxLength: 500,
            maxLines: 5,
            autofocus: true,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'What are you grateful for?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _anonymous = !_anonymous),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _anonymous
                      ? MyWalkColor.softGold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _anonymous ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: _anonymous
                    ? const Icon(Icons.check, size: 14, color: MyWalkColor.softGold)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('Share anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.softGold,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Share Gratitude',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final provider = context.read<GroupPrayerListProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.shareGratitude(
        circleId: widget.circleId,
        text: text,
        isAnonymous: _anonymous,
      );
      nav.pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(const SnackBar(
          content: Text("Couldn't share. Check your connection.")));
    }
  }
}
