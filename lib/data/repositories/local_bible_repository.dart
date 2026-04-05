import '../../domain/entities/bible_entities.dart';
import '../../domain/repositories/bible_repository.dart';
import '../datasources/local/bible_database.dart';

class LocalBibleRepository implements BibleRepository {
  final BibleDatabase _db;

  LocalBibleRepository(this._db);

  @override
  bool get isReady => _db.isReady;

  @override
  Stream<double> get initProgress => _db.progressStream;

  @override
  Future<void> init() => _db.init();

  @override
  Future<ChapterData> getChapter(int bookNum, int chapter) async {
    final book = BibleBook.byNum(bookNum) ??
        (throw ArgumentError('Unknown book number: $bookNum'));

    final rows = await _db.queryChapter(bookNum, chapter);
    final verses = rows
        .map((r) => BibleVerse(
              bookNum: bookNum,
              chapter: chapter,
              verseNum: r['verse_num'] as int,
              bookName: book.name,
              text: r['text'] as String,
            ))
        .toList();

    return ChapterData(book: book, chapter: chapter, verses: verses);
  }

  @override
  Future<BibleVerse?> getVerse(
      int bookNum, int chapter, int verseNum) async {
    final book = BibleBook.byNum(bookNum);
    if (book == null) return null;
    final row = await _db.queryVerse(bookNum, chapter, verseNum);
    if (row == null) return null;
    return BibleVerse(
      bookNum: bookNum,
      chapter: chapter,
      verseNum: verseNum,
      bookName: book.name,
      text: row['text'] as String,
    );
  }

  @override
  Future<List<BibleVerse>> searchVerses(String query,
      {int limit = 50}) async {
    if (query.trim().isEmpty) return [];
    final rows = await _db.querySearch(query.trim(), limit);
    return rows.map((r) {
      final bn = r['book_num'] as int;
      final bookName = BibleBook.byNum(bn)?.name ?? '';
      return BibleVerse(
        bookNum: bn,
        chapter: r['chapter'] as int,
        verseNum: r['verse_num'] as int,
        bookName: bookName,
        text: r['text'] as String,
      );
    }).toList();
  }

  @override
  int getChapterCount(int bookNum) =>
      BibleBook.byNum(bookNum)?.chapterCount ?? 1;

  @override
  Future<int> getVerseCount(int bookNum, int chapter) =>
      _db.queryVerseCount(bookNum, chapter);
}
