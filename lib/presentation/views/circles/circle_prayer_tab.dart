import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/entities/habit.dart' show PrayerItemStatus;
import '../../providers/group_prayer_list_provider.dart';
import '../../providers/circle_notification_provider.dart';
import '../../theme/app_theme.dart';
import 'prayer_list_tab.dart';

// ── Top-level Prayer tab: Requests | List sub-tabs ───────────────────────────

class CirclePrayerTab extends StatefulWidget {
  final String circleId;
  final bool isAdmin;
  final List<CircleMember> members;

  const CirclePrayerTab({
    super.key,
    required this.circleId,
    required this.isAdmin,
    required this.members,
  });

  @override
  State<CirclePrayerTab> createState() => _CirclePrayerTabState();
}

class _CirclePrayerTabState extends State<CirclePrayerTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // circle_detail_view._loadProviders() already calls load() before this
    // widget builds, so no second call needed here.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: MyWalkColor.charcoal,
        child: TabBar(
          controller: _tabController,
          labelColor: MyWalkColor.golden,
          unselectedLabelColor: MyWalkColor.softGold,
          indicatorColor: MyWalkColor.golden,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'List'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            PrayerListTab(circleId: widget.circleId),
            GroupPrayerListTab(
              circleId: widget.circleId,
              isAdmin: widget.isAdmin,
              members: widget.members,
            ),
          ],
        ),
      ),
    ]);
  }
}

// ── Group Prayer List Tab ─────────────────────────────────────────────────────

class GroupPrayerListTab extends StatelessWidget {
  final String circleId;
  final bool isAdmin;
  final List<CircleMember> members;

  const GroupPrayerListTab({
    super.key,
    required this.circleId,
    required this.isAdmin,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupPrayerListProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoading(circleId);
        final list = provider.listFor(circleId);

        if (isLoading && list == null) {
          return const Center(
              child: CircularProgressIndicator(color: MyWalkColor.golden));
        }

        if (list == null) {
          return _NoListState(
              circleId: circleId, isAdmin: isAdmin, members: members);
        }

        final uid = AuthService.shared.userId ?? '';
        if (!list.canView(uid, isAdmin: isAdmin)) {
          return _notVisibleState();
        }

        return _ListBody(
            circleId: circleId, list: list, isAdmin: isAdmin, members: members);
      },
    );
  }

  Widget _notVisibleState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.lock_outline_rounded,
            size: 40, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('This list is private.',
            style:
                TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text('Ask your circle admin to give you access.',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }
}

// ── No list state ─────────────────────────────────────────────────────────────

class _NoListState extends StatelessWidget {
  final String circleId;
  final bool isAdmin;
  final List<CircleMember> members;

  const _NoListState(
      {required this.circleId,
      required this.isAdmin,
      required this.members});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(children: [
        Icon(Icons.format_list_bulleted_rounded,
            size: 40, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('No group prayer list yet.',
            style:
                TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text(
          isAdmin
              ? 'Create a list to share curated prayer items with your circle.'
              : 'Your admin hasn\'t created a prayer list yet.',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                _showCreateListSheet(context, circleId, members),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create Prayer List',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  void _showCreateListSheet(BuildContext context, String circleId,
      List<CircleMember> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => _VisibilityPickerSheet(
        circleId: circleId,
        members: members,
        currentIds: const [],
        showNotifyToggle: true,
        onSave: (ids) =>
            context.read<GroupPrayerListProvider>().createList(circleId, ids),
      ),
    );
  }
}

// ── List body ─────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  final String circleId;
  final CirclePrayerList list;
  final bool isAdmin;
  final List<CircleMember> members;

  const _ListBody({
    required this.circleId,
    required this.list,
    required this.isAdmin,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final active = list.activeItems;
    final answered = list.answeredItems;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      floatingActionButton: isAdmin
          ? FloatingActionButton.small(
              onPressed: () => _showAddItemSheet(context),
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        color: MyWalkColor.golden,
        backgroundColor: MyWalkColor.cardBackground,
        onRefresh: () =>
            context.read<GroupPrayerListProvider>().load(circleId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (isAdmin)
              _adminHeader(context),
            if (active.isEmpty && answered.isEmpty)
              _emptyState()
            else ...[
              if (active.isNotEmpty) ...[
                _sectionHeader('Praying (${active.length})'),
                const SizedBox(height: 8),
                ...active.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PrayerItemCard(
                          circleId: circleId, item: item, isAdmin: isAdmin),
                    )),
              ],
              if (answered.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionHeader('Answered Prayers (${answered.length})'),
                const SizedBox(height: 8),
                ...answered.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PrayerItemCard(
                          circleId: circleId, item: item, isAdmin: isAdmin),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _adminHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(Icons.admin_panel_settings_outlined,
            size: 13, color: MyWalkColor.golden.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text('Admin · ${list.visibleToMemberIds.length} members can view',
            style: TextStyle(
                fontSize: 12, color: MyWalkColor.softGold.withValues(alpha: 0.6))),
        const Spacer(),
        GestureDetector(
          onTap: () => _showVisibilitySheet(context),
          child: Text('Manage',
              style: TextStyle(
                  fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.8))),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.volunteer_activism_rounded,
            size: 40, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text(
          isAdmin
              ? 'Tap + to add your first prayer item.'
              : 'No prayer items yet.',
          style:
              TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4)),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.2));
  }

  void _showAddItemSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Add Prayer Item',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: MyWalkColor.warmWhite)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 300,
              maxLines: 3,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What should the circle pray for?',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                filled: true,
                fillColor: MyWalkColor.inputBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                counterStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  context
                      .read<GroupPrayerListProvider>()
                      .addItem(circleId, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add to List',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _showVisibilitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => _VisibilityPickerSheet(
        circleId: circleId,
        members: members,
        currentIds: list.visibleToMemberIds,
        onSave: (ids) => context
            .read<GroupPrayerListProvider>()
            .updateVisibility(circleId, ids),
      ),
    );
  }
}

// ── Prayer Item Card ──────────────────────────────────────────────────────────

class _PrayerItemCard extends StatefulWidget {
  final String circleId;
  final CirclePrayerItem item;
  final bool isAdmin;

  const _PrayerItemCard({
    required this.circleId,
    required this.item,
    required this.isAdmin,
  });

  @override
  State<_PrayerItemCard> createState() => _PrayerItemCardState();
}

class _PrayerItemCardState extends State<_PrayerItemCard> {
  bool _editingMemo = false;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController =
        TextEditingController(text: widget.item.memo ?? '');
  }

  @override
  void didUpdateWidget(_PrayerItemCard old) {
    super.didUpdateWidget(old);
    // Keep controller in sync when the item changes after a provider reload,
    // but only if the user isn't actively editing (don't clobber their draft).
    if (old.item.memo != widget.item.memo && !_editingMemo) {
      _memoController.text = widget.item.memo ?? '';
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Color _statusColor(PrayerItemStatus s) {
    switch (s) {
      case PrayerItemStatus.praying:
        return MyWalkColor.golden;
      case PrayerItemStatus.unanswered:
        return MyWalkColor.warmCoral;
      case PrayerItemStatus.answered:
        return MyWalkColor.sage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAnswered = item.status == PrayerItemStatus.answered;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnswered
            ? MyWalkColor.sage.withValues(alpha: 0.05)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered
              ? MyWalkColor.sage.withValues(alpha: 0.18)
              : MyWalkColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(item.text,
                style: TextStyle(
                    fontSize: 14,
                    color: isAnswered
                        ? Colors.white.withValues(alpha: 0.45)
                        : MyWalkColor.warmWhite,
                    decoration:
                        isAnswered ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white.withValues(alpha: 0.3),
                    height: 1.45)),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.25)),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (widget.isAdmin)
            _statusMenu(context, item)
          else
            _statusBadge(item),
          const Spacer(),
          if (widget.isAdmin)
            GestureDetector(
              onTap: () => setState(() => _editingMemo = !_editingMemo),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notes_rounded,
                    size: 13,
                    color: (item.memo?.isNotEmpty ?? false)
                        ? MyWalkColor.softGold
                        : Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text('Note',
                    style: TextStyle(
                        fontSize: 11,
                        color: (item.memo?.isNotEmpty ?? false)
                            ? MyWalkColor.softGold
                            : Colors.white.withValues(alpha: 0.3))),
              ]),
            ),
        ]),
        if (item.memo != null && item.memo!.isNotEmpty && !_editingMemo) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item.memo!,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.4)),
          ),
        ],
        if (_editingMemo) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            autofocus: true,
            maxLength: 300,
            maxLines: 2,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              counterStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => setState(() {
                _memoController.text = widget.item.memo ?? '';
                _editingMemo = false;
              }),
              child: Text('Cancel',
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4))),
            ),
            TextButton(
              onPressed: () {
                setState(() => _editingMemo = false);
                context.read<GroupPrayerListProvider>().updateItemMemo(
                    widget.circleId,
                    widget.item,
                    _memoController.text.trim());
              },
              child: const Text('Save',
                  style: TextStyle(color: MyWalkColor.golden)),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _statusBadge(CirclePrayerItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(item.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _statusColor(item.status).withValues(alpha: 0.3)),
      ),
      child: Text(item.status.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _statusColor(item.status))),
    );
  }

  Widget _statusMenu(BuildContext context, CirclePrayerItem item) {
    return GestureDetector(
      onTap: () => _showStatusPicker(context, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(item.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _statusColor(item.status).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(item.status.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(item.status))),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 13, color: _statusColor(item.status)),
        ]),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, CirclePrayerItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ...PrayerItemStatus.values.map((s) => ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _statusColor(s)),
                ),
                title: Text(s.label,
                    style: TextStyle(
                        color: item.status == s
                            ? _statusColor(s)
                            : MyWalkColor.warmWhite,
                        fontWeight: item.status == s
                            ? FontWeight.w600
                            : FontWeight.normal)),
                trailing: item.status == s
                    ? Icon(Icons.check_rounded,
                        size: 16, color: _statusColor(s))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (item.status == s) return;
                  if (s == PrayerItemStatus.answered) {
                    _confirmAnswered(context, item);
                  } else {
                    context
                        .read<GroupPrayerListProvider>()
                        .updateItemStatus(widget.circleId, item, s);
                  }
                },
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmAnswered(BuildContext context, CirclePrayerItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Mark as Answered',
            style: TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text(
          'Praise God! Would you like to share this answered prayer on the Gratitude Wall?',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupPrayerListProvider>().updateItemStatus(
                  widget.circleId, item, PrayerItemStatus.answered);
            },
            child: Text('Mark only',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupPrayerListProvider>().updateItemStatus(
                  widget.circleId, item, PrayerItemStatus.answered);
              _shareToGratitudeWall(context, item);
            },
            child: const Text('Mark & Share',
                style: TextStyle(
                    color: MyWalkColor.sage,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _shareToGratitudeWall(BuildContext context, CirclePrayerItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GratitudeShareSheet(
          circleId: widget.circleId,
          prayerText: item.text,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Remove Item',
            style:
                TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text('Remove "${widget.item.text}" from the prayer list?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<GroupPrayerListProvider>()
                  .deleteItem(widget.circleId, widget.item.id);
            },
            child: const Text('Remove',
                style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

// ── Gratitude Share Sheet (post answered prayer to wall) ──────────────────────

class _GratitudeShareSheet extends StatefulWidget {
  final String circleId;
  final String prayerText;

  const _GratitudeShareSheet(
      {required this.circleId, required this.prayerText});

  @override
  State<_GratitudeShareSheet> createState() => _GratitudeShareSheetState();
}

class _GratitudeShareSheetState extends State<_GratitudeShareSheet> {
  late final TextEditingController _controller;
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: 'God answered my prayer: ${widget.prayerText}');
  }

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
        title: const Text('Share to Gratitude Wall',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _controller,
            maxLength: 500,
            maxLines: 5,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              counterStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _anonymous = !_anonymous),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _anonymous
                      ? MyWalkColor.golden.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _anonymous
                        ? MyWalkColor.golden
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: _anonymous
                    ? const Icon(Icons.check, size: 14, color: MyWalkColor.golden)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('Share anonymously',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
            ]),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.sage,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Share Gratitude',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
    try {
      await provider.shareGratitude(
        circleId: widget.circleId,
        text: text,
        isAnonymous: _anonymous,
      );
      nav.pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── Visibility Picker Sheet ───────────────────────────────────────────────────

class _VisibilityPickerSheet extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;
  final List<String> currentIds;
  final Future<void> Function(List<String>) onSave;
  final bool showNotifyToggle;

  const _VisibilityPickerSheet({
    required this.circleId,
    required this.members,
    required this.currentIds,
    required this.onSave,
    this.showNotifyToggle = false,
  });

  @override
  State<_VisibilityPickerSheet> createState() => _VisibilityPickerSheetState();
}

class _VisibilityPickerSheetState extends State<_VisibilityPickerSheet> {
  late Set<String> _selected;
  bool _notifyMembers = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.currentIds);
  }

  @override
  Widget build(BuildContext context) {
    final nonAdminMembers = widget.members
        .where((m) => !m.isAdmin)
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Who can view this list?',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite)),
        const SizedBox(height: 4),
        Text('Admins always have access.',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            shrinkWrap: true,
            children: nonAdminMembers.map((m) {
              final selected = _selected.contains(m.userId);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.displayName,
                    style: const TextStyle(
                        color: MyWalkColor.warmWhite, fontSize: 14)),
                trailing: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selected.remove(m.userId);
                    } else {
                      _selected.add(m.userId);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected
                          ? MyWalkColor.golden.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected
                            ? MyWalkColor.golden
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 14, color: MyWalkColor.golden)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.showNotifyToggle) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: MyWalkColor.inputBackground,
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
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    final notifProvider = _notifyMembers && widget.showNotifyToggle
                        ? context.read<CircleNotificationProvider>()
                        : null;
                    try {
                      await widget.onSave(_selected.toList());
                      notifProvider?.sendAnnouncement(
                        circleId: widget.circleId,
                        message: 'Your circle\'s Group Prayer List is ready — check the Prayer tab.',
                      ).catchError((_) {});
                      nav.pop();
                    } catch (_) {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MyWalkColor.charcoal))
                : const Text('Save',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
