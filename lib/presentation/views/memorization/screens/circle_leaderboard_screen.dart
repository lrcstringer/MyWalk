import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../data/datasources/remote/auth_service.dart';
import '../../../../domain/entities/memorization_circle.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';

class CircleLeaderboardScreen extends StatefulWidget {
  final MemorizationCircle circle;

  const CircleLeaderboardScreen({super.key, required this.circle});

  @override
  State<CircleLeaderboardScreen> createState() =>
      _CircleLeaderboardScreenState();
}

class _CircleLeaderboardScreenState extends State<CircleLeaderboardScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _posting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(widget.circle.name),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Invite members',
            onPressed: () => _showInviteSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PassageCard(circle: widget.circle),
                      const SizedBox(height: 20),
                      _Leaderboard(circle: widget.circle),
                      const SizedBox(height: 24),
                      _CommentSection(circleId: widget.circle.id),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          _CommentInput(
            controller: _commentCtrl,
            posting: _posting,
            onPost: _postComment,
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await context.read<MemorizationProvider>().addCircleComment(
            circleId: widget.circle.id,
            text: text,
          );
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showInviteSheet(BuildContext context) {
    final inviteCode = widget.circle.id.substring(0, 8).toUpperCase();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add_outlined,
                size: 40, color: MyWalkColor.golden),
            const SizedBox(height: 16),
            Text(
              'Invite to ${widget.circle.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: MyWalkColor.warmWhite,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with friends:',
              style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: MyWalkColor.golden.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        color: MyWalkColor.golden,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.copy_outlined,
                        color: MyWalkColor.golden.withValues(alpha: 0.6),
                        size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to copy',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Passage card
// ---------------------------------------------------------------------------

class _PassageCard extends StatelessWidget {
  final MemorizationCircle circle;
  const _PassageCard({required this.circle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  size: 16, color: MyWalkColor.golden),
              const SizedBox(width: 8),
              Text(
                circle.itemTitle,
                style: const TextStyle(
                  color: MyWalkColor.golden,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (circle.targetDate != null) ...[
                const Spacer(),
                Text(
                  _daysLabel(circle.targetDate!),
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            circle.itemText,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.7,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _daysLabel(DateTime target) {
    final diff = target.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Goal passed';
    if (diff == 0) return 'Goal: today!';
    return '$diff days to goal';
  }
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

class _Leaderboard extends StatelessWidget {
  final MemorizationCircle circle;
  const _Leaderboard({required this.circle});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.shared.userId ?? '';

    // Sort members by mastery desc.
    final ranked = circle.memberIds.map((memberId) {
      final mastery = circle.memberMastery[memberId] ?? 0.0;
      return _RankedMember(uid: memberId, mastery: mastery, isMe: memberId == uid);
    }).toList()
      ..sort((a, b) => b.mastery.compareTo(a.mastery));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Leaderboard',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '${circle.memberIds.length} member${circle.memberIds.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...ranked.asMap().entries.map(
              (e) => _LeaderboardTile(
                rank: e.key + 1,
                member: e.value,
                onMasteryUpdate: e.value.isMe
                    ? () => _updateMyMastery(context, uid)
                    : null,
              ),
            ),
      ],
    );
  }

  Future<void> _updateMyMastery(BuildContext context, String uid) async {
    final provider = context.read<MemorizationProvider>();
    final items = provider.items;
    if (items.isEmpty) return;

    final totalAttempts =
        items.fold<int>(0, (s, i) => s + i.totalAttempts);
    final totalSuccess =
        items.fold<int>(0, (s, i) => s + i.successfulAttempts);
    final mastery =
        totalAttempts == 0 ? 0.0 : totalSuccess / totalAttempts * 100;

    await provider.updateMemberMastery(
      circleId: circle.id,
      uid: uid,
      masteryPercent: mastery,
    );
  }
}

class _RankedMember {
  final String uid;
  final double mastery;
  final bool isMe;
  const _RankedMember({required this.uid, required this.mastery, required this.isMe});
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final _RankedMember member;
  final VoidCallback? onMasteryUpdate;

  const _LeaderboardTile({
    required this.rank,
    required this.member,
    this.onMasteryUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? MyWalkColor.golden
        : rank == 2
            ? Colors.grey.shade400
            : rank == 3
                ? const Color(0xFFCD7F32) // bronze
                : MyWalkColor.warmWhite.withValues(alpha: 0.3);

    final mastery = member.mastery;
    final barColor = mastery >= 80
        ? const Color(0xFF7A9E7E)
        : mastery >= 50
            ? MyWalkColor.golden
            : const Color(0xFFD4836B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: member.isMe
            ? MyWalkColor.golden.withValues(alpha: 0.05)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: member.isMe
            ? Border.all(color: MyWalkColor.golden.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank <= 3 ? _medal(rank) : '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w700,
                fontSize: rank <= 3 ? 18 : 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.isMe ? 'You' : _shortId(member.uid),
                      style: TextStyle(
                        color: member.isMe
                            ? MyWalkColor.golden
                            : MyWalkColor.warmWhite,
                        fontWeight: member.isMe
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (member.isMe && onMasteryUpdate != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onMasteryUpdate,
                        child: Icon(
                          Icons.refresh,
                          size: 14,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: mastery / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${mastery.toInt()}%',
            style: TextStyle(
              color: member.isMe ? MyWalkColor.golden : MyWalkColor.warmWhite,
              fontWeight:
                  member.isMe ? FontWeight.w700 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) =>
      rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

  // Show first 6 chars of uid as an anonymous handle.
  String _shortId(String uid) => 'Member ${uid.substring(0, 6).toUpperCase()}';
}

// ---------------------------------------------------------------------------
// Comment section — stream of existing comments
// ---------------------------------------------------------------------------

class _CommentSection extends StatelessWidget {
  final String circleId;
  const _CommentSection({required this.circleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CircleComment>>(
      stream: context.read<MemorizationProvider>().watchCircleComments(circleId),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Discussion',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                if (comments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Be the first to encourage your circle!',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...comments.map((c) => _CommentTile(comment: c)),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CircleComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isMe = comment.authorUid == AuthService.shared.userId;
    final handle = isMe
        ? 'You'
        : 'Member ${comment.authorUid.substring(0, 6).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? MyWalkColor.golden.withValues(alpha: 0.05)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: isMe
            ? Border.all(color: MyWalkColor.golden.withValues(alpha: 0.15))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                handle,
                style: TextStyle(
                  color: isMe ? MyWalkColor.golden : MyWalkColor.warmWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(comment.createdAt),
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.text,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

// ---------------------------------------------------------------------------
// Comment input bar — pinned at the bottom of the screen
// ---------------------------------------------------------------------------

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool posting;
  final VoidCallback onPost;

  const _CommentInput({
    required this.controller,
    required this.posting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 8, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Encourage your circle…',
                hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                    fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          posting
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: MyWalkColor.golden),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: MyWalkColor.golden, size: 22),
                  onPressed: onPost,
                ),
        ],
      ),
    );
  }
}
