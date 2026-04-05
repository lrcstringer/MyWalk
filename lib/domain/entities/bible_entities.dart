/// Domain entities for the Bible viewer feature.
///
/// BibleBook — one of 66 canonical books (data hardcoded, no DB round-trip).
/// BibleVerse — a single verse from the SQLite database.
/// ChapterData — all verses for one chapter.
/// BibleBookmark — a user-saved verse (persisted to Firestore).

class BibleVerse {
  final int bookNum;
  final int chapter;
  final int verseNum;
  final String bookName;
  final String text;

  const BibleVerse({
    required this.bookNum,
    required this.chapter,
    required this.verseNum,
    required this.bookName,
    required this.text,
  });

  String get reference => '$bookName $chapter:$verseNum';
}

class ChapterData {
  final BibleBook book;
  final int chapter;
  final List<BibleVerse> verses;

  const ChapterData({
    required this.book,
    required this.chapter,
    required this.verses,
  });

  bool get isEmpty => verses.isEmpty;
}

class BibleBookmark {
  final int bookNum;
  final int chapter;
  final int verseNum;
  final String bookName;
  final String text;
  final DateTime savedAt;

  const BibleBookmark({
    required this.bookNum,
    required this.chapter,
    required this.verseNum,
    required this.bookName,
    required this.text,
    required this.savedAt,
  });

  String get id => '${bookNum}_${chapter}_$verseNum';
  String get reference => '$bookName $chapter:$verseNum';
}

// ── BibleBook ────────────────────────────────────────────────────────────────

class BibleBook {
  final int bookNum;
  final String code;
  final String name;
  final int chapterCount;
  final bool isOldTestament;

  const BibleBook({
    required this.bookNum,
    required this.code,
    required this.name,
    required this.chapterCount,
    required this.isOldTestament,
  });

  // ── All 66 books ────────────────────────────────────────────────────────────

  static const all = <BibleBook>[
    // Old Testament
    BibleBook(bookNum: 1,  code: 'GEN', name: 'Genesis',       chapterCount: 50,  isOldTestament: true),
    BibleBook(bookNum: 2,  code: 'EXO', name: 'Exodus',        chapterCount: 40,  isOldTestament: true),
    BibleBook(bookNum: 3,  code: 'LEV', name: 'Leviticus',     chapterCount: 27,  isOldTestament: true),
    BibleBook(bookNum: 4,  code: 'NUM', name: 'Numbers',       chapterCount: 36,  isOldTestament: true),
    BibleBook(bookNum: 5,  code: 'DEU', name: 'Deuteronomy',   chapterCount: 34,  isOldTestament: true),
    BibleBook(bookNum: 6,  code: 'JOS', name: 'Joshua',        chapterCount: 24,  isOldTestament: true),
    BibleBook(bookNum: 7,  code: 'JDG', name: 'Judges',        chapterCount: 21,  isOldTestament: true),
    BibleBook(bookNum: 8,  code: 'RUT', name: 'Ruth',          chapterCount: 4,   isOldTestament: true),
    BibleBook(bookNum: 9,  code: '1SA', name: '1 Samuel',      chapterCount: 31,  isOldTestament: true),
    BibleBook(bookNum: 10, code: '2SA', name: '2 Samuel',      chapterCount: 24,  isOldTestament: true),
    BibleBook(bookNum: 11, code: '1KI', name: '1 Kings',       chapterCount: 22,  isOldTestament: true),
    BibleBook(bookNum: 12, code: '2KI', name: '2 Kings',       chapterCount: 25,  isOldTestament: true),
    BibleBook(bookNum: 13, code: '1CH', name: '1 Chronicles',  chapterCount: 29,  isOldTestament: true),
    BibleBook(bookNum: 14, code: '2CH', name: '2 Chronicles',  chapterCount: 36,  isOldTestament: true),
    BibleBook(bookNum: 15, code: 'EZR', name: 'Ezra',          chapterCount: 10,  isOldTestament: true),
    BibleBook(bookNum: 16, code: 'NEH', name: 'Nehemiah',      chapterCount: 13,  isOldTestament: true),
    BibleBook(bookNum: 17, code: 'EST', name: 'Esther',        chapterCount: 10,  isOldTestament: true),
    BibleBook(bookNum: 18, code: 'JOB', name: 'Job',           chapterCount: 42,  isOldTestament: true),
    BibleBook(bookNum: 19, code: 'PSA', name: 'Psalms',        chapterCount: 150, isOldTestament: true),
    BibleBook(bookNum: 20, code: 'PRO', name: 'Proverbs',      chapterCount: 31,  isOldTestament: true),
    BibleBook(bookNum: 21, code: 'ECC', name: 'Ecclesiastes',  chapterCount: 12,  isOldTestament: true),
    BibleBook(bookNum: 22, code: 'SNG', name: 'Song of Songs', chapterCount: 8,   isOldTestament: true),
    BibleBook(bookNum: 23, code: 'ISA', name: 'Isaiah',        chapterCount: 66,  isOldTestament: true),
    BibleBook(bookNum: 24, code: 'JER', name: 'Jeremiah',      chapterCount: 52,  isOldTestament: true),
    BibleBook(bookNum: 25, code: 'LAM', name: 'Lamentations',  chapterCount: 5,   isOldTestament: true),
    BibleBook(bookNum: 26, code: 'EZK', name: 'Ezekiel',       chapterCount: 48,  isOldTestament: true),
    BibleBook(bookNum: 27, code: 'DAN', name: 'Daniel',        chapterCount: 12,  isOldTestament: true),
    BibleBook(bookNum: 28, code: 'HOS', name: 'Hosea',         chapterCount: 14,  isOldTestament: true),
    BibleBook(bookNum: 29, code: 'JOL', name: 'Joel',          chapterCount: 3,   isOldTestament: true),
    BibleBook(bookNum: 30, code: 'AMO', name: 'Amos',          chapterCount: 9,   isOldTestament: true),
    BibleBook(bookNum: 31, code: 'OBA', name: 'Obadiah',       chapterCount: 1,   isOldTestament: true),
    BibleBook(bookNum: 32, code: 'JON', name: 'Jonah',         chapterCount: 4,   isOldTestament: true),
    BibleBook(bookNum: 33, code: 'MIC', name: 'Micah',         chapterCount: 7,   isOldTestament: true),
    BibleBook(bookNum: 34, code: 'NAM', name: 'Nahum',         chapterCount: 3,   isOldTestament: true),
    BibleBook(bookNum: 35, code: 'HAB', name: 'Habakkuk',      chapterCount: 3,   isOldTestament: true),
    BibleBook(bookNum: 36, code: 'ZEP', name: 'Zephaniah',     chapterCount: 3,   isOldTestament: true),
    BibleBook(bookNum: 37, code: 'HAG', name: 'Haggai',        chapterCount: 2,   isOldTestament: true),
    BibleBook(bookNum: 38, code: 'ZEC', name: 'Zechariah',     chapterCount: 14,  isOldTestament: true),
    BibleBook(bookNum: 39, code: 'MAL', name: 'Malachi',       chapterCount: 4,   isOldTestament: true),
    // New Testament
    BibleBook(bookNum: 40, code: 'MAT', name: 'Matthew',       chapterCount: 28,  isOldTestament: false),
    BibleBook(bookNum: 41, code: 'MRK', name: 'Mark',          chapterCount: 16,  isOldTestament: false),
    BibleBook(bookNum: 42, code: 'LUK', name: 'Luke',          chapterCount: 24,  isOldTestament: false),
    BibleBook(bookNum: 43, code: 'JHN', name: 'John',          chapterCount: 21,  isOldTestament: false),
    BibleBook(bookNum: 44, code: 'ACT', name: 'Acts',          chapterCount: 28,  isOldTestament: false),
    BibleBook(bookNum: 45, code: 'ROM', name: 'Romans',        chapterCount: 16,  isOldTestament: false),
    BibleBook(bookNum: 46, code: '1CO', name: '1 Corinthians', chapterCount: 16,  isOldTestament: false),
    BibleBook(bookNum: 47, code: '2CO', name: '2 Corinthians', chapterCount: 13,  isOldTestament: false),
    BibleBook(bookNum: 48, code: 'GAL', name: 'Galatians',     chapterCount: 6,   isOldTestament: false),
    BibleBook(bookNum: 49, code: 'EPH', name: 'Ephesians',     chapterCount: 6,   isOldTestament: false),
    BibleBook(bookNum: 50, code: 'PHP', name: 'Philippians',   chapterCount: 4,   isOldTestament: false),
    BibleBook(bookNum: 51, code: 'COL', name: 'Colossians',    chapterCount: 4,   isOldTestament: false),
    BibleBook(bookNum: 52, code: '1TH', name: '1 Thessalonians', chapterCount: 5, isOldTestament: false),
    BibleBook(bookNum: 53, code: '2TH', name: '2 Thessalonians', chapterCount: 3, isOldTestament: false),
    BibleBook(bookNum: 54, code: '1TI', name: '1 Timothy',     chapterCount: 6,   isOldTestament: false),
    BibleBook(bookNum: 55, code: '2TI', name: '2 Timothy',     chapterCount: 4,   isOldTestament: false),
    BibleBook(bookNum: 56, code: 'TIT', name: 'Titus',         chapterCount: 3,   isOldTestament: false),
    BibleBook(bookNum: 57, code: 'PHM', name: 'Philemon',      chapterCount: 1,   isOldTestament: false),
    BibleBook(bookNum: 58, code: 'HEB', name: 'Hebrews',       chapterCount: 13,  isOldTestament: false),
    BibleBook(bookNum: 59, code: 'JAS', name: 'James',         chapterCount: 5,   isOldTestament: false),
    BibleBook(bookNum: 60, code: '1PE', name: '1 Peter',       chapterCount: 5,   isOldTestament: false),
    BibleBook(bookNum: 61, code: '2PE', name: '2 Peter',       chapterCount: 3,   isOldTestament: false),
    BibleBook(bookNum: 62, code: '1JN', name: '1 John',        chapterCount: 5,   isOldTestament: false),
    BibleBook(bookNum: 63, code: '2JN', name: '2 John',        chapterCount: 1,   isOldTestament: false),
    BibleBook(bookNum: 64, code: '3JN', name: '3 John',        chapterCount: 1,   isOldTestament: false),
    BibleBook(bookNum: 65, code: 'JUD', name: 'Jude',          chapterCount: 1,   isOldTestament: false),
    BibleBook(bookNum: 66, code: 'REV', name: 'Revelation',    chapterCount: 22,  isOldTestament: false),
  ];

  static final _byNum = <int, BibleBook>{
    for (final b in all) b.bookNum: b,
  };

  static final _byCode = <String, BibleBook>{
    for (final b in all) b.code: b,
  };

  /// Look up by book number (1–66). Returns null if out of range.
  static BibleBook? byNum(int n) => _byNum[n];

  /// Look up by eBible.org 3-letter code (e.g. 'GEN'). Returns null if unknown.
  static BibleBook? byCode(String code) => _byCode[code.toUpperCase()];

  static final List<BibleBook> oldTestament =
      all.where((b) => b.isOldTestament).toList();

  static final List<BibleBook> newTestament =
      all.where((b) => !b.isOldTestament).toList();
}
