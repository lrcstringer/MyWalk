import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/scripture_thread_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import '../kingdom_life/bible_project_browser_view.dart';

// Parses Delta JSON with plain-text fallback.
Document _documentFromString(String raw) {
  try {
    return Document.fromJson(jsonDecode(raw) as List);
  } catch (_) {
    final doc = Document();
    if (raw.isNotEmpty) doc.insert(0, raw);
    return doc;
  }
}

class ScriptureThreadDetailView extends StatefulWidget {
  final ScriptureThread thread;
  final bool isAdmin;

  const ScriptureThreadDetailView({
    super.key,
    required this.thread,
    required this.isAdmin,
  });

  @override
  State<ScriptureThreadDetailView> createState() =>
      _ScriptureThreadDetailViewState();
}

class _ScriptureThreadDetailViewState
    extends State<ScriptureThreadDetailView> {
  late final QuillController _passageCtrl;
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  // Cached to avoid context.read<>() in dispose(), which is unsafe on a
  // deactivated element.
  late final ScriptureThreadProvider _threadProvider;

  // When set, the input bar shows "Replying to [name]" and posts as a reply.
  ScriptureComment? _replyingTo;

  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _threadProvider = context.read<ScriptureThreadProvider>();
    _passageCtrl = QuillController(
      document: _documentFromString(widget.thread.passageText),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _threadProvider.watchComments(
        widget.thread.circleId,
        widget.thread.id,
      );
    });
  }

  @override
  void dispose() {
    _passageCtrl.dispose();
    _commentController.dispose();
    _commentFocus.dispose();
    _threadProvider.stopWatchingComments(widget.thread.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.shared.userId ?? '';

    return Consumer<ScriptureThreadProvider>(
      builder: (context, provider, _) {
        final allComments = provider.commentsFor(widget.thread.id);
        final tree = _buildTree(allComments);

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          appBar: AppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            title: Text(
              widget.thread.reference,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.golden),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined,
                    size: 20, color: MyWalkColor.golden),
                tooltip: 'Open in Bible',
                onPressed: () => BibleProjectBrowserView.openOrPrompt(context, reference: widget.thread.reference),
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _PassageCard(thread: widget.thread, ctrl: _passageCtrl),
                  const SizedBox(height: 20),
                  if (tree.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'No comments yet. Be the first to share.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                    )
                  else
                    ...tree.map((node) => _CommentNode(
                          node: node,
                          uid: uid,
                          isAdmin: widget.isAdmin,
                          threadOpen: widget.thread.isOpen,
                          onReply: (c) {
                            setState(() => _replyingTo = c);
                            _commentFocus.requestFocus();
                          },
                          onDelete: (c) => _deleteComment(context, c),
                        )),
                ],
              ),
            ),
            if (widget.thread.isOpen)
              _CommentInputBar(
                controller: _commentController,
                focusNode: _commentFocus,
                replyingTo: _replyingTo,
                posting: _posting,
                onCancelReply: () => setState(() => _replyingTo = null),
                onPost: () => _postComment(context),
              ),
          ]),
        );
      },
    );
  }

  List<_NodeData> _buildTree(List<ScriptureComment> all) {
    final topLevel =
        all.where((c) => c.parentId == null).toList();
    final repliesByParent = <String, List<ScriptureComment>>{};
    for (final c in all.where((c) => c.parentId != null)) {
      repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
    }
    return topLevel
        .map((c) => _NodeData(
              comment: c,
              replies: repliesByParent[c.id] ?? [],
            ))
        .toList();
  }

  Future<void> _postComment(BuildContext context) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final parentId = _replyingTo?.id;
    setState(() {
      _posting = true;
      _replyingTo = null;
    });
    _commentController.clear();
    try {
      await _threadProvider.addComment(
        circleId: widget.thread.circleId,
        threadId: widget.thread.id,
        text: text,
        parentId: parentId,
      );
    } catch (_) {
      // Restore the typed text so the user can retry.
      if (mounted) _commentController.text = text;
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _deleteComment(
      BuildContext context, ScriptureComment comment) async {
    try {
      await _threadProvider.deleteComment(
          widget.thread.circleId, widget.thread.id, comment.id);
    } catch (_) {}
  }
}

// ─── Passage card ─────────────────────────────────────────────────────────────

class _PassageCard extends StatelessWidget {
  final ScriptureThread thread;
  final QuillController ctrl;
  const _PassageCard({required this.thread, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: MyWalkColor.golden.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(thread.translation,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.golden,
                  letterSpacing: 0.8)),
          const Spacer(),
          Text('Posted by ${thread.createdByDisplayName}',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
        ]),
        const SizedBox(height: 12),
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 15,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
            height: 1.65,
            decoration: TextDecoration.none,
          ),
          child: QuillEditor.basic(
            controller: ctrl,
            config: const QuillEditorConfig(
              scrollable: false,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Comment tree node ────────────────────────────────────────────────────────

class _NodeData {
  final ScriptureComment comment;
  final List<ScriptureComment> replies;
  const _NodeData({required this.comment, required this.replies});
}

class _CommentNode extends StatelessWidget {
  final _NodeData node;
  final String uid;
  final bool isAdmin;
  final bool threadOpen;
  final void Function(ScriptureComment) onReply;
  final void Function(ScriptureComment) onDelete;

  const _CommentNode({
    required this.node,
    required this.uid,
    required this.isAdmin,
    required this.threadOpen,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CommentBubble(
          comment: node.comment,
          uid: uid,
          isAdmin: isAdmin,
          threadOpen: threadOpen,
          isReply: false,
          onReply: () => onReply(node.comment),
          onDelete: () => onDelete(node.comment),
        ),
        ...node.replies.map((r) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 6),
              child: _CommentBubble(
                comment: r,
                uid: uid,
                isAdmin: isAdmin,
                threadOpen: threadOpen,
                isReply: true,
                onReply: () => onReply(node.comment), // replies always target top-level
                onDelete: () => onDelete(r),
              ),
            )),
      ]),
    );
  }
}

// ─── Comment bubble ───────────────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  final ScriptureComment comment;
  final String uid;
  final bool isAdmin;
  final bool threadOpen;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentBubble({
    required this.comment,
    required this.uid,
    required this.isAdmin,
    required this.threadOpen,
    required this.isReply,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = comment.isAuthor(uid);
    final canDelete = isMe || isAdmin;

    if (comment.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '[comment deleted]',
          style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.25),
              fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: isReply
            ? MyWalkColor.inputBackground
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isReply
            ? Border(
                left: BorderSide(
                    color: MyWalkColor.golden.withValues(alpha: 0.3), width: 2))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            isMe ? 'You' : comment.authorDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMe ? MyWalkColor.golden : MyWalkColor.softGold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _relativeTime(comment.createdAt),
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const Spacer(),
          if (canDelete)
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
          if (threadOpen && !isReply) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onReply,
              child: Text('Reply',
                  style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.golden.withValues(alpha: 0.7))),
            ),
          ],
        ]),
        const SizedBox(height: 5),
        Text(
          comment.text,
          style: TextStyle(
              fontSize: 14,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.88),
              height: 1.45),
        ),
      ]),
    );
  }

  String _relativeTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Comment input bar ────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScriptureComment? replyingTo;
  final bool posting;
  final VoidCallback onCancelReply;
  final VoidCallback onPost;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.replyingTo,
    required this.posting,
    required this.onCancelReply,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        border: Border(
            top: BorderSide(
                color: MyWalkColor.golden.withValues(alpha: 0.1))),
      ),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (replyingTo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.reply_rounded,
                  size: 14,
                  color: MyWalkColor.golden.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Replying to ${replyingTo!.authorDisplayName}',
                  style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.golden.withValues(alpha: 0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onCancelReply,
                child: Icon(Icons.close_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
            ]),
          ),
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: replyingTo != null ? 'Write a reply…' : 'Write a comment…',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14),
                filled: true,
                fillColor: MyWalkColor.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: posting ? null : onPost,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: MyWalkColor.golden,
                shape: BoxShape.circle,
              ),
              child: posting
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MyWalkColor.charcoal),
                    )
                  : const Icon(Icons.send_rounded,
                      size: 18, color: MyWalkColor.charcoal),
            ),
          ),
        ]),
      ]),
    );
  }
}
