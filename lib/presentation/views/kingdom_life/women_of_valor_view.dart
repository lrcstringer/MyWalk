import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';

HabitCategory _categoryFromPractice(String text) {
  final m = RegExp(r'\(([^)]+)\)').firstMatch(text);
  final cat = m?.group(1) ?? '';
  return switch (cat) {
    'Prayer & Worship' => HabitCategory.prayer,
    'Generosity' => HabitCategory.service,
    'Community' => HabitCategory.connection,
    'Spiritual Disciplines' => HabitCategory.scripture,
    _ => HabitCategory.study,
  };
}

const _kAccent = Color(0xFFB89AC8); // soft violet-rose
const _kPurple = Color(0xFF7B5EA7); // section header purple

// ── Women of Scripture data ───────────────────────────────────────────────

class _Woman {
  final String name;
  final String subtitle;
  final String description;
  final String keyVerses;
  final String poemConnections;
  final List<String> practices;
  const _Woman({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.keyVerses,
    required this.poemConnections,
    this.practices = const [],
  });
}

const _kWomen = [
  _Woman(
    name: 'Ruth',
    subtitle: 'The Woman the Poem Names',
    description:
        'There is one woman in all of Scripture whom someone directly addresses as eshet chayil — using the exact phrase of Proverbs 31:10. That woman is Ruth.\n\n'
        'In Ruth 3:11, Boaz says to her: "All the city of my people knows that you are a woman of chayil." This is not coincidence. Many scholars believe that the book of Ruth and the poem of Proverbs 31 are in deliberate conversation with each other — that Ruth is, in some sense, the poem\'s own illustration of itself.\n\n'
        'What does Ruth embody? Everything. She works with her hands (gleaning in Boaz\'s fields from morning until evening). She rises early. She extends herself to the needy by remaining with Naomi when she had every right to leave. She makes wise, courageous commercial and social decisions — the threshing-floor scene in Ruth 3 is an act of extraordinary strategic courage. She wins the trust of the community, and her husband-to-be praises her publicly. Her fear of the God of Israel — the God she has adopted as her own — is the root of all of it.\n\n'
        'Most significantly: her story ends at "the gates." Boaz conducts the legal transaction that secures Ruth\'s redemption at the city gate (Ruth 4:1–12) — the very location where Proverbs 31:31 insists the woman of valour should be praised. It is as if the poem is asking the reader: Remember Ruth? That is what I mean.',
    keyVerses: 'Ruth 1:16–17; 2:11–12; 3:11; 4:13–17',
    poemConnections: 'vv. 10, 13, 15, 16, 20, 28, 31',
    practices: const [
      'Covenant Loyalty (Generosity) — Read Ruth 1:6–18 slowly. Identify one relationship in your life where loyalty is costly. What would it look like to stay? Journal a prayer of commitment to that person.',
      'Crossing Boundaries (Community) — Ruth’s courage was partly the willingness to be the outsider. Is there someone in your community who is a “foreigner” in some sense — culturally, socially, economically? Take one concrete step toward welcome this week.',
      'Strategic Courage (Reflection) — The threshing-floor scene (Ruth 3) is Ruth acting boldly on wise counsel. Where in your life do you need to take a bold step you’ve been avoiding? Write out what it would look like to act with Ruth’s combination of humility and courage.',
      'Fear of the LORD as the Root (Prayer & Worship) — Boaz praises Ruth for taking refuge under the wings of the LORD (Ruth 2:12). Spend time in Psalm 91 or Psalm 36:7. Pray through what it means to make the LORD your true refuge, not your circumstances.',
    ],
  ),
  _Woman(
    name: 'Deborah',
    subtitle: 'The Warrior Judge',
    description:
        'Deborah (Judges 4–5) is the only woman in the Old Testament described as both a judge and a prophet — two of the highest offices in Israel. She held court under a palm tree between Ramah and Bethel, where the Israelites came to have their disputes decided (Judges 4:5). She was Israel\'s supreme court and its national conscience simultaneously.\n\n'
        'When God called her to lead the military campaign against Sisera, she did not hesitate. She told Barak what the LORD had commanded, and when he refused to go without her, she went. But she also prophesied that the honour of the victory would go to a woman (Judges 4:9). That woman turned out to be Jael.\n\n'
        'Deborah\'s song in Judges 5 — one of the oldest pieces of poetry in the Hebrew Bible — is a masterwork of theological and military narrative. She "arose as a mother in Israel" (Judges 5:7), using the language of nurture and household even in the context of war. She is not domesticated strength; she is full-spectrum valour. She opens her mouth with wisdom (v. 26) before any audience Israel could offer.',
    keyVerses: 'Judges 4:4–9; 5:1–7; 5:31',
    poemConnections: 'vv. 17, 25, 26, 27',
    practices: const [
      'Using Your Voice (Community) — Deborah did not wait to be asked; she spoke when she saw what was needed. Identify one situation in your community, church, or family where you have insight others may not have. What would it look like to speak up with wisdom and care this week?',
      'Leading from Strength Not Fear (Reflection) — Deborah’s confidence came from knowing who had called her. Journal about an area of your life where fear is preventing you from acting. What would change if you led from the conviction that God had placed you here for this?',
      'Intercession for a Nation (Prayer & Worship) — Deborah arose as a mother in Israel (Judges 5:7) — which is to say, she took responsibility for people beyond her own household. Spend time in intercessory prayer for your city, nation, or church. Write down what you pray.',
      'Willingness to Praise Others (Spiritual Disciplines) — Deborah’s song (Judges 5) publicly honours Jael, Barak, and those who volunteered. Who in your life deserves more recognition than they receive? Write a note of genuine, specific encouragement to them this week.',
    ],
  ),
  _Woman(
    name: 'Jael',
    subtitle: 'Courageous Action at the Right Moment',
    description:
        'Jael (Judges 4:17–22) is often overlooked, partly because her act of killing Sisera is jarring to modern readers. But within the poem\'s framework she is essential. Deborah had prophesied that "the LORD will sell Sisera into the hand of a woman" (Judges 4:9). Jael was that woman.\n\n'
        'When Sisera fled the battlefield and sought shelter in her tent, she made a rapid, courageous, morally serious decision. She acted without hesitation. Deborah\'s song celebrates her: "Most blessed of women is Jael… most blessed of women in the tent" (Judges 5:24). The phrase "blessed of women" echoes through Scripture to Elizabeth\'s greeting to Mary ("blessed are you among women") and back to the woman of Proverbs 31 whose "children rise up and call her blessed" (v. 28).\n\n'
        'Jael embodies "she arms her loins with strength" (v. 17) in its most stark expression. She is a reminder that the poem\'s heroism is not soft.',
    keyVerses: 'Judges 4:17–22; 5:24–27',
    poemConnections: 'vv. 17, 25, 28',
    practices: const [
      'Recognising the Decisive Moment (Reflection) — Jael’s act required recognising a moment that would not come again. Journal about a moment you may be in right now that requires courage and decision. What is God calling you to do that only you are positioned to do?',
      'Using Ordinary Tools (Spiritual Disciplines) — Jael used tent pegs and a mallet — the tools of her household. Spend time in prayer asking God to show you the ordinary things in your hands — skills, relationships, daily rhythms — that are already sufficient for what he’s calling you to.',
      'Hard Courage (Prayer & Worship) — Deborah’s song calls Jael “most blessed of women.” That blessing was not given for ease but for costly action. Pray through Luke 14:27–33. What does it mean to count the cost and still choose faithfulness?',
    ],
  ),
  _Woman(
    name: 'Abigail',
    subtitle: 'Wisdom in a Crisis',
    description:
        'Abigail (1 Samuel 25) is one of the most remarkable figures in the Old Testament — a woman of extraordinary wisdom, courage, and speed of thought, married to a man described as "harsh and badly behaved" (1 Sam 25:3). The text introduces her as "discerning and beautiful."\n\n'
        'When her husband Nabal insulted David and his men, setting the household on a path toward massacre, it was Abigail who acted. Without telling Nabal, she loaded donkeys with food, rode out to meet David, dismounted before him, and delivered one of the most theologically sophisticated speeches in the entire narrative books. She addressed David\'s anger, appealed to his future kingship, invoked the LORD\'s protection, asked for forgiveness on behalf of her household, and — in a remarkable closing move — predicted David\'s eventual kingship (1 Sam 25:24–31). Her instruction saved a future king from the guilt of unnecessary bloodshed.\n\n'
        'David\'s response is immediate: "Blessed be your discernment, and blessed be you" (1 Sam 25:33). He receives her counsel. He changes course. He changes his mind because of a woman\'s wisdom. After Nabal\'s death, David sought her as a wife — recognising that this was the kind of woman whose counsel he wanted beside him.',
    keyVerses: '1 Samuel 25:3, 14–31, 39–42',
    poemConnections: 'vv. 11, 23, 25, 26',
    practices: const [
      'Wise and Rapid Response (Reflection) — Abigail acted without delay when she understood the situation. Journal about a situation in your life that requires wisdom and speed. What information do you already have? What does wise action look like right now, before the moment passes?',
      'Speaking Truth to Power (Community) — Abigail spoke truth to a future king at risk to herself. Is there a relationship in your life where you need to speak a hard truth with gentleness and courage? Prepare what you would say. Pray for the right moment and the right spirit.',
      'Discernment First (Spiritual Disciplines) — Before Abigail acted, she assessed clearly. Practise a form of Ignatian discernment this week: for a decision you’re facing, list what draws you toward each option and what causes resistance. Bring both to prayer.',
      'Theology in the Ordinary (Prayer & Worship) — Abigail’s speech to David is full of theology woven into the practical moment (1 Sam 25:24–31). Read that passage and then journal: how does your faith actually shape the way you handle conflict, not just in theory but in the moment?',
    ],
  ),
  _Woman(
    name: 'Esther',
    subtitle: 'Dignity in the Face of Death',
    description:
        'Esther\'s story is one of the greatest narratives of courage in all of Scripture, made more remarkable by its hiddenness. God is never explicitly mentioned in the book of Esther. Yet his hand is everywhere — and so is a woman who had quietly formed the kind of character that was ready when everything depended on it.\n\n'
        'Esther did not act impulsively. When Mordecai urged her to intercede for her people, she first called for three days of fasting — for herself, her maids, all the Jews of Susa (Esther 4:16). She prepared. She took counsel. She considered the field before she bought it (cf. v. 16). Then she acted: "I will go to the king, which is against the law; and if I perish, I perish" (Esther 4:16). She said it twice because she knew it might happen. And still she went.\n\n'
        '"Strength and dignity are her clothing; she laughs at the time to come" (v. 25). Esther\'s laughter is not naive — it is the laughter of a woman who has given her outcome to God and is therefore free to act without being paralysed by fear. Her royal robes in chapter 5 are beautiful, but her real clothing was the dignity she wore before she put them on.\n\n'
        'The book ends with Esther\'s decrees recorded throughout the empire (Esther 9:29–32) — her works praising her "in the gates" (v. 31) at the highest possible level.',
    keyVerses: 'Esther 4:12–16; 5:1–3; 9:29–32',
    poemConnections: 'vv. 16, 21, 22, 25, 28, 30, 31',
    practices: const [
      'Prepared Courage (Spiritual Disciplines) — Before Esther acted, she fasted for three days. Practise a partial fast (one meal, or a digital fast) as preparation for something significant ahead. Use the time for prayer and Scripture rather than simply abstaining.',
      'Strategic Patience (Reflection) — Esther did not ask at the first banquet. She waited. Journal about a situation where you tend to act too quickly out of anxiety. What would it look like to wait — not passively, but in strategic, prayerful preparation?',
      'Naming the Moment (Community) — Mordecai told Esther: “For such a time as this.” Share with a trusted friend or group something you believe you have been placed in your current context to do. Ask them to pray with you for clarity and courage.',
      'Royal Robes Before the Throne (Prayer & Worship) — Esther put on royal clothing — an act of dignity before power. Spend time in worship before you ask for anything. Practise coming into God’s presence with praise before petition. Try Psalm 100 or Psalm 95 as your entry.',
    ],
  ),
  _Woman(
    name: 'Hannah',
    subtitle: 'Prayer as the Foundation of Provision',
    description:
        'Hannah (1 Samuel 1–2) is the great exemplar of prayer in the Old Testament — and her story is one of the most poignant and ultimately triumphant in all of Scripture. Barren and despised by her rival Peninnah, Hannah brought her grief to the LORD with such intensity that Eli the priest thought she was drunk. Her lips moved but no sound came — she was praying with her whole body, her whole heart. She vowed. She waited. She was faithful.\n\n'
        'What elevates Hannah beyond the typical "answered prayer" story is her response. She had prayed for a son. She received him. And then she gave him back — taking Samuel to Eli at Shiloh and dedicating him to the LORD\'s service for life (1 Sam 1:27–28). Her generosity outran even what God had asked of her.\n\n'
        'Her song in 1 Samuel 2:1–10 — the Magnificat\'s direct precursor — is a theological declaration of the LORD\'s character: he lifts the poor from the dust, he exalts the humble, he brings down the mighty. Mary of Nazareth almost certainly knew it by heart. Hannah\'s song shaped the understanding of what God\'s kingdom looks like centuries before Jesus arrived.',
    keyVerses: '1 Samuel 1:10–18, 26–28; 2:1–10',
    poemConnections: 'vv. 15, 20, 28, 30',
    practices: const [
      'Silent Honest Prayer (Prayer & Worship) — Hannah prayed in her heart, moving only her lips (1 Sam 1:13). Set aside time for silent, honest prayer — no performance, no beautiful language. Bring exactly what you feel, as it is, and lay it before God.',
      'The Peace Before the Answer (Reflection) — After Eli’s blessing, Hannah ate and was no longer sad (1 Sam 1:18) — before anything had changed. Journal about what it would mean for you to receive peace about a situation before the answer comes. What would that kind of trust look like in practice?',
      'Extravagant Return (Generosity) — Hannah gave Samuel back to the LORD as soon as he was weaned. What has God given you that you hold tightly? Prayerfully consider whether there is an act of extravagant giving or releasing — time, resource, a person — that you are being called to.',
      'A Little Robe Every Year (Spiritual Disciplines) — Hannah brought Samuel a new robe each year (1 Sam 2:19). Choose one person you are investing in spiritually or practically. What is the equivalent of the little robe — a consistent, intentional act of nurture — that you could commit to for the next year?',
    ],
  ),
  _Woman(
    name: 'Lydia',
    subtitle: 'The Businesswoman of Purple',
    description:
        'Lydia (Acts 16:14–15, 40) is introduced with unusual precision: she is "a seller of purple goods, from the city of Thyatira, who was a worshipper of God." Luke gives us her profession, her city of origin, and her spiritual status in one sentence. She is a woman of means, commerce, and faith — and the combination is presented as entirely unremarkable. It is simply who she is.\n\n'
        'Purple dye in the ancient world was extraordinarily expensive — made from the murex sea snail and worth more than its weight in gold. Lydia\'s trade was not a small-scale craft. She was dealing in luxury goods across significant geographic distances. Note the direct echo: the Woman of Valour\'s clothing is "fine linen and purple" (v. 22) — the very material Lydia traded. She was, in the terms of Proverbs 31, making fine garments and selling them, delivering to the merchant (v. 24) — except her merchant connections were empire-wide.\n\n'
        'She was gathered with women at a place of prayer by the river when Paul arrived. The LORD opened her heart (16:14). She and her entire household were baptised. And then, immediately, she acted: "If you have judged me to be faithful to the Lord, come into my house and stay." She "prevailed upon" them (16:15) — the verb suggests insistence, not polite invitation. Lydia becomes the founding patron of the church at Philippi, the church Paul wrote to in his most affectionate letter. Her works praise her in the gates of every church that has ever read Philippians.',
    keyVerses: 'Acts 16:13–15, 40; Philippians 1:3–5',
    poemConnections: 'vv. 13, 14, 16, 22, 24, 25, 27, 30, 31',
    practices: const [
      'Faith and Commerce United (Reflection) — Lydia’s business life and her spiritual life were not separate. Journal about your own work or daily responsibilities. How would it look different if you treated them as acts of worship and witness, not just duty?',
      'Open Heart Open House (Generosity) — Lydia opened her home immediately after her baptism. Hospitality was the first expression of her new faith. Invite someone into your home or life this week — not for a formal event, but for ordinary presence. Make the offer before you feel ready.',
      'The River before the Market (Prayer & Worship) — Lydia was at a place of prayer on the Sabbath before God opened her heart. Establish or protect a regular time of prayer that comes before your work week, not after it. Pray through Acts 16:11–15 as a model.',
      'Europe’s First Patron (Community) — Lydia became the founding patron of the Philippian church. Identify one person, ministry, or initiative in your community that you could support more tangibly — with time, money, or practical help. Commit to a specific act this month.',
    ],
  ),
  _Woman(
    name: 'Priscilla',
    subtitle: 'The Teacher of Apollos',
    description:
        'Priscilla (also called Prisca) is mentioned six times in the New Testament, and in four of those six mentions she is named before her husband Aquila — a highly unusual inversion for the cultural context, almost certainly indicating that she was the more prominent of the two in the Christian community.\n\n'
        'She and Aquila were tentmakers — a skilled trade requiring technical knowledge and business acumen (Acts 18:2–3). They hosted a church in their home in Corinth, then Rome, then Ephesus (Romans 16:5; 1 Corinthians 16:19). Their home was a centre of the early Christian mission. She was not merely present; she was central.\n\n'
        'The key moment comes in Acts 18:24–26. Apollos — described as "an eloquent man, competent in the Scriptures" — arrived in Ephesus and began teaching in the synagogue. Priscilla and Aquila heard him and recognised a gap in his understanding. They "took him aside and explained to him the way of God more accurately." Priscilla taught a gifted male preacher with grace, precision, and evident knowledge. She opens her mouth with wisdom; kind instruction is on her tongue (v. 26). Apollos went on to become one of the most effective preachers of the early church.\n\n'
        'Paul calls her a "fellow worker in Christ Jesus" who "risked their necks" for his life (Romans 16:3–4). She is a woman of chayil — strength, risk, and wisdom in service of the kingdom.',
    keyVerses: 'Acts 18:2–3, 18–19, 24–26; Romans 16:3–5; 1 Corinthians 16:19',
    poemConnections: 'vv. 11, 13, 16, 24, 25, 26, 27, 31',
    practices: const [
      'Alongside Not Instead Of (Community) — Priscilla and Aquila always appear together; she does not act solo. Consider: who is the person you do your most significant work alongside? What does it look like to honour that partnership more deliberately? Pray for them by name today.',
      'The Tent-Working Life (Reflection) — Paul, Priscilla, and Aquila all worked with their hands. Journal about the relationship between your ordinary work and your calling. What does faithfulness look like in both? How does working with integrity witness to the gospel?',
      'Risking Your Neck (Prayer & Worship) — Romans 16:4 says Priscilla and Aquila risked their lives for Paul. Spend time with Romans 12:1–2. Pray through what it would mean to offer your life — not dramatically but daily — as a living sacrifice.',
      'The Church in Your House (Spiritual Disciplines) — Three times the NT mentions a church meeting in their home (Rom 16:5; 1 Cor 16:19; Col 4:15). Practise making your home a space of spiritual formation. Invite a small group, a younger believer, or a neighbour into genuine community in your own space.',
    ],
  ),
  _Woman(
    name: 'Mary of Bethany',
    subtitle: 'The Good Portion',
    description:
        'Mary of Bethany appears three times in the Gospels, and each time she is at the feet of Jesus: listening to him teach (Luke 10:39), mourning after Lazarus\'s death (John 11:32), and anointing his feet with expensive perfume (John 12:3). Her posture is constant: she is always oriented toward Jesus.\n\n'
        'This is, at first, a striking contrast to the industrious energy of Proverbs 31. The Woman of Valour does so much. Mary appears to do only one thing. But Jesus\'s response to Martha reveals the deeper point: "Mary has chosen the good portion, which will not be taken away from her" (Luke 10:42). The Greek verb is eklegomai — to choose deliberately from among alternatives. Mary has not drifted into passive sitting. She has actively chosen to prioritise one thing. And that one thing — the fear of the LORD, sitting at his feet, hearing his word — is, per Proverbs 31:30, the root of everything the poem describes.\n\n'
        'The anointing in John 12 adds a further dimension. Mary took a pound of pure nard (worth about a year\'s wages) and anointed Jesus\'s feet. Judas protested: this could have been given to the poor. But Jesus defended her: "She has done this in preparation for my burial" (John 12:7). Mary had understood something the disciples had not yet grasped. She "extended her hands to the needy" (v. 20) in the most extravagant possible way: to the One who would bear the world\'s need on a cross.',
    keyVerses: 'Luke 10:38–42; John 11:28–32; John 12:1–8',
    poemConnections: 'vv. 20, 26, 28, 30',
    practices: const [
      'Choosing the One Thing (Spiritual Disciplines) — Jesus said Mary chose the one thing that would not be taken from her (Luke 10:42). This week, identify one spiritual practice — prayer, Scripture, silence — and protect it from displacement. Refuse to let the urgent crowd it out.',
      'Extravagant Worship (Prayer & Worship) — Mary poured out what was worth a year’s wages (John 12:3). Worship extravagantly this week: more time than feels reasonable, more honesty than feels comfortable, more silence than feels productive. Bring your costliest attention to God.',
      'Tears as Theology (Reflection) — Mary fell at Jesus’ feet weeping (John 11:32), and Jesus wept with her. Journal about grief, disappointment, or confusion you are carrying. Bring it directly to Jesus — not with a resolution, but as Mary did: at his feet.',
      'The Prophetic Gesture (Community) — Jesus said Mary’s act would be told wherever the gospel is preached. Is there an act of love or worship in your community that you have been holding back out of fear of what others will think? Pray for the courage to do it anyway.',
    ],
  ),
  _Woman(
    name: 'Martha',
    subtitle: 'The Confession at the Tomb',
    description:
        'Martha appears in three Gospel scenes, and in each one she is doing something. In Luke 10 she is busy with much serving while Mary sits at Jesus\'s feet. The contrast is often read as a rebuke of Martha — but Jesus\'s word is more precise: "Martha, Martha, you are anxious and troubled about many things, but one thing is necessary" (Luke 10:41–42). He does not condemn her service; he calls her to single-mindedness. Her hospitality and practical care were real; they needed to flow from a deeper root.\n\n'
        'That deeper root is revealed in John 11. When Lazarus died, Martha ran out to meet Jesus on the road — the same forward, purposeful energy, now oriented directly toward him. In one of the most remarkable exchanges in the Gospels, Jesus says: "I am the resurrection and the life. Whoever believes in me, though he die, yet shall he live. Do you believe this?" Her answer is the confession of Caesarea Philippi, spoken by a woman: "Yes, Lord; I believe that you are the Christ, the Son of God, who is coming into the world" (John 11:27). She opens her mouth with wisdom (v. 26). The strength and dignity she wears in that moment are not of her own making.\n\n'
        'She is at the table in John 12 — still serving — while Mary anoints Jesus. She looks well to the ways of her household (v. 27). Her service and Mary\'s worship are not opposites: they are two expressions of the same love, offered to the same Lord.',
    keyVerses: 'Luke 10:38–42; John 11:17–44; 12:2',
    poemConnections: 'vv. 11, 25, 26, 27, 28',
    practices: const [
      'The Theology of the Graveside (Reflection) — Martha’s confession — “I believe that you are the Christ” (John 11:27) — came in a moment of grief, not triumph. Journal about your own “graveside” moments. What do you actually believe when everything has gone wrong? How does your theology hold up under weight?',
      'Receiving the Correction (Spiritual Disciplines) — When Jesus gently corrected Martha (Luke 10:41–42), she received it. Practise the discipline of receiving feedback without defensiveness. This week, ask someone you trust: “Is there an area where you think I’m missing something?” Listen without interrupting.',
      'From Anxiety to Doxology (Prayer & Worship) — Martha moved from anxious service (Luke 10) to serving at the table again (John 12:2) after the resurrection of Lazarus. Read John 11:38–44, then spend time in thanksgiving for something you once grieved that God has redeemed.',
      'Hospitality as Ministry (Community) — Martha opened her home (Luke 10:38) and served again (John 12:2). Practise intentional hospitality this week: invite someone, prepare carefully, and be fully present — not distracted by the service itself.',
    ],
  ),
  _Woman(
    name: 'Mary Magdalene',
    subtitle: 'First Witness of the Resurrection',
    description:
        'Mary Magdalene is perhaps the most misrepresented woman in Christian history — wrongly identified with the unnamed sinful woman of Luke 7, and traditionally depicted as a reformed prostitute with no biblical basis. What the Bible actually says is simpler and more remarkable: she was a woman from whom Jesus had cast out seven demons (Luke 8:2), who became one of his most devoted followers, and who was the first human being to witness the risen Christ.\n\n'
        'She was at the cross when nearly all of the male disciples had fled (Mark 15:40–41). She was at the burial (Matthew 27:61). She arrived at the empty tomb "while it was still dark" (John 20:1) — she rises while it is yet night (v. 15), her lamp not gone out (v. 18). And she was the first person the risen Jesus chose to appear to — commissioning her as the first herald of the resurrection (John 20:17–18).\n\n'
        'The early church called her Apostola Apostolorum — Apostle to the Apostles. The one who proclaimed the resurrection to those who would proclaim it to the world. Her testimony, given in that upper room, was the seed of everything that followed. Let her works praise her in the gates (v. 31) — and they have, in every Easter proclamation since.',
    keyVerses: 'Luke 8:1–3; Mark 15:40–41; John 20:1–18',
    poemConnections: 'vv. 15, 18, 28, 30, 31',
    practices: const [
      'Staying When Others Leave (Spiritual Disciplines) — Mary stood weeping at the empty tomb after the disciples left (John 20:11). Practise the discipline of staying — in prayer, in a hard relationship, in a commitment — past the point where it seems productive. Stay until you encounter the risen Christ.',
      'Rising Before Dawn (Prayer & Worship) — Mary came to the tomb while it was still dark (John 20:1). Set your alarm early one morning this week to pray before the day begins. Use Psalm 63 as a guide: “O God, you are my God; earnestly I seek you.”',
      'Hearing Your Name (Reflection) — Mary recognised Jesus when he called her name (John 20:16). Journal about a time you experienced God’s personal, specific address to you. What would it mean to live more attentively to his voice in the ordinary moments of your day?',
      '"I Have Seen the Lord" (Community) — Mary’s first act after the resurrection encounter was to tell the disciples (John 20:18). Who in your life needs to hear, specifically and personally, what Christ has done for you? Choose one person and tell them this week.',
    ],
  ),
  _Woman(
    name: 'Dorcas / Tabitha',
    subtitle: 'Her Works Were Her Testimony',
    description:
        'Dorcas (Acts 9:36–42) appears in only eleven verses, but her impact was immediate and community-wide. She was a disciple — Luke uses the feminine form of the Greek mathētria — who was "always doing good and helping the poor." When she died, the widows of Joppa stood around Peter weeping and showing him the tunics and garments she had made (Acts 9:39).\n\n'
        'She had worked with her hands (v. 13). She had extended her hands to the needy (v. 20). She had clothed the vulnerable — and her work was so personal, so tangible, that the widows were not simply grieving a benefactor. They were grieving a friend who had made their clothes.\n\n'
        'Peter raised her from the dead. The text gives us the moment with great simplicity: "He called the saints and widows and presented her alive" (Acts 9:41). Her resurrection became a turning point for the whole region: "it became known throughout all Joppa, and many believed in the Lord" (Acts 9:42). Her works praised her in the gates — literally, through the gates of death and back.',
    keyVerses: 'Acts 9:36–42',
    poemConnections: 'vv. 13, 19, 20, 24, 28, 31',
    practices: const [
      'Wearable Love (Generosity) — Dorcas made garments for the widows (Acts 9:39). Consider a practical act of generosity that meets a physical or material need for someone in your community. Make it specific, tangible, and personal — not a donation to an institution but a gift to a person.',
      'The Widow’s Circle (Community) — The widows showed Peter the garments Dorcas had made (Acts 9:39). Who is your community of witnesses? Who could you ask to vouch for your life’s work? Build relationships of genuine care with those who are often overlooked — the lonely, the grieving, the marginalised.',
      'Discipleship as a Title (Reflection) — Acts 9:36 calls Dorcas a “disciple” (the only woman in the NT explicitly so named). Journal: what does it mean for you to bear that title? What habits, choices, and relationships would others point to as evidence of your discipleship?',
      'Works as Evangelism (Spiritual Disciplines) — Many believed because of the miracle that restored Dorcas (Acts 9:42). But her works already bore witness before her death. Practise asking God each week: “What one act of love or service could I do that would make the gospel visible to someone who doesn’t know you?”',
    ],
  ),
  _Woman(
    name: 'The Daughters of Zelophehad',
    subtitle: 'Claiming Their Inheritance',
    description:
        'The five daughters of Zelophehad — Mahlah, Noah, Hoglah, Milcah, and Tirzah (Numbers 27) — appear in one of the most quietly revolutionary moments in the Pentateuch. Their father had died without male heirs. Under existing law, his property would pass to the nearest male relative, leaving his daughters with nothing.\n\n'
        'They went to Moses. To the priest Eleazar. To the leaders. To the whole congregation. At the entrance to the tent of meeting (Numbers 27:2). They stated their case clearly, without apology, without hysteria: "Why should the name of our father be removed from his family, because he had no son? Give to us a possession among our father\'s brothers" (Numbers 27:4).\n\n'
        'God\'s response to Moses is remarkable: "The daughters of Zelophehad are right… You shall give them possession of an inheritance among their father\'s brothers" (Numbers 27:7). God changed the law. Five women changed Israelite inheritance law. They "considered a field, and bought it" (v. 16) — not metaphorically but legally and nationally, on behalf of their father\'s memory and every daughter who would come after them. Their case is settled definitively in Joshua 17 when they successfully claim their land in Canaan.',
    keyVerses: 'Numbers 27:1–8; Joshua 17:3–6',
    poemConnections: 'vv. 16, 25, 26, 31',
    practices: const [
      'Articulate Advocacy (Community) — The daughters presented a reasoned, coherent case (Num 27:3–4). Identify a situation where someone in your community is being overlooked or treated unjustly. Prepare to speak on their behalf — calmly, specifically, and with evidence.',
      'Going to the Highest Authority (Prayer & Worship) — They went directly to Moses, Eleazar, and the congregation — the highest forum available. Pray through what it means to bring your boldest requests directly to God. Spend time with Hebrews 4:16: “Let us then with confidence draw near to the throne of grace.”',
      'Claiming Your Inheritance (Reflection) — They asked for what was theirs by right under a new covenant logic. Journal: what has God promised you, or given you, that you are not claiming? Where are you living below your inheritance? What step of faith would it take to walk into it?',
      'The Next Generation (Spiritual Disciplines) — Their case changed Israelite inheritance law for all time (Num 27:8–11). What legacy are you building? What decisions you make now will still shape the lives of people you will never meet? Spend time praying over the next generation in your family, church, or community.',
    ],
  ),
  _Woman(
    name: 'Anna the Prophetess',
    subtitle: 'The Long Vigil',
    description:
        'Anna (Luke 2:36–38) is one of the most quietly magnificent figures in the New Testament. She was "a prophetess, the daughter of Phanuel, of the tribe of Asher." She had been married seven years before her husband died, and had then lived as a widow until she was eighty-four — decades of faithful obscurity. During those years, "she did not depart from the temple, worshipping with fasting and prayer night and day." Her whole life was a single extended act of worship.\n\n'
        'Her lamp does not go out by night (v. 18) in the most literal and sustained sense in all of Scripture. She is the keeper of the long vigil.\n\n'
        'When Mary and Joseph brought the infant Jesus to the temple, Anna "came up at that very hour and began to give thanks to God and to speak of him to all who were waiting for the redemption of Jerusalem" (Luke 2:38). She had waited for decades. She recognised him in an instant. She immediately became a witness — opening her mouth in public to speak of what she had seen, to all who had ears to hear. She opens her mouth with wisdom (v. 26).',
    keyVerses: 'Luke 2:36–38',
    poemConnections: 'vv. 15, 18, 26, 30, 31',
    practices: const [
      'The Practice of Presence (Prayer & Worship) — Anna never left the temple, worshipping night and day (Luke 2:37). You cannot live in the temple, but you can cultivate habitual return to God. Choose one daily transition — waking, mealtimes, bedtime — and mark it consistently with a brief act of prayer or Scripture.',
      'The Long Wait (Reflection) — Anna waited decades for the consolation of Israel. Journal about something you have been waiting for — a prayer unanswered, a promise not yet fulfilled. What would it mean to wait faithfully, like Anna: not passively but actively, with worship rather than anxiety?',
      'Fasting as Formation (Spiritual Disciplines) — Fasting was a regular part of Anna’s life, not an emergency measure. Practise a structured fast this week — one meal, or a digital fast — and use the time for extended prayer. Notice what the hunger reveals about where you look for comfort.',
      'Immediate Proclamation (Community) — When Anna saw Jesus, she immediately began to speak of him to all who were waiting (Luke 2:38). Who is in your life who is “waiting for the redemption of Jerusalem” — longing, searching, not yet found? Pray for them, and look for the right moment to speak.',
    ],
  ),
  _Woman(
    name: 'Eunice and Lois',
    subtitle: 'Mothers of Faith',
    description:
        'Eunice and Lois appear only briefly in the New Testament, but their influence spans generations. Paul writes to Timothy: "I am reminded of your sincere faith, a faith that dwelt first in your grandmother Lois and your mother Eunice and now, I am sure, dwells in you as well" (2 Timothy 1:5). Faith as inheritance. Faith as something transmitted and nurtured in the ordinary daily life of a family.\n\n'
        'Eunice was a Jewish believer married to a Greek man (Acts 16:1) — which means she navigated a cross-cultural marriage in a world where that was unusual, apparently without losing either her faith or her son. Timothy knew "the sacred writings" from childhood (2 Timothy 3:15) — which means Eunice and Lois had taught him the Scriptures from infancy. Kind instruction had been on their tongues (v. 26). The fruit of that instruction became one of the most significant young leaders of the early church — a man discipled by Paul himself.\n\n'
        'Their children rose up and called them blessed (v. 28) — not in words, but in a life. Timothy is their testimony.',
    keyVerses: 'Acts 16:1; 2 Timothy 1:5; 3:14–15',
    poemConnections: 'vv. 26, 27, 28, 30',
    practices: const [
      'Scripture from the Cradle (Spiritual Disciplines) — Timothy knew the sacred writings from infancy (2 Tim 3:15). Whether or not you have children, consider who you are discipling. Begin reading Scripture with them regularly — not lecturing, but sharing what you’re learning.',
      'Unfeigned Faith (Reflection) — Paul names their faith as “sincerely held” (2 Tim 1:5 — lit. “without hypocrisy”). Journal about the gap, if any, between your public faith and your private faith. What would it mean to close that gap by 10% this month?',
      'The Cross-Cultural Household (Prayer & Worship) — Eunice was Jewish, her husband was Greek (Acts 16:1). The household was already a bridge of cultures. Pray for one relationship or context in your life that crosses cultures, backgrounds, or generations. Ask God how to invest in it more intentionally.',
      'Three Generations (Community) — Lois to Eunice to Timothy — faith passed deliberately through three generations. Identify one person at least one generation younger than you. Commit to a regular, intentional investment in their faith formation over the next six months.',
    ],
  ),
  _Woman(
    name: 'Phoebe',
    subtitle: 'The Deaconess Who Carried Romans',
    description:
        'Phoebe receives one of the most compressed but significant introductions in the New Testament. Paul writes in Romans 16:1–2: "I commend to you our sister Phoebe, a deaconess of the church at Cenchreae, that you may welcome her in the Lord in a way worthy of the saints, and help her in whatever she may need from you, for she has been a patron of many and of myself as well."\n\n'
        'She was a diakonos — a deacon or minister — of the church at Cenchreae, the eastern port of Corinth. She was a prostatis — a patron or benefactor — of many, including Paul himself. Patrons in the Roman world were people of social standing and financial means who used their resources to support others. Phoebe was that person for the apostle.\n\n'
        'Most significantly: the scholarly consensus is that Phoebe was the courier who carried Paul\'s letter to the Romans from Corinth to Rome — which means she carried what is arguably the most theologically dense letter ever written across the Mediterranean, and as the letter\'s bearer, she would have been the one to read it aloud to the Roman church and field questions about its content. She was, in effect, the letter\'s first expositor. She delivered the most important document in the history of Christian theology. Let her works praise her in the gates (v. 31).',
    keyVerses: 'Romans 16:1–2',
    poemConnections: 'vv. 13, 16, 20, 24, 25, 31',
    practices: const [
      'Patron of the Gospel (Generosity) — Phoebe was a “patron of many” (Rom 16:2). Consider what resources God has given you — financial, relational, professional — and identify one gospel ministry or person you could support more substantially. Patronage is a spiritual vocation.',
      'The Letter You Carry (Community) — Phoebe carried Paul’s letter to Rome and would have read and explained it in the congregation. You carry the word of God in your community. Who are you helping to understand it? Commit to one act of biblical explanation or encouragement this week.',
      'Faithful in the Ordinary Port (Reflection) — Cenchreae was a small harbour town. Phoebe’s faithfulness there equipped her for the mission to Rome. Journal about faithfulness in your ordinary context. What does it look like to be excellent where God has placed you now, not where you wish you were?',
      'Receive and Help (Spiritual Disciplines) — Paul asks the Romans to “receive her in the Lord” and “help her in whatever she may need” (Rom 16:2). Practise both sides of this: receive help this week from someone who offers it. Then actively look to help someone who hasn’t asked.',
    ],
  ),
  _Woman(
    name: 'The Shunammite Woman',
    subtitle: 'Practical Hospitality and Resilient Faith',
    description:
        'The unnamed Shunammite woman (2 Kings 4 and 8) is one of the Old Testament\'s most three-dimensional characters. She was "a wealthy woman" who "urged" Elisha to eat with her (4:8) — the same verb used of Lydia\'s compelling hospitality in Acts 16:15. She then took the practical initiative of persuading her husband to build a small room on the roof for Elisha — furnishing it with a bed, a table, a chair, and a lamp (4:10). Her practical generosity was precise and thoughtful: she looked well to the ways of her household (v. 27) with careful, anticipatory wisdom.\n\n'
        'When her son died suddenly, she did not panic. She laid him on Elisha\'s bed, saddled a donkey, and rode urgently to Elisha — saying to her husband: "All is well" (2 Kings 4:23) and then to Elisha\'s servant: "All is well" (4:26). Only when she reached Elisha himself did she fall at his feet in grief. She managed her household and her emotions with remarkable steadiness. "Strength and dignity are her clothing; she laughs at the time to come" (v. 25).\n\n'
        'She reappears in 2 Kings 8 — seven years after leaving the land during a famine — calmly petitioning the king for the restoration of her house and land. And she received it. She considers a field, and she gets it back.',
    keyVerses: '2 Kings 4:8–37; 8:1–6',
    poemConnections: 'vv. 11, 16, 20, 21, 25, 27',
    practices: const [
      'Anticipatory Hospitality (Generosity) — The Shunammite saw Elisha’s need before he asked (2 Kgs 4:9–10). Practise anticipatory generosity this week: notice a need before it is voiced, and meet it without being asked.',
      '"I Dwell Among My Own People" (Reflection) — When Elisha offered to use his influence for her, she declined: “I dwell among my own people” (2 Kgs 4:13). Journal about contentment and ambition in your own life. Are there places where you are striving for advancement that God is not calling you to? What would it mean to be at peace where you are?',
      'Shalom Under Pressure (Prayer & Worship) — When asked if all was well after her son’s death, she said: “It is well” (2 Kgs 4:26). Read 2 Kings 4:18–37. Then spend time in Philippians 4:6–7. Pray for the peace that passes understanding in the hardest situation you are currently facing.',
      'Back to the Gates (Community) — The Shunammite woman went to the king to reclaim her land and got it back (2 Kgs 8:1–6). Is there something that was taken from you — property, reputation, relationship — that it is time to contend for? Identify one trusted person to help you discern what rightful action looks like.',
    ],
  ),
  _Woman(
    name: 'Rahab',
    subtitle: 'Fear of the LORD as the Root of Courage',
    description:
        'Rahab (Joshua 2; 6:22–25; Matthew 1:5; Hebrews 11:31; James 2:25) is one of the most surprising entries in the hall of faith — a Canaanite woman from Jericho who hid the Israelite spies and secured her family\'s survival. She is cited in two New Testament passages as a model of saving faith.\n\n'
        'What drove her? She tells the spies directly: "I know that the LORD has given you the land… for the LORD your God, he is God in the heavens above and on the earth beneath" (Joshua 2:9, 11). Her fear of the LORD (v. 30) was the root of her courage, her hospitality, her willingness to risk her own life for strangers. She secured her family\'s safety through the scarlet cord (Joshua 2:18) — a detail that has resonated as a foreshadowing of redemption.\n\n'
        'She joined the people of Israel (Joshua 6:25). She married into the tribe of Judah. Her son was Boaz — the man who would call Ruth an eshet chayil. Her name appears in Matthew 1:5 in the genealogy of Jesus. From Jericho to Bethlehem to Nazareth: Rahab\'s fear of the LORD sent ripples into the history of salvation that reached the manger.',
    keyVerses: 'Joshua 2:1–21; 6:22–25; Hebrews 11:31; James 2:25; Matthew 1:5',
    poemConnections: 'vv. 20, 21, 25, 30, 31',
    practices: const [
      'Acting on What You Know (Reflection) — Rahab acted on the knowledge she already had (Josh 2:9–11). Journal: what do you already know about God that you are not yet acting on? Identify one piece of theology you believe but haven’t yet applied to your daily decisions.',
      'The Scarlet Cord (Prayer & Worship) — The scarlet cord is a thread of salvation woven through Rahab’s story and into the genealogy of Jesus. Spend time meditating on Matthew 1:5 and Hebrews 11:31. Praise God for the way he weaves the most unlikely stories into his redemptive purposes — including yours.',
      'Household Salvation (Community) — Rahab asked for the safety of her entire household (Josh 2:13). Who in your household, family, or circle of closest relationships does not yet know God? Write their names. Pray for them daily for the next month.',
      'The Outsider’s Inheritance (Spiritual Disciplines) — Rahab “lived in Israel to this day” (Josh 6:25) and appears in Jesus’ genealogy (Matt 1:5). Practise welcoming the outsider as Rahab herself was welcomed. Identify one person who is on the margins of your community and take one step toward genuine inclusion.',
    ],
  ),
  _Woman(
    name: 'The Widow with Two Mites',
    subtitle: 'Extravagant Generosity',
    description:
        'The unnamed widow of Mark 12:41–44 is perhaps the most radical exemplar of Proverbs 31:20 in the Gospels. Jesus sat opposite the temple treasury and watched. Many rich people put in large sums. The widow "put in two small copper coins, which make a penny."\n\n'
        'Jesus called his disciples over: "This poor widow has put in more than all those who are contributing to the offering box. For they all contributed out of their abundance, but she out of her poverty has put in everything she had, all she had to live on" (Mark 12:43–44). She gave everything. She extended her hands to the needy (v. 20) with nothing held back. She did not eat the bread of idleness (v. 27) — though she had practically nothing to eat. Her trust in God was total.\n\n'
        'She is anonymous. But her works are praised in the gates of history by Jesus himself — and by every sermon that has ever been preached on her. She is the poem\'s most radical illustration of "giving of the fruit of her hands" (v. 31).',
    keyVerses: 'Mark 12:41–44; Luke 21:1–4',
    poemConnections: 'vv. 20, 27, 30, 31',
    practices: const [
      'Kingdom Arithmetic (Generosity) — The widow gave more than all the others combined (Luke 21:3). Practise giving in a way that costs you something real this week — not from surplus but from substance. It doesn’t need to be large by human calculation; it needs to be genuine.',
      'Watched by the One Who Sees (Prayer & Worship) — Jesus sat and watched (Mark 12:41). He sees what no one else notices. Spend time in prayer reflecting on the acts of faithfulness in your life that only God has seen — the prayers prayed, the sacrifices made, the kindnesses given without recognition. Thank him for seeing.',
      'The Widow’s Vulnerability (Community) — Widows in the first century had no social safety net. Jesus’ praise of her is also a rebuke of systems that leave the vulnerable with nothing. Identify one person in genuine material vulnerability in your community. What one concrete act could you take to bear their burden?',
      'Nothing Held Back (Reflection) — She gave her whole living (Mark 12:44). Journal about your own patterns of withholding — from God, from others, from your own calling. What is the thing you are holding back “for safety”? What would total release look like?',
    ],
  ),
  _Woman(
    name: 'Mary, Mother of Jesus',
    subtitle: 'Favoured and Faithful',
    description:
        'Mary of Nazareth sits at the centre of the New Testament\'s gallery of women. She was chosen, not for her accomplishments, but for her character. The angel calls her kecharitomēne — "highly favoured" or "graced" (Luke 1:28). Her response to the most disruptive news any human being has ever received was measured, theologically curious, and ultimately surrendered: "Behold, I am the servant of the Lord; let it be to me according to your word" (Luke 1:38). She laughed at the future — not because she didn\'t understand the cost, but because she trusted the One who had spoken.\n\n'
        'Her Magnificat (Luke 1:46–55) is the most theologically dense poem a woman speaks in the New Testament — a meditation on the character of God, the reversal of social orders, the faithfulness of the covenant. It draws directly on Hannah\'s song and the language of the Psalms. She opens her mouth with wisdom (v. 26). She treasured words and pondered them in her heart (Luke 2:19, 51) — she does not eat the bread of idleness (v. 27) but the bread of contemplation, which feeds everything else.\n\n'
        'She was at the cross (John 19:25). She was in the upper room at Pentecost (Acts 1:14). She stayed through everything. And her own prophecy has been continuously fulfilled: "henceforth all generations will call me blessed" (Luke 1:48) — her children rising up, generation after generation, to call her blessed (v. 28).',
    keyVerses: 'Luke 1:26–55; John 2:1–5; 19:25–27; Acts 1:14',
    poemConnections: 'vv. 11, 25, 26, 28, 30',
    practices: const [
      '"Let It Be" (Prayer & Worship) — Mary’s fiat — “Let it be to me according to your word” (Luke 1:38) — is one of the most consequential prayers in history. Spend time this week practising surrendered prayer: bring a situation to God and say, specifically, “Not my will but yours.” Write down what you’re releasing.',
      'The Magnifying Life (Spiritual Disciplines) — “My soul magnifies the Lord” (Luke 1:46). Praying the Magnificat (Luke 1:46–55) as a regular practice has formed Christians for centuries. Use it as your prayer this week, one verse at a time, letting each line become personal.',
      'Pondering (Reflection) — Mary “teasured up all these things and pondered them in her heart” (Luke 2:19). Practise sacred pondering: at the end of each day this week, write one sentence about where you saw God at work. Don’t analyse — just notice and hold it.',
      'Staying Through the Cross (Community) — Mary was at the cross (John 19:25–27). Not all presence is joyful. Is there someone in your community who is in a season of suffering — illness, grief, crisis — who needs you to simply be there? Choose one person. Show up. Stay.',
    ],
  ),
  _Woman(
    name: 'Junia',
    subtitle: 'Outstanding Among the Apostles',
    description:
        'Junia appears in a single verse: "Greet Andronicus and Junia, my kinsmen and my fellow prisoners. They are well known to the apostles, and they were in Christ before me" (Romans 16:7). Twenty words — but those twenty words carry extraordinary weight.\n\n'
        'She was a woman. She was an apostle. The phrase "well known to the apostles" is most naturally read as "prominent among the apostles" — an interpretation held by the early church fathers including John Chrysostom, who wrote: "How great the wisdom of this woman must have been, that she was even deemed worthy of the title of apostle." She was also, Paul notes, in Christ before him — a believer before Paul\'s Damascus road conversion, which places her among the earliest Jewish Christians in Jerusalem or its environs.\n\n'
        'She had been imprisoned for her faith alongside Andronicus — she arms herself with strength (v. 17) in the most direct and costly sense. She is perhaps the greatest argument against the idea that the poem\'s vision of female strength is confined to domestic life. Junia was an apostle. Her works praised her in the gates (v. 31) of the early church at its most foundational moment.',
    keyVerses: 'Romans 16:7',
    poemConnections: 'vv. 25, 26, 31',
    practices: const [],
  ),
];

// ── Scholarly resources data ──────────────────────────────────────────────

class _Resource {
  final String author;
  final String title;
  final String description;
  const _Resource({required this.author, required this.title, required this.description});
}

const _kPrimaryCommentaries = [
  _Resource(
    author: 'Bruce Waltke',
    title: 'Proverbs (NICOT, 2 vols., Eerdmans, 2004–2005)',
    description: 'The definitive evangelical commentary. Waltke\'s treatment of Proverbs 31 is magisterial, with close attention to the Hebrew, the acrostic structure, and intertextual connections to wisdom literature.',
  ),
  _Resource(
    author: 'Tremper Longman III',
    title: 'Proverbs (Baker Commentary, Baker, 2006)',
    description: 'Readable and theologically rich; excellent on the literary context and the relationship between Proverbs 31 and the wisdom poetry of Proverbs 1–9.',
  ),
  _Resource(
    author: 'Roland Murphy',
    title: 'Proverbs (Word Biblical Commentary, Nelson, 1998)',
    description: 'More technical; particularly valuable on the history of interpretation and the ancient Near Eastern parallels.',
  ),
  _Resource(
    author: 'Ellen F. Davis',
    title: 'Proverbs, Ecclesiastes, and the Song of Songs (WJK, 2000)',
    description: 'Beautifully written; brings literary sensibility and theological depth together. Particularly strong on the Woman of Valour as embodied wisdom.',
  ),
];

const _kWomensScholarship = [
  _Resource(
    author: 'Christine Roy Yoder',
    title: 'Wisdom as a Woman of Substance (de Gruyter, 2001)',
    description: 'Groundbreaking study of the economic and social dimensions of the Woman of Valour. Argues that the poem\'s commercial language is intentional and sophisticated — not to be domesticated.',
  ),
  _Resource(
    author: 'Carolyn Custis James',
    title: 'The Gospel of Ruth (Zondervan, 2008)',
    description: 'Superb on the Ruth–Proverbs 31 intertextual connection and the meaning of chayil. Essential reading for anyone working with this poem in a women\'s context.',
  ),
  _Resource(
    author: 'Phyllis Trible',
    title: 'God and the Rhetoric of Sexuality (Fortress, 1978)',
    description: 'A landmark feminist literary reading. Valuable for close reading of women\'s texts in the OT.',
  ),
];

const _kDevotionalResources = [
  _Resource(
    author: 'Kathleen Nielson',
    title: 'Proverbs: The Ways of Wisdom (P&R, 2018)',
    description: 'An excellent women\'s Bible study with strong exegetical foundations. Accessible without being shallow.',
  ),
  _Resource(
    author: 'Lois Tverberg',
    title: 'Walking in the Dust of Rabbi Jesus (Zondervan, 2012)',
    description: 'Invaluable for understanding the Jewish cultural and liturgical context of Proverbs 31, including the Shabbat tradition of Eshet Chayil.',
  ),
];

const _kNTResources = [
  _Resource(
    author: 'Lynn Cohick',
    title: 'Women in the World of the Earliest Christians (Baker, 2009)',
    description: 'The most comprehensive scholarly treatment of the social, economic, and religious world of NT women. Essential background for Lydia, Priscilla, Phoebe, and Dorcas.',
  ),
  _Resource(
    author: 'N. T. Wright',
    title: 'Paul and the Faithfulness of God (Fortress, 2013), ch. 16',
    description: 'Wright\'s treatment of women in the Pauline communities is theologically nuanced and culturally informed.',
  ),
];

// ── Scripture verses ──────────────────────────────────────────────────────

const _kVerses = [
  (10, 'Who can find a worthy woman?', 'For her price is far above rubies.', null),
  (11, 'The heart of her husband trusts in her.', 'He shall have no lack of gain.', null),
  (12, 'She does him good, and not harm,', 'all the days of her life.', null),
  (13, 'She seeks wool and flax,', 'and works with her hands willingly.', null),
  (14, 'She is like the merchant ships.', 'She brings her bread from afar.', null),
  (15, 'She rises also while it is yet night,', 'gives food to her household,', 'and portions to her servant girls.'),
  (16, 'She considers a field, and buys it.', 'With the fruit of her hands, she plants a vineyard.', null),
  (17, 'She arms her loins with strength,', 'and makes her arms strong.', null),
  (18, 'She perceives that her merchandise is profitable.', 'Her lamp doesn\'t go out by night.', null),
  (19, 'She lays her hands to the distaff,', 'and her hands hold the spindle.', null),
  (20, 'She opens her arms to the poor;', 'yes, she extends her hands to the needy.', null),
  (21, 'She is not afraid of the snow for her household,', 'for all her household are clothed in scarlet.', null),
  (22, 'She makes for herself carpets of tapestry.', 'Her clothing is fine linen and purple.', null),
  (23, 'Her husband is known in the gates,', 'when he sits among the elders of the land.', null),
  (24, 'She makes linen garments and sells them,', 'and delivers sashes to the merchant.', null),
  (25, 'Strength and dignity are her clothing.', 'She laughs at the time to come.', null),
  (26, 'She opens her mouth with wisdom.', 'Kind instruction is on her tongue.', null),
  (27, 'She looks well to the ways of her household,', 'and doesn\'t eat the bread of idleness.', null),
  (28, 'Her children rise up and call her blessed.', 'Her husband also praises her:', null),
  (29, '"Many daughters have done virtuously,', 'but you excel them all."', null),
  (30, 'Charm is deceitful, and beauty is vain;', 'but a woman who fears Yahweh, she shall be praised.', null),
  (31, 'Give her of the fruit of her hands!', 'Let her works praise her in the gates!', null),
];

// ── Main view ─────────────────────────────────────────────────────────────

class WomenOfValorView extends StatefulWidget {
  const WomenOfValorView({super.key});

  @override
  State<WomenOfValorView> createState() => _WomenOfValorViewState();
}

class _WomenOfValorViewState extends State<WomenOfValorView> {
  final Map<String, Map<int, bool>> _adding = {};

  String _habitName(String text) {
    final parts = text.split(' — ');
    final raw = parts.first.trim();
    return raw.length <= 60 ? raw : raw.substring(0, 60);
  }

  Future<void> _addPractice(String womanName, int index, String practiceText) async {
    setState(() => (_adding[womanName] ??= {})[index] = true);
    try {
      await context.read<HabitProvider>().addHabit(
            name: _habitName(practiceText),
            category: _categoryFromPractice(practiceText),
            trackingType: HabitTrackingType.checkIn,
            purpose: practiceText,
            dailyTarget: 1,
            targetUnit: '',
            sourceType: 'women_of_valor_practice',
            categoryId: 'women_of_valor',
            categoryName: 'Women of Valor',
          );
    } finally {
      if (mounted) setState(() => (_adding[womanName] ??= {})[index] = false);
    }
  }

  Widget _practiceCard(String womanName, int index, String text) {
    final isAdding = (_adding[womanName] ?? {})[index] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 13.5, color: MyWalkColor.warmWhite.withValues(alpha: 0.8), height: 1.55)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isAdding ? null : () => _addPractice(womanName, index, text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: isAdding ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAccent.withValues(alpha: isAdding ? 0.1 : 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isAdding)
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(_kAccent.withValues(alpha: 0.6))))
                else
                  Icon(Icons.add, size: 14, color: _kAccent.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(isAdding ? 'Adding…' : 'Add this practice', style: TextStyle(fontSize: 13, color: _kAccent.withValues(alpha: isAdding ? 0.5 : 0.85), fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/Women/womenofvalor.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.6),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Women of Valor',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Eshet Chayil — אשת חייל',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Proverbs 31:10–31',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opening quote
                  _highlightBox(
                    '"Charm is deceitful, and beauty is vain;\nbut a woman who fears Yahweh, she shall be praised."\n\n— Proverbs 31:30 (WEB)',
                    italic: true,
                    centered: true,
                  ),
                  const SizedBox(height: 36),

                  // ── Section 1 ────────────────────────────────────────
                  _sectionTitle('1.', 'Audience & Context'),
                  _divider(),
                  const SizedBox(height: 16),
                  _subsectionTitle('Who Wrote It, and For Whom?'),
                  _body('Proverbs 31 is the conclusion of the entire book of Proverbs, and it ends with two distinct poems. The first (vv. 1–9) is the instruction of King Lemuel\'s mother — a queen mother teaching her royal son about integrity and justice. The second (vv. 10–31) is the famous acrostic poem known in Jewish tradition as Eshet Chayil: "Woman of Valour."'),
                  _body('The book of Proverbs is addressed primarily to young men ("my son" is the recurring address), yet it opens and closes with women as the authoritative voices. Wisdom herself is personified as a woman (Proverbs 8–9), and the book ends with a portrait of a woman who embodies her. The young man who began Proverbs learning to seek wisdom ends by recognising her in a real, embodied human life.'),
                  const SizedBox(height: 12),
                  _subsectionTitle('Authorship and Dating'),
                  _body('The title of 31:1 attributes these words to King Lemuel\'s mother. While Lemuel cannot be identified with certainty, the poem\'s final form belongs to the later editing of Proverbs, likely during or after the return from exile (6th–5th century BC), when the book was compiled in its canonical shape.'),
                  const SizedBox(height: 12),
                  _subsectionTitle('Cultural Setting'),
                  _body('The poem describes a woman of means in ancient Israelite society — likely urban, prosperous, married into a family of standing. She is not a servant or slave but a woman with genuine agency. She manages commercial transactions, employs household staff, and makes independent investment decisions. Dismissing her as "just a housewife" misreads the poem entirely.'),
                  const SizedBox(height: 12),
                  _subsectionTitle('Liturgical Life'),
                  _body('In Jewish practice, Proverbs 31:10–31 is traditionally sung by husbands to their wives at the Shabbat table on Friday evenings — not as a measuring stick, but as a blessing and a song of praise. The poem was designed to be sung over a woman, not recited at her as a standard. It is a celebration, not a curriculum.'),
                  const SizedBox(height: 36),

                  // ── Section 2 ────────────────────────────────────────
                  _sectionTitle('2.', 'Hebrew Literary Note — The Acrostic Structure'),
                  _divider(),
                  const SizedBox(height: 16),
                  _highlightBox(
                    'The poem is an acrostic: each of its 22 verses begins with a successive letter of the Hebrew alphabet, from aleph (א) to taw (ת). This literary device — used also in Psalm 119, Psalm 34, and the book of Lamentations — carries deliberate meaning.\n\n'
                    'In Hebrew literary culture, an acrostic from aleph to taw signified completeness, much as we say "from A to Z." The poem is not a partial list of virtues the woman happens to have. It is declaring, through its very structure, that she embodies virtue in its fullness.\n\n'
                    'For the reader today, the structural point is this: you are not reading a checklist. You are reading a poem about wholeness. The Woman of Valour is not someone who has ticked 22 boxes; she is someone whose life, in its completeness, reflects the character of God.',
                  ),
                  const SizedBox(height: 36),

                  // ── Section 3 ────────────────────────────────────────
                  _sectionTitle('3.', 'The Word "Chayil" — A Note on Translation'),
                  _divider(),
                  const SizedBox(height: 16),
                  _body('The Hebrew phrase translated "worthy woman," "capable wife," "excellent wife," or "virtuous woman" in various English versions is אֵשֶׁת חַיִל (eshet chayil).'),
                  _body('The word chayil (חַיִל) is powerful and frequently mistranslated. Across the Hebrew Bible, it most commonly means:'),
                  _bullet('Strength, might, valour — used of armies and warriors: "mighty men of valour" (Joshua 1:14; 6:2; 10:7)'),
                  _bullet('Wealth, resources, and substance'),
                  _bullet('Capability and competence in their fullest expression'),
                  const SizedBox(height: 12),
                  _body('The same word appears in Ruth 3:11 when Boaz says to Ruth: "All the city of my people knows that you are a woman of chayil." He is not calling her tidy or domestically competent. He is calling her a woman of strength and honour — the same honour attributed to warriors.'),
                  const SizedBox(height: 12),
                  _highlightBox(
                    'The Woman of Proverbs 31 is not primarily a homemaker. She is a warrior of character — strong, capable, strategic, generous, and rooted in the fear of the LORD.\n\nShe is not the Ideal Wife. She is the Valiant Woman.',
                    bold: true,
                  ),
                  const SizedBox(height: 36),

                  // ── Section 4 ────────────────────────────────────────
                  _sectionTitle('4.', 'A Grace Note — Before You Read'),
                  _divider(),
                  const SizedBox(height: 16),
                  _highlightBox(
                    'This passage has been used, with the best of intentions, to wound women rather than celebrate them. It has been preached as a standard no one can reach — a portrait that leaves women feeling perpetually inadequate. If that is how you have heard it before, hear this first:\n\n'
                    'The poem does not begin with a command. It begins with a question: "Who can find a worthy woman?" The implication is not that she is impossibly rare — it is that she is astonishingly valuable. The poem is a song of praise, not a job description.\n\n'
                    'The woman in this poem is not anxious. She "laughs at the time to come" (v. 25). She is not performing for approval — she "fears the LORD" (v. 30), and her works flow from that centre.\n\n'
                    'Read this as a picture of who you are becoming in Christ, not a measuring rod for who you have failed to be.',
                    bold: true,
                  ),
                  const SizedBox(height: 36),

                  // ── Section 5 ────────────────────────────────────────
                  _sectionTitle('5.', 'The Story in Brief'),
                  _divider(),
                  const SizedBox(height: 16),
                  _body('The poem is not a narrative — it has no plot — but it has a movement. It begins with her value ("her price is far above rubies," v. 10) and the trust she has earned (vv. 11–12). It unfolds in a sweeping panorama of her daily life: her industry (vv. 13–19), her generosity (v. 20), her provision and care (vv. 21–22), her husband\'s honour (v. 23), her commerce (v. 24), her dignity and wisdom (vv. 25–26), her household oversight (v. 27), and finally her family\'s praise (vv. 28–29).'),
                  _body('But the poem does not end with any of these things. It ends — in a deliberate anti-climax — with a theological statement: "Charm is deceitful, and beauty is vain; but a woman who fears the LORD, she shall be praised" (v. 30). Everything in the poem flows from this. Her fear of the LORD is the root; the rest of the poem is the fruit.'),
                  _body('The final verse is a call to public honour: "Let her works praise her in the gates" (v. 31). In ancient Israel, the "gates" were the city\'s public forum — the place of commerce, law, and civic life. The poem ends by insisting that this woman\'s life deserves recognition in the fullest possible public sense.'),
                  const SizedBox(height: 36),

                  // ── Section 6 ────────────────────────────────────────
                  _sectionTitle('6.', 'The Central Point'),
                  _divider(),
                  const SizedBox(height: 16),
                  _highlightBox(
                    'The Woman of Valour is the embodied answer to the whole book of Proverbs.\n\n'
                    'Proverbs has spent thirty chapters calling its reader to seek Wisdom — to choose her, fear the LORD, walk in her ways, build a life on her foundation. Proverbs 31:10–31 shows us what it looks like when someone does exactly that.\n\n'
                    'A life ordered by the fear of the LORD becomes a life of extraordinary strength, generosity, wisdom, and dignity — and it will be praised.\n\n'
                    'The woman who fears the LORD does not become a better version of herself by trying harder. She becomes more fully herself as her fear of the LORD grows deeper. The poem is Wisdom\'s self-portrait.',
                    bold: true,
                  ),
                  const SizedBox(height: 36),

                  // ── Section 7 ────────────────────────────────────────
                  _sectionTitle('7.', 'The Question It Asks You'),
                  _divider(),
                  const SizedBox(height: 16),
                  _highlightBox(
                    'Which virtue in this woman\'s life comes most naturally to you — and which do you most avoid? What does your answer reveal about where fear of the LORD is, and is not, active in you?',
                    italic: true,
                  ),
                  const SizedBox(height: 36),

                  // ── Section 8 ────────────────────────────────────────
                  _sectionTitle('8.', 'Key Verses for Memorisation'),
                  _divider(),
                  const SizedBox(height: 16),
                  _verseLabel('Primary verse:'),
                  _verseCard(
                    '"Strength and dignity are her clothing. She laughs at the time to come."',
                    '— Proverbs 31:25 (WEB)',
                  ),
                  const SizedBox(height: 12),
                  _verseLabel('For wisdom:'),
                  _verseCard(
                    '"She opens her mouth with wisdom. Kind instruction is on her tongue."',
                    '— Proverbs 31:26 (WEB)',
                  ),
                  const SizedBox(height: 12),
                  _verseLabel('The climactic verse:'),
                  _verseCard(
                    '"Charm is deceitful, and beauty is vain; but a woman who fears Yahweh, she shall be praised."',
                    '— Proverbs 31:30 (WEB)',
                  ),
                  const SizedBox(height: 36),

                  // ── Section 9 ────────────────────────────────────────
                  _sectionTitle('9.', 'Scripture — Proverbs 31:10–31'),
                  _divider(),
                  const SizedBox(height: 16),
                  _scriptureBlock(),
                  const SizedBox(height: 36),

                  // ── Section 10 ───────────────────────────────────────
                  _sectionTitle('10.', '"Your Why" — Identity Aphorisms'),
                  _divider(),
                  const SizedBox(height: 12),
                  _body('Speak these as declarations of who you are becoming, not goals you are striving toward.'),
                  const SizedBox(height: 12),
                  _aphorism('I am a woman of valour — not because of what I achieve, but because of whose I am.'),
                  _aphorism('My strength and dignity come from the LORD, not from the approval of others.'),
                  _aphorism('I extend my hands to the needy because I have received grace I did not earn.'),
                  _aphorism('I open my mouth with wisdom because I have sat long at the feet of the Wise One.'),
                  _aphorism('I laugh at the future because I trust the One who holds it.'),
                  const SizedBox(height: 36),

                  // ── Section 11 ───────────────────────────────────────
                  _sectionTitle('11.', 'Suggested Practices'),
                  _divider(),
                  const SizedBox(height: 12),
                  _body('Five concrete habits drawn from the poem:'),
                  const SizedBox(height: 12),
                  _practice('Prayer & Worship', 'Begin one day each week by praying Proverbs 31:30 over yourself — not as a goal but as a declaration: "I am a woman who fears the LORD." Let the prayer shape the day.'),
                  _practice('Generosity', 'Identify one practical way each week to "extend your hands to the needy" (v. 20) — financial, practical, or relational. Let it be specific, not vague.'),
                  _practice('Wisdom', 'Cultivate a monthly habit of reading one chapter of Proverbs in a single sitting, listening for wisdom\'s voice rather than looking for rules.'),
                  _practice('Stewardship', 'Choose one area of your home or work life that is languishing (the "bread of idleness", v. 27) and give it one focused hour of intentional care this week.'),
                  _practice('Community', 'Find one woman to speak "kind instruction" (v. 26) to this week — not flattery, but a true and specific word of encouragement grounded in what you have genuinely observed.'),
                  const SizedBox(height: 36),

                  // ── Section 12 ───────────────────────────────────────
                  _sectionTitle('12.', 'Women of Scripture — Living the Poem'),
                  _divider(),
                  const SizedBox(height: 12),
                  Text(
                    'The Eshet Chayil is not an abstract portrait. She has faces. The following women from Scripture each embody one or more of the poem\'s virtues with particular clarity. Read their stories alongside the poem, and the poem comes alive.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._kWomen.map(_womanTile),
                  const SizedBox(height: 36),

                  // ── Section 13 ───────────────────────────────────────
                  _sectionTitle('13.', 'Scholarly Resources'),
                  _divider(),
                  const SizedBox(height: 12),
                  Text(
                    'The following resources combine rigorous scholarship with accessibility for pastoral and devotional use.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _resourceGroupTitle('Primary Commentaries on Proverbs'),
                  ..._kPrimaryCommentaries.map(_resourceEntry),
                  const SizedBox(height: 12),
                  _resourceGroupTitle('Women\'s Scholarship and Feminist Readings'),
                  ..._kWomensScholarship.map(_resourceEntry),
                  const SizedBox(height: 12),
                  _resourceGroupTitle('For Women\'s Devotional Groups'),
                  ..._kDevotionalResources.map(_resourceEntry),
                  const SizedBox(height: 12),
                  _resourceGroupTitle('On Women in the New Testament'),
                  ..._kNTResources.map(_resourceEntry),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────

  Widget _sectionTitle(String number, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$number  ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPurple,
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPurple,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.only(top: 6),
        height: 1,
        color: _kPurple.withValues(alpha: 0.3),
      );

  Widget _subsectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kAccent,
            height: 1.3,
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.78),
            height: 1.65,
          ),
        ),
      );

  Widget _highlightBox(String text, {bool bold = false, bool italic = false, bool centered = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: MyWalkColor.softGold.withValues(alpha: 0.88),
          height: 1.65,
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: _kAccent, fontSize: 14, height: 1.65)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.78),
                  height: 1.65,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _verseLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _verseCard(String verse, String ref) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.88),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ref,
              style: const TextStyle(
                fontSize: 12,
                color: _kAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _scriptureBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROVERBS 31:10–31',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kAccent,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ..._kVerses.map((v) => _scriptureVerse(v.$1, v.$2, v.$3, v.$4)),
        ],
      ),
    );
  }

  Widget _scriptureVerse(int num, String line1, String? line2, String? line3) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$num',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kAccent,
                height: 1.7,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line1, style: TextStyle(fontSize: 13.5, color: MyWalkColor.warmWhite.withValues(alpha: 0.88), height: 1.65)),
                if (line2 != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(line2, style: TextStyle(fontSize: 13.5, color: MyWalkColor.warmWhite.withValues(alpha: 0.88), height: 1.65)),
                  ),
                if (line3 != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(line3, style: TextStyle(fontSize: 13.5, color: MyWalkColor.warmWhite.withValues(alpha: 0.88), height: 1.65)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aphorism(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 10),
              child: Icon(Icons.favorite_rounded, size: 10, color: _kAccent),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _practice(String category, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: _kAccent, fontSize: 14, height: 1.65)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.78),
                    height: 1.65,
                  ),
                  children: [
                    TextSpan(
                      text: '$category: ',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: _kAccent),
                    ),
                    TextSpan(text: description),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _womanTile(_Woman woman) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAccent.withValues(alpha: 0.18)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            woman.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kAccent,
              height: 1.3,
            ),
          ),
          subtitle: Text(
            woman.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          iconColor: _kAccent,
          collapsedIconColor: _kAccent.withValues(alpha: 0.5),
          children: [
            Text(
              woman.description,
              style: TextStyle(
                fontSize: 13.5,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.78),
                height: 1.65,
              ),
            ),
            const SizedBox(height: 12),
            _keyVerseRow('Key verses', woman.keyVerses),
            const SizedBox(height: 4),
            _keyVerseRow('Poem connections', woman.poemConnections),
            if (woman.practices.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'SUGGESTED PRACTICES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kAccent.withValues(alpha: 0.7),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              ...woman.practices.asMap().entries.map(
                (e) => _practiceCard(woman.name, e.key, e.value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _keyVerseRow(String label, String value) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: MyWalkColor.warmWhite.withValues(alpha: 0.6), height: 1.5),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, color: _kAccent),
            ),
            TextSpan(text: value),
          ],
        ),
      );

  Widget _resourceGroupTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kAccent,
            height: 1.3,
          ),
        ),
      );

  Widget _resourceEntry(_Resource r) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: _kAccent, fontSize: 13, height: 1.6)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(
                      text: '${r.author}, ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: '${r.title}. ',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(text: r.description),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
