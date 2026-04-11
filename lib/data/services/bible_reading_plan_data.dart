import '../../domain/entities/bible_reading_plan.dart';

/// Static 52-week × 7-day Bible reading schedule.
///
/// Layout: planData[weekIndex][dayIndex]  (weekIndex 0–51, dayIndex 0=Sun … 6=Sat)
///
/// Book numbers match BibleBook.bookNum (1=Genesis … 66=Revelation).
/// Each BibleReadingRef carries the chapter to open in the Bible browser plus
/// the human-readable display label from the original reading plan.
class BibleReadingPlanData {
  BibleReadingPlanData._();

  static BibleReadingRef _r(int book, int ch, String label) =>
      BibleReadingRef(bookNum: book, chapter: ch, label: label);

  // ignore: non_constant_identifier_names
  static BibleReadingDayPlan _day({
    List<BibleReadingRef> ps = const [],
    List<BibleReadingRef> nt = const [],
    List<BibleReadingRef> to = const [],
    List<BibleReadingRef> hi = const [],
    List<BibleReadingRef> pr = const [],
    List<BibleReadingRef> wi = const [],
  }) =>
      BibleReadingDayPlan(
        psalms: ps,
        newTestament: nt,
        torah: to,
        historical: hi,
        prophetic: pr,
        wisdom: wi,
      );

  /// Full 52-week schedule. Index [w][d] → BibleReadingDayPlan.
  static final List<List<BibleReadingDayPlan>> weeks = [
    // ── Week 1 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 1,  'Psalm 1')]),
      _day(ps: [_r(19, 2,  'Psalm 2:1–4')],   nt: [_r(40,1,'Matthew 1')],   to: [_r(1,1,'Genesis 1')],    hi: [_r(6,1,'Joshua 1')],               wi: [_r(20,1,'Proverbs 1')]),
      _day(ps: [_r(19, 2,  'Psalm 2:5–12')],  nt: [_r(40,2,'Matthew 2')],   to: [_r(1,2,'Genesis 2')],    hi: [_r(6,2,'Joshua 2')]),
      _day(ps: [_r(19, 3,  'Psalm 3')],        nt: [_r(40,3,'Matthew 3')],   to: [_r(1,3,'Genesis 3')],    hi: [_r(6,3,'Joshua 3')]),
      _day(ps: [_r(19, 4,  'Psalm 4')],        nt: [_r(40,4,'Matthew 4')],   to: [_r(1,4,'Genesis 4')],    hi: [_r(6,4,'Joshua 4')],               wi: [_r(18,1,'Job 1')]),
      _day(ps: [_r(19, 5,  'Psalm 5:1–6')],   nt: [_r(40,5,'Matthew 5')],   to: [_r(1,5,'Genesis 5')],    hi: [_r(6,5,'Joshua 5')]),
      _day(ps: [_r(19, 5,  'Psalm 5:7–12')],                                 to: [_r(1,6,'Genesis 6')],    hi: [_r(6,6,'Joshua 6')]),
    ],
    // ── Week 2 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 6,  'Psalm 6')]),
      _day(ps: [_r(19, 7,  'Psalm 7:1–5')],   nt: [_r(40,6,'Matthew 6')],   to: [_r(1,7,'Genesis 7')],    hi: [_r(6,7,'Joshua 7')],               wi: [_r(20,2,'Proverbs 2')]),
      _day(ps: [_r(19, 7,  'Psalm 7:6–11')],  nt: [_r(40,7,'Matthew 7')],   to: [_r(1,8,'Genesis 8')],    hi: [_r(6,8,'Joshua 8')]),
      _day(ps: [_r(19, 7,  'Psalm 7:12–17')], nt: [_r(40,8,'Matthew 8')],   to: [_r(1,9,'Genesis 9'),_r(1,10,'Genesis 10')], hi: [_r(6,9,'Joshua 9')]),
      _day(ps: [_r(19, 8,  'Psalm 8')],        nt: [_r(40,9,'Matthew 9')],   to: [_r(1,11,'Genesis 11')],  hi: [_r(6,10,'Joshua 10')],             wi: [_r(18,2,'Job 2')]),
      _day(ps: [_r(19, 9,  'Psalm 9:1–12')],  nt: [_r(40,10,'Matthew 10')], to: [_r(1,12,'Genesis 12')],  hi: [_r(6,11,'Joshua 11')]),
      _day(ps: [_r(19, 9,  'Psalm 9:13–20')],                                to: [_r(1,13,'Genesis 13')],  hi: [_r(6,12,'Joshua 12'),_r(6,13,'Joshua 13')]),
    ],
    // ── Week 3 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 10, 'Psalm 10:1–11')]),
      _day(ps: [_r(19, 10, 'Psalm 10:12–18')],nt: [_r(40,11,'Matthew 11')], to: [_r(1,14,'Genesis 14')],  hi: [_r(6,14,'Joshua 14'),_r(6,15,'Joshua 15')], wi: [_r(20,3,'Proverbs 3')]),
      _day(ps: [_r(19, 11, 'Psalm 11')],       nt: [_r(40,12,'Matthew 12')], to: [_r(1,15,'Genesis 15')],  hi: [_r(6,16,'Joshua 16'),_r(6,17,'Joshua 17')]),
      _day(ps: [_r(19, 12, 'Psalm 12')],       nt: [_r(40,13,'Matthew 13')], to: [_r(1,16,'Genesis 16')],  hi: [_r(6,18,'Joshua 18'),_r(6,19,'Joshua 19')]),
      _day(ps: [_r(19, 13, 'Psalm 13')],       nt: [_r(40,14,'Matthew 14')], to: [_r(1,17,'Genesis 17')],  hi: [_r(6,20,'Joshua 20'),_r(6,21,'Joshua 21')], wi: [_r(18,3,'Job 3')]),
      _day(ps: [_r(19, 14, 'Psalm 14')],       nt: [_r(40,15,'Matthew 15')], to: [_r(1,18,'Genesis 18')],  hi: [_r(6,22,'Joshua 22')]),
      _day(ps: [_r(19, 15, 'Psalm 15')],                                      to: [_r(1,19,'Genesis 19')],  hi: [_r(6,23,'Joshua 23')]),
    ],
    // ── Week 4 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 16, 'Psalm 16:1–6')]),
      _day(ps: [_r(19, 16, 'Psalm 16:7–11')], nt: [_r(40,16,'Matthew 16')], to: [_r(1,20,'Genesis 20')],  hi: [_r(6,24,'Joshua 24')],             wi: [_r(20,4,'Proverbs 4')]),
      _day(ps: [_r(19, 17, 'Psalm 17:1–9')],  nt: [_r(40,17,'Matthew 17')], to: [_r(1,21,'Genesis 21')],  hi: [_r(7,1,'Judges 1')]),
      _day(ps: [_r(19, 17, 'Psalm 17:10–15')],nt: [_r(40,18,'Matthew 18')], to: [_r(1,22,'Genesis 22')],  hi: [_r(7,2,'Judges 2')]),
      _day(ps: [_r(19, 18, 'Psalm 18:1–6')],  nt: [_r(40,19,'Matthew 19')], to: [_r(1,23,'Genesis 23')],  hi: [_r(7,3,'Judges 3')],               wi: [_r(18,4,'Job 4')]),
      _day(ps: [_r(19, 18, 'Psalm 18:7–19')], nt: [_r(40,20,'Matthew 20')], to: [_r(1,24,'Genesis 24')],  hi: [_r(7,4,'Judges 4')]),
      _day(ps: [_r(19, 18, 'Psalm 18:20–27')],                               to: [_r(1,25,'Genesis 25')],  hi: [_r(7,5,'Judges 5')]),
    ],
    // ── Week 5 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 18, 'Psalm 18:28–33')]),
      _day(ps: [_r(19, 18, 'Psalm 18:34–45')],nt: [_r(40,21,'Matthew 21')], to: [_r(1,26,'Genesis 26')],  hi: [_r(7,6,'Judges 6')],               wi: [_r(20,5,'Proverbs 5')]),
      _day(ps: [_r(19, 18, 'Psalm 18:46–50')],nt: [_r(40,22,'Matthew 22')], to: [_r(1,27,'Genesis 27')],  hi: [_r(7,7,'Judges 7')]),
      _day(ps: [_r(19, 19, 'Psalm 19')],       nt: [_r(40,23,'Matthew 23')], to: [_r(1,28,'Genesis 28')],  hi: [_r(7,8,'Judges 8')]),
      _day(ps: [_r(19, 19, 'Psalm 19:7–14')], nt: [_r(40,24,'Matthew 24')], to: [_r(1,29,'Genesis 29')],  hi: [_r(7,9,'Judges 9')],               wi: [_r(18,5,'Job 5')]),
      _day(ps: [_r(19, 20, 'Psalm 20')],       nt: [_r(40,25,'Matthew 25')], to: [_r(1,30,'Genesis 30')],  hi: [_r(7,10,'Judges 10')]),
      _day(ps: [_r(19, 21, 'Psalm 21:1–7')],                                 to: [_r(1,31,'Genesis 31')],  hi: [_r(7,11,'Judges 11')]),
    ],
    // ── Week 6 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 21, 'Psalm 21:8–13')]),
      _day(ps: [_r(19, 22, 'Psalm 22:1–8')],  nt: [_r(40,26,'Matthew 26')], to: [_r(1,32,'Genesis 32')],  hi: [_r(7,12,'Judges 12')],             wi: [_r(20,6,'Proverbs 6')]),
      _day(ps: [_r(19, 22, 'Psalm 22:9–18')], nt: [_r(40,27,'Matthew 27')], to: [_r(1,33,'Genesis 33')],  hi: [_r(7,13,'Judges 13')]),
      _day(ps: [_r(19, 22, 'Psalm 22:19–26')],nt: [_r(40,28,'Matthew 28')], to: [_r(1,34,'Genesis 34')],  hi: [_r(7,14,'Judges 14')]),
      _day(ps: [_r(19, 22, 'Psalm 22:27–31')],nt: [_r(41,1,'Mark 1')],      to: [_r(1,35,'Genesis 35'),_r(1,36,'Genesis 36')], hi: [_r(7,15,'Judges 15')], wi: [_r(18,6,'Job 6')]),
      _day(ps: [_r(19, 23, 'Psalm 23')],       nt: [_r(41,2,'Mark 2')],      to: [_r(1,37,'Genesis 37')],  hi: [_r(7,16,'Judges 16')]),
      _day(ps: [_r(19, 24, 'Psalm 24:1–6')],                                 to: [_r(1,38,'Genesis 38')],  hi: [_r(7,17,'Judges 17')]),
    ],
    // ── Week 7 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 24, 'Psalm 24:7–10')]),
      _day(ps: [_r(19, 25, 'Psalm 25:1–7')],  nt: [_r(41,3,'Mark 3')],      to: [_r(1,39,'Genesis 39')],  hi: [_r(7,18,'Judges 18')],             wi: [_r(20,7,'Proverbs 7')]),
      _day(ps: [_r(19, 25, 'Psalm 25:8–14')], nt: [_r(41,4,'Mark 4')],      to: [_r(1,40,'Genesis 40')],  hi: [_r(7,19,'Judges 19')]),
      _day(ps: [_r(19, 25, 'Psalm 25:15–22')],nt: [_r(41,5,'Mark 5')],      to: [_r(1,41,'Genesis 41')],  hi: [_r(7,20,'Judges 20')]),
      _day(ps: [_r(19, 26, 'Psalm 26:1–5')],  nt: [_r(41,6,'Mark 6')],      to: [_r(1,42,'Genesis 42')],  hi: [_r(7,21,'Judges 21')],             wi: [_r(18,7,'Job 7')]),
      _day(ps: [_r(19, 26, 'Psalm 26:6–12')], nt: [_r(41,7,'Mark 7')],      to: [_r(1,43,'Genesis 43')],  hi: [_r(8,1,'Ruth 1')]),
      _day(ps: [_r(19, 27, 'Psalm 27')],                                      to: [_r(1,44,'Genesis 44')],  hi: [_r(8,2,'Ruth 2')]),
    ],
    // ── Week 8 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 27, 'Psalm 27:7–14')]),
      _day(ps: [_r(19, 28, 'Psalm 28:1–5')],  nt: [_r(41,8,'Mark 8')],      to: [_r(1,45,'Genesis 45')],  hi: [_r(8,3,'Ruth 3'),_r(8,4,'Ruth 4')], wi: [_r(20,8,'Proverbs 8')]),
      _day(ps: [_r(19, 28, 'Psalm 28:6–9')],  nt: [_r(41,9,'Mark 9')],      to: [_r(1,46,'Genesis 46')],  hi: [_r(9,1,'1 Samuel 1')]),
      _day(ps: [_r(19, 29, 'Psalm 29')],       nt: [_r(41,10,'Mark 10')],    to: [_r(1,47,'Genesis 47')],  hi: [_r(9,2,'1 Samuel 2')]),
      _day(ps: [_r(19, 30, 'Psalm 30:1–5')],  nt: [_r(41,11,'Mark 11')],    to: [_r(1,48,'Genesis 48')],  hi: [_r(9,3,'1 Samuel 3')],             wi: [_r(18,8,'Job 8')]),
      _day(ps: [_r(19, 30, 'Psalm 30:6–12')], nt: [_r(41,12,'Mark 12')],    to: [_r(1,49,'Genesis 49')],  hi: [_r(9,4,'1 Samuel 4')]),
      _day(ps: [_r(19, 31, 'Psalm 31:1–8')],                                 to: [_r(1,50,'Genesis 50')],  hi: [_r(9,5,'1 Samuel 5'),_r(9,6,'1 Samuel 6')]),
    ],
    // ── Week 9 ───────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 31, 'Psalm 31:9–18')]),
      _day(ps: [_r(19, 31, 'Psalm 31:19–24')],nt: [_r(41,13,'Mark 13')],    to: [_r(2,1,'Exodus 1')],     hi: [_r(9,7,'1 Samuel 7'),_r(9,8,'1 Samuel 8')], wi: [_r(20,9,'Proverbs 9')]),
      _day(ps: [_r(19, 32, 'Psalm 32:1–5')],  nt: [_r(41,14,'Mark 14')],    to: [_r(2,2,'Exodus 2')],     hi: [_r(9,9,'1 Samuel 9')]),
      _day(ps: [_r(19, 32, 'Psalm 32:6–11')], nt: [_r(41,15,'Mark 15')],    to: [_r(2,3,'Exodus 3')],     hi: [_r(9,10,'1 Samuel 10')]),
      _day(ps: [_r(19, 33, 'Psalm 33:1–9')],  nt: [_r(41,16,'Mark 16')],    to: [_r(2,4,'Exodus 4')],     hi: [_r(9,11,'1 Samuel 11')],            wi: [_r(18,9,'Job 9')]),
      _day(ps: [_r(19, 33, 'Psalm 33:10–17')],nt: [_r(42,1,'Luke 1:1–38')], to: [_r(2,5,'Exodus 5')],     hi: [_r(9,12,'1 Samuel 12')]),
      _day(ps: [_r(19, 33, 'Psalm 33:18–22')],                               to: [_r(2,6,'Exodus 6')],     hi: [_r(9,13,'1 Samuel 13')]),
    ],
    // ── Week 10 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 34, 'Psalm 34:1–10')]),
      _day(ps: [_r(19, 34, 'Psalm 34:11–16')],nt: [_r(42,1,'Luke 1:39–80')],to: [_r(2,7,'Exodus 7')],    hi: [_r(9,14,'1 Samuel 14')],            wi: [_r(20,10,'Proverbs 10')]),
      _day(ps: [_r(19, 34, 'Psalm 34:17–22')],nt: [_r(42,2,'Luke 2')],       to: [_r(2,8,'Exodus 8')],    hi: [_r(9,15,'1 Samuel 15')]),
      _day(ps: [_r(19, 35, 'Psalm 35:1–10')], nt: [_r(42,3,'Luke 3')],       to: [_r(2,9,'Exodus 9')],    hi: [_r(9,16,'1 Samuel 16')]),
      _day(ps: [_r(19, 35, 'Psalm 35:11–18')],nt: [_r(42,4,'Luke 4')],       to: [_r(2,10,'Exodus 10')],  hi: [_r(9,17,'1 Samuel 17')],            wi: [_r(18,10,'Job 10')]),
      _day(ps: [_r(19, 35, 'Psalm 35:19–28')],nt: [_r(42,5,'Luke 5')],       to: [_r(2,11,'Exodus 11')],  hi: [_r(9,18,'1 Samuel 18')]),
      _day(ps: [_r(19, 36, 'Psalm 36:1–4')],                                  to: [_r(2,12,'Exodus 12')],  hi: [_r(9,19,'1 Samuel 19')]),
    ],
    // ── Week 11 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 36, 'Psalm 36:5–12')]),
      _day(ps: [_r(19, 37, 'Psalm 37')],       nt: [_r(42,6,'Luke 6')],       to: [_r(2,13,'Exodus 13')],  hi: [_r(9,20,'1 Samuel 20')],            wi: [_r(20,11,'Proverbs 11')]),
      _day(ps: [_r(19, 37, 'Psalm 37:7–11')], nt: [_r(42,7,'Luke 7')],       to: [_r(2,14,'Exodus 14')],  hi: [_r(9,21,'1 Samuel 21'),_r(9,22,'1 Samuel 22')]),
      _day(ps: [_r(19, 37, 'Psalm 37:12–20')],nt: [_r(42,8,'Luke 8')],       to: [_r(2,15,'Exodus 15')],  hi: [_r(9,23,'1 Samuel 23')]),
      _day(ps: [_r(19, 37, 'Psalm 37:21–26')],nt: [_r(42,9,'Luke 9')],       to: [_r(2,16,'Exodus 16')],  hi: [_r(9,24,'1 Samuel 24')],            wi: [_r(18,11,'Job 11')]),
      _day(ps: [_r(19, 37, 'Psalm 37:27–34')],nt: [_r(42,10,'Luke 10')],     to: [_r(2,17,'Exodus 17')],  hi: [_r(9,25,'1 Samuel 25')]),
      _day(ps: [_r(19, 37, 'Psalm 37:35–40')],                                to: [_r(2,18,'Exodus 18')],  hi: [_r(9,26,'1 Samuel 26')]),
    ],
    // ── Week 12 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 38, 'Psalm 38:1–8')]),
      _day(ps: [_r(19, 38, 'Psalm 38:9–14')], nt: [_r(42,11,'Luke 11')],    to: [_r(2,19,'Exodus 19')],  hi: [_r(9,27,'1 Samuel 27')],            wi: [_r(20,12,'Proverbs 12')]),
      _day(ps: [_r(19, 38, 'Psalm 38:15–22')],nt: [_r(42,12,'Luke 12')],    to: [_r(2,20,'Exodus 20')],  hi: [_r(9,28,'1 Samuel 28')]),
      _day(ps: [_r(19, 39, 'Psalm 39')],       nt: [_r(42,13,'Luke 13')],    to: [_r(2,21,'Exodus 21')],  hi: [_r(9,29,'1 Samuel 29'),_r(9,30,'1 Samuel 30')]),
      _day(ps: [_r(19, 40, 'Psalm 40:1–5')],  nt: [_r(42,14,'Luke 14')],    to: [_r(2,22,'Exodus 22')],  hi: [_r(9,31,'1 Samuel 31')],            wi: [_r(18,12,'Job 12')]),
      _day(ps: [_r(19, 40, 'Psalm 40:6–10')], nt: [_r(42,15,'Luke 15')],    to: [_r(2,23,'Exodus 23')],  hi: [_r(10,1,'2 Samuel 1')]),
      _day(ps: [_r(19, 40, 'Psalm 40:11–17')],                               to: [_r(2,24,'Exodus 24')],  hi: [_r(10,2,'2 Samuel 2')]),
    ],
    // ── Week 13 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 41, 'Psalm 41:1–4')]),
      _day(ps: [_r(19, 41, 'Psalm 41:5–8')],  nt: [_r(42,16,'Luke 16')],    to: [_r(2,25,'Exodus 25')],  hi: [_r(10,3,'2 Samuel 3')],             wi: [_r(20,13,'Proverbs 13')]),
      _day(ps: [_r(19, 41, 'Psalm 41:9–13')], nt: [_r(42,17,'Luke 17')],    to: [_r(2,26,'Exodus 26')],  hi: [_r(10,4,'2 Samuel 4'),_r(10,5,'2 Samuel 5')]),
      _day(ps: [_r(19, 42, 'Psalm 42:1–5')],  nt: [_r(42,18,'Luke 18')],    to: [_r(2,27,'Exodus 27')],  hi: [_r(10,6,'2 Samuel 6')]),
      _day(ps: [_r(19, 42, 'Psalm 42:6–11')], nt: [_r(42,19,'Luke 19')],    to: [_r(2,28,'Exodus 28')],  hi: [_r(10,7,'2 Samuel 7')],             wi: [_r(18,13,'Job 13')]),
      _day(ps: [_r(19, 43, 'Psalm 43')],       nt: [_r(42,20,'Luke 20')],    to: [_r(2,29,'Exodus 29')],  hi: [_r(10,8,'2 Samuel 8'),_r(10,9,'2 Samuel 9')]),
      _day(ps: [_r(19, 44, 'Psalm 44:1–8')],                                 to: [_r(2,30,'Exodus 30')],  hi: [_r(10,10,'2 Samuel 10')]),
    ],
    // ── Week 14 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 44, 'Psalm 44:9–16')]),
      _day(ps: [_r(19, 44, 'Psalm 44:17–26')],nt: [_r(42,21,'Luke 21')],    to: [_r(2,31,'Exodus 31')],  hi: [_r(10,11,'2 Samuel 11')],           wi: [_r(20,14,'Proverbs 14')]),
      _day(ps: [_r(19, 45, 'Psalm 45:1–9')],  nt: [_r(42,22,'Luke 22')],    to: [_r(2,32,'Exodus 32')],  hi: [_r(10,12,'2 Samuel 12')]),
      _day(ps: [_r(19, 45, 'Psalm 45:10–17')],nt: [_r(42,23,'Luke 23')],    to: [_r(2,33,'Exodus 33')],  hi: [_r(10,13,'2 Samuel 13')]),
      _day(ps: [_r(19, 46, 'Psalm 46:1–5')],  nt: [_r(42,24,'Luke 24')],    to: [_r(2,34,'Exodus 34')],  hi: [_r(10,14,'2 Samuel 14')],           wi: [_r(18,14,'Job 14')]),
      _day(ps: [_r(19, 46, 'Psalm 46:6–11')], nt: [_r(43,1,'John 1')],       to: [_r(2,35,'Exodus 35')],  hi: [_r(10,15,'2 Samuel 15')]),
      _day(ps: [_r(19, 47, 'Psalm 47:1–3')],                                 to: [_r(2,36,'Exodus 36')],  hi: [_r(10,16,'2 Samuel 16')]),
    ],
    // ── Week 15 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 47, 'Psalm 47:4–9')]),
      _day(ps: [_r(19, 48, 'Psalm 48:1–8')],  nt: [_r(43,2,'John 2')],       to: [_r(2,37,'Exodus 37')],  hi: [_r(10,17,'2 Samuel 17')],           wi: [_r(20,15,'Proverbs 15')]),
      _day(ps: [_r(19, 48, 'Psalm 48:9–14')], nt: [_r(43,3,'John 3')],       to: [_r(2,38,'Exodus 38')],  hi: [_r(10,18,'2 Samuel 18')]),
      _day(ps: [_r(19, 49, 'Psalm 49:1–4')],  nt: [_r(43,4,'John 4')],       to: [_r(2,39,'Exodus 39')],  hi: [_r(10,19,'2 Samuel 19')]),
      _day(ps: [_r(19, 49, 'Psalm 49:5–12')], nt: [_r(43,5,'John 5')],       to: [_r(2,40,'Exodus 40')],  hi: [_r(10,20,'2 Samuel 20')],           wi: [_r(18,15,'Job 15')]),
      _day(ps: [_r(19, 49, 'Psalm 49:13–20')],nt: [_r(43,6,'John 6')],       to: [_r(3,1,'Leviticus 1')], hi: [_r(10,21,'2 Samuel 21')]),
      _day(ps: [_r(19, 50, 'Psalm 50:1–6')],                                  to: [_r(3,2,'Leviticus 2'),_r(3,3,'Leviticus 3')], hi: [_r(10,22,'2 Samuel 22')]),
    ],
    // ── Week 16 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 50, 'Psalm 50:7–15')]),
      _day(ps: [_r(19, 50, 'Psalm 50:16–23')],nt: [_r(43,7,'John 7')],       to: [_r(3,4,'Leviticus 4')], hi: [_r(10,23,'2 Samuel 23')],           wi: [_r(20,16,'Proverbs 16')]),
      _day(ps: [_r(19, 51, 'Psalm 51:1–4')],  nt: [_r(43,8,'John 8')],       to: [_r(3,5,'Leviticus 5')], hi: [_r(10,24,'2 Samuel 24')]),
      _day(ps: [_r(19, 51, 'Psalm 51:5–9')],  nt: [_r(43,9,'John 9')],       to: [_r(3,6,'Leviticus 6')], hi: [_r(11,1,'1 Kings 1')]),
      _day(ps: [_r(19, 51, 'Psalm 51:10–13')],nt: [_r(43,10,'John 10')],     to: [_r(3,7,'Leviticus 7')], hi: [_r(11,2,'1 Kings 2')],              wi: [_r(18,16,'Job 16'),_r(18,17,'Job 17')]),
      _day(ps: [_r(19, 51, 'Psalm 51:14–19')],nt: [_r(43,11,'John 11')],     to: [_r(3,8,'Leviticus 8')], hi: [_r(11,3,'1 Kings 3')]),
      _day(ps: [_r(19, 52, 'Psalm 52:1–4')],                                  to: [_r(3,9,'Leviticus 9')], hi: [_r(11,4,'1 Kings 4'),_r(11,5,'1 Kings 5')]),
    ],
    // ── Week 17 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 52, 'Psalm 52:5–9')]),
      _day(ps: [_r(19, 53, 'Psalm 53')],       nt: [_r(43,12,'John 12')],    to: [_r(3,10,'Leviticus 10')],hi: [_r(11,6,'1 Kings 6')],             wi: [_r(20,17,'Proverbs 17')]),
      _day(ps: [_r(19, 54, 'Psalm 54')],        nt: [_r(43,13,'John 13')],    to: [_r(3,11,'Leviticus 11'),_r(3,12,'Leviticus 12')], hi: [_r(11,7,'1 Kings 7')]),
      _day(ps: [_r(19, 55, 'Psalm 55:1–8')],  nt: [_r(43,14,'John 14')],    to: [_r(3,13,'Leviticus 13')],hi: [_r(11,8,'1 Kings 8')]),
      _day(ps: [_r(19, 55, 'Psalm 55:9–19')], nt: [_r(43,15,'John 15')],    to: [_r(3,14,'Leviticus 14')],hi: [_r(11,9,'1 Kings 9')],             wi: [_r(18,18,'Job 18')]),
      _day(ps: [_r(19, 55, 'Psalm 55:20–23')],nt: [_r(43,16,'John 16')],    to: [_r(3,15,'Leviticus 15')],hi: [_r(11,10,'1 Kings 10')]),
      _day(ps: [_r(19, 56, 'Psalm 56:1–7')],                                 to: [_r(3,16,'Leviticus 16')],hi: [_r(11,11,'1 Kings 11')]),
    ],
    // ── Week 18 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 56, 'Psalm 56:8–13')]),
      _day(ps: [_r(19, 57, 'Psalm 57:1–6')],  nt: [_r(43,17,'John 17')],    to: [_r(3,17,'Leviticus 17')],hi: [_r(11,12,'1 Kings 12')],           wi: [_r(20,18,'Proverbs 18')]),
      _day(ps: [_r(19, 57, 'Psalm 57:7–11')], nt: [_r(43,18,'John 18')],    to: [_r(3,18,'Leviticus 18')],hi: [_r(11,13,'1 Kings 13')]),
      _day(ps: [_r(19, 58, 'Psalm 58:1–5')],  nt: [_r(43,19,'John 19')],    to: [_r(3,19,'Leviticus 19')],hi: [_r(11,14,'1 Kings 14')]),
      _day(ps: [_r(19, 58, 'Psalm 58:6–11')], nt: [_r(43,20,'John 20')],    to: [_r(3,20,'Leviticus 20')],hi: [_r(11,15,'1 Kings 15')],           wi: [_r(18,19,'Job 19')]),
      _day(ps: [_r(19, 59, 'Psalm 59:1–7')],  nt: [_r(43,21,'John 21')],    to: [_r(3,21,'Leviticus 21')],hi: [_r(11,16,'1 Kings 16')]),
      _day(ps: [_r(19, 59, 'Psalm 59:8–13')],                                to: [_r(3,22,'Leviticus 22')],hi: [_r(11,17,'1 Kings 17')]),
    ],
    // ── Week 19 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 59, 'Psalm 59:14–17')]),
      _day(ps: [_r(19, 60, 'Psalm 60:1–5')],  nt: [_r(44,1,'Acts 1')],       to: [_r(3,23,'Leviticus 23')],hi: [_r(11,18,'1 Kings 18')],           wi: [_r(20,19,'Proverbs 19')]),
      _day(ps: [_r(19, 60, 'Psalm 60:6–12')], nt: [_r(44,2,'Acts 2')],       to: [_r(3,24,'Leviticus 24')],hi: [_r(11,19,'1 Kings 19')]),
      _day(ps: [_r(19, 61, 'Psalm 61')],       nt: [_r(44,3,'Acts 3')],       to: [_r(3,25,'Leviticus 25')],hi: [_r(11,20,'1 Kings 20')]),
      _day(ps: [_r(19, 62, 'Psalm 62:1–4')],  nt: [_r(44,4,'Acts 4')],       to: [_r(3,26,'Leviticus 26')],hi: [_r(11,21,'1 Kings 21')],           wi: [_r(18,20,'Job 20')]),
      _day(ps: [_r(19, 62, 'Psalm 62:5–8')],  nt: [_r(44,5,'Acts 5')],       to: [_r(3,27,'Leviticus 27')],hi: [_r(11,22,'1 Kings 22')]),
      _day(ps: [_r(19, 62, 'Psalm 62:9–12')],                                 to: [_r(4,1,'Numbers 1')],    hi: [_r(12,1,'2 Kings 1')]),
    ],
    // ── Week 20 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 63, 'Psalm 63:1–4')]),
      _day(ps: [_r(19, 63, 'Psalm 63:5–8')],  nt: [_r(44,6,'Acts 6')],       to: [_r(4,2,'Numbers 2')],    hi: [_r(12,2,'2 Kings 2')],              wi: [_r(20,20,'Proverbs 20')]),
      _day(ps: [_r(19, 63, 'Psalm 63:9–11')], nt: [_r(44,7,'Acts 7')],       to: [_r(4,3,'Numbers 3')],    hi: [_r(12,3,'2 Kings 3')]),
      _day(ps: [_r(19, 64, 'Psalm 64:1–6')],  nt: [_r(44,8,'Acts 8')],       to: [_r(4,4,'Numbers 4')],    hi: [_r(12,4,'2 Kings 4')]),
      _day(ps: [_r(19, 64, 'Psalm 64:7–10')], nt: [_r(44,9,'Acts 9')],       to: [_r(4,5,'Numbers 5')],    hi: [_r(12,5,'2 Kings 5')],              wi: [_r(18,21,'Job 21')]),
      _day(ps: [_r(19, 65, 'Psalm 65:1–4')],  nt: [_r(44,10,'Acts 10')],     to: [_r(4,6,'Numbers 6')],    hi: [_r(12,6,'2 Kings 6')]),
      _day(ps: [_r(19, 65, 'Psalm 65:5–8')],                                  to: [_r(4,7,'Numbers 7')],    hi: [_r(12,7,'2 Kings 7')]),
    ],
    // ── Week 21 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 65, 'Psalm 65:9–13')]),
      _day(ps: [_r(19, 66, 'Psalm 66:1–5')],  nt: [_r(19,18,'Psalm 18')],    to: [_r(4,8,'Numbers 8')],    hi: [_r(12,8,'2 Kings 8')],              wi: [_r(20,21,'Proverbs 21')]),
      _day(ps: [_r(19, 66, 'Psalm 66:6–12')], nt: [_r(19,19,'Psalm 19')],    to: [_r(4,9,'Numbers 9')],    hi: [_r(12,9,'2 Kings 9')]),
      _day(ps: [_r(19, 66, 'Psalm 66:13–16')],nt: [_r(19,20,'Psalm 20'),_r(19,21,'Psalm 21')], to: [_r(4,10,'Numbers 10')], hi: [_r(12,10,'2 Kings 10'),_r(12,11,'2 Kings 11')]),
      _day(ps: [_r(19, 66, 'Psalm 66:17–20')],nt: [_r(19,22,'Psalm 22')],    to: [_r(4,11,'Numbers 11')],  hi: [_r(12,12,'2 Kings 12')],            wi: [_r(18,22,'Job 22')]),
      _day(ps: [_r(19, 67, 'Psalm 67')],       nt: [_r(19,23,'Psalm 23'),_r(19,24,'Psalm 24')], to: [_r(4,12,'Numbers 12'),_r(4,13,'Numbers 13')], hi: [_r(12,13,'2 Kings 13')]),
      _day(ps: [_r(19, 68, 'Psalm 68:1–6')],                                  to: [_r(4,14,'Numbers 14')],  hi: [_r(12,14,'2 Kings 14')]),
    ],
    // ── Week 22 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 68, 'Psalm 68:7–18')]),
      _day(ps: [_r(19, 68, 'Psalm 68:19–23')],nt: [_r(44,11,'Acts 11')],     to: [_r(4,15,'Numbers 15')],  hi: [_r(12,15,'2 Kings 15')],            wi: [_r(20,22,'Proverbs 22')]),
      _day(ps: [_r(19, 68, 'Psalm 68:24–31')],nt: [_r(44,12,'Acts 12')],     to: [_r(4,16,'Numbers 16')],  hi: [_r(12,16,'2 Kings 16')]),
      _day(ps: [_r(19, 68, 'Psalm 68:32–35')],nt: [_r(44,13,'Acts 13')],     to: [_r(4,17,'Numbers 17'),_r(4,18,'Numbers 18')], hi: [_r(12,17,'2 Kings 17')]),
      _day(ps: [_r(19, 69, 'Psalm 69:1–6')],  nt: [_r(44,14,'Acts 14')],     to: [_r(4,19,'Numbers 19')],  hi: [_r(12,18,'2 Kings 18')],            wi: [_r(18,23,'Job 23')]),
      _day(ps: [_r(19, 69, 'Psalm 69:7–12')], nt: [_r(44,15,'Acts 15')],     to: [_r(4,20,'Numbers 20')],  hi: [_r(12,19,'2 Kings 19')]),
      _day(ps: [_r(19, 69, 'Psalm 69:13–18')],                                to: [_r(4,21,'Numbers 21')],  hi: [_r(12,20,'2 Kings 20')]),
    ],
    // ── Week 23 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 69, 'Psalm 69:19–21')]),
      _day(ps: [_r(19, 69, 'Psalm 69:22–28')],nt: [_r(44,16,'Acts 16')],     to: [_r(4,22,'Numbers 22')],  hi: [_r(12,21,'2 Kings 21')],            wi: [_r(20,23,'Proverbs 23')]),
      _day(ps: [_r(19, 69, 'Psalm 69:29–33')],nt: [_r(44,17,'Acts 17')],     to: [_r(4,23,'Numbers 23')],  hi: [_r(12,22,'2 Kings 22')]),
      _day(ps: [_r(19, 69, 'Psalm 69:34–36')],nt: [_r(44,18,'Acts 18')],     to: [_r(4,24,'Numbers 24')],  hi: [_r(12,23,'2 Kings 23')]),
      _day(ps: [_r(19, 70, 'Psalm 70')],       nt: [_r(44,19,'Acts 19')],     to: [_r(4,25,'Numbers 25')],  hi: [_r(12,24,'2 Kings 24')],            wi: [_r(18,24,'Job 24')]),
      _day(ps: [_r(19, 71, 'Psalm 71:1–6')],  nt: [_r(44,20,'Acts 20')],     to: [_r(4,26,'Numbers 26')],  hi: [_r(12,25,'2 Kings 25')]),
      _day(ps: [_r(19, 71, 'Psalm 71:7–18')],                                 to: [_r(4,27,'Numbers 27')],  hi: [_r(13,1,'1 Chronicles 1'),_r(13,2,'1 Chronicles 2')]),
    ],
    // ── Week 24 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 71, 'Psalm 71:19–24')]),
      _day(ps: [_r(19, 72, 'Psalm 72:1–7')],  nt: [_r(44,21,'Acts 21')],     to: [_r(4,28,'Numbers 28')],  hi: [_r(13,3,'1 Chronicles 3'),_r(13,4,'1 Chronicles 4')], wi: [_r(20,24,'Proverbs 24')]),
      _day(ps: [_r(19, 72, 'Psalm 72:8–14')], nt: [_r(44,22,'Acts 22')],     to: [_r(4,29,'Numbers 29')],  hi: [_r(13,5,'1 Chronicles 5'),_r(13,6,'1 Chronicles 6')]),
      _day(ps: [_r(19, 72, 'Psalm 72:15–20')],nt: [_r(44,23,'Acts 23')],     to: [_r(4,30,'Numbers 30')],  hi: [_r(13,7,'1 Chronicles 7'),_r(13,8,'1 Chronicles 8')]),
      _day(ps: [_r(19, 73, 'Psalm 73:1–3')],  nt: [_r(44,24,'Acts 24')],     to: [_r(4,31,'Numbers 31')],  hi: [_r(13,9,'1 Chronicles 9'),_r(13,10,'1 Chronicles 10')], wi: [_r(18,25,'Job 25'),_r(18,26,'Job 26')]),
      _day(ps: [_r(19, 73, 'Psalm 73:4–9')],  nt: [_r(44,25,'Acts 25')],     to: [_r(4,32,'Numbers 32')],  hi: [_r(13,11,'1 Chronicles 11'),_r(13,12,'1 Chronicles 12')]),
      _day(ps: [_r(19, 73, 'Psalm 73:10–14')],                                to: [_r(4,33,'Numbers 33')],  hi: [_r(13,13,'1 Chronicles 13'),_r(13,14,'1 Chronicles 14')]),
    ],
    // ── Week 25 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 73, 'Psalm 73:15–20')]),
      _day(ps: [_r(19, 73, 'Psalm 73:21–23')],nt: [_r(44,26,'Acts 26')],     to: [_r(4,34,'Numbers 34')],  hi: [_r(13,15,'1 Chronicles 15')],       wi: [_r(20,25,'Proverbs 25')]),
      _day(ps: [_r(19, 73, 'Psalm 73:24–28')],nt: [_r(44,27,'Acts 27')],     to: [_r(4,35,'Numbers 35')],  hi: [_r(13,16,'1 Chronicles 16')]),
      _day(ps: [_r(19, 74, 'Psalm 74:1–8')],  nt: [_r(44,28,'Acts 28')],     to: [_r(4,36,'Numbers 36')],  hi: [_r(13,17,'1 Chronicles 17')]),
      _day(ps: [_r(19, 74, 'Psalm 74:9–17')], nt: [_r(45,1,'Romans 1')],     to: [_r(5,1,'Deuteronomy 1')],hi: [_r(13,18,'1 Chronicles 18')],       wi: [_r(18,27,'Job 27')]),
      _day(ps: [_r(19, 74, 'Psalm 74:18–23')],nt: [_r(45,2,'Romans 2')],     to: [_r(5,2,'Deuteronomy 2')],hi: [_r(13,19,'1 Chronicles 19'),_r(13,20,'1 Chronicles 20')]),
      _day(ps: [_r(19, 75, 'Psalm 75:1–5')],                                  to: [_r(5,3,'Deuteronomy 3')],hi: [_r(13,21,'1 Chronicles 21')]),
    ],
    // ── Week 26 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 75, 'Psalm 75:6–10')]),
      _day(ps: [_r(19, 76, 'Psalm 76:1–6')],  nt: [_r(45,3,'Romans 3')],     to: [_r(5,4,'Deuteronomy 4')],hi: [_r(13,22,'1 Chronicles 22')],       wi: [_r(20,26,'Proverbs 26')]),
      _day(ps: [_r(19, 76, 'Psalm 76:7–12')], nt: [_r(45,4,'Romans 4')],     to: [_r(5,5,'Deuteronomy 5')],hi: [_r(13,23,'1 Chronicles 23')]),
      _day(ps: [_r(19, 77, 'Psalm 77:1–4')],  nt: [_r(45,5,'Romans 5')],     to: [_r(5,6,'Deuteronomy 6')],hi: [_r(13,24,'1 Chronicles 24'),_r(13,25,'1 Chronicles 25')]),
      _day(ps: [_r(19, 77, 'Psalm 77:5–9')],  nt: [_r(45,6,'Romans 6')],     to: [_r(5,7,'Deuteronomy 7')],hi: [_r(13,26,'1 Chronicles 26'),_r(13,27,'1 Chronicles 27')], wi: [_r(18,29,'Job 29')]),
      _day(ps: [_r(19, 77, 'Psalm 77:10–15')],nt: [_r(45,7,'Romans 7')],     to: [_r(5,8,'Deuteronomy 8')],hi: [_r(13,28,'1 Chronicles 28')]),
      _day(ps: [_r(19, 77, 'Psalm 77:16–20')],                                to: [_r(5,9,'Deuteronomy 9')],hi: [_r(13,29,'1 Chronicles 29')]),
    ],
    // ── Week 27 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 78, 'Psalm 78:1–8')]),
      _day(ps: [_r(19, 78, 'Psalm 78:9–16')], nt: [_r(45,8,'Romans 8')],     to: [_r(5,10,'Deuteronomy 10')],hi: [_r(14,1,'2 Chronicles 1')],       wi: [_r(20,27,'Proverbs 27')]),
      _day(ps: [_r(19, 78, 'Psalm 78:17–25')],nt: [_r(45,9,'Romans 9')],     to: [_r(5,11,'Deuteronomy 11')],hi: [_r(14,2,'2 Chronicles 2')]),
      _day(ps: [_r(19, 78, 'Psalm 78:26–31')],nt: [_r(45,10,'Romans 10')],   to: [_r(5,12,'Deuteronomy 12')],hi: [_r(14,3,'2 Chronicles 3'),_r(14,4,'2 Chronicles 4')]),
      _day(ps: [_r(19, 78, 'Psalm 78:32–37')],nt: [_r(45,11,'Romans 11')],   to: [_r(5,13,'Deuteronomy 13'),_r(5,14,'Deuteronomy 14')], hi: [_r(14,5,'2 Chronicles 5')], wi: [_r(18,29,'Job 29')]),
      _day(ps: [_r(19, 78, 'Psalm 78:38–43')],nt: [_r(45,12,'Romans 12')],   to: [_r(5,15,'Deuteronomy 15')],hi: [_r(14,6,'2 Chronicles 6')]),
      _day(ps: [_r(19, 78, 'Psalm 78:44–53')],                                to: [_r(5,16,'Deuteronomy 16')],hi: [_r(14,7,'2 Chronicles 7')]),
    ],
    // ── Week 28 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 78, 'Psalm 78:54–58')]),
      _day(ps: [_r(19, 78, 'Psalm 78:59–64')],nt: [_r(45,13,'Romans 13')],   to: [_r(5,17,'Deuteronomy 17')],hi: [_r(14,8,'2 Chronicles 8')],       wi: [_r(20,28,'Proverbs 28')]),
      _day(ps: [_r(19, 78, 'Psalm 78:65–72')],nt: [_r(45,14,'Romans 14')],   to: [_r(5,18,'Deuteronomy 18')],hi: [_r(14,9,'2 Chronicles 9')]),
      _day(ps: [_r(19, 79, 'Psalm 79:1–8')],  nt: [_r(45,15,'Romans 15')],   to: [_r(5,19,'Deuteronomy 19')],hi: [_r(14,10,'2 Chronicles 10')]),
      _day(ps: [_r(19, 79, 'Psalm 79:9–13')], nt: [_r(45,16,'Romans 16')],   to: [_r(5,20,'Deuteronomy 20')],hi: [_r(14,11,'2 Chronicles 11'),_r(14,12,'2 Chronicles 12')], wi: [_r(18,30,'Job 30')]),
      _day(ps: [_r(19, 80, 'Psalm 80:1–7')],  nt: [_r(46,1,'1 Corinthians 1')], to: [_r(5,21,'Deuteronomy 21')], hi: [_r(14,13,'2 Chronicles 13')]),
      _day(ps: [_r(19, 80, 'Psalm 80:8–13')],                                 to: [_r(5,22,'Deuteronomy 22')],hi: [_r(14,14,'2 Chronicles 14'),_r(14,15,'2 Chronicles 15')]),
    ],
    // ── Week 29 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 80, 'Psalm 80:14–19')]),
      _day(ps: [_r(19, 81, 'Psalm 81:1–4')],  nt: [_r(46,2,'1 Corinthians 2')], to: [_r(5,23,'Deuteronomy 23')], hi: [_r(14,16,'2 Chronicles 16')], wi: [_r(20,29,'Proverbs 29')]),
      _day(ps: [_r(19, 81, 'Psalm 81:5–10')], nt: [_r(46,3,'1 Corinthians 3')], to: [_r(5,24,'Deuteronomy 24')], hi: [_r(14,17,'2 Chronicles 17')]),
      _day(ps: [_r(19, 81, 'Psalm 81:11–16')],nt: [_r(46,4,'1 Corinthians 4')], to: [_r(5,25,'Deuteronomy 25')], hi: [_r(14,18,'2 Chronicles 18')]),
      _day(ps: [_r(19, 82, 'Psalm 82')],       nt: [_r(46,5,'1 Corinthians 5')], to: [_r(5,26,'Deuteronomy 26')], hi: [_r(14,19,'2 Chronicles 19'),_r(14,20,'2 Chronicles 20')], wi: [_r(18,31,'Job 31')]),
      _day(ps: [_r(19, 83, 'Psalm 83:1–8')],  nt: [_r(46,6,'1 Corinthians 6')], to: [_r(5,27,'Deuteronomy 27')], hi: [_r(14,21,'2 Chronicles 21')]),
      _day(ps: [_r(19, 83, 'Psalm 83:9–13')],                                 to: [_r(5,28,'Deuteronomy 28')],hi: [_r(14,22,'2 Chronicles 22'),_r(14,23,'2 Chronicles 23')]),
    ],
    // ── Week 30 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 83, 'Psalm 83:14–18')]),
      _day(ps: [_r(19, 84, 'Psalm 84:1–4')],  nt: [_r(46,7,'1 Corinthians 7')], to: [_r(5,29,'Deuteronomy 29')], hi: [_r(14,24,'2 Chronicles 24')], wi: [_r(20,30,'Proverbs 30')]),
      _day(ps: [_r(19, 84, 'Psalm 84:5–8')],  nt: [_r(46,8,'1 Corinthians 8')], to: [_r(5,30,'Deuteronomy 30')], hi: [_r(14,25,'2 Chronicles 25')]),
      _day(ps: [_r(19, 84, 'Psalm 84:9–12')], nt: [_r(46,9,'1 Corinthians 9')], to: [_r(5,31,'Deuteronomy 31')], hi: [_r(14,26,'2 Chronicles 26')]),
      _day(ps: [_r(19, 85, 'Psalm 85:1–8')],  nt: [_r(46,10,'1 Corinthians 10')],to: [_r(5,32,'Deuteronomy 32')],hi: [_r(14,27,'2 Chronicles 27'),_r(14,28,'2 Chronicles 28')], wi: [_r(18,32,'Job 32')]),
      _day(ps: [_r(19, 85, 'Psalm 85:9–13')], nt: [_r(46,11,'1 Corinthians 11')],to: [_r(5,33,'Deuteronomy 33'),_r(5,34,'Deuteronomy 34')], hi: [_r(14,29,'2 Chronicles 29')]),
      // Torah ends; Prophetic begins
      _day(ps: [_r(19, 86, 'Psalm 86:1–7')],  pr: [_r(23,1,'Isaiah 1'),_r(23,2,'Isaiah 2')], hi: [_r(14,30,'2 Chronicles 30')]),
    ],
    // ── Week 31 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 86, 'Psalm 86:8–13')]),
      _day(ps: [_r(19, 86, 'Psalm 86:14–17')],nt: [_r(46,12,'1 Corinthians 12')],pr: [_r(23,3,'Isaiah 3'),_r(23,4,'Isaiah 4'),_r(23,5,'Isaiah 5')], hi: [_r(14,31,'2 Chronicles 31')], wi: [_r(20,31,'Proverbs 31')]),
      _day(ps: [_r(19, 87, 'Psalm 87')],       nt: [_r(46,13,'1 Corinthians 13')],pr: [_r(23,6,'Isaiah 6'),_r(23,7,'Isaiah 7')],   hi: [_r(14,32,'2 Chronicles 32')]),
      _day(ps: [_r(19, 88, 'Psalm 88:1–9')],  nt: [_r(46,14,'1 Corinthians 14')],pr: [_r(23,8,'Isaiah 8'),_r(23,9,'Isaiah 9')],   hi: [_r(14,33,'2 Chronicles 33')]),
      _day(ps: [_r(19, 88, 'Psalm 88:10–18')],nt: [_r(46,15,'1 Corinthians 15')],pr: [_r(23,10,'Isaiah 10'),_r(23,11,'Isaiah 11'),_r(23,12,'Isaiah 12')], hi: [_r(14,34,'2 Chronicles 34')], wi: [_r(18,33,'Job 33')]),
      _day(ps: [_r(19, 89, 'Psalm 89:1–8')],  nt: [_r(46,16,'1 Corinthians 16')],pr: [_r(23,13,'Isaiah 13'),_r(23,14,'Isaiah 14')], hi: [_r(14,35,'2 Chronicles 35')]),
      _day(ps: [_r(19, 89, 'Psalm 89:9–18')],  pr: [_r(23,15,'Isaiah 15'),_r(23,16,'Isaiah 16')], hi: [_r(14,36,'2 Chronicles 36')]),
    ],
    // ── Week 32 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 89, 'Psalm 89:19–26')]),
      _day(ps: [_r(19, 89, 'Psalm 89:27–37')],nt: [_r(47,1,'2 Corinthians 1')],pr: [_r(23,17,'Isaiah 17'),_r(23,18,'Isaiah 18'),_r(23,19,'Isaiah 19'),_r(23,20,'Isaiah 20')], hi: [_r(15,1,'Ezra 1')], wi: [_r(21,1,'Ecclesiastes 1')]),
      _day(ps: [_r(19, 89, 'Psalm 89:38–45')],nt: [_r(47,2,'2 Corinthians 2')],pr: [_r(23,21,'Isaiah 21'),_r(23,22,'Isaiah 22')], hi: [_r(15,2,'Ezra 2')]),
      _day(ps: [_r(19, 89, 'Psalm 89:46–52')],nt: [_r(47,3,'2 Corinthians 3')],pr: [_r(23,23,'Isaiah 23'),_r(23,24,'Isaiah 24')], hi: [_r(15,3,'Ezra 3')]),
      _day(ps: [_r(19, 90, 'Psalm 90:1–4')],  nt: [_r(47,4,'2 Corinthians 4')],pr: [_r(23,25,'Isaiah 25'),_r(23,26,'Isaiah 26')], hi: [_r(15,4,'Ezra 4')],  wi: [_r(18,34,'Job 34')]),
      _day(ps: [_r(19, 90, 'Psalm 90:5–12')], nt: [_r(47,5,'2 Corinthians 5')],pr: [_r(23,27,'Isaiah 27'),_r(23,28,'Isaiah 28')], hi: [_r(15,5,'Ezra 5')]),
      _day(ps: [_r(19, 90, 'Psalm 90:13–17')], pr: [_r(23,29,'Isaiah 29'),_r(23,30,'Isaiah 30')], hi: [_r(15,6,'Ezra 6')]),
    ],
    // ── Week 33 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 91, 'Psalm 91:1–4')]),
      _day(ps: [_r(19, 91, 'Psalm 91:5–13')], nt: [_r(47,6,'2 Corinthians 6')],pr: [_r(23,31,'Isaiah 31'),_r(23,32,'Isaiah 32')], hi: [_r(15,7,'Ezra 7')],  wi: [_r(21,2,'Ecclesiastes 2')]),
      _day(ps: [_r(19, 91, 'Psalm 91:14–16')],nt: [_r(47,7,'2 Corinthians 7')],pr: [_r(23,33,'Isaiah 33'),_r(23,34,'Isaiah 34')], hi: [_r(15,8,'Ezra 8')]),
      _day(ps: [_r(19, 92, 'Psalm 92:1–4')],  nt: [_r(47,8,'2 Corinthians 8')],pr: [_r(23,35,'Isaiah 35'),_r(23,36,'Isaiah 36')], hi: [_r(15,9,'Ezra 9')]),
      _day(ps: [_r(19, 92, 'Psalm 92:5–9')],  nt: [_r(47,9,'2 Corinthians 9')],pr: [_r(23,37,'Isaiah 37'),_r(23,38,'Isaiah 38')], hi: [_r(15,10,'Ezra 10')], wi: [_r(18,35,'Job 35')]),
      _day(ps: [_r(19, 92, 'Psalm 92:10–15')],nt: [_r(47,10,'2 Corinthians 10')],pr: [_r(23,39,'Isaiah 39'),_r(23,40,'Isaiah 40')], hi: [_r(16,1,'Nehemiah 1')]),
      _day(ps: [_r(19, 93, 'Psalm 93')],        pr: [_r(23,41,'Isaiah 41'),_r(23,42,'Isaiah 42')], hi: [_r(16,2,'Nehemiah 2')]),
    ],
    // ── Week 34 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 94, 'Psalm 94:1–10')]),
      _day(ps: [_r(19, 94, 'Psalm 94:11–15')],nt: [_r(47,11,'2 Corinthians 11')],pr: [_r(23,43,'Isaiah 43'),_r(23,44,'Isaiah 44')], hi: [_r(16,3,'Nehemiah 3')], wi: [_r(21,3,'Ecclesiastes 3')]),
      _day(ps: [_r(19, 94, 'Psalm 94:16–23')],nt: [_r(47,12,'2 Corinthians 12')],pr: [_r(23,45,'Isaiah 45'),_r(23,46,'Isaiah 46')], hi: [_r(16,4,'Nehemiah 4')]),
      _day(ps: [_r(19, 95, 'Psalm 95:1–4')],  nt: [_r(47,13,'2 Corinthians 13')],pr: [_r(23,47,'Isaiah 47'),_r(23,48,'Isaiah 48')], hi: [_r(16,5,'Nehemiah 5')]),
      _day(ps: [_r(19, 95, 'Psalm 95:5–7')],  nt: [_r(48,1,'Galatians 1')],  pr: [_r(23,49,'Isaiah 49'),_r(23,50,'Isaiah 50')], hi: [_r(16,6,'Nehemiah 6')], wi: [_r(18,36,'Job 36')]),
      _day(ps: [_r(19, 95, 'Psalm 95:8–11')], nt: [_r(48,2,'Galatians 2')],  pr: [_r(23,51,'Isaiah 51'),_r(23,52,'Isaiah 52')], hi: [_r(16,7,'Nehemiah 7')]),
      _day(ps: [_r(19, 96, 'Psalm 96:1–9')],   pr: [_r(23,53,'Isaiah 53'),_r(23,54,'Isaiah 54')], hi: [_r(16,8,'Nehemiah 8')]),
    ],
    // ── Week 35 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 96, 'Psalm 96:10–13')]),
      _day(ps: [_r(19, 97, 'Psalm 97:1–5')],  nt: [_r(48,3,'Galatians 3')],  pr: [_r(23,55,'Isaiah 55'),_r(23,56,'Isaiah 56')], hi: [_r(16,9,'Nehemiah 9')],  wi: [_r(21,4,'Ecclesiastes 4')]),
      _day(ps: [_r(19, 97, 'Psalm 97:6–9')],  nt: [_r(48,4,'Galatians 4')],  pr: [_r(23,57,'Isaiah 57'),_r(23,58,'Isaiah 58')], hi: [_r(16,10,'Nehemiah 10')]),
      _day(ps: [_r(19, 97, 'Psalm 97:10–12')],nt: [_r(48,5,'Galatians 5')],  pr: [_r(23,59,'Isaiah 59'),_r(23,60,'Isaiah 60')], hi: [_r(16,11,'Nehemiah 11')]),
      _day(ps: [_r(19, 98, 'Psalm 98:1–6')],  nt: [_r(48,6,'Galatians 6')],  pr: [_r(23,61,'Isaiah 61'),_r(23,62,'Isaiah 62')], hi: [_r(16,12,'Nehemiah 12')], wi: [_r(18,37,'Job 37')]),
      _day(ps: [_r(19, 98, 'Psalm 98:7–9')],  nt: [_r(49,1,'Ephesians 1')],  pr: [_r(23,63,'Isaiah 63'),_r(23,64,'Isaiah 64')], hi: [_r(16,13,'Nehemiah 13')]),
      _day(ps: [_r(19, 99, 'Psalm 99:1–5')],   pr: [_r(23,65,'Isaiah 65'),_r(23,66,'Isaiah 66')], hi: [_r(17,1,'Esther 1')]),
    ],
    // ── Week 36 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19, 99, 'Psalm 99:6–9')]),
      _day(ps: [_r(19,100, 'Psalm 100')],      nt: [_r(49,2,'Ephesians 2')],  pr: [_r(24,1,'Jeremiah 1'),_r(24,2,'Jeremiah 2')],   hi: [_r(17,2,'Esther 2')],   wi: [_r(21,5,'Ecclesiastes 5')]),
      _day(ps: [_r(19,101, 'Psalm 101')],       nt: [_r(49,3,'Ephesians 3')],  pr: [_r(24,3,'Jeremiah 3'),_r(24,4,'Jeremiah 4')],   hi: [_r(17,3,'Esther 3')]),
      _day(ps: [_r(19,102, 'Psalm 102:1–11')], nt: [_r(49,4,'Ephesians 4')],  pr: [_r(24,5,'Jeremiah 5'),_r(24,6,'Jeremiah 6')],   hi: [_r(17,4,'Esther 4')]),
      _day(ps: [_r(19,102, 'Psalm 102:12–17')],nt: [_r(49,5,'Ephesians 5')],  pr: [_r(24,7,'Jeremiah 7'),_r(24,8,'Jeremiah 8')],   hi: [_r(17,5,'Esther 5')],   wi: [_r(18,38,'Job 38')]),
      _day(ps: [_r(19,102, 'Psalm 102:18–22')],nt: [_r(49,6,'Ephesians 6')],  pr: [_r(24,9,'Jeremiah 9'),_r(24,10,'Jeremiah 10')], hi: [_r(17,6,'Esther 6')]),
      _day(ps: [_r(19,102, 'Psalm 102:23–28')], pr: [_r(24,11,'Jeremiah 11'),_r(24,12,'Jeremiah 12')], hi: [_r(17,7,'Esther 7')]),
    ],
    // ── Week 37 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,103, 'Psalm 103:1–5')]),
      _day(ps: [_r(19,103, 'Psalm 103:6–12')], nt: [_r(50,1,'Philippians 1')],pr: [_r(24,13,'Jeremiah 13'),_r(24,14,'Jeremiah 14')], hi: [_r(17,8,'Esther 8')], wi: [_r(21,6,'Ecclesiastes 6')]),
      _day(ps: [_r(19,103, 'Psalm 103:13–18')],nt: [_r(50,2,'Philippians 2')],pr: [_r(24,15,'Jeremiah 15'),_r(24,16,'Jeremiah 16')], hi: [_r(17,9,'Esther 9'),_r(17,10,'Esther 10')]),
      _day(ps: [_r(19,103, 'Psalm 103:19–22')],nt: [_r(50,3,'Philippians 3')],pr: [_r(24,17,'Jeremiah 17'),_r(24,18,'Jeremiah 18')]),
      _day(ps: [_r(19,104, 'Psalm 104:1–4')],  nt: [_r(50,4,'Philippians 4')],pr: [_r(24,19,'Jeremiah 19'),_r(24,20,'Jeremiah 20')],                            wi: [_r(18,39,'Job 39')]),
      _day(ps: [_r(19,104, 'Psalm 104:5–9')],  nt: [_r(51,1,'Colossians 1')], pr: [_r(24,21,'Jeremiah 21'),_r(24,22,'Jeremiah 22')]),
      _day(ps: [_r(19,104, 'Psalm 104:10–13')], pr: [_r(24,23,'Jeremiah 23'),_r(24,24,'Jeremiah 24')]),
    ],
    // ── Week 38 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,104, 'Psalm 104:14–18')]),
      _day(ps: [_r(19,104, 'Psalm 104:19–24')],nt: [_r(51,2,'Colossians 2')], pr: [_r(24,25,'Jeremiah 25'),_r(24,26,'Jeremiah 26')],                            wi: [_r(21,7,'Ecclesiastes 7')]),
      _day(ps: [_r(19,104, 'Psalm 104:25–29')],nt: [_r(51,3,'Colossians 3')], pr: [_r(24,27,'Jeremiah 27'),_r(24,28,'Jeremiah 28')]),
      _day(ps: [_r(19,104, 'Psalm 104:30–35')],nt: [_r(51,4,'Colossians 4')], pr: [_r(24,29,'Jeremiah 29'),_r(24,30,'Jeremiah 30'),_r(24,31,'Jeremiah 31')]),
      _day(ps: [_r(19,105, 'Psalm 105:1–7')],  nt: [_r(52,1,'1 Thessalonians 1')], pr: [_r(24,32,'Jeremiah 32'),_r(24,33,'Jeremiah 33')],                       wi: [_r(18,40,'Job 40')]),
      _day(ps: [_r(19,105, 'Psalm 105:8–11')], nt: [_r(52,2,'1 Thessalonians 2')], pr: [_r(24,34,'Jeremiah 34'),_r(24,35,'Jeremiah 35')]),
      _day(ps: [_r(19,105, 'Psalm 105:12–15')], pr: [_r(24,36,'Jeremiah 36'),_r(24,37,'Jeremiah 37')]),
    ],
    // ── Week 39 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,105, 'Psalm 105:16–22')]),
      _day(ps: [_r(19,105, 'Psalm 105:23–25')],nt: [_r(52,3,'1 Thessalonians 3')], pr: [_r(24,38,'Jeremiah 38'),_r(24,39,'Jeremiah 39')],                       wi: [_r(21,8,'Ecclesiastes 8')]),
      _day(ps: [_r(19,105, 'Psalm 105:26–36')],nt: [_r(52,4,'1 Thessalonians 4')], pr: [_r(24,40,'Jeremiah 40'),_r(24,41,'Jeremiah 41')]),
      _day(ps: [_r(19,105, 'Psalm 105:37–42')],nt: [_r(52,5,'1 Thessalonians 5')], pr: [_r(24,42,'Jeremiah 42'),_r(24,43,'Jeremiah 43')]),
      _day(ps: [_r(19,105, 'Psalm 105:43–45')],nt: [_r(53,1,'2 Thessalonians 1')], pr: [_r(24,44,'Jeremiah 44'),_r(24,45,'Jeremiah 45'),_r(24,46,'Jeremiah 46')], wi: [_r(18,41,'Job 41')]),
      _day(ps: [_r(19,106, 'Psalm 106:1–5')],  nt: [_r(53,2,'2 Thessalonians 2')], pr: [_r(24,47,'Jeremiah 47'),_r(24,48,'Jeremiah 48')]),
      _day(ps: [_r(19,106, 'Psalm 106:6–12')],  pr: [_r(24,49,'Jeremiah 49'),_r(24,50,'Jeremiah 50')]),
    ],
    // ── Week 40 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,106, 'Psalm 106:13–18')]),
      _day(ps: [_r(19,106, 'Psalm 106:19–23')],nt: [_r(53,3,'2 Thessalonians 3')], pr: [_r(24,51,'Jeremiah 51'),_r(24,52,'Jeremiah 52')],                       wi: [_r(21,9,'Ecclesiastes 9')]),
      _day(ps: [_r(19,106, 'Psalm 106:24–31')],nt: [_r(54,1,'1 Timothy 1')],  pr: [_r(25,1,'Lamentations 1'),_r(25,2,'Lamentations 2')]),
      _day(ps: [_r(19,106, 'Psalm 106:32–39')],nt: [_r(54,2,'1 Timothy 2')],  pr: [_r(25,3,'Lamentations 3'),_r(25,4,'Lamentations 4')]),
      _day(ps: [_r(19,106, 'Psalm 106:40–48')],nt: [_r(54,3,'1 Timothy 3')],  pr: [_r(25,5,'Lamentations 5'),_r(26,1,'Ezekiel 1')],                            wi: [_r(18,42,'Job 42')]),
      _day(ps: [_r(19,107, 'Psalm 107:1–9')],  nt: [_r(54,4,'1 Timothy 4')],  pr: [_r(26,2,'Ezekiel 2'),_r(26,3,'Ezekiel 3')]),
      _day(ps: [_r(19,107, 'Psalm 107:10–16')], pr: [_r(26,4,'Ezekiel 4'),_r(26,5,'Ezekiel 5')]),
    ],
    // ── Week 41 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,107, 'Psalm 107:17–22')]),
      _day(ps: [_r(19,107, 'Psalm 107:23–32')],nt: [_r(54,5,'1 Timothy 5')],  pr: [_r(26,6,'Ezekiel 6'),_r(26,7,'Ezekiel 7')],                                wi: [_r(21,10,'Ecclesiastes 10')]),
      _day(ps: [_r(19,107, 'Psalm 107:33–43')],nt: [_r(54,6,'1 Timothy 6')],  pr: [_r(26,8,'Ezekiel 8'),_r(26,9,'Ezekiel 9')]),
      _day(ps: [_r(19,108, 'Psalm 108:1–4')],  nt: [_r(55,1,'2 Timothy 1')],  pr: [_r(26,10,'Ezekiel 10'),_r(26,11,'Ezekiel 11')]),
      _day(ps: [_r(19,108, 'Psalm 108:5–13')], nt: [_r(55,2,'2 Timothy 2')],  pr: [_r(26,12,'Ezekiel 12'),_r(26,13,'Ezekiel 13')]),
      _day(ps: [_r(19,109, 'Psalm 109:1–5')],  nt: [_r(55,3,'2 Timothy 3')],  pr: [_r(26,14,'Ezekiel 14'),_r(26,15,'Ezekiel 15')]),
      _day(ps: [_r(19,109, 'Psalm 109:6–15')],  pr: [_r(26,16,'Ezekiel 16'),_r(26,17,'Ezekiel 17')]),
    ],
    // ── Week 42 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,109, 'Psalm 109:16–20')]),
      _day(ps: [_r(19,109, 'Psalm 109:21–29')],nt: [_r(55,4,'2 Timothy 4')],  pr: [_r(26,18,'Ezekiel 18'),_r(26,19,'Ezekiel 19')],                            wi: [_r(21,11,'Ecclesiastes 11')]),
      _day(ps: [_r(19,109, 'Psalm 109')],       nt: [_r(56,1,'Titus 1')],      pr: [_r(26,20,'Ezekiel 20'),_r(26,21,'Ezekiel 21')]),
      _day(ps: [_r(19,110, 'Psalm 110')],        nt: [_r(56,2,'Titus 2')],      pr: [_r(26,22,'Ezekiel 22'),_r(26,23,'Ezekiel 23')]),
      _day(ps: [_r(19,111, 'Psalm 111')],        nt: [_r(56,3,'Titus 3')],      pr: [_r(26,24,'Ezekiel 24'),_r(26,25,'Ezekiel 25')]),
      _day(ps: [_r(19,112, 'Psalm 112')],        nt: [_r(57,1,'Philemon 1')],   pr: [_r(26,26,'Ezekiel 26'),_r(26,27,'Ezekiel 27')]),
      _day(ps: [_r(19,113, 'Psalm 113')],         pr: [_r(26,28,'Ezekiel 28'),_r(26,29,'Ezekiel 29')]),
    ],
    // ── Week 43 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,114, 'Psalm 114')]),
      _day(ps: [_r(19,115, 'Psalm 115:1–8')],  nt: [_r(58,1,'Hebrews 1')],   pr: [_r(26,30,'Ezekiel 30'),_r(26,31,'Ezekiel 31')],                            wi: [_r(21,12,'Ecclesiastes 12')]),
      _day(ps: [_r(19,115, 'Psalm 115:9–18')], nt: [_r(58,2,'Hebrews 2')],   pr: [_r(26,32,'Ezekiel 32'),_r(26,33,'Ezekiel 33')]),
      _day(ps: [_r(19,116, 'Psalm 116:1–11')], nt: [_r(58,3,'Hebrews 3')],   pr: [_r(26,34,'Ezekiel 34'),_r(26,35,'Ezekiel 35')]),
      _day(ps: [_r(19,116, 'Psalm 116:12–19')],nt: [_r(58,4,'Hebrews 4')],   pr: [_r(26,36,'Ezekiel 36'),_r(26,37,'Ezekiel 37')]),
      _day(ps: [_r(19,117, 'Psalm 117')],       nt: [_r(58,5,'Hebrews 5')],   pr: [_r(26,38,'Ezekiel 38'),_r(26,39,'Ezekiel 39')]),
      _day(ps: [_r(19,118, 'Psalm 118:1–9')],   pr: [_r(26,40,'Ezekiel 40'),_r(26,41,'Ezekiel 41')]),
    ],
    // ── Week 44 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,118, 'Psalm 118:10–18')]),
      _day(ps: [_r(19,118, 'Psalm 118:19–29')],nt: [_r(58,6,'Hebrews 6')],   pr: [_r(26,42,'Ezekiel 42'),_r(26,43,'Ezekiel 43')],                            wi: [_r(22,1,'Song of Solomon 1')]),
      _day(ps: [_r(19,119, 'Psalm 119:1–8')],  nt: [_r(58,7,'Hebrews 7')],   pr: [_r(26,44,'Ezekiel 44'),_r(26,45,'Ezekiel 45')]),
      _day(ps: [_r(19,119, 'Psalm 119:9–16')], nt: [_r(58,8,'Hebrews 8')],   pr: [_r(26,46,'Ezekiel 46'),_r(26,47,'Ezekiel 47')]),
      _day(ps: [_r(19,119, 'Psalm 119:17–24')],nt: [_r(58,9,'Hebrews 9')],   pr: [_r(26,48,'Ezekiel 48'),_r(27,1,'Daniel 1')]),
      _day(ps: [_r(19,119, 'Psalm 119:25–32')],nt: [_r(58,10,'Hebrews 10')], pr: [_r(27,2,'Daniel 2'),_r(27,3,'Daniel 3')]),
      _day(ps: [_r(19,119, 'Psalm 119:33–40')], pr: [_r(27,4,'Daniel 4'),_r(27,5,'Daniel 5')]),
    ],
    // ── Week 45 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,119, 'Psalm 119:41–48')]),
      _day(ps: [_r(19,119, 'Psalm 119:49–56')],nt: [_r(58,11,'Hebrews 11')], pr: [_r(27,6,'Daniel 6'),_r(27,7,'Daniel 7')],                                   wi: [_r(22,2,'Song of Solomon 2')]),
      _day(ps: [_r(19,119, 'Psalm 119:57–64')],nt: [_r(58,12,'Hebrews 12')], pr: [_r(27,8,'Daniel 8'),_r(27,9,'Daniel 9')]),
      _day(ps: [_r(19,119, 'Psalm 119:65–72')],nt: [_r(58,13,'Hebrews 13')], pr: [_r(27,10,'Daniel 10'),_r(27,11,'Daniel 11')]),
      _day(ps: [_r(19,119, 'Psalm 119:73–80')],nt: [_r(59,1,'James 1')],      pr: [_r(27,12,'Daniel 12'),_r(28,1,'Hosea 1')]),
      _day(ps: [_r(19,119, 'Psalm 119:81–88')],nt: [_r(59,2,'James 2')],      pr: [_r(28,2,'Hosea 2'),_r(28,3,'Hosea 3'),_r(28,4,'Hosea 4')]),
      _day(ps: [_r(19,119, 'Psalm 119:89–96')], pr: [_r(28,5,'Hosea 5'),_r(28,6,'Hosea 6'),_r(28,7,'Hosea 7')]),
    ],
    // ── Week 46 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,119, 'Psalm 119:97–104')]),
      _day(ps: [_r(19,119, 'Psalm 119:105–112')],nt: [_r(59,3,'James 3')],   pr: [_r(28,8,'Hosea 8'),_r(28,9,'Hosea 9')],                                     wi: [_r(22,3,'Song of Solomon 3')]),
      _day(ps: [_r(19,119, 'Psalm 119:113–120')],nt: [_r(59,4,'James 4')],   pr: [_r(28,10,'Hosea 10'),_r(28,11,'Hosea 11')]),
      _day(ps: [_r(19,119, 'Psalm 119:121–128')],nt: [_r(59,5,'James 5')],   pr: [_r(28,12,'Hosea 12'),_r(28,13,'Hosea 13')]),
      _day(ps: [_r(19,119, 'Psalm 119:129–136')],nt: [_r(60,1,'1 Peter 1')], pr: [_r(28,14,'Hosea 14'),_r(29,1,'Joel 1')]),
      _day(ps: [_r(19,119, 'Psalm 119:137–144')],nt: [_r(60,2,'1 Peter 2')], pr: [_r(29,2,'Joel 2'),_r(29,3,'Joel 3')]),
      _day(ps: [_r(19,119, 'Psalm 119')],          pr: [_r(30,1,'Amos 1'),_r(30,2,'Amos 2')]),
    ],
    // ── Week 47 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,119, 'Psalm 119:153–160')]),
      _day(ps: [_r(19,119, 'Psalm 119:161–168')],nt: [_r(60,3,'1 Peter 3')], pr: [_r(30,3,'Amos 3'),_r(30,4,'Amos 4')],                                       wi: [_r(22,4,'Song of Solomon 4')]),
      _day(ps: [_r(19,119, 'Psalm 119:169–176')],nt: [_r(60,4,'1 Peter 4')], pr: [_r(30,5,'Amos 5'),_r(30,6,'Amos 6')]),
      _day(ps: [_r(19,120, 'Psalm 120')],          nt: [_r(60,5,'1 Peter 5')], pr: [_r(30,7,'Amos 7'),_r(30,8,'Amos 8')]),
      _day(ps: [_r(19,121, 'Psalm 121')],           nt: [_r(61,1,'2 Peter 1')], pr: [_r(30,9,'Amos 9'),_r(31,1,'Obadiah 1')]),
      _day(ps: [_r(19,122, 'Psalm 122')],           nt: [_r(61,2,'2 Peter 2')], pr: [_r(32,1,'Jonah 1'),_r(32,2,'Jonah 2')]),
      _day(ps: [_r(19,123, 'Psalm 123')],           nt: [_r(61,3,'2 Peter 3')], pr: [_r(32,3,'Jonah 3'),_r(32,4,'Jonah 4')]),
    ],
    // ── Week 48 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,124, 'Psalm 124')]),
      _day(ps: [_r(19,125, 'Psalm 125')],          nt: [_r(62,1,'1 John 1')],   pr: [_r(33,1,'Micah 1'),_r(33,2,'Micah 2')],                                   wi: [_r(22,5,'Song of Solomon 5')]),
      _day(ps: [_r(19,126, 'Psalm 126')],           nt: [_r(62,2,'1 John 2')],   pr: [_r(33,3,'Micah 3'),_r(33,4,'Micah 4')]),
      _day(ps: [_r(19,127, 'Psalm 127')],           nt: [_r(62,3,'1 John 3')],   pr: [_r(33,5,'Micah 5'),_r(33,6,'Micah 6')]),
      _day(ps: [_r(19,128, 'Psalm 128')],           nt: [_r(62,4,'1 John 4')],   pr: [_r(33,7,'Micah 7'),_r(34,1,'Nahum 1')]),
      _day(ps: [_r(19,129, 'Psalm 129')],           nt: [_r(62,5,'1 John 5')],   pr: [_r(34,2,'Nahum 2'),_r(34,3,'Nahum 3')]),
      _day(ps: [_r(19,130, 'Psalm 130')],           nt: [_r(63,1,'2 John 1')],   pr: [_r(35,1,'Habakkuk 1'),_r(35,2,'Habakkuk 2')]),
    ],
    // ── Week 49 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,131, 'Psalm 131')]),
      _day(ps: [_r(19,132, 'Psalm 132:1–10')],  nt: [_r(64,1,'3 John 1')],   pr: [_r(35,3,'Habakkuk 3'),_r(36,1,'Zephaniah 1')],                             wi: [_r(22,6,'Song of Solomon 6')]),
      _day(ps: [_r(19,132, 'Psalm 132:11–18')], nt: [_r(65,1,'Jude 1')],     pr: [_r(36,2,'Zephaniah 2'),_r(36,3,'Zephaniah 3')]),
      _day(ps: [_r(19,133, 'Psalm 133')],         nt: [_r(66,1,'Revelation 1')],pr: [_r(37,1,'Haggai 1'),_r(37,2,'Haggai 2')]),
      _day(ps: [_r(19,134, 'Psalm 134')],         nt: [_r(66,2,'Revelation 2')],pr: [_r(38,1,'Zechariah 1'),_r(38,2,'Zechariah 2')]),
      _day(ps: [_r(19,135, 'Psalm 135:1–12')],  nt: [_r(66,3,'Revelation 3')],pr: [_r(38,3,'Zechariah 3'),_r(38,4,'Zechariah 4')]),
      _day(ps: [_r(19,135, 'Psalm 135:13–21')], nt: [_r(66,4,'Revelation 4')],pr: [_r(38,5,'Zechariah 5'),_r(38,6,'Zechariah 6')]),
    ],
    // ── Week 50 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,136, 'Psalm 136:1–9')]),
      _day(ps: [_r(19,136, 'Psalm 136:10–16')], nt: [_r(66,5,'Revelation 5')],pr: [_r(38,7,'Zechariah 7'),_r(38,8,'Zechariah 8')],                            wi: [_r(22,7,'Song of Solomon 7')]),
      _day(ps: [_r(19,136, 'Psalm 136:17–26')], nt: [_r(66,6,'Revelation 6')],pr: [_r(38,9,'Zechariah 9'),_r(38,10,'Zechariah 10')]),
      _day(ps: [_r(19,137, 'Psalm 137')],         nt: [_r(66,7,'Revelation 7')],pr: [_r(38,11,'Zechariah 11'),_r(38,12,'Zechariah 12')]),
      _day(ps: [_r(19,138, 'Psalm 138')],         nt: [_r(66,8,'Revelation 8')],pr: [_r(38,13,'Zechariah 13'),_r(38,14,'Zechariah 14')]),
      _day(ps: [_r(19,139, 'Psalm 139:1–12')],  nt: [_r(66,9,'Revelation 9')],pr: [_r(39,1,'Malachi 1'),_r(39,2,'Malachi 2')]),
      _day(ps: [_r(19,139, 'Psalm 139:13–24')], nt: [_r(66,10,'Revelation 10')],pr: [_r(39,3,'Malachi 3'),_r(39,4,'Malachi 4')]),
    ],
    // ── Week 51 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,140, 'Psalm 140')]),
      _day(ps: [_r(19,141, 'Psalm 141')],         nt: [_r(66,11,'Revelation 11')],                                                                             wi: [_r(22,8,'Song of Solomon 8')]),
      _day(ps: [_r(19,142, 'Psalm 142')],         nt: [_r(66,12,'Revelation 12')]),
      _day(ps: [_r(19,143, 'Psalm 143')],         nt: [_r(66,13,'Revelation 13')]),
      _day(ps: [_r(19,144, 'Psalm 144:1–8')],   nt: [_r(66,14,'Revelation 14')]),
      _day(ps: [_r(19,144, 'Psalm 144:9–15')],  nt: [_r(66,15,'Revelation 15')]),
      _day(ps: [_r(19,145, 'Psalm 145:1–9')],   nt: [_r(66,16,'Revelation 16')]),
    ],
    // ── Week 52 ──────────────────────────────────────────────────────────────
    [
      _day(ps: [_r(19,145, 'Psalm 145:10–21')]),
      _day(ps: [_r(19,146, 'Psalm 146')],         nt: [_r(66,17,'Revelation 17')]),
      _day(ps: [_r(19,147, 'Psalm 147:1–11')],  nt: [_r(66,18,'Revelation 18')]),
      _day(ps: [_r(19,148, 'Psalm 148:1–6')],   nt: [_r(66,19,'Revelation 19')]),
      _day(ps: [_r(19,148, 'Psalm 148:7–14')],  nt: [_r(66,20,'Revelation 20')]),
      _day(ps: [_r(19,149, 'Psalm 149')],         nt: [_r(66,21,'Revelation 21')]),
      _day(ps: [_r(19,150, 'Psalm 150')],         nt: [_r(66,22,'Revelation 22')]),
    ],
  ];

  /// Convenience: get the day plan for a given week/day index.
  static BibleReadingDayPlan dayPlan(int weekIndex, int dayIndex) =>
      weeks[weekIndex][dayIndex];

  static const List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> fullDayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  /// The milestone week indices (0-based) at which to show a celebration.
  static const List<int> milestoneWeeks = [0, 9, 19, 29, 39, 51];
}
