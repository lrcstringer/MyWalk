import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/bible_entities.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';

class BibleProvider extends ChangeNotifier {
  final BibleRepository _bible;
  final BookmarkRepository _bookmarks;

  BibleProvider(this._bible, this._bookmarks) {
    _bible.initProgress.listen((p) {
      _initProgress = p;
      notifyListeners();
    });
    _bookmarkSub = _bookmarks.watchBookmarks().listen((list) {
      _bookmarkList = list;
      notifyListeners();
    });
  }

  // ── Init state ───────────────────────────────────────────────────────────────

  bool _isInitialising = false;
  double _initProgress = 0.0;

  bool get isReady => _bible.isReady;
  bool get isInitialising => _isInitialising;
  double get initProgress => _initProgress;

  Future<void> ensureReady() async {
    if (_bible.isReady) return;
    _isInitialising = true;
    notifyListeners();
    try {
      await _bible.init();
    } finally {
      _isInitialising = false;
      notifyListeners();
    }
    // Load Genesis 1 as the default chapter on first open.
    if (_currentChapter == null) {
      await navigateTo(1, 1);
    }
  }

  // ── Navigation state ─────────────────────────────────────────────────────────

  ChapterData? _currentChapter;
  int? _highlightVerse;
  bool _isChapterLoading = false;
  // Monotonically-increasing counter used to discard stale navigation results
  // when navigateTo is called multiple times in rapid succession.
  int _navGeneration = 0;

  ChapterData? get currentChapter => _currentChapter;
  int? get highlightVerse => _highlightVerse;
  bool get isChapterLoading => _isChapterLoading;

  BibleBook get currentBook =>
      _currentChapter?.book ?? BibleBook.all.first;

  int get currentChapterNum => _currentChapter?.chapter ?? 1;

  bool get hasPreviousChapter =>
      currentBook.bookNum > 1 || currentChapterNum > 1;

  bool get hasNextChapter {
    final book = currentBook;
    return book.bookNum < 66 ||
        currentChapterNum < book.chapterCount;
  }

  Future<void> navigateTo(int bookNum, int chapter,
      {int? highlightVerse}) async {
    if (!_bible.isReady) await ensureReady();
    final generation = ++_navGeneration;
    _isChapterLoading = true;
    _highlightVerse = highlightVerse;
    notifyListeners();
    try {
      final data = await _bible.getChapter(bookNum, chapter);
      // Discard result if a newer navigation was started while we were loading.
      if (generation != _navGeneration) return;
      _currentChapter = data;
    } finally {
      if (generation == _navGeneration) {
        _isChapterLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> nextChapter() async {
    final book = currentBook;
    final ch = currentChapterNum;
    if (ch < book.chapterCount) {
      await navigateTo(book.bookNum, ch + 1);
    } else if (book.bookNum < 66) {
      await navigateTo(book.bookNum + 1, 1);
    }
  }

  Future<void> previousChapter() async {
    final book = currentBook;
    final ch = currentChapterNum;
    if (ch > 1) {
      await navigateTo(book.bookNum, ch - 1);
    } else if (book.bookNum > 1) {
      final prevBook = BibleBook.byNum(book.bookNum - 1)!;
      await navigateTo(prevBook.bookNum, prevBook.chapterCount);
    }
  }

  void clearHighlight() {
    _highlightVerse = null;
    notifyListeners();
  }

  // ── Reference parser ─────────────────────────────────────────────────────────

  /// Opens a chapter from a human-readable reference like "John 3:16" or
  /// "1 Corinthians 6:19".  Silently no-ops if the reference cannot be parsed.
  Future<void> openByReference(String reference) async {
    final parsed = _parseReference(reference);
    if (parsed == null) return;
    await navigateTo(parsed.$1, parsed.$2, highlightVerse: parsed.$3);
  }

  (int, int, int?)? _parseReference(String ref) {
    final trimmed = ref.trim();
    // Match "Book chapter:verse" — book name may contain spaces and numbers
    // (e.g. "1 Corinthians 6:19", "Song of Songs 3:1").
    // The regex captures (chapter):(verse); everything before the match is the
    // book name, cvMatch.group(1) is the chapter, group(2) is the verse.
    final cvMatch = RegExp(r'(\d+):(\d+)').firstMatch(trimmed);
    if (cvMatch == null) {
      // Try "Book chapter" with no verse (e.g. "John 3").
      final chMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(trimmed);
      if (chMatch == null) return null;
      final bookNum = _resolveBookName(chMatch.group(1)!.trim());
      final chapter = int.tryParse(chMatch.group(2)!);
      if (bookNum == null || chapter == null) return null;
      return (bookNum, chapter, null);
    }

    // Everything before the chapter digit is the book name.
    final bookName = trimmed.substring(0, cvMatch.start).trim();
    final chapter = int.tryParse(cvMatch.group(1)!);
    final verse = int.tryParse(cvMatch.group(2)!);
    if (chapter == null) return null;
    final bookNum = _resolveBookName(bookName);
    if (bookNum == null) return null;
    return (bookNum, chapter, verse);
  }

  int? _resolveBookName(String name) {
    final lower = name.toLowerCase().trim();
    return _bookNameMap[lower];
  }

  static const _bookNameMap = <String, int>{
    // Genesis
    'genesis': 1, 'gen': 1, 'gn': 1,
    // Exodus
    'exodus': 2, 'exo': 2, 'ex': 2,
    // Leviticus
    'leviticus': 3, 'lev': 3, 'lv': 3,
    // Numbers
    'numbers': 4, 'num': 4, 'nm': 4,
    // Deuteronomy
    'deuteronomy': 5, 'deut': 5, 'deu': 5, 'dt': 5,
    // Joshua
    'joshua': 6, 'josh': 6, 'jos': 6,
    // Judges
    'judges': 7, 'judg': 7, 'jdg': 7,
    // Ruth
    'ruth': 8, 'rut': 8,
    // 1 Samuel
    '1 samuel': 9, '1 sam': 9, '1sa': 9, '1sam': 9,
    // 2 Samuel
    '2 samuel': 10, '2 sam': 10, '2sa': 10, '2sam': 10,
    // 1 Kings
    '1 kings': 11, '1 kgs': 11, '1ki': 11, '1kgs': 11,
    // 2 Kings
    '2 kings': 12, '2 kgs': 12, '2ki': 12, '2kgs': 12,
    // 1 Chronicles
    '1 chronicles': 13, '1 chr': 13, '1ch': 13, '1chr': 13,
    // 2 Chronicles
    '2 chronicles': 14, '2 chr': 14, '2ch': 14, '2chr': 14,
    // Ezra
    'ezra': 15, 'ezr': 15,
    // Nehemiah
    'nehemiah': 16, 'neh': 16,
    // Esther
    'esther': 17, 'est': 17,
    // Job
    'job': 18, 'jb': 18,
    // Psalms
    'psalms': 19, 'psalm': 19, 'ps': 19, 'psa': 19,
    // Proverbs
    'proverbs': 20, 'prov': 20, 'pro': 20, 'prv': 20,
    // Ecclesiastes
    'ecclesiastes': 21, 'eccl': 21, 'ecc': 21, 'qoh': 21,
    // Song of Songs
    'song of songs': 22, 'song of solomon': 22, 'song': 22,
    'sos': 22, 'sng': 22, 'ss': 22,
    // Isaiah
    'isaiah': 23, 'isa': 23,
    // Jeremiah
    'jeremiah': 24, 'jer': 24,
    // Lamentations
    'lamentations': 25, 'lam': 25,
    // Ezekiel
    'ezekiel': 26, 'ezek': 26, 'ezk': 26,
    // Daniel
    'daniel': 27, 'dan': 27,
    // Hosea
    'hosea': 28, 'hos': 28,
    // Joel
    'joel': 29, 'jol': 29,
    // Amos
    'amos': 30, 'amo': 30,
    // Obadiah
    'obadiah': 31, 'obad': 31, 'oba': 31,
    // Jonah
    'jonah': 32, 'jon': 32,
    // Micah
    'micah': 33, 'mic': 33,
    // Nahum
    'nahum': 34, 'nah': 34, 'nam': 34,
    // Habakkuk
    'habakkuk': 35, 'hab': 35,
    // Zephaniah
    'zephaniah': 36, 'zeph': 36, 'zep': 36,
    // Haggai
    'haggai': 37, 'hag': 37,
    // Zechariah
    'zechariah': 38, 'zech': 38, 'zec': 38,
    // Malachi
    'malachi': 39, 'mal': 39,
    // Matthew
    'matthew': 40, 'matt': 40, 'mat': 40, 'mt': 40,
    // Mark
    'mark': 41, 'mrk': 41, 'mk': 41,
    // Luke
    'luke': 42, 'luk': 42, 'lk': 42,
    // John
    'john': 43, 'jhn': 43, 'jn': 43,
    // Acts
    'acts': 44, 'act': 44,
    // Romans
    'romans': 45, 'rom': 45,
    // 1 Corinthians
    '1 corinthians': 46, '1 cor': 46, '1co': 46, '1cor': 46,
    // 2 Corinthians
    '2 corinthians': 47, '2 cor': 47, '2co': 47, '2cor': 47,
    // Galatians
    'galatians': 48, 'gal': 48,
    // Ephesians
    'ephesians': 49, 'eph': 49,
    // Philippians
    'philippians': 50, 'phil': 50, 'php': 50,
    // Colossians
    'colossians': 51, 'col': 51,
    // 1 Thessalonians
    '1 thessalonians': 52, '1 thess': 52, '1th': 52, '1thess': 52,
    // 2 Thessalonians
    '2 thessalonians': 53, '2 thess': 53, '2th': 53, '2thess': 53,
    // 1 Timothy
    '1 timothy': 54, '1 tim': 54, '1ti': 54, '1tim': 54,
    // 2 Timothy
    '2 timothy': 55, '2 tim': 55, '2ti': 55, '2tim': 55,
    // Titus
    'titus': 56, 'tit': 56,
    // Philemon
    'philemon': 57, 'phlm': 57, 'phm': 57,
    // Hebrews
    'hebrews': 58, 'heb': 58,
    // James
    'james': 59, 'jas': 59, 'jm': 59,
    // 1 Peter
    '1 peter': 60, '1 pet': 60, '1pe': 60, '1pet': 60,
    // 2 Peter
    '2 peter': 61, '2 pet': 61, '2pe': 61, '2pet': 61,
    // 1 John
    '1 john': 62, '1 jn': 62, '1jn': 62, '1jhn': 62,
    // 2 John
    '2 john': 63, '2 jn': 63, '2jn': 63,
    // 3 John
    '3 john': 64, '3 jn': 64, '3jn': 64,
    // Jude
    'jude': 65, 'jud': 65,
    // Revelation
    'revelation': 66, 'rev': 66, 'rv': 66,
  };

  // ── Search ────────────────────────────────────────────────────────────────────

  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  Timer? _debounce;
  int _searchGeneration = 0;

  List<BibleVerse> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = [];
      _lastQuery = '';
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;
    final generation = ++_searchGeneration;
    _isSearching = true;
    notifyListeners();
    try {
      final results = await _bible.searchVerses(query, limit: 50);
      if (generation != _searchGeneration) return;
      _searchResults = results;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _searchResults = [];
    } finally {
      if (generation == _searchGeneration) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchResults = [];
    _lastQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────────

  List<BibleBookmark> _bookmarkList = [];
  StreamSubscription<List<BibleBookmark>>? _bookmarkSub;

  List<BibleBookmark> get bookmarks => _bookmarkList;

  bool isBookmarked(int bookNum, int chapter, int verseNum) =>
      _bookmarkList.any((b) =>
          b.bookNum == bookNum &&
          b.chapter == chapter &&
          b.verseNum == verseNum);

  Future<void> toggleBookmark(BibleVerse verse) async {
    final id =
        '${verse.bookNum}_${verse.chapter}_${verse.verseNum}';
    if (isBookmarked(verse.bookNum, verse.chapter, verse.verseNum)) {
      await _bookmarks.removeBookmark(id);
    } else {
      await _bookmarks.addBookmark(BibleBookmark(
        bookNum: verse.bookNum,
        chapter: verse.chapter,
        verseNum: verse.verseNum,
        bookName: verse.bookName,
        text: verse.text,
        savedAt: DateTime.now(),
      ));
    }
  }

  Future<void> loadBookmarks() async {
    _bookmarkList = await _bookmarks.getBookmarks();
    notifyListeners();
  }

  // ── Font size ─────────────────────────────────────────────────────────────────

  double _fontSize = 17.0;
  double get fontSize => _fontSize;

  void increaseFontSize() {
    if (_fontSize >= 24) return;
    _fontSize += 1;
    notifyListeners();
  }

  void decreaseFontSize() {
    if (_fontSize <= 12) return;
    _fontSize -= 1;
    notifyListeners();
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _debounce?.cancel();
    _bookmarkSub?.cancel();
    super.dispose();
  }
}
