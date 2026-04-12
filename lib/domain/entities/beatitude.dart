class SupportingBeatitudeVerse {
  final String text;
  final String ref;
  const SupportingBeatitudeVerse({required this.text, required this.ref});
}

class BeatitudePractice {
  final String text;
  final String habit; // e.g. 'Prayer', 'God\'s Word'
  const BeatitudePractice({required this.text, required this.habit});
}

class BeatitudeModel {
  final int number;
  final String title;
  final String verse;
  final String verseRef;
  final String promise;
  final String yourWhy;
  final String whatThisMeans;
  final String keyVerse;
  final String keyVerseRef;
  final String reflectionQuestion;
  final List<BeatitudePractice> practices;
  final List<String> fruitConnection;
  final List<SupportingBeatitudeVerse> supportingVerses;
  final String imagePath;

  // ── Scholarly fields ───────────────────────────────────────────────────────
  final String greekText;
  final String statementInBrief;
  final String centralPointTitle;
  final String centralPoint;
  final String audienceContext;
  final String historicalContext;
  final String scholarlyInterpretation;
  final String exegeticalNotes;
  final String pdfQuestion;
  final List<String> pdfPractices;

  const BeatitudeModel({
    required this.number,
    required this.title,
    required this.verse,
    required this.verseRef,
    required this.promise,
    required this.yourWhy,
    required this.whatThisMeans,
    required this.keyVerse,
    required this.keyVerseRef,
    required this.reflectionQuestion,
    required this.practices,
    required this.fruitConnection,
    required this.supportingVerses,
    required this.imagePath,
    this.greekText = '',
    this.statementInBrief = '',
    this.centralPointTitle = '',
    this.centralPoint = '',
    this.audienceContext = '',
    this.historicalContext = '',
    this.scholarlyInterpretation = '',
    this.exegeticalNotes = '',
    this.pdfQuestion = '',
    this.pdfPractices = const [],
  });
}

const List<BeatitudeModel> kBeatitudes = [
  // ── 1. Poor in Spirit ──────────────────────────────────────────────────────
  BeatitudeModel(
    number: 1,
    title: 'Poor in Spirit',
    verse: 'Blessed are the poor in spirit, for theirs is the kingdom of heaven.',
    verseRef: 'Matthew 5:3',
    promise: 'theirs is the kingdom of heaven',
    yourWhy: 'I come to God with empty hands because that is the only way to receive what He is offering \u2014 and the kingdom belongs not to those who have it together, but to those who know they don\'t.',
    whatThisMeans: 'To be poor in spirit is to recognise your complete spiritual bankruptcy before God \u2014 no self-sufficiency, no hidden reserves of goodness to rely on. It is the opposite of pride. It is the posture of someone who has stopped pretending and started depending. Jesus places this first because it is the gateway to everything else \u2014 nothing else in the Beatitudes is possible without it.',
    keyVerse: 'God opposes the proud but gives grace to the humble.',
    keyVerseRef: 'James 4:6',
    reflectionQuestion: 'Where am I still relying on my own strength, goodness or competence instead of coming to God with open hands?',
    practices: [
      BeatitudePractice(text: 'Begin each day this week with a written prayer of dependence \u2014 acknowledging specifically what you cannot do without God', habit: 'Prayer'),
      BeatitudePractice(text: 'Confess to God one area where spiritual pride has crept in', habit: 'Prayer'),
      BeatitudePractice(text: 'Read and meditate on Psalm 51 \u2014 David\'s prayer from the place of bankruptcy', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Fast from self-promotion for one day \u2014 say nothing about your own achievements or abilities', habit: 'Fasting'),
      BeatitudePractice(text: 'Memorise James 4:6 and return to it when you feel self-sufficient', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Gentleness', 'Faithfulness', 'Self-Control'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'For thus says the One who is high and lifted up, who inhabits eternity, whose name is Holy: \'I dwell in the high and holy place, and also with him who is of a contrite and lowly spirit, to revive the spirit of the lowly, and to revive the heart of the contrite.\'', ref: 'Isaiah 57:15'),
      SupportingBeatitudeVerse(text: 'The sacrifices of God are a broken spirit; a broken and contrite heart, O God, you will not despise.', ref: 'Psalm 51:17'),
      SupportingBeatitudeVerse(text: 'Humble yourselves before the Lord, and he will exalt you.', ref: 'James 4:10'),
      SupportingBeatitudeVerse(text: 'For everyone who exalts himself will be humbled, and he who humbles himself will be exalted.', ref: 'Luke 14:11'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/1_poor_in_spirit.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03c0\u03c4\u03c9\u03c7\u03bf\u1f76 \u03c4\u1ff7 \u03c0\u03bd\u03b5\u03cd\u03bc\u03b1\u03c4\u03b9 (makarioi hoi pt\u014dchoi t\u014d pneumati)',
    statementInBrief: 'Jesus declares those who are spiritually bankrupt \u2014 who recognise they have nothing to bring to God \u2014 to be the very people to whom the Kingdom of Heaven belongs. This is the gateway Beatitude: nothing else in the Sermon is accessible without this posture.',
    centralPointTitle: 'The Kingdom belongs to the empty-handed',
    centralPoint: 'Spiritual poverty is not a deficiency to overcome but a posture to embrace. The Kingdom of God belongs not to those who have arrived spiritually but to those who know they haven\'t \u2014 and who have stopped pretending otherwise.',
    audienceContext: 'In a religious culture that measured standing before God by observance, lineage, and moral achievement, this declaration was scandalous. Jesus announces that the Kingdom belongs to those who arrive with nothing to offer \u2014 not to those who have most to show.',
    historicalContext: 'The background lies in Isaiah\'s \'anawim tradition \u2014 the humble poor who depend entirely on God (Isa 61:1; 66:2). In Second Temple Judaism, ptōchos (one who crouches, destitute) was the strongest term for poverty. Matthew\'s addition \'in spirit\' (tō pneumati) moves the phrase beyond social class to a fundamental orientation of soul before God. The Qumran community cultivated similar language of self-abasement in their hymns (1QH), contrasting human insufficiency with divine holiness.',
    scholarlyInterpretation: 'France (NICNT, 2007) reads ptōchoi tō pneumati as those who \'recognise their own utter helplessness before God.\' Davies and Allison (ICC, 1988) trace the phrase to Isa 66:2 LXX and the \'anawim tradition, reading it as spiritual destitution rather than social poverty \u2014 people who \'know they have nothing to offer God.\' Hagner (WBC, 1993) notes that the qualifier \'in spirit\' moves the beatitude beyond a social category to a fundamental posture of soul. The present-tense promise \'theirs is the kingdom\' (not future) is unique among the eight beatitudes, pointing to a possession already in effect.',
    exegeticalNotes: 'ptōchos derives from ptōssō (to crouch or cower) \u2014 the most extreme Greek term for poverty, denoting total destitution rather than mere insufficiency. The dative tō pneumati is a dative of reference: poor with respect to the spirit. The present tense in the apodosis (\'theirs is the kingdom\') is unique in the series, which otherwise uses future promises \u2014 signalling that the Kingdom already belongs to such people, not only at the eschaton.',
    pdfQuestion: 'Am I arriving before God with empty hands \u2014 or do I bring hidden reserves of religious achievement, personal goodness, or spiritual r\u00e9sum\u00e9 that prevent me from receiving what He offers only to the empty-handed?',
    pdfPractices: [
      'Spend fifteen minutes in silence before God \u2014 make no requests, offer no performance. Simply acknowledge that you are empty without Him.',
      'Write down three specific areas where you are relying on your own resources rather than God\'s, and hold each one open before Him in prayer.',
      'Read Isaiah 66:2 slowly: \'But this is the one to whom I will look: he who is humble and contrite in spirit and trembles at my word.\' Sit with it.',
    ],
  ),

  // ── 2. Those Who Mourn ────────────────────────────────────────────────────
  BeatitudeModel(
    number: 2,
    title: 'Those Who Mourn',
    verse: 'Blessed are those who mourn, for they shall be comforted.',
    verseRef: 'Matthew 5:4',
    promise: 'they shall be comforted',
    yourWhy: 'I bring my grief to God rather than bury it \u2014 because the comfort He promises is only found on the other side of honesty, and He is close to the brokenhearted.',
    whatThisMeans: 'This is not a blessing on sadness in general but on a specific kind of mourning \u2014 grieving over sin, over the brokenness of the world, over the distance between what is and what God intended. It is the grief of someone who takes both God and reality seriously. It also encompasses personal loss and suffering brought honestly before God rather than suppressed or spiritualised away. The promise is not that the mourning will be explained, but that it will be met \u2014 with the comfort of God himself.',
    keyVerse: 'The Lord is near to the brokenhearted and saves the crushed in spirit.',
    keyVerseRef: 'Psalm 34:18',
    reflectionQuestion: 'What am I carrying right now that I have not yet brought honestly to God \u2014 and what would it mean to lay it down before Him today?',
    practices: [
      BeatitudePractice(text: 'Write a prayer of honest lament \u2014 tell God exactly what grieves you without softening it', habit: 'Prayer'),
      BeatitudePractice(text: 'Pray specifically for someone you know who is suffering today', habit: 'Prayer'),
      BeatitudePractice(text: 'Read a Psalm of lament \u2014 Psalm 22, 42 or 88 \u2014 and let it give language to your own grief', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Reach out to someone who is mourning and simply be present with them', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Pray for a broken situation in the world that you normally look away from', habit: 'Prayer'),
    ],
    fruitConnection: ['Peace', 'Kindness', 'Goodness', 'Love'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'He heals the brokenhearted and binds up their wounds.', ref: 'Psalm 147:3'),
      SupportingBeatitudeVerse(text: 'Blessed be the God and Father of our Lord Jesus Christ, the Father of mercies and God of all comfort, who comforts us in all our affliction.', ref: '2 Corinthians 1:3\u20134'),
      SupportingBeatitudeVerse(text: 'Rejoice with those who rejoice, weep with those who weep.', ref: 'Romans 12:15'),
      SupportingBeatitudeVerse(text: 'He will wipe away every tear from their eyes, and death shall be no more, neither shall there be mourning, nor crying, nor pain anymore, for the former things have passed away.', ref: 'Revelation 21:4'),
      SupportingBeatitudeVerse(text: 'For godly grief produces a repentance that leads to salvation without regret.', ref: '2 Corinthians 7:10'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/2_those_who_mourn.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03c0\u03b5\u03bd\u03b8\u03bf\u1fe6\u03bd\u03c4\u03b5\u03c2 (makarioi hoi penthountes)',
    statementInBrief: 'Jesus blesses those who mourn \u2014 over sin, over the world\'s brokenness, over personal loss brought honestly before God \u2014 with the promise that their grief will be met with divine comfort. The mourning is not the endpoint; the comfort is.',
    centralPointTitle: 'Grief is the doorway to comfort',
    centralPoint: 'The mourning Jesus blesses is not the grief of despair but of honesty \u2014 the grief of people who see reality clearly and bring it to God without softening it. Such mourning is not explained away; it is met by God himself.',
    audienceContext: 'In a culture that prizes resilience and the suppression of pain, this Beatitude restores the dignity of honest lament. Jesus does not call us to manage our grief but to bring it.',
    historicalContext: 'pentheō was the strongest Greek word for grief, used of mourning the dead. In the OT, the prophetic tradition closely connected grief over sin and the fallen world with the hope of divine comfort (Isa 61:2\u20133; 66:10\u201313). Isaiah\'s promise to \'comfort all who mourn\' is explicitly evoked here. The Psalms of lament (22, 42, 88) and the Qumran community\'s hymns (1QH) both model the posture of bringing grief honestly before God in expectation of His response.',
    scholarlyInterpretation: 'Luz (Hermeneia, 2007) identifies this Beatitude as standing in the tradition of Isaiah\'s comfort oracles \u2014 a promise to those who \'mourn over the gap between what is and what God intends.\' Allison (1999) argues the mourning is primarily prophetic in character: grief over sin and the fallen world, not merely personal sorrow. Betz (Hermeneia, 1995) notes the eschatological passive paraklēthēsontai (\'they shall be comforted\') implies divine agency: God himself is the unstated subject of the promise.',
    exegeticalNotes: 'paraklēthēsontai (they shall be comforted, future passive) is a divine passive \u2014 God is the implied agent. The root paraklēsis (comfort, consolation) is cognate with paraklētos (the Paraclete, John 14:16), the Holy Spirit as Comforter. The present participle penthountes describes ongoing, habitual mourning \u2014 a characteristic posture, not a single episode of grief.',
    pdfQuestion: 'What am I grieving right now that I have not yet brought honestly to God? Is there a pain, a loss, a disappointment, or a sin that I have been managing or suppressing rather than mourning before Him?',
    pdfPractices: [
      'Write a prayer of lament today \u2014 do not soften it or resolve it prematurely. Let it end with an open hand rather than a tidy conclusion.',
      'Read Psalm 88 \u2014 the one lament psalm that offers no resolution \u2014 and sit with the discomfort of it without trying to fix it.',
      'Reach out to someone you know is grieving and say simply: \'I am sorry.\' Say nothing else. Simply be present.',
    ],
  ),

  // ── 3. The Meek ───────────────────────────────────────────────────────────
  BeatitudeModel(
    number: 3,
    title: 'The Meek',
    verse: 'Blessed are the meek, for they shall inherit the earth.',
    verseRef: 'Matthew 5:5',
    promise: 'they shall inherit the earth',
    yourWhy: 'Meekness is not weakness \u2014 it is strength that has been surrendered to God. I choose not to assert myself, not because I have nothing to offer, but because I trust Him to vindicate me.',
    whatThisMeans: 'The Greek word here is praus \u2014 used of a wild horse that has been broken and trained. All the power is still there; it is simply now under the rider\'s control. Meekness is not passivity or timidity. It is choosing not to force your own way, not to retaliate, not to demand your rights \u2014 because you have placed yourself under God\'s authority and trusted Him with the outcome. Jesus himself is described as meek (Matthew 11:29), and he was anything but weak.',
    keyVerse: 'Take my yoke upon you, and learn from me, for I am gentle and lowly in heart, and you will find rest for your souls.',
    keyVerseRef: 'Matthew 11:29',
    reflectionQuestion: 'Where am I striving, forcing or demanding my own way \u2014 and what would it look like to release that to God today?',
    practices: [
      BeatitudePractice(text: 'Identify one situation where you are pushing for your own way and consciously release it to God in prayer', habit: 'Prayer'),
      BeatitudePractice(text: 'Choose not to defend yourself in a conversation where you normally would \u2014 and notice what that costs you', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Serve someone today in a way that will go unnoticed and unacknowledged', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Pray for someone who has authority over you \u2014 a difficult boss, a demanding family member', habit: 'Prayer'),
      BeatitudePractice(text: 'Memorise Numbers 12:3 and reflect on Moses as a model of meekness under pressure', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Gentleness', 'Self-Control', 'Peace', 'Patience'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Now the man Moses was very meek, more than all people who were on the face of the earth.', ref: 'Numbers 12:3'),
      SupportingBeatitudeVerse(text: 'But the meek shall inherit the land and delight themselves in abundant peace.', ref: 'Psalm 37:11'),
      SupportingBeatitudeVerse(text: 'Let your reasonableness be known to everyone. The Lord is at hand.', ref: 'Philippians 4:5'),
      SupportingBeatitudeVerse(text: 'Put on then, as God\'s chosen ones, holy and beloved, compassionate hearts, kindness, humility, meekness, and patience.', ref: 'Colossians 3:12'),
      SupportingBeatitudeVerse(text: 'But I say to you, do not resist the one who is evil. But if anyone slaps you on the right cheek, turn to him the other also.', ref: 'Matthew 5:39'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/3_the_meek.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03c0\u03c1\u03b1\u03b5\u1fd6\u03c2 (makarioi hoi praeis)',
    statementInBrief: 'Jesus reverses every expectation about power and inheritance: not those who seize and dominate, but those who place their strength under God\'s authority, will receive the earth. praus is disciplined, directed strength \u2014 not its absence.',
    centralPointTitle: 'Surrendered strength, not weakness',
    centralPoint: 'Meekness is not the absence of power but power brought under God\'s authority. The meek person could assert themselves, retaliate, or demand their rights \u2014 and chooses not to, trusting God to vindicate them in His time.',
    audienceContext: 'This Beatitude challenges every culture of assertion, dominance, and self-promotion. It offers a counterintuitive path to lasting inheritance \u2014 not through seizing but through yielding.',
    historicalContext: 'praus had an established usage in Greek literature of a horse trained to the bridle \u2014 all the animal\'s force, now responsive to direction. In the LXX, it translates \'anaw, the humble-meek who trust God for vindication (Ps 37:11 LXX, which is explicitly echoed here). Moses was the paradigmatic meek man (Num 12:3 LXX), and Jesus applies praus to himself in Matt 11:29 \u2014 the strongest possible model of meekness as active, not passive.',
    scholarlyInterpretation: 'France (NICNT, 2007) translates praus as \'gentle\' but insists it must be understood against Ps 37:11: those who \'patiently wait for God to act rather than taking matters into their own hands.\' Davies and Allison (ICC, 1988) note the deliberate echo of Ps 37 (LXX 36), a wisdom psalm contrasting the aggressive wicked with the meek who wait and ultimately inherit. Hagner (WBC, 1993) stresses that praus in Matthew connotes patient endurance under mistreatment \u2014 active, not passive, submission to God\'s timing.',
    exegeticalNotes: 'klēronomēsousin tēn gēn (they shall inherit the earth/land) mirrors Ps 37:11 LXX almost verbatim. The noun gē can mean either \'land\' (evoking the Promised Land) or \'earth\' (eschatological scope) \u2014 the ambiguity is likely deliberate, extending the original covenant promise to a universal horizon. The future tense is unambiguously eschatological, though many see a partial present realisation in the community of the Kingdom.',
    pdfQuestion: 'Where am I currently striving, forcing, or insisting on my own way \u2014 and what would it look like to release that situation into God\'s hands, trusting Him with the outcome rather than securing it myself?',
    pdfPractices: [
      'Identify one relationship or situation where you regularly assert yourself. For one day, consciously hold back your natural response and pray instead of acting.',
      'Before your next significant conversation or decision, pray: \'Lord, I do not need to win this. I trust you to vindicate me.\' Then enter without needing to dominate.',
      'Read Psalm 37 slowly, noticing how many times the psalmist calls the meek to wait, trust, and refrain from striving. Count the invitations to stillness.',
    ],
  ),

  // ── 4. Hunger & Thirst for Righteousness ─────────────────────────────────
  BeatitudeModel(
    number: 4,
    title: 'Hunger & Thirst for Righteousness',
    verse: 'Blessed are those who hunger and thirst for righteousness, for they shall be satisfied.',
    verseRef: 'Matthew 5:6',
    promise: 'they shall be satisfied',
    yourWhy: 'I want to want God more than I want anything else \u2014 and this hunger, however small it feels, is itself a sign that He is already at work in me.',
    whatThisMeans: 'Jesus uses the language of physical desperation \u2014 not mild interest but the urgent, consuming need of someone who is genuinely starving and parched. The righteousness in view is both personal (a longing to be made right before God, to be holy) and cosmic (a longing for the world to be set right, for justice to prevail). This beatitude is a hunger for God himself \u2014 for His character, His kingdom, His will to be done. The promise is extraordinary: those who hunger this way will be filled. Not partially. Satisfied.',
    keyVerse: 'As a deer pants for flowing streams, so pants my soul for you, O God. My soul thirsts for God, for the living God.',
    keyVerseRef: 'Psalm 42:1\u20132',
    reflectionQuestion: 'What am I currently hungering for more than I hunger for God \u2014 and what would it mean to bring that appetite to Him instead?',
    practices: [
      BeatitudePractice(text: 'Spend more time in God\'s Word today than you planned \u2014 go beyond your normal reading', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Pray specifically for justice in a situation you know about personally', habit: 'Prayer'),
      BeatitudePractice(text: 'Fast as a physical expression of spiritual hunger \u2014 let your body feel what your soul should be feeling', habit: 'Fasting'),
      BeatitudePractice(text: 'Advocate for someone being treated unjustly', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Memorise Psalm 42:1\u20132 and pray it back to God as a request', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Love', 'Faithfulness', 'Goodness', 'Joy'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Blessed are you who are hungry now, for you shall be satisfied.', ref: 'Luke 6:21'),
      SupportingBeatitudeVerse(text: 'O God, you are my God; earnestly I seek you; my soul thirsts for you; my flesh faints for you, as in a dry and weary land where there is no water.', ref: 'Psalm 63:1'),
      SupportingBeatitudeVerse(text: 'For he satisfies the longing soul, and the hungry soul he fills with good things.', ref: 'Psalm 107:9'),
      SupportingBeatitudeVerse(text: 'Jesus said to them, \'I am the bread of life; whoever comes to me shall not hunger, and whoever believes in me shall never thirst.\'', ref: 'John 6:35'),
      SupportingBeatitudeVerse(text: 'But seek first the kingdom of God and his righteousness, and all these things will be added to you.', ref: 'Matthew 6:33'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/4_hunger_and_thirst_for_righteousness.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03c0\u03b5\u03b9\u03bd\u1ff6\u03bd\u03c4\u03b5\u03c2 \u03ba\u03b1\u1f76 \u03b4\u03b9\u03c8\u1ff6\u03bd\u03c4\u03b5\u03c2 \u03c4\u1f74\u03bd \u03b4\u03b9\u03ba\u03b1\u03b9\u03bf\u03c3\u03cd\u03bd\u03b7\u03bd (makarioi hoi pein\u014dntes kai dips\u014dntes t\u0113n dikaiosyn\u0113n)',
    statementInBrief: 'Jesus blesses those whose longing for righteousness \u2014 for being made right before God and for God\'s justice to prevail in the world \u2014 is as urgent as the physical desperation of starvation. Such people, he promises, will be completely satisfied.',
    centralPointTitle: 'Desperate longing, certain satisfaction',
    centralPoint: 'dikaiosynē encompasses both personal righteousness (being made right before God) and cosmic justice (God\'s order prevailing in the world). The hunger Jesus describes is not mild aspiration but consuming urgency \u2014 and the promise is not partial relief but full satisfaction.',
    audienceContext: 'This Beatitude names and validates the ache at the centre of the human soul \u2014 the sense that things are not right and we are part of the problem. Jesus does not dismiss this longing; he promises it will be filled.',
    historicalContext: 'Hunger and thirst for righteousness and justice was an established OT idiom (Ps 42:1\u20132; 63:1; Amos 5:24). In Matthew, dikaiosynē carries a double sense: personal conformity to God\'s will (Matt 5:20; 6:1) and the wider coming of God\'s just order (Matt 6:33). The eschatological tradition of Isa 55:1\u20133 (\'Come, all who are thirsty\u2026\') and Isa 61:3 (\'a garment of praise instead of a faint spirit\') stands as the OT horizon of this promise.',
    scholarlyInterpretation: 'The central scholarly debate concerns which sense of dikaiosynē is primary. Strecker argues it refers to personal ethical righteousness. Luz (Hermeneia, 2007) insists it includes the expectation of God\'s cosmic justice. Davies and Allison (ICC, 1988) conclude that the ambiguity is intentional and both senses are present simultaneously. France (NICNT, 2007) accepts the double meaning, arguing the two cannot finally be separated in Matthew\'s theological vision: personal and social righteousness belong together.',
    exegeticalNotes: 'chortasthēsontai (they shall be satisfied) is the verb used of animals being fed to satiation and of the feeding miracles (Matt 14:20; 15:37) \u2014 the fullness is total, not partial. The present participles peinōntes and dipsōntes describe ongoing, habitual longing \u2014 not a one-time desire but a characteristic appetite. The accusative dikaiosynēn (direct object of both verbs) is unusual \u2014 one does not normally \'hunger for\' an abstraction: the hunger here is conceived as a quasi-physical craving.',
    pdfQuestion: 'What am I hungering for more than I hunger for God and His righteousness? What specific appetite could I redirect toward Him this week \u2014 bringing my actual longing to God rather than feeding it elsewhere?',
    pdfPractices: [
      'Identify the desire that currently dominates most of your attention. Fast from it for one day and redirect that energy toward prayer and Scripture.',
      'Pray specifically for a situation of injustice you know about \u2014 either in your immediate context or in the wider world. Do not move on quickly.',
      'Read Isaiah 55:1\u20133 and Amos 5:21\u201324 together, letting the prophetic tradition shape your understanding of what the \'righteousness\' Jesus is describing actually looks like.',
    ],
  ),

  // ── 5. The Merciful ──────────────────────────────────────────────────────
  BeatitudeModel(
    number: 5,
    title: 'The Merciful',
    verse: 'Blessed are the merciful, for they shall receive mercy.',
    verseRef: 'Matthew 5:7',
    promise: 'they shall receive mercy',
    yourWhy: 'I give away what I have been given \u2014 and since I have been shown mercy beyond what I deserved, I have no right to withhold it from anyone.',
    whatThisMeans: 'Mercy is compassion in action \u2014 seeing someone in need or in the wrong, and responding with grace rather than judgment, with help rather than condemnation. Jesus is not describing an occasional kind impulse but a characteristic posture \u2014 the merciful person is someone for whom mercy has become a way of seeing and responding to the world. The connection between giving and receiving mercy here is not a transaction but a revelation: the person who withholds mercy has likely not truly received it themselves.',
    keyVerse: 'Be merciful, even as your Father is merciful.',
    keyVerseRef: 'Luke 6:36',
    reflectionQuestion: 'Who in my life am I finding it hardest to show mercy to right now \u2014 and what would it look like to give them what God has given me?',
    practices: [
      BeatitudePractice(text: 'Pray for someone who has wronged you, by name, asking God to bless them', habit: 'Prayer'),
      BeatitudePractice(text: 'Reach out to someone from whom you are estranged or with whom there is unresolved tension', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Perform an act of kindness for someone who has not earned it and does not expect it', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Write down one place where you are withholding forgiveness and bring it to God', habit: 'Prayer'),
      BeatitudePractice(text: 'Visit or contact someone who is lonely, sick or overlooked', habit: 'Connection & Community'),
    ],
    fruitConnection: ['Love', 'Kindness', 'Goodness', 'Patience', 'Gentleness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'He has told you, O man, what is good; and what does the Lord require of you but to do justice, and to love kindness, and to walk humbly with your God?', ref: 'Micah 6:8'),
      SupportingBeatitudeVerse(text: 'Therefore be merciful, just as your Father also is merciful.', ref: 'Luke 6:36'),
      SupportingBeatitudeVerse(text: 'For judgment is without mercy to one who has shown no mercy. Mercy triumphs over judgment.', ref: 'James 2:13'),
      SupportingBeatitudeVerse(text: 'Put on then, as God\'s chosen ones, holy and beloved, compassionate hearts, kindness, humility, meekness, and patience, bearing with one another and, if one has a complaint against another, forgiving each other; as the Lord has forgiven you, so you also must forgive.', ref: 'Colossians 3:12\u201313'),
      SupportingBeatitudeVerse(text: 'Blessed is the one who considers the poor! In the day of trouble the Lord delivers him.', ref: 'Psalm 41:1'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/5_the_merciful.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u1f10\u03bb\u03b5\u03ae\u03bc\u03bf\u03bd\u03b5\u03c2 (makarioi hoi ele\u0113mones)',
    statementInBrief: 'Jesus declares that those who extend mercy \u2014 actively, not merely as a sentiment \u2014 will receive mercy from God. The reciprocity is not a transaction; it is a revelation of the heart: those who truly receive mercy become merciful.',
    centralPointTitle: 'You give what you have truly received',
    centralPoint: 'Mercy in the NT sense is not tolerance or indifference to wrong. It is the choice to respond to need or failure with grace rather than judgment \u2014 and the ability to do this depends entirely on having genuinely received mercy oneself. Withholding mercy is a sign that the mercy of God has not yet penetrated deeply enough.',
    audienceContext: 'This Beatitude is structurally reciprocal: the giving and receiving of mercy are bound together \u2014 not as a transaction but as evidence of transformation. The merciful have been changed by the mercy they received.',
    historicalContext: 'eleos (mercy) in the LXX translates hesed, the covenant-loyalty and steadfast love of God toward Israel (Exod 34:6\u20137; Ps 103:8). In rabbinic tradition, gemilut hasadim (acts of lovingkindness) was one of the three pillars on which the world stands (Pirqe Avot 1:2). Jesus\'s teaching stands in deliberate continuity with Hos 6:6 (\'I desire mercy, not sacrifice\'), which he cites twice in Matthew (9:13; 12:7) \u2014 making this the interpretive key to his entire ethical programme.',
    scholarlyInterpretation: 'France (NICNT, 2007) notes the reciprocity is not mechanical: those who show mercy receive mercy \'not as a reward but as evidence that they themselves have been transformed by grace.\' Davies and Allison (ICC, 1988) connect this to the parable of the unforgiving servant (Matt 18:21\u201335): the one who has received forgiveness but withholds it from others has not actually absorbed the mercy shown to them. Hagner (WBC, 1993) stresses that eleēmones is an adjective, not a participle \u2014 it describes what these people are, not merely what they do: mercy is their character.',
    exegeticalNotes: 'eleēmones is an adjective denoting a habitual disposition, not a single act. eleēthēsontai (they shall receive mercy, future passive) mirrors the form of eleēmones \u2014 the verbal symmetry is exact. The divine passive implies the mercy comes from God. The pattern of correspondence between human action and divine response appears also in Matt 6:14\u201315 (forgiveness) and 7:1\u20132 (judgment) \u2014 mercy given freely opens the recipient to mercy received.',
    pdfQuestion: 'Who am I finding it hardest to show mercy to right now? What specifically would it cost me to treat them as God has treated me \u2014 and am I willing to pay that cost today?',
    pdfPractices: [
      'Write the name of one person toward whom you are withholding mercy or forgiveness. Pray for them specifically today \u2014 not that they would change, but that God would bless them.',
      'Perform one concrete act of mercy this week for someone who has not earned it and does not expect it. Do it without telling anyone.',
      'Meditate on the parable of the prodigal son (Luke 15:11\u201332) from the perspective of the father. Notice what the father\'s mercy costs him, and what it produces.',
    ],
  ),

  // ── 6. The Pure in Heart ─────────────────────────────────────────────────
  BeatitudeModel(
    number: 6,
    title: 'The Pure in Heart',
    verse: 'Blessed are the pure in heart, for they shall see God.',
    verseRef: 'Matthew 5:8',
    promise: 'they shall see God',
    yourWhy: 'I pursue purity not to earn God\'s approval but because a divided heart cannot see Him clearly \u2014 and I want to see Him as He is.',
    whatThisMeans: 'Purity of heart in the Biblical sense is not primarily about moral perfection but about singleness of devotion \u2014 what Kierkegaard called \'willing one thing.\' The pure heart has no hidden agenda, no double life, no compartment where God is not welcome. It is oriented wholly toward God without the distortion of competing loves. The extraordinary promise \u2014 that the pure in heart will see God \u2014 suggests that this kind of inner clarity is itself a form of spiritual vision. The divided heart sees a blurred God; the undivided heart sees more clearly.',
    keyVerse: 'Create in me a clean heart, O God, and renew a right spirit within me.',
    keyVerseRef: 'Psalm 51:10',
    reflectionQuestion: 'Is there any part of my inner life \u2014 a secret habit, a hidden motive, a private compromise \u2014 that I am keeping from God? What would it mean to open that room to Him today?',
    practices: [
      BeatitudePractice(text: 'Pray Psalm 51 slowly as your own prayer \u2014 let David\'s words become yours', habit: 'Prayer'),
      BeatitudePractice(text: 'Identify one area where your private life does not match your public faith and bring it to God specifically', habit: 'Prayer'),
      BeatitudePractice(text: 'Break a habit today that compromises your integrity before God', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Memorise Psalm 51:10 and pray it as a daily request', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Examine your motives before a significant conversation or decision today \u2014 ask God to show you what is driving you', habit: 'Prayer'),
    ],
    fruitConnection: ['Self-Control', 'Faithfulness', 'Goodness', 'Gentleness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Who shall ascend the hill of the Lord? And who shall stand in his holy place? He who has clean hands and a pure heart, who does not lift up his soul to what is false and does not swear deceitfully.', ref: 'Psalm 24:3\u20134'),
      SupportingBeatitudeVerse(text: 'Keep your heart with all vigilance, for from it flow the springs of life.', ref: 'Proverbs 4:23'),
      SupportingBeatitudeVerse(text: 'The eye is the lamp of the body. So, if your eye is healthy, your whole body will be full of light.', ref: 'Matthew 6:22'),
      SupportingBeatitudeVerse(text: 'Flee youthful passions and pursue righteousness, faith, love, and peace, along with those who call on the Lord from a pure heart.', ref: '2 Timothy 2:22'),
      SupportingBeatitudeVerse(text: 'Draw near to God, and he will draw near to you. Cleanse your hands, you sinners, and purify your hearts, you double-minded.', ref: 'James 4:8'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/6_pure_in_heart.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03ba\u03b1\u03b8\u03b1\u03c1\u03bf\u1f76 \u03c4\u1fc7 \u03ba\u03b1\u03c1\u03b4\u03af\u1fb3 (makarioi hoi katharoi t\u0113 kardia)',
    statementInBrief: 'Jesus declares that those whose inner life is undivided \u2014 free from hidden agendas, double loyalty, and compartmentalisation \u2014 will receive the ultimate promise: they will see God. Purity of heart is singleness of devotion, not moral perfection.',
    centralPointTitle: 'Single-hearted devotion opens spiritual sight',
    centralPoint: 'Purity of heart in the biblical sense is not moral perfection but singleness of devotion \u2014 what Kierkegaard memorably called \'purity of heart is to will one thing.\' The pure heart sees God clearly because it is not distorted by competing loves or a divided self.',
    audienceContext: 'This Beatitude confronts the gap between public faith and private life \u2014 the divided self that presents one face to the world and keeps another hidden. Jesus names this as the fundamental obstacle to seeing God clearly.',
    historicalContext: 'kardia (heart) in the Hebrew\u2013Greek biblical tradition is not primarily the seat of emotion but of will, intention, and moral decision. Ps 24:3\u20134 asks who may ascend the hill of the Lord: \'he who has clean hands and a pure heart.\' Deut 6:5\'s command to love God \'with all your heart\' establishes undivided devotion as Israel\'s central calling \u2014 and Israel\'s failure to maintain it as the ground of prophetic critique throughout the OT.',
    scholarlyInterpretation: 'The majority of modern commentators (Luz, France, Hagner) interpret katharos tē kardia as describing moral and volitional purity \u2014 specifically the absence of duplicity or divided loyalty. Davies and Allison (ICC, 1988) note the connection to Ps 24 and the tradition of temple access: to \'see God\' was the ultimate goal of Israelite worship, and moral integrity was the precondition. The promise opsontai ton theon (they shall see God) likely refers to both present spiritual vision and its eschatological completion (Rev 22:4).',
    exegeticalNotes: 'katharos (pure, clean) is used in both cultic (ritually clean) and moral senses in the NT. The dative tē kardia (pure with respect to the heart) focuses the purity inward \u2014 toward the locus of will and intention, not merely outward conduct. opsontai ton theon (they shall see God) is unique in the Synoptics \u2014 the \'beatific vision\' appears here and in Rev 22:4 (\'they will see his face\'). The future tense points to eschatological fullness without excluding a present partial fulfilment through spiritual perception.',
    pdfQuestion: 'Is there a room in my inner life \u2014 a habit, a motive, a private compromise, a secret loyalty \u2014 that I am keeping closed to God? What would it mean to open it today and let the light in?',
    pdfPractices: [
      'Set aside thirty minutes of honest self-examination before God. Ask Him to show you any area of division or double-mindedness in your inner life. Write down what you see.',
      'Identify one area of your private life that does not match your public Christian identity, and take one concrete step toward alignment today \u2014 even if only a first step.',
      'Read Psalm 24:3\u20134, Psalm 51:10, and James 4:8 together. Then pray them back to God as a request for integrity, not just as words.',
    ],
  ),

  // ── 7. The Peacemakers ───────────────────────────────────────────────────
  BeatitudeModel(
    number: 7,
    title: 'The Peacemakers',
    verse: 'Blessed are the peacemakers, for they shall be called sons of God.',
    verseRef: 'Matthew 5:9',
    promise: 'they shall be called sons of God',
    yourWhy: 'I pursue peace because God is a reconciling God \u2014 and when I make peace, I bear the family resemblance of my Father.',
    whatThisMeans: 'The peacemaker is not someone who avoids conflict or keeps the peace at the cost of truth \u2014 that is simply conflict avoidance. The peacemaker actively works to create peace where it does not exist: restoring broken relationships, reconciling people to each other, and ultimately pointing people toward reconciliation with God. The title \'sons of God\' is remarkable \u2014 it is a family likeness. Peacemaking is what God does (Romans 5:1), and those who do it look like Him.',
    keyVerse: 'Therefore, since we have been justified by faith, we have peace with God through our Lord Jesus Christ.',
    keyVerseRef: 'Romans 5:1',
    reflectionQuestion: 'Is there a broken relationship or unresolved conflict in my life that I have been avoiding rather than working to restore \u2014 and what is the first step toward peace?',
    practices: [
      BeatitudePractice(text: 'Take the first step toward reconciliation with someone from whom you are estranged', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Pray specifically for a conflict you know about \u2014 in your family, church, workplace or community', habit: 'Prayer'),
      BeatitudePractice(text: 'Share the gospel with someone this week \u2014 the ultimate act of peacemaking', habit: 'Evangelism'),
      BeatitudePractice(text: 'Choose a gentle answer today in a situation that normally provokes a sharp response', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Pray for peace in a region of the world currently experiencing conflict', habit: 'Prayer'),
    ],
    fruitConnection: ['Peace', 'Love', 'Kindness', 'Gentleness', 'Goodness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'If possible, so far as it depends on you, live peaceably with all.', ref: 'Romans 12:18'),
      SupportingBeatitudeVerse(text: 'For he himself is our peace, who has made us both one and has broken down in his flesh the dividing wall of hostility.', ref: 'Ephesians 2:14'),
      SupportingBeatitudeVerse(text: 'And the harvest of righteousness is sown in peace by those who make peace.', ref: 'James 3:18'),
      SupportingBeatitudeVerse(text: 'Let the peace of Christ rule in your hearts, to which indeed you were called in one body. And be thankful.', ref: 'Colossians 3:15'),
      SupportingBeatitudeVerse(text: 'How beautiful upon the mountains are the feet of him who brings good news, who publishes peace.', ref: 'Isaiah 52:7'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/7_peacemakers.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03b5\u1f30\u03c1\u03b7\u03bd\u03bf\u03c0\u03bf\u03b9\u03bf\u03af (makarioi hoi eir\u0113nopoioi)',
    statementInBrief: 'Jesus blesses those who actively create peace where there is none \u2014 not those who merely love peace or avoid conflict. Such people bear the ultimate distinction: they shall be called sons of God, because peacemaking is what God does.',
    centralPointTitle: 'Peacemaking is the family trade of God\'s children',
    centralPoint: 'eirēnopoios does not describe passive peacekeeping or conflict avoidance. It describes the active work of creating peace where there is none \u2014 restoring broken relationships, reconciling divided people, and pointing toward ultimate reconciliation with God. This is what God does; those who do it look like Him.',
    audienceContext: 'In a world saturated with relational, political, and spiritual conflict, Jesus identifies the people who do the costly work of reconciliation as bearing the family likeness of God. This is not a peripheral calling but a defining one.',
    historicalContext: 'shalom in the OT tradition is not merely the absence of hostility but the positive state of wholeness, flourishing, and right relationship (Num 6:26; Isa 52:7; 57:19). The compound eirēnopoios (peacemaker) was used in Hellenistic political discourse of those who ended wars between city-states. Jesus redirects the concept to the relational and spiritual sphere, grounding peacemaking in the character of God who is \'the God of peace\' (Rom 15:33) and who reconciled the world to himself through Christ (2 Cor 5:18\u201319; Col 1:20).',
    scholarlyInterpretation: 'France (NICNT, 2007) stresses the active force of eirēnopoios: \'not those who simply love peace, but those who work to create it.\' Davies and Allison (ICC, 1988) note that the title huioi theou (sons of God) denotes family likeness \u2014 peacemakers look like God because God is the peacemaker par excellence. Luz (Hermeneia, 2007) highlights the eschatological dimension: peacemaking is participation in God\'s own reconciling activity that will culminate in the new creation.',
    exegeticalNotes: 'eirēnopoios is a single compound word (unique in the NT) denoting active peace-creation, not passive preference for peace. huioi theou (sons of God) is a title given to Israel in the OT (Exod 4:22; Hos 11:1) and applied to followers of Jesus who share his character (Rom 8:14; Gal 3:26). The future klēthēsontai (\'shall be called\') implies both present recognition within the community of the Kingdom and eschatological confirmation at the final judgement.',
    pdfQuestion: 'Is there a broken relationship, an unresolved conflict, or a divided community that I have been observing from a safe distance rather than entering at cost? What would the first step toward peace actually look like?',
    pdfPractices: [
      'Identify the most significant unresolved conflict in your relational world. Pray about it specifically today \u2014 not for God to fix it, but for courage and wisdom to enter it.',
      'Write a message to someone from whom you are estranged. You don\'t need to send it immediately, but write it as if you were going to \u2014 and see what it requires of you.',
      'Read 2 Corinthians 5:18\u201320 and reflect on your calling as an \'ambassador of reconciliation.\' Consider one context this week where you could represent that calling.',
    ],
  ),

  // ── 8. Those Who Are Persecuted ──────────────────────────────────────────
  BeatitudeModel(
    number: 8,
    title: 'Those Who Are Persecuted',
    verse: 'Blessed are those who are persecuted for righteousness\u2019 sake, for theirs is the kingdom of heaven. Blessed are you when others revile you and persecute you and utter all kinds of evil against you falsely on my account. Rejoice and be glad, for your reward is great in heaven.',
    verseRef: 'Matthew 5:10\u201312',
    promise: 'theirs is the kingdom of heaven',
    yourWhy: 'I will not shrink from what is true to avoid what is uncomfortable \u2014 because faithfulness to Christ is worth more than the approval of people, and my reward is not in this moment but in eternity.',
    whatThisMeans: 'This is the only Beatitude that Jesus immediately expands and personalises \u2014 moving from the third person (\'those who are persecuted\') to the second (\'blessed are you\'). It is also the only one that shares the same promise as the first: the kingdom of heaven. This is deliberate. The journey from spiritual poverty (Beatitude 1) to persecution (Beatitude 8) is a complete arc \u2014 from recognising your need for God to standing firm for God regardless of cost. Jesus is not romanticising suffering but promising that faithfulness under pressure is both seen and rewarded by the Father.',
    keyVerse: 'Indeed, all who desire to live a godly life in Christ Jesus will be persecuted.',
    keyVerseRef: '2 Timothy 3:12',
    reflectionQuestion: 'Where am I currently staying silent, softening my convictions or compromising my faith to avoid someone\'s disapproval \u2014 and what would faithfulness look like in that situation?',
    practices: [
      BeatitudePractice(text: 'Share your faith with someone today despite the risk of rejection or ridicule', habit: 'Evangelism'),
      BeatitudePractice(text: 'Pray for persecuted Christians around the world \u2014 use Open Doors or Voice of the Martyrs for specific names and regions', habit: 'Prayer'),
      BeatitudePractice(text: 'Read the account of a Christian martyr or someone who suffered for their faith', habit: 'Reading & Learning'),
      BeatitudePractice(text: 'Identify one situation where you are staying quiet about your faith to avoid awkwardness \u2014 and ask God for courage', habit: 'Prayer'),
      BeatitudePractice(text: 'Write down what you believe and why \u2014 articulate your faith clearly so you are ready to give a reason for your hope', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Pray for someone who is currently hostile to Christianity \u2014 by name', habit: 'Prayer'),
    ],
    fruitConnection: ['Faithfulness', 'Joy', 'Peace', 'Self-Control'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'But in your hearts honour Christ the Lord as holy, always being prepared to make a defence to anyone who asks you for a reason for the hope that is in you; yet do it with gentleness and respect.', ref: '1 Peter 3:15'),
      SupportingBeatitudeVerse(text: 'For I am not ashamed of the gospel, for it is the power of God for salvation to everyone who believes.', ref: 'Romans 1:16'),
      SupportingBeatitudeVerse(text: 'Count it all joy, my brothers, when you meet trials of various kinds, for you know that the testing of your faith produces steadfastness.', ref: 'James 1:2\u20133'),
      SupportingBeatitudeVerse(text: 'If the world hates you, know that it has hated me before it hated you.', ref: 'John 15:18'),
      SupportingBeatitudeVerse(text: 'And after you have suffered a little while, the God of all grace, who has called you to his eternal glory in Christ, will himself restore, confirm, strengthen, and establish you.', ref: '1 Peter 5:10'),
      SupportingBeatitudeVerse(text: 'So do not be ashamed of the testimony about our Lord, nor of me his prisoner, but share in suffering for the gospel by the power of God.', ref: '2 Timothy 1:8'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/8_those_who_are_persecuted.webp',
    greekText: '\u03bc\u03b1\u03ba\u03ac\u03c1\u03b9\u03bf\u03b9 \u03bf\u1f31 \u03b4\u03b5\u03b4\u03b9\u03c9\u03b3\u03bc\u03ad\u03bd\u03bf\u03b9 \u1f55\u03bd\u03b5\u03ba\u03b5\u03bd \u03b4\u03b9\u03ba\u03b1\u03b9\u03bf\u03c3\u03cd\u03bd\u03b7\u03c2 (makarioi hoi dedi\u014dgmenoi heneken dikaiosyn\u0113s)',
    statementInBrief: 'Jesus declares that those who suffer because of their identification with righteousness \u2014 and specifically with him \u2014 share in the Kingdom of Heaven and the company of the prophets. Faithfulness under pressure is not incidental to the Christian life; it is the culmination of it.',
    centralPointTitle: 'Faithfulness at cost is the mark of the Kingdom',
    centralPoint: 'The promise is not that persecution will be short or comfortable. It is that it will be seen and rewarded by the Father \u2014 and that those who endure it enter the long lineage of God\'s faithful people throughout history. Suffering for Jesus is not a detour from the Kingdom; it is the road through it.',
    audienceContext: 'This is the only Beatitude Jesus immediately expands and personalises \u2014 moving from the third person to the second: \'blessed are you.\' He is no longer speaking abstractly. He is warning his hearers that following him will bring cost, and that such cost is not evidence against the Kingdom but evidence of it.',
    historicalContext: 'Persecution of the righteous was a well-established tradition in Second Temple Judaism \u2014 prophets suffered at the hands of faithless Israel (Jer 26; 37\u201338), and the Maccabean martyrs (2 Macc 6\u20137) became paradigmatic examples of faithful suffering under Antiochus IV Epiphanes. This \'persecuted righteous\' tradition shaped Jewish apocalypticism and Paul\'s theology of suffering for Christ (2 Cor 4:8\u201312; Phil 1:29). The prophets are explicitly invoked in v.12 as the precedent \u2014 Jesus places his followers in that tradition.',
    scholarlyInterpretation: 'France (NICNT, 2007) notes the shift to second person (\'blessed are you\') signals Jesus is addressing his immediate disciples \u2014 those for whom persecution will become personal. Luz (Hermeneia, 2007) identifies \'for my sake\' (heneken emou, v.11) as the hermeneutical key: it is persecution arising from identification with Jesus that has eschatological weight. Davies and Allison (ICC, 1988) highlight the structural symmetry with Beatitude 1: both share the identical promise (\'theirs is the kingdom of heaven\'), framing the entire series as a journey from spiritual poverty to costly faithfulness.',
    exegeticalNotes: 'dediōgmenoi is a perfect passive participle of diōkō (to pursue, persecute) \u2014 the perfect tense denotes a settled, ongoing state: these are people who have been and continue to be persecuted. heneken dikaiosynēs (v.10, for the sake of righteousness) becomes heneken emou (v.11, for my sake) \u2014 an implicit identification of righteousness with Jesus himself. misthon (reward, v.12) is the same word used in Matt 6:1\u20136 for the rewards of genuine piety; here it is explicitly polys (great) and located \'in heaven.\'',
    pdfQuestion: 'Where am I currently staying silent, softening my convictions, or managing my reputation in order to avoid the cost of standing with Jesus publicly? What would faithfulness look like in that specific situation this week?',
    pdfPractices: [
      'Identify one specific context \u2014 a relationship, workplace, or social setting \u2014 where your faith is invisible or muted. Ask God for courage to speak or act differently there this week.',
      'Pray for persecuted Christians by name, using the Open Doors World Watch List or Voice of the Martyrs to find specific situations you would not otherwise know about.',
      'Read the account of one early church martyr (Polycarp, Stephen in Acts 6\u20137, or Perpetua) and reflect on what they believed was worth their life \u2014 and whether you believe the same.',
    ],
  ),
];
