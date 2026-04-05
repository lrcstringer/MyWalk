import '../entities/bible_entities.dart';

abstract class BibleRepository {
  /// Whether the underlying database is ready for queries.
  bool get isReady;

  /// Stream of build progress (0.0–1.0) emitted during the first-launch
  /// database construction from the TXT asset.
  Stream<double> get initProgress;

  /// Ensures the database is initialised.  Must be awaited before any query
  /// when [isReady] is false.
  Future<void> init();

  /// Returns all verses for [bookNum]/[chapter], ordered by verse number.
  Future<ChapterData> getChapter(int bookNum, int chapter);

  /// Returns a single verse, or null if not found.
  Future<BibleVerse?> getVerse(int bookNum, int chapter, int verseNum);

  /// Full-text search across all verses.  Results are limited to [limit].
  Future<List<BibleVerse>> searchVerses(String query, {int limit = 50});

  /// Returns the number of chapters in [bookNum].
  int getChapterCount(int bookNum);

  /// Returns the number of verses in [bookNum]/[chapter].
  Future<int> getVerseCount(int bookNum, int chapter);
}
