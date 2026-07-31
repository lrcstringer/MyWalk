import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../providers/scripture_thread_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import '../bible/bible_browser_view.dart';
import '../journal/journal_entry_composer.dart';
import 'scripture_thread_detail_view.dart';

class ScriptureThreadsTab extends StatefulWidget {
  final String circleId;
  final CircleSettings settings;
  final bool isAdmin;

  const ScriptureThreadsTab({
    super.key,
    required this.circleId,
    required this.settings,
    required this.isAdmin,
  });

  @override
  State<ScriptureThreadsTab> createState() => _ScriptureThreadsTabState();
}

class _ScriptureThreadsTabState extends State<ScriptureThreadsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScriptureThreadProvider>().watchThreads(
            widget.circleId,
            isAdmin: widget.isAdmin,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = widget.settings.scriptureFocusPermission == 'any_member' ||
        widget.isAdmin;

    return Consumer<ScriptureThreadProvider>(
      builder: (context, provider, _) {
        final threads = provider.threadsFor(widget.circleId);
        final isLoading = provider.isLoadingThreads(widget.circleId);

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: canCreate
              ? FloatingActionButton.small(
                  onPressed: () => _showCreateSheet(context),
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  tooltip: 'Start a Thread',
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: MyWalkColor.golden))
              : threads.isEmpty
              ? _emptyState()
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionHeader('THREADS'),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: threads.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ThreadCard(
                        thread: threads[i],
                        isAdmin: widget.isAdmin,
                        onTap: () => _openThread(context, threads[i]),
                        onClose: () => _confirmClose(context, threads[i]),
                        onDelete: () => _confirmDelete(context, threads[i]),
                      ),
                    ),
                  ),
                ]),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: MyWalkColor.golden, letterSpacing: 1.2)),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.menu_book_rounded,
            size: 40, color: MyWalkColor.golden.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text('No threads yet.',
            style: TextStyle(
                fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text('Tap + to start a scripture discussion.',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }

  void _openThread(BuildContext context, ScriptureThread thread) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ScriptureThreadDetailView(
          thread: thread,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CreateThreadSheet(circleId: widget.circleId, isAdmin: widget.isAdmin),
    );
  }

  Future<void> _confirmClose(
      BuildContext context, ScriptureThread thread) async {
    final provider = context.read<ScriptureThreadProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Close Thread',
            style: TextStyle(color: MyWalkColor.warmWhite)),
        content: Text(
            'Members will no longer see "${thread.reference}". You can delete it afterwards.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: MyWalkColor.softGold))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Close Thread',
                  style: TextStyle(color: MyWalkColor.warmCoral))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await provider.closeThread(widget.circleId, thread.id);
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: MyWalkColor.cardBackground));
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, ScriptureThread thread) async {
    final provider = context.read<ScriptureThreadProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Delete Thread',
            style: TextStyle(color: MyWalkColor.warmWhite)),
        content: Text(
            'Permanently delete "${thread.reference}" and all its comments?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: MyWalkColor.softGold))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: MyWalkColor.warmCoral))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await provider.deleteThread(widget.circleId, thread.id);
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: MyWalkColor.cardBackground));
      }
    }
  }
}

// ─── Thread Card ──────────────────────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final ScriptureThread thread;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _ThreadCard({
    required this.thread,
    required this.isAdmin,
    required this.onTap,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = !thread.isOpen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: MyWalkColor.golden,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
        margin: const EdgeInsets.only(left: 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isClosed
              ? MyWalkColor.cardBackground.withValues(alpha: 0.5)
              : MyWalkColor.cardBackground,
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          border: Border.all(
            color: MyWalkColor.cardBorder,
            width: 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            MyWalkAvatar(name: thread.createdByDisplayName, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(thread.createdByDisplayName,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isClosed
                      ? Colors.white.withValues(alpha: 0.45)
                      : MyWalkColor.softGold,
                )),
            ),
            Text(_relativeTime(thread.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            if (!isClosed && isAdmin) ...[
              const SizedBox(width: 4),
              PopupMenuButton<_ThreadAction>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: Colors.white.withValues(alpha: 0.4)),
                color: MyWalkColor.cardBackground,
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  if (action == _ThreadAction.close) onClose();
                  if (action == _ThreadAction.delete) onDelete();
                },
                itemBuilder: (_) => [
                  _menuItem(_ThreadAction.close, Icons.lock_outline_rounded, 'Close Thread'),
                  _menuItem(_ThreadAction.delete, Icons.delete_outline_rounded, 'Delete Thread',
                      color: MyWalkColor.warmCoral),
                ],
              ),
            ],
            if (isClosed && isAdmin) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: MyWalkColor.warmCoral.withValues(alpha: 0.7)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Thread',
                onPressed: onDelete,
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.menu_book_rounded,
                size: 13,
                color: isClosed ? Colors.white.withValues(alpha: 0.3) : MyWalkColor.golden),
            const SizedBox(width: 6),
            Expanded(
              child: Text(thread.reference,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isClosed ? Colors.white.withValues(alpha: 0.35) : MyWalkColor.golden,
                )),
            ),
            if (isClosed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Closed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.35))),
              ),
          ]),
          const SizedBox(height: 6),
          Text(
            _passagePreview(thread.passageText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isClosed
                  ? Colors.white.withValues(alpha: 0.3)
                  : MyWalkColor.warmWhite.withValues(alpha: 0.88),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 12,
                color: isClosed
                    ? Colors.white.withValues(alpha: 0.25)
                    : MyWalkColor.golden.withValues(alpha: 0.65)),
            const SizedBox(width: 4),
            Text(
              isClosed
                  ? '${thread.commentCount} ${thread.commentCount == 1 ? "comment" : "comments"}'
                  : thread.commentCount == 0
                      ? 'Be the first to comment'
                      : '${thread.commentCount} ${thread.commentCount == 1 ? "comment" : "comments"}',
              style: TextStyle(
                  fontSize: 12,
                  color: isClosed
                      ? Colors.white.withValues(alpha: 0.25)
                      : MyWalkColor.golden.withValues(alpha: 0.75)),
            ),
            const Spacer(),
            Text(thread.translation,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11,
                color: isClosed
                    ? Colors.white.withValues(alpha: 0.2)
                    : MyWalkColor.golden.withValues(alpha: 0.5)),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push<void>(context, MaterialPageRoute(
              builder: (_) => JournalEntryComposer(
                habitName: thread.reference,
                sourceType: 'group_scripture',
                chipIcon: Icons.groups_rounded,
              ),
            )),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit_note, size: 14,
                  color: MyWalkColor.softGold.withValues(alpha: isClosed ? 0.35 : 0.65)),
              const SizedBox(width: 4),
              Text('Create journal entry',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: MyWalkColor.softGold.withValues(alpha: isClosed ? 0.35 : 0.65))),
            ]),
          ),
        ]),
        ),
      ),
    );
  }

  PopupMenuItem<_ThreadAction> _menuItem(_ThreadAction action, IconData icon,
      String label,
      {Color? color}) {
    return PopupMenuItem(
      value: action,
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? MyWalkColor.softGold),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color ?? MyWalkColor.warmWhite, fontSize: 14)),
      ]),
    );
  }

  /// Extract plain text preview from stored Delta JSON (or raw string fallback).
  String _passagePreview(String raw) {
    try {
      final doc = Document.fromJson(jsonDecode(raw) as List);
      return doc.toPlainText().trim();
    } catch (_) {
      return raw;
    }
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
}

enum _ThreadAction { close, delete }

// ─── Create Thread Sheet ──────────────────────────────────────────────────────

class CreateThreadSheet extends StatefulWidget {
  final String circleId;
  final bool isAdmin;
  const CreateThreadSheet({super.key, required this.circleId, this.isAdmin = false});

  @override
  State<CreateThreadSheet> createState() => _CreateThreadSheetState();
}

class _CreateThreadSheetState extends State<CreateThreadSheet> {
  final _refController = TextEditingController();
  late final QuillController _textController;
  final _textFocusNode = FocusNode();
  final _messageController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = QuillController.basic();
  }

  @override
  void dispose() {
    _refController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('New Scripture Thread',
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
          child: SizedBox(height: 1, child: ColoredBox(color: MyWalkColor.golden)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Reference'),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _refController,
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, fontSize: 14),
                decoration: _inputDec('e.g. John 3:16'),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _browseBible,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.menu_book_outlined,
                      size: 14, color: MyWalkColor.golden),
                  SizedBox(width: 4),
                  Text('Browse',
                      style: TextStyle(
                          fontSize: 13, color: MyWalkColor.golden)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _label('Passage Text (WEB)'),
          const SizedBox(height: 6),
          _QuillField(
            controller: _textController,
            focusNode: _textFocusNode,
            placeholder: 'Paste or type the passage text…',
            minHeight: 120,
          ),
          const SizedBox(height: 14),
          _label('Your Message (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            maxLines: 4,
            minLines: 3,
            decoration: _inputDec('Add a message or reflection…'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Post Thread',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.inputBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  void _browseBible() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BibleBrowserView(
          onVerseSelected: (verse) {
            if (!mounted) return;
            setState(() => _refController.text = verse.reference);
            _textController.replaceText(
              0,
              _textController.document.length - 1,
              verse.text,
              null,
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final ref = _refController.text.trim();
    final textPlain = _textController.document.toPlainText().trim();
    if (ref.isEmpty) {
      setState(() => _error = 'Reference required.');
      return;
    }
    if (textPlain.isEmpty) {
      setState(() => _error = 'Passage text required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final passageJson =
        jsonEncode(_textController.document.toDelta().toJson());
    try {
      final msg = _messageController.text.trim();
      await context.read<ScriptureThreadProvider>().createThread(
            circleId: widget.circleId,
            reference: ref,
            passageText: passageJson,
            translation: 'WEB',
            message: msg.isEmpty ? null : msg,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _submitting = false;
        });
      }
    }
  }
}

// ─── Shared Quill field (same config as scripture_focus_tab) ──────────────────

class _QuillField extends StatelessWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final String placeholder;
  final double minHeight;

  const _QuillField({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: QuillSimpleToolbar(
            controller: controller,
            config: QuillSimpleToolbarConfig(
              color: Colors.transparent,
              multiRowsDisplay: false,
              showDividers: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: false,
              showSmallButton: false,
              showFontFamily: false,
              showFontSize: false,
              showAlignmentButtons: false,
              showLeftAlignment: false,
              showCenterAlignment: false,
              showRightAlignment: false,
              showJustifyAlignment: false,
              showHeaderStyle: false,
              showListNumbers: false,
              showListBullets: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showUndo: true,
              showRedo: true,
              showDirection: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              iconTheme: QuillIconTheme(
                iconButtonUnselectedData: IconButtonData(
                  color: Colors.white.withValues(alpha: 0.5),
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
        ),
        DefaultTextStyle(
          style: const TextStyle(
            color: MyWalkColor.warmWhite,
            fontSize: 14,
            height: 1.55,
            decoration: TextDecoration.none,
          ),
          child: QuillEditor.basic(
            controller: controller,
            focusNode: focusNode,
            config: QuillEditorConfig(
              placeholder: placeholder,
              minHeight: minHeight,
              scrollable: false,
              padding: const EdgeInsets.all(12),
              customStyles: DefaultStyles(
                placeHolder: DefaultTextBlockStyle(
                  TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                    decoration: TextDecoration.none,
                  ),
                  const HorizontalSpacing(0, 0),
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
