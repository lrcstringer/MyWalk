import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const _kAccent = Color(0xFFB89AC8); // soft violet-rose
const _kPurple = Color(0xFF7B5EA7); // section header purple

// ── Women of Scripture data ───────────────────────────────────────────────

class _Woman {
  final String name;
  final String subtitle;
  final String description;
  final String keyVerses;
  final String poemConnections;
  const _Woman({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.keyVerses,
    required this.poemConnections,
  });
}

const _kWomen = [
  _Woman(
    name: 'Ruth',
    subtitle: 'The Woman the Poem Names',
    description:
        'There is one woman in all of Scripture whom someone directly addresses as eshet chayil — using the exact phrase of Proverbs 31:10. That woman is Ruth.\n\n'
        'In Ruth 3:11, Boaz says to her: "All the city of my people knows that you are a woman of chayil." Many scholars believe the book of Ruth and Proverbs 31 are in deliberate conversation — that Ruth is, in some sense, the poem\'s own illustration of itself.\n\n'
        'Ruth works with her hands, rises early, extends herself to Naomi when she had every right to leave, and makes wise, courageous decisions. Most significantly, her story ends at "the gates" — the very location where Proverbs 31:31 insists the woman of valour should be praised.',
    keyVerses: 'Ruth 1:16–17; 2:11–12; 3:11; 4:13–17',
    poemConnections: 'vv. 10, 13, 15, 16, 20, 28, 31',
  ),
  _Woman(
    name: 'Deborah',
    subtitle: 'The Warrior Judge',
    description:
        'Deborah (Judges 4–5) is the only woman in the Old Testament described as both a judge and a prophet. She held court under a palm tree between Ramah and Bethel — Israel\'s supreme court and national conscience simultaneously.\n\n'
        'When God called her to lead the military campaign against Sisera, she did not hesitate. Deborah\'s song in Judges 5 — one of the oldest pieces of poetry in the Hebrew Bible — is a masterwork of theological and military narrative. She "arose as a mother in Israel" (Judges 5:7), using the language of nurture even in the context of war. She is not domesticated strength; she is full-spectrum valour.',
    keyVerses: 'Judges 4:4–9; 5:1–7; 5:31',
    poemConnections: 'vv. 17, 25, 26, 27',
  ),
  _Woman(
    name: 'Jael',
    subtitle: 'Courageous Action at the Right Moment',
    description:
        'Jael (Judges 4:17–22) is often overlooked, partly because her act is jarring to modern readers. But within the poem\'s framework she is essential. Deborah had prophesied that "the LORD will sell Sisera into the hand of a woman" — Jael was that woman.\n\n'
        'When Sisera sought shelter in her tent, she made a rapid, courageous, morally serious decision. Deborah\'s song celebrates her: "Most blessed of women is Jael… most blessed of women in the tent" (Judges 5:24). She embodies "she arms her loins with strength" (v. 17) in its most stark expression. The poem\'s heroism is not soft.',
    keyVerses: 'Judges 4:17–22; 5:24–27',
    poemConnections: 'vv. 17, 25, 28',
  ),
  _Woman(
    name: 'Abigail',
    subtitle: 'Wisdom in a Crisis',
    description:
        'Abigail (1 Samuel 25) is one of the most remarkable figures in the Old Testament — a woman of extraordinary wisdom, courage, and speed of thought, married to a man described as "harsh and badly behaved." The text introduces her as "discerning and beautiful."\n\n'
        'When her husband Nabal insulted David, setting the household on a path toward massacre, Abigail loaded donkeys with food, rode out to meet David, and delivered one of the most theologically sophisticated speeches in the entire narrative books. Her instruction saved a future king from the guilt of unnecessary bloodshed.\n\n'
        'David\'s response was immediate: "Blessed be your discernment, and blessed be you" (1 Sam 25:33). He changed course because of a woman\'s wisdom.',
    keyVerses: '1 Samuel 25:3, 14–31, 39–42',
    poemConnections: 'vv. 11, 23, 25, 26',
  ),
  _Woman(
    name: 'Esther',
    subtitle: 'Dignity in the Face of Death',
    description:
        'Esther\'s story is one of the greatest narratives of courage in Scripture, made more remarkable by its hiddenness — God is never explicitly mentioned in the book, yet his hand is everywhere.\n\n'
        'Esther did not act impulsively. When Mordecai urged her to intercede, she first called for three days of fasting. She prepared. She took counsel. Then she acted: "I will go to the king, which is against the law; and if I perish, I perish" (Esther 4:16). She said it twice because she knew it might happen. And still she went.\n\n'
        '"Strength and dignity are her clothing; she laughs at the time to come" (v. 25). Esther\'s laughter is the laughter of a woman who has given her outcome to God and is therefore free to act without being paralysed by fear.',
    keyVerses: 'Esther 4:12–16; 5:1–3; 9:29–32',
    poemConnections: 'vv. 16, 21, 22, 25, 28, 30, 31',
  ),
  _Woman(
    name: 'Hannah',
    subtitle: 'Prayer as the Foundation of Provision',
    description:
        'Hannah (1 Samuel 1–2) is the great exemplar of prayer in the Old Testament. Barren and despised, she brought her grief to the LORD with such intensity that Eli thought she was drunk. She vowed. She waited. She was faithful.\n\n'
        'What elevates Hannah is her response. She had prayed for a son, received him — and then gave him back, dedicating Samuel to the LORD\'s service for life. Her generosity outran even what God had asked.\n\n'
        'Her song in 1 Samuel 2:1–10 — the Magnificat\'s direct precursor — is a theological declaration of the LORD\'s character. Mary of Nazareth almost certainly knew it by heart. Hannah\'s song shaped the understanding of what God\'s kingdom looks like, centuries before Jesus arrived.',
    keyVerses: '1 Samuel 1:10–18, 26–28; 2:1–10',
    poemConnections: 'vv. 15, 20, 28, 30',
  ),
  _Woman(
    name: 'Lydia',
    subtitle: 'The Businesswoman of Purple',
    description:
        'Lydia (Acts 16:14–15) is introduced with unusual precision: "a seller of purple goods, from the city of Thyatira, who was a worshipper of God." She is a woman of means, commerce, and faith — and the combination is presented as entirely unremarkable.\n\n'
        'Purple dye was extraordinarily expensive — worth more than its weight in gold. Lydia\'s trade was empire-wide. Note the direct echo: the Woman of Valour\'s clothing is "fine linen and purple" (v. 22) — the very material Lydia traded.\n\n'
        'When the LORD opened her heart, she and her household were baptised. She immediately insisted Paul and his companions stay in her home. Lydia became the founding patron of the church at Philippi — the church Paul wrote to in his most affectionate letter.',
    keyVerses: 'Acts 16:13–15, 40; Philippians 1:3–5',
    poemConnections: 'vv. 13, 14, 16, 22, 24, 25, 27, 30, 31',
  ),
  _Woman(
    name: 'Priscilla',
    subtitle: 'The Teacher of Apollos',
    description:
        'Priscilla is mentioned six times in the New Testament; in four of those she is named before her husband Aquila — almost certainly indicating she was the more prominent of the two in the Christian community.\n\n'
        'She and Aquila were tentmakers who hosted a church in their home in Corinth, then Rome, then Ephesus. When Apollos arrived in Ephesus — "an eloquent man, competent in the Scriptures" — Priscilla and Aquila recognised a gap in his understanding and "explained to him the way of God more accurately." Priscilla taught a gifted male preacher with grace and precision.\n\n'
        'Paul calls her a "fellow worker in Christ Jesus" who "risked their necks" for his life (Romans 16:3–4). She is a woman of chayil — strength, risk, and wisdom in service of the kingdom.',
    keyVerses: 'Acts 18:2–3, 18–19, 24–26; Romans 16:3–5',
    poemConnections: 'vv. 11, 13, 16, 24, 25, 26, 27, 31',
  ),
  _Woman(
    name: 'Mary of Bethany',
    subtitle: 'The Good Portion',
    description:
        'Mary of Bethany appears three times in the Gospels, and each time she is at the feet of Jesus: listening to him teach (Luke 10:39), mourning after Lazarus\'s death (John 11:32), and anointing his feet with expensive perfume (John 12:3). Her posture is constant: she is always oriented toward Jesus.\n\n'
        'Jesus\'s response to Martha reveals the deeper point: "Mary has chosen the good portion, which will not be taken away from her" (Luke 10:42). Mary had not drifted into passive sitting. She had actively chosen to prioritise one thing — the fear of the LORD, sitting at his feet — which is, per Proverbs 31:30, the root of everything the poem describes.',
    keyVerses: 'Luke 10:38–42; John 11:28–32; John 12:1–8',
    poemConnections: 'vv. 20, 26, 28, 30',
  ),
  _Woman(
    name: 'Mary Magdalene',
    subtitle: 'First Witness of the Resurrection',
    description:
        'Mary Magdalene is perhaps the most misrepresented woman in Christian history — wrongly identified with the unnamed sinful woman of Luke 7. What the Bible actually says is simpler and more remarkable: she was a woman from whom Jesus had cast out seven demons, who became one of his most devoted followers, and was the first human being to witness the risen Christ.\n\n'
        'She was at the cross when nearly all the male disciples had fled. She arrived at the empty tomb "while it was still dark" (John 20:1) — she rises while it is yet night (v. 15), her lamp not gone out (v. 18). And she was the first person the risen Jesus chose to appear to.\n\n'
        'The early church called her Apostola Apostolorum — Apostle to the Apostles. Let her works praise her in the gates — and they have, in every Easter proclamation since.',
    keyVerses: 'Luke 8:1–3; Mark 15:40–41; John 20:1–18',
    poemConnections: 'vv. 15, 18, 28, 30, 31',
  ),
  _Woman(
    name: 'Dorcas / Tabitha',
    subtitle: 'Her Works Were Her Testimony',
    description:
        'Dorcas (Acts 9:36–42) appears in only eleven verses, but her impact was immediate and community-wide. She was a disciple — Luke uses the feminine form mathētria — who was "always doing good and helping the poor." When she died, the widows of Joppa stood around Peter weeping and showing him the tunics and garments she had made.\n\n'
        'She had worked with her hands (v. 13). She had extended her hands to the needy (v. 20). Her work was so personal and tangible that the widows were not simply grieving a benefactor — they were grieving a friend who had made their clothes.\n\n'
        'Peter raised her from the dead. Her resurrection became a turning point for the whole region: "many believed in the Lord" (Acts 9:42). Her works praised her in the gates — literally, through the gates of death and back.',
    keyVerses: 'Acts 9:36–42',
    poemConnections: 'vv. 13, 19, 20, 24, 28, 31',
  ),
  _Woman(
    name: 'The Daughters of Zelophehad',
    subtitle: 'Claiming Their Inheritance',
    description:
        'The five daughters of Zelophehad — Mahlah, Noah, Hoglah, Milcah, and Tirzah (Numbers 27) — appear in one of the most quietly revolutionary moments in the Pentateuch. Their father had died without male heirs; under existing law his property would pass to the nearest male relative, leaving his daughters with nothing.\n\n'
        'They went to Moses, to the priest Eleazar, to the leaders, to the whole congregation — at the entrance to the tent of meeting. They stated their case clearly, without apology: "Why should the name of our father be removed? Give us a possession among our father\'s brothers."\n\n'
        'God\'s response: "The daughters of Zelophehad are right." God changed the law. Five women changed Israelite inheritance law — and their case is settled definitively in Joshua 17.',
    keyVerses: 'Numbers 27:1–8; Joshua 17:3–6',
    poemConnections: 'vv. 16, 25, 26, 31',
  ),
  _Woman(
    name: 'Anna the Prophetess',
    subtitle: 'The Long Vigil',
    description:
        'Anna (Luke 2:36–38) had been married seven years before her husband died, then lived as a widow until she was eighty-four — decades of faithful obscurity. During those years "she did not depart from the temple, worshipping with fasting and prayer night and day." Her whole life was a single extended act of worship.\n\n'
        'Her lamp does not go out by night (v. 18) in the most literal and sustained sense in all of Scripture. She is the keeper of the long vigil.\n\n'
        'When Mary and Joseph brought the infant Jesus to the temple, Anna immediately gave thanks and began to speak of him to all who were waiting for the redemption of Jerusalem. She had waited for decades. She recognised him in an instant.',
    keyVerses: 'Luke 2:36–38',
    poemConnections: 'vv. 15, 18, 26, 30, 31',
  ),
  _Woman(
    name: 'Eunice and Lois',
    subtitle: 'Mothers of Faith',
    description:
        'Eunice and Lois appear only briefly in the New Testament, but their influence spans generations. Paul writes to Timothy: "I am reminded of your sincere faith, a faith that dwelt first in your grandmother Lois and your mother Eunice and now, I am sure, dwells in you as well" (2 Timothy 1:5). Faith as inheritance — transmitted and nurtured in the ordinary daily life of a family.\n\n'
        'Eunice was a Jewish believer married to a Greek man — navigating a cross-cultural marriage without losing either her faith or her son. Timothy knew "the sacred writings" from childhood, which means Eunice and Lois had taught him the Scriptures from infancy. Their children rose up and called them blessed — not in words, but in a life. Timothy is their testimony.',
    keyVerses: 'Acts 16:1; 2 Timothy 1:5; 3:14–15',
    poemConnections: 'vv. 26, 27, 28, 30',
  ),
  _Woman(
    name: 'Phoebe',
    subtitle: 'The Deaconess Who Carried Romans',
    description:
        'Paul writes in Romans 16:1–2: "I commend to you our sister Phoebe, a deaconess of the church at Cenchreae… for she has been a patron of many and of myself as well."\n\n'
        'She was a diakonos — a deacon or minister. She was a prostatis — a patron of social standing and financial means. Most significantly: the scholarly consensus is that Phoebe was the courier who carried Paul\'s letter to the Romans across the Mediterranean — and as the letter\'s bearer, she would have been the one to read it aloud to the Roman church and field questions about its content.\n\n'
        'She was, in effect, the letter\'s first expositor. She delivered the most important document in the history of Christian theology. Let her works praise her in the gates (v. 31).',
    keyVerses: 'Romans 16:1–2',
    poemConnections: 'vv. 13, 16, 20, 24, 25, 31',
  ),
  _Woman(
    name: 'The Shunammite Woman',
    subtitle: 'Practical Hospitality and Resilient Faith',
    description:
        'The unnamed Shunammite woman (2 Kings 4 and 8) was "a wealthy woman" who urged Elisha to eat with her, then persuaded her husband to build a small room on the roof for him — furnishing it with a bed, a table, a chair, and a lamp. Her practical generosity was precise and thoughtful.\n\n'
        'When her son died suddenly, she did not panic. She saddled a donkey and rode urgently to Elisha, saying "All is well" until she reached him. She managed her household and emotions with remarkable steadiness: "Strength and dignity are her clothing; she laughs at the time to come" (v. 25).\n\n'
        'She reappears in 2 Kings 8 — seven years after leaving the land during a famine — calmly petitioning the king for the restoration of her house and land. And she received it.',
    keyVerses: '2 Kings 4:8–37; 8:1–6',
    poemConnections: 'vv. 11, 16, 20, 21, 25, 27',
  ),
  _Woman(
    name: 'Rahab',
    subtitle: 'Fear of the LORD as the Root of Courage',
    description:
        'Rahab (Joshua 2; 6:22–25) is one of the most surprising entries in the hall of faith — a Canaanite woman from Jericho who hid the Israelite spies and secured her family\'s survival. She is cited in two New Testament passages as a model of saving faith.\n\n'
        'She tells the spies directly: "I know that the LORD has given you the land… for the LORD your God, he is God in the heavens above and on the earth beneath" (Joshua 2:9, 11). Her fear of the LORD was the root of her courage, her hospitality, her willingness to risk her life for strangers.\n\n'
        'She joined Israel, married into the tribe of Judah, and her son was Boaz — the man who would call Ruth an eshet chayil. Her name appears in Matthew 1:5 in the genealogy of Jesus.',
    keyVerses: 'Joshua 2:1–21; 6:22–25; Hebrews 11:31; Matthew 1:5',
    poemConnections: 'vv. 20, 21, 25, 30, 31',
  ),
  _Woman(
    name: 'The Widow with Two Mites',
    subtitle: 'Extravagant Generosity',
    description:
        'The unnamed widow of Mark 12:41–44 is perhaps the most radical exemplar of Proverbs 31:20 in the Gospels. Jesus sat opposite the temple treasury and watched. Many rich people put in large sums. The widow put in two small copper coins.\n\n'
        '"This poor widow has put in more than all those who are contributing to the offering box. For they all contributed out of their abundance, but she out of her poverty has put in everything she had, all she had to live on" (Mark 12:43–44).\n\n'
        'She is anonymous. But her works are praised in the gates of history by Jesus himself — and by every sermon ever preached on her. She is the poem\'s most radical illustration of "giving of the fruit of her hands" (v. 31).',
    keyVerses: 'Mark 12:41–44; Luke 21:1–4',
    poemConnections: 'vv. 20, 27, 30, 31',
  ),
  _Woman(
    name: 'Mary, Mother of Jesus',
    subtitle: 'Favoured and Faithful',
    description:
        'Mary of Nazareth was chosen not for her accomplishments, but for her character. The angel calls her kecharitomēne — "highly favoured" or "graced" (Luke 1:28). Her response to the most disruptive news any human being has ever received was measured, theologically curious, and ultimately surrendered: "Behold, I am the servant of the Lord; let it be to me according to your word" (Luke 1:38).\n\n'
        'Her Magnificat (Luke 1:46–55) is the most theologically dense poem a woman speaks in the New Testament — a meditation on the character of God, the reversal of social orders, the faithfulness of the covenant. It draws directly on Hannah\'s song. She opens her mouth with wisdom (v. 26).\n\n'
        'She was at the cross (John 19:25). She was in the upper room at Pentecost (Acts 1:14). And her own prophecy has been continuously fulfilled: "henceforth all generations will call me blessed" — her children rising up, generation after generation, to call her blessed (v. 28).',
    keyVerses: 'Luke 1:26–55; John 2:1–5; 19:25–27; Acts 1:14',
    poemConnections: 'vv. 11, 25, 26, 28, 30',
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

class WomenOfValorView extends StatelessWidget {
  const WomenOfValorView({super.key});

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
                    'assets/Women/womenofvalor.png',
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
