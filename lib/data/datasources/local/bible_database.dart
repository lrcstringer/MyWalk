import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite database for the WEB Bible translation.
///
/// On first launch the 31,102-verse TXT asset is parsed and inserted in
/// batches of 500.  Subsequent launches open the existing file instantly.
///
/// All public methods are safe to call concurrently — the internal
/// [_initCompleter] ensures the DB is only built once.
class BibleDatabase {
  BibleDatabase._();
  static final BibleDatabase instance = BibleDatabase._();

  Database? _db;
  Completer<void>? _initCompleter;
  bool _initInFlight = false;

  // Progress stream: emits 0.0–1.0 during the first-launch build.
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;
  bool get isReady => _db != null;

  // ── Public init ─────────────────────────────────────────────────────────────

  /// Initialises the database.  Safe to call multiple times and retryable
  /// after a previous error.  Awaiting this future guarantees the DB is ready.
  Future<void> init() async {
    if (_db != null) return;

    // A build is already in progress — join it.
    if (_initInFlight) {
      await _initCompleter!.future;
      return;
    }

    _initInFlight = true;
    // Capture the completer in a local variable so that a concurrent close()
    // call (which nulls _initCompleter) cannot cause a null crash when we
    // try to complete it after _openOrBuild() returns.
    final completer = Completer<void>();
    _initCompleter = completer;
    try {
      await _openOrBuild();
      completer.complete();
    } catch (e) {
      // Reset so the caller can retry on the next call.
      _initInFlight = false;
      completer.completeError(e);
      rethrow;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    // Reset init state so that init() can open the DB again after close().
    _initInFlight = false;
    _initCompleter = null;
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> queryChapter(
      int bookNum, int chapter) async {
    await init();
    return _db!.query(
      'verses',
      where: 'book_num = ? AND chapter = ?',
      whereArgs: [bookNum, chapter],
      orderBy: 'verse_num ASC',
    );
  }

  Future<Map<String, Object?>?> queryVerse(
      int bookNum, int chapter, int verseNum) async {
    await init();
    final rows = await _db!.query(
      'verses',
      where: 'book_num = ? AND chapter = ? AND verse_num = ?',
      whereArgs: [bookNum, chapter, verseNum],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> querySearch(
      String keyword, int limit) async {
    await init();
    return _db!.query(
      'verses',
      where: 'text LIKE ?',
      whereArgs: ['%$keyword%'],
      limit: limit,
    );
  }

  Future<int> queryVerseCount(int bookNum, int chapter) async {
    await init();
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM verses WHERE book_num = ? AND chapter = ?',
      [bookNum, chapter],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<void> _openOrBuild() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'bible_web.db');
    final dbFile = await openDatabase(dbPath, version: 1);

    // Check whether the table exists and is populated.
    final tables = await dbFile.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='verses'",
    );
    if (tables.isNotEmpty) {
      final count = await dbFile
          .rawQuery('SELECT COUNT(*) as cnt FROM verses');
      if ((count.first['cnt'] as int? ?? 0) > 30000) {
        _db = dbFile;
        _progressController.add(1.0);
        return;
      }
    }

    // First launch — build from asset.
    await _buildDatabase(dbFile);
    _db = dbFile;
  }

  Future<void> _buildDatabase(Database db) async {
    // Create schema.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verses (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        book_num  INTEGER NOT NULL,
        chapter   INTEGER NOT NULL,
        verse_num INTEGER NOT NULL,
        text      TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bcv ON verses(book_num, chapter, verse_num)',
    );
    // Truncate any partial data from a previous interrupted build so that
    // re-running this method never produces duplicate verses.
    await db.execute('DELETE FROM verses');

    // Load and parse the TXT asset.
    final raw = await rootBundle.loadString('assets/bible/engwebp_vpl.txt');
    final lines = raw.split('\n');
    final total = lines.length;

    // Insert in batches of 500 for performance.
    var batch = db.batch();
    var batchCount = 0;
    var processed = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        processed++;
        continue;
      }

      final parsed = _parseLine(trimmed);
      if (parsed == null) {
        processed++;
        continue;
      }

      batch.insert('verses', parsed);
      batchCount++;
      processed++;

      if (batchCount >= 500) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCount = 0;
        _progressController.add(processed / total);
      }
    }

    if (batchCount > 0) {
      await batch.commit(noResult: true);
    }

    _progressController.add(1.0);
  }

  /// Parses one TXT line: `GEN 1:1 In the beginning...`
  /// Returns null for malformed lines.
  Map<String, Object>? _parseLine(String line) {
    try {
      final firstSpace = line.indexOf(' ');
      if (firstSpace < 0) return null;

      final bookCode = line.substring(0, firstSpace);
      final bookNum = _codeToNum[bookCode];
      if (bookNum == null) return null;

      final secondSpace = line.indexOf(' ', firstSpace + 1);
      if (secondSpace < 0) return null;

      final ref = line.substring(firstSpace + 1, secondSpace); // e.g. "1:1"
      final colon = ref.indexOf(':');
      if (colon < 0) return null;

      final chapter = int.tryParse(ref.substring(0, colon));
      final verseNum = int.tryParse(ref.substring(colon + 1));
      if (chapter == null || verseNum == null) return null;

      final text = line.substring(secondSpace + 1).trim();
      if (text.isEmpty) return null;

      return {
        'book_num': bookNum,
        'chapter': chapter,
        'verse_num': verseNum,
        'text': text,
      };
    } catch (_) {
      return null;
    }
  }

  // ── Book code → number map (eBible.org standard abbreviations) ───────────────

  static const _codeToNum = <String, int>{
    'GEN': 1,  'EXO': 2,  'LEV': 3,  'NUM': 4,  'DEU': 5,
    'JOS': 6,  'JDG': 7,  'RUT': 8,  '1SA': 9,  '2SA': 10,
    '1KI': 11, '2KI': 12, '1CH': 13, '2CH': 14, 'EZR': 15,
    'NEH': 16, 'EST': 17, 'JOB': 18, 'PSA': 19, 'PRO': 20,
    'ECC': 21, 'SNG': 22, 'ISA': 23, 'JER': 24, 'LAM': 25,
    'EZK': 26, 'DAN': 27, 'HOS': 28, 'JOL': 29, 'AMO': 30,
    'OBA': 31, 'JON': 32, 'MIC': 33, 'NAM': 34, 'HAB': 35,
    'ZEP': 36, 'HAG': 37, 'ZEC': 38, 'MAL': 39, 'MAT': 40,
    'MRK': 41, 'LUK': 42, 'JHN': 43, 'ACT': 44, 'ROM': 45,
    '1CO': 46, '2CO': 47, 'GAL': 48, 'EPH': 49, 'PHP': 50,
    'COL': 51, '1TH': 52, '2TH': 53, '1TI': 54, '2TI': 55,
    'TIT': 56, 'PHM': 57, 'HEB': 58, 'JAS': 59, '1PE': 60,
    '2PE': 61, '1JN': 62, '2JN': 63, '3JN': 64, 'JUD': 65,
    'REV': 66,
  };
}
