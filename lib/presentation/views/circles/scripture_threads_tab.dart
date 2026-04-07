import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../providers/scripture_thread_provider.dart';
import '../../providers/circle_notification_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import '../bible/bible_browser_view.dart';
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.menu_book_rounded,
              size: 40, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('No threads yet.',
              style: TextStyle(
                  fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Text('Tap + to start a scripture discussion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
        ]),
      ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isClosed
              ? MyWalkColor.cardBackground.withValues(alpha: 0.5)
              : MyWalkColor.golden.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClosed
                ? Colors.white.withValues(alpha: 0.08)
                : MyWalkColor.golden.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.menu_book_rounded,
                size: 13,
                color: isClosed
                    ? Colors.white.withValues(alpha: 0.3)
                    : MyWalkColor.golden),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                thread.reference,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isClosed
                      ? Colors.white.withValues(alpha: 0.35)
                      : MyWalkColor.golden,
                ),
              ),
            ),
            if (isClosed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Closed',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.35))),
              )
            else if (isAdmin)
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
                  _menuItem(_ThreadAction.close, Icons.lock_outline_rounded,
                      'Close Thread'),
                  _menuItem(_ThreadAction.delete, Icons.delete_outline_rounded,
                      'Delete Thread',
                      color: MyWalkColor.warmCoral),
                ],
              ),
            if (isClosed && isAdmin)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: MyWalkColor.warmCoral.withValues(alpha: 0.7)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Thread',
                onPressed: onDelete,
              ),
          ]),
          const SizedBox(height: 8),
          Text(
            _passagePreview(thread.passageText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isClosed
                  ? Colors.white.withValues(alpha: 0.3)
                  : MyWalkColor.warmWhite.withValues(alpha: 0.75),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 12, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text('${thread.commentCount}',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
            const Spacer(),
            Text('${thread.translation}  •  ${thread.createdByDisplayName}',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
          ]),
        ]),
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
  bool _notifyMembers = false;
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
                : const Text('Post',
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
          if (widget.isAdmin) ...[
            const SizedBox(height: 14),
            _notifyRow(),
          ],
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
    final notifProvider = _notifyMembers && widget.isAdmin
        ? context.read<CircleNotificationProvider>()
        : null;
    final passageJson =
        jsonEncode(_textController.document.toDelta().toJson());
    try {
      await context.read<ScriptureThreadProvider>().createThread(
            circleId: widget.circleId,
            reference: ref,
            passageText: passageJson,
            translation: 'WEB',
          );
      notifProvider?.sendAnnouncement(
        circleId: widget.circleId,
        message: 'New scripture thread: $ref — join the discussion.',
      ).catchError((_) {});
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
