import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_entry_composer.dart';

/// Embeddable gratitude wall widget (used inside CircleDetailView).
class GratitudeWallWidget extends StatefulWidget {
  final String circleId;
  final bool showHeader;
  const GratitudeWallWidget({super.key, required this.circleId, this.showHeader = true});

  @override
  State<GratitudeWallWidget> createState() => _GratitudeWallWidgetState();
}

class _GratitudeWallWidgetState extends State<GratitudeWallWidget> {
  List<GratitudePost> _gratitudes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasOlderWeeks = true;
  int _weeksBack = 0;
  int _newCount = 0;
  bool _showNewBadge = false;
  bool _loadError = false;
  GratitudePost? _deleteTarget;

  @override
  void initState() {
    super.initState();
    _loadWall();
    _loadNewCount();
    _markSeen();
  }

  Future<void> _loadWall() async {
    setState(() { _isLoading = true; _loadError = false; });
    try {
      final r = await context.read<CircleRepository>().getGratitudeWall(widget.circleId, weeksBack: _weeksBack);
      if (mounted) setState(() { _gratitudes = r.gratitudes; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _loadError = true; });
    }
  }

  Future<void> _loadNewCount() async {
    try {
      final count = await context.read<CircleRepository>().getGratitudeNewCount(widget.circleId);
      if (mounted && count > 0) {
        setState(() { _newCount = count; _showNewBadge = true; });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showNewBadge = false);
        });
      }
    } catch (_) {}
  }

  Future<void> _markSeen() async {
    try { await context.read<CircleRepository>().markGratitudesSeen(widget.circleId); } catch (_) {}
  }

  void _loadPreviousWeek() {
    setState(() => _isLoadingMore = true);
    final nextWeek = _weeksBack + 1;
    context.read<CircleRepository>().getGratitudeWall(widget.circleId, weeksBack: nextWeek).then((r) {
      if (!mounted) return;
      if (r.gratitudes.isEmpty) {
        setState(() { _hasOlderWeeks = false; _isLoadingMore = false; });
      } else {
        setState(() {
          _gratitudes.addAll(r.gratitudes);
          _weeksBack = nextWeek;
          _isLoadingMore = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _deleteGratitude(GratitudePost item) async {
    try {
      await context.read<CircleRepository>().deleteGratitude(widget.circleId, item.id);
      if (mounted) setState(() => _gratitudes.removeWhere((g) => g.id == item.id));
    } catch (_) {}
  }

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

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold, letterSpacing: 1.2));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.showHeader) ...[
        _sectionHeader('GRATITUDE WALL'),
        const SizedBox(height: 10),
      ],
      if (_isLoading)
        const Center(child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: MyWalkColor.golden, strokeWidth: 2),
        ))
      else if (_loadError && _gratitudes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              "Couldn't connect. Check your connection.",
              style: TextStyle(fontSize: 13, color: MyWalkColor.warmCoral.withValues(alpha: 0.8)),
            ),
          ),
        )
      else if (_gratitudes.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(children: [
            Icon(Icons.volunteer_activism_rounded, size: 40,
                color: MyWalkColor.softGold.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              _weeksBack == 0 ? 'No gratitudes shared this week yet' : 'No gratitudes this week',
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 6),
            Text('Be the first to share a moment of praise.',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
          ]),
        )
      else ...[
        if (_showNewBadge && _newCount > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$_newCount new gratitude${_newCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
            ),
          ),
        ..._gratitudes.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _gratitudeCard(item),
            )),
        if (_hasOlderWeeks)
          Center(
            child: TextButton(
              onPressed: _isLoadingMore ? null : _loadPreviousWeek,
              child: _isLoadingMore
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
                  : Text('Previous weeks',
                      style: TextStyle(fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.7))),
            ),
          ),
      ],
      if (_deleteTarget != null)
        _confirmDeleteDialog(),
    ]);
  }

  Widget _gratitudeCard(GratitudePost item) {
    return GestureDetector(
      onLongPress: item.isMine
          ? () => setState(() => _deleteTarget = item)
          : null,
      child: Container(
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
              MyWalkAvatar(name: item.isAnonymous ? null : item.displayName, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.isAnonymous
                      ? 'Someone in your group'
                      : (item.displayName?.split(' ').first ?? 'Member'),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: item.isAnonymous
                          ? Colors.white.withValues(alpha: 0.45)
                          : (item.isMine ? MyWalkColor.golden : MyWalkColor.softGold)),
                ),
              ),
              Text(_relativeTime(item.sharedAt),
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            ]),
            const SizedBox(height: 8),
            Text(item.gratitudeText,
                style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite.withValues(alpha: 0.88), height: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push<void>(context, MaterialPageRoute(
                builder: (_) => JournalEntryComposer(
                  habitName: 'Gratitude',
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
          ]),
        ),
      ),
    );
  }

  Widget _confirmDeleteDialog() {
    return AlertDialog(
      backgroundColor: MyWalkColor.cardBackground,
      title: const Text('Delete Gratitude', style: TextStyle(color: MyWalkColor.warmWhite)),
      content: Text(
        'This gratitude will be removed from the wall for all group members.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _deleteTarget = null),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        TextButton(
          onPressed: () {
            final t = _deleteTarget;
            setState(() => _deleteTarget = null);
            if (t != null) _deleteGratitude(t);
          },
          child: const Text('Delete', style: TextStyle(color: MyWalkColor.warmCoral)),
        ),
      ],
    );
  }
}

/// Full-screen gratitude wall view (standalone navigation target).
class GratitudeWallView extends StatelessWidget {
  final String circleId;
  const GratitudeWallView({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: Text('Gratitude Wall',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20, color: MyWalkColor.warmWhite)),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 0, left: 0, right: 0,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: MyWalkColor.warmGlow),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GratitudeWallWidget(circleId: circleId),
            ),
          ),
        ],
      ),
    );
  }
}
