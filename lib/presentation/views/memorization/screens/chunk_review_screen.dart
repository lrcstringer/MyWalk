import 'package:flutter/material.dart';
import '../../../../data/services/chunking_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../domain/utils/hint_generator.dart';
import '../../../../presentation/theme/app_theme.dart';
import 'initial_memorization_screen.dart';

class ChunkReviewScreen extends StatefulWidget {
  final MemorizationItem item;
  final void Function(MemorizationItem confirmedItem) onConfirmed;

  const ChunkReviewScreen({
    super.key,
    required this.item,
    required this.onConfirmed,
  });

  @override
  State<ChunkReviewScreen> createState() => _ChunkReviewScreenState();
}

class _ChunkReviewScreenState extends State<ChunkReviewScreen> {
  late List<TextChunk> _chunks;

  @override
  void initState() {
    super.initState();
    _chunks = List.of(widget.item.chunks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Review phrases'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        actions: [
          if (_chunks.length < kMaxChunks)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add phrase',
              onPressed: _addChunk,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Drag to reorder. Tap to edit. Swipe to delete.',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chunks.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemBuilder: (context, i) => _ChunkTile(
                key: ValueKey(_chunks[i].id),
                chunk: _chunks[i],
                index: i,
                onEdit: () => _editChunk(i),
                onDelete: _chunks.length > 1 ? () => _deleteChunk(i) : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_chunks.length >= kMaxChunks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Maximum $kMaxChunks phrases reached',
                      style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: MyWalkButtonStyle.primary(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Begin memorizing'),
                    onPressed: _onBeginMemorizing,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final chunk = _chunks.removeAt(oldIndex);
      _chunks.insert(newIndex, chunk);
      // Re-sequence
      for (var i = 0; i < _chunks.length; i++) {
        _chunks[i] = _chunks[i].copyWith(sequenceNumber: i);
      }
    });
  }

  void _deleteChunk(int index) {
    setState(() {
      _chunks.removeAt(index);
      for (var i = 0; i < _chunks.length; i++) {
        _chunks[i] = _chunks[i].copyWith(sequenceNumber: i);
      }
    });
  }

  void _addChunk() {
    _showEditDialog(null, null);
  }

  void _editChunk(int index) {
    _showEditDialog(index, _chunks[index].text);
  }

  void _showEditDialog(int? index, String? initialText) {
    final ctrl = TextEditingController(text: initialText ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: Text(
          index == null ? 'Add phrase' : 'Edit phrase',
          style: const TextStyle(color: MyWalkColor.warmWhite),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: MyWalkColor.warmWhite),
          maxLines: 3,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Enter the phrase…',
            hintStyle: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.charcoal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MyWalkColor.golden),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              setState(() {
                if (index == null) {
                  _chunks.add(TextChunk.create(
                    sequenceNumber: _chunks.length,
                    text: text,
                    hint: generateHint(text),
                  ));
                } else {
                  _chunks[index] = _chunks[index].copyWith(
                    text: text,
                    hint: generateHint(text),
                  );
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: MyWalkColor.golden)),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }

  void _onBeginMemorizing() {
    final confirmed = widget.item.copyWith(chunks: _chunks);
    widget.onConfirmed(confirmed);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InitialMemorizationScreen(item: confirmed),
      ),
    );
  }
}

class _ChunkTile extends StatelessWidget {
  final TextChunk chunk;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ChunkTile({
    super.key,
    required this.chunk,
    required this.index,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MyWalkColor.golden.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: MyWalkColor.golden,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          chunk.text,
          style: const TextStyle(color: MyWalkColor.warmWhite, height: 1.4),
        ),
        subtitle: Text(
          chunk.hint,
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: MyWalkColor.warmWhite.withValues(alpha: 0.5)),
              onPressed: onEdit,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: onDelete,
              ),
            const Icon(Icons.drag_handle,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
