import 'package:flutter/material.dart';
import '../../../../data/datasources/remote/auth_service.dart';
import '../../../../data/datasources/local/bible_database.dart';
import '../../../../data/services/chunking_service.dart';
import '../../../../domain/entities/bible_entities.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';
import 'chunk_review_screen.dart';

class MemorizationInputScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialText;

  const MemorizationInputScreen({super.key, this.initialTitle, this.initialText});

  @override
  State<MemorizationInputScreen> createState() => _MemorizationInputScreenState();
}

class _MemorizationInputScreenState extends State<MemorizationInputScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _textCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isChunking = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _textCtrl = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Add verse or passage'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: _isChunking ? _ChunkingLoader() : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bible verse picker ──────────────────────────────────────────
            _BibleVersePicker(
              onInsert: (title, text) {
                _titleCtrl.text = title;
                _textCtrl.text = text;
              },
            ),
            const SizedBox(height: 24),
            // ── Manual title ────────────────────────────────────────────────
            _SectionLabel('Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: MyWalkColor.warmWhite),
              decoration: _inputDecoration('e.g. John 3:16'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Text to memorize'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textCtrl,
              style: const TextStyle(color: MyWalkColor.warmWhite, height: 1.6),
              decoration: _inputDecoration(
                'Paste or type the verse or passage…',
              ),
              maxLines: 8,
              minLines: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Text is required';
                if (v.trim().split(RegExp(r'\s+')).length < 3) {
                  return 'Please enter at least a few words';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'AI will suggest how to break this into memorizable phrases.',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: MyWalkButtonStyle.primary(),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Suggest chunks'),
                onPressed: _onSuggestChunks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSuggestChunks() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();

    setState(() => _isChunking = true);

    final chunks = await ChunkingService.instance.chunkText(text);

    if (!mounted) return;

    setState(() => _isChunking = false);

    final uid = AuthService.shared.userId;
    if (uid == null) return;

    final item = MemorizationItem.create(
      userId: uid,
      title: title,
      fullText: text,
      chunks: chunks,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChunkReviewScreen(item: item),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
        filled: true,
        fillColor: MyWalkColor.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MyWalkColor.golden, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ── Bible verse picker ────────────────────────────────────────────────────────
//
// Collapsible panel: Book → Chapter → Verse from → Verse to → Add button.
// Queries the local WEB SQLite database — no network needed.

class _BibleVersePicker extends StatefulWidget {
  final void Function(String title, String text) onInsert;

  const _BibleVersePicker({required this.onInsert});

  @override
  State<_BibleVersePicker> createState() => _BibleVersePickerState();
}

class _BibleVersePickerState extends State<_BibleVersePicker> {
  bool _expanded = false;

  BibleBook _book = BibleBook.all[42]; // John (book 43, index 42)
  int _chapter = 3;
  int _verseFrom = 16;
  int _verseTo = 16;
  int _verseCount = 0; // loaded after chapter selection

  bool _loading = false;
  bool _loadingVerses = true; // true until first _loadVerseCount() completes
  int _loadGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVerseCount();
  }

  Future<void> _loadVerseCount() async {
    final gen = ++_loadGeneration;
    try {
      final count = await BibleDatabase.instance
          .queryVerseCount(_book.bookNum, _chapter);
      if (mounted && gen == _loadGeneration) {
        setState(() {
          _verseCount = count;
          _verseFrom = _verseFrom.clamp(1, count.clamp(1, 9999));
          _verseTo = _verseTo.clamp(_verseFrom, count.clamp(1, 9999));
          _loadingVerses = false;
        });
      }
    } catch (_) {
      if (mounted && gen == _loadGeneration) {
        setState(() { _loadingVerses = false; });
      }
    }
  }

  Future<void> _onBookChanged(BibleBook book) async {
    setState(() {
      _book = book;
      _chapter = 1;
      _verseFrom = 1;
      _verseTo = 1;
      _verseCount = 0;
      _loadingVerses = true;
    });
    await _loadVerseCount();
  }

  Future<void> _onChapterChanged(int chapter) async {
    setState(() {
      _chapter = chapter;
      _verseFrom = 1;
      _verseTo = 1;
      _verseCount = 0;
      _loadingVerses = true;
    });
    await _loadVerseCount();
  }

  Future<void> _onAdd() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await BibleDatabase.instance
          .queryChapter(_book.bookNum, _chapter);

      final selected = rows
          .where((r) {
            final vn = r['verse_num'] as int;
            return vn >= _verseFrom && vn <= _verseTo;
          })
          .map((r) => (r['text'] as String).trim())
          .toList();

      if (selected.isEmpty) {
        setState(() {
          _error = 'No verses found for that selection.';
          _loading = false;
        });
        return;
      }

      final text = selected.join(' ');
      final title = _verseTo == _verseFrom
          ? '${_book.name} $_chapter:$_verseFrom'
          : '${_book.name} $_chapter:$_verseFrom–$_verseTo';

      widget.onInsert(title, text);

      if (mounted) {
        setState(() {
          _loading = false;
          _expanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load verses. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: _expanded ? 0.35 : 0.15)),
      ),
      child: Column(
        children: [
          // Header / toggle
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: MyWalkColor.golden, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pick from Bible',
                      style: TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded picker body
          if (_expanded) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book selector
                  _PickerLabel('Book'),
                  const SizedBox(height: 6),
                  _BookDropdown(
                    selected: _book,
                    onChanged: _onBookChanged,
                  ),
                  const SizedBox(height: 14),

                  // Chapter selector
                  _PickerLabel('Chapter'),
                  const SizedBox(height: 6),
                  _NumberDropdown(
                    value: _chapter,
                    min: 1,
                    max: _book.chapterCount,
                    onChanged: _onChapterChanged,
                  ),
                  const SizedBox(height: 14),

                  // Verse from / to
                  if (_loadingVerses) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: MyWalkColor.golden),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_verseCount > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PickerLabel('From verse'),
                              const SizedBox(height: 6),
                              _NumberDropdown(
                                value: _verseFrom,
                                min: 1,
                                max: _verseCount,
                                onChanged: (v) => setState(() {
                                  _verseFrom = v;
                                  if (_verseTo < v) _verseTo = v;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PickerLabel('To verse'),
                              const SizedBox(height: 6),
                              _NumberDropdown(
                                value: _verseTo,
                                min: _verseFrom,
                                max: _verseCount,
                                onChanged: (v) =>
                                    setState(() => _verseTo = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade400, fontSize: 12),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyWalkColor.golden,
                        foregroundColor: MyWalkColor.charcoal,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed:
                          _loading || _loadingVerses || _verseCount == 0 ? null : _onAdd,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MyWalkColor.charcoal),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: const Text('Add verses',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Book dropdown ─────────────────────────────────────────────────────────────

class _BookDropdown extends StatefulWidget {
  final BibleBook selected;
  final void Function(BibleBook) onChanged;

  const _BookDropdown({required this.selected, required this.onChanged});

  @override
  State<_BookDropdown> createState() => _BookDropdownState();
}

class _BookDropdownState extends State<_BookDropdown> {
  final _searchCtrl = TextEditingController();
  List<BibleBook> _filtered = BibleBook.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? BibleBook.all
          : BibleBook.all
              .where((b) => b.name.toLowerCase().contains(lower))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MyWalkColor.charcoal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selected.name,
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, fontSize: 14),
              ),
            ),
            Icon(Icons.expand_more,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                size: 18),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    _searchCtrl.clear();
    _filtered = BibleBook.all;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                        color: MyWalkColor.warmWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search books…',
                      hintStyle: TextStyle(
                          color: MyWalkColor.warmWhite
                              .withValues(alpha: 0.35),
                          fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                          size: 18),
                      filled: true,
                      fillColor: MyWalkColor.charcoal,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (q) {
                      _onSearch(q);
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final book = _filtered[i];
                      final isSelected =
                          book.bookNum == widget.selected.bookNum;
                      return ListTile(
                        dense: true,
                        title: Text(
                          book.name,
                          style: TextStyle(
                            color: isSelected
                                ? MyWalkColor.golden
                                : MyWalkColor.warmWhite,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: MyWalkColor.golden, size: 16)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onChanged(book);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Number dropdown (chapter / verse) ────────────────────────────────────────

class _NumberDropdown extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _NumberDropdown({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  void _showSheet(BuildContext context) {
    const double itemHeight = 40.0;
    final initialOffset =
        ((value - min) * itemHeight - 80).clamp(0.0, double.infinity);
    final scrollCtrl = ScrollController(initialScrollOffset: initialOffset);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: max - min + 1,
                itemExtent: itemHeight,
                itemBuilder: (ctx, i) {
                  final num = min + i;
                  final isSelected = num == value;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '$num',
                      style: TextStyle(
                        color: isSelected
                            ? MyWalkColor.golden
                            : MyWalkColor.warmWhite,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check,
                            color: MyWalkColor.golden, size: 16)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onChanged(num);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MyWalkColor.charcoal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$value',
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, fontSize: 14),
              ),
            ),
            Icon(Icons.expand_more,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _PickerLabel extends StatelessWidget {
  final String label;
  const _PickerLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
        fontSize: 11,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: MyWalkColor.warmWhite,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ChunkingLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: MyWalkColor.golden),
            const SizedBox(height: 24),
            Text(
              'Breaking into memorizable phrases…',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
