import '../entities/bible_entities.dart';

abstract class BookmarkRepository {
  /// Loads all bookmarks for the current user, sorted by savedAt descending.
  Future<List<BibleBookmark>> getBookmarks();

  /// Saves a bookmark. Overwrites silently if the same verse is saved twice.
  Future<void> addBookmark(BibleBookmark bookmark);

  /// Removes a bookmark by its id (`bookNum_chapter_verseNum`).
  Future<void> removeBookmark(String id);

  /// Real-time stream of all bookmarks, sorted by savedAt descending.
  Stream<List<BibleBookmark>> watchBookmarks();
}
