import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'bible_project_browser_view.dart';

const _kAccent = Color(0xFF7DAEC8); // celestial blue

// ── Data ─────────────────────────────────────────────────────────────────────

class _IAmSaying {
  final String title;
  final String reference;
  final String imagePath;
  final String fullVerse;
  final String reflection;
  final String scripture;
  final String statementInBrief;
  final String centralPoint;
  final String question;
  final List<String> practices;
  final String audienceContextTitle;
  final String audienceContext;
  final String historicalContext;
  final String scholarlyInterpretation;
  final String exegeticalNotes;
  // Optional override for the modal header line (used for absolute I AM sayings)
  final String? headerLabel;

  const _IAmSaying({
    required this.title,
    required this.reference,
    required this.imagePath,
    required this.fullVerse,
    required this.reflection,
    required this.scripture,
    required this.statementInBrief,
    required this.centralPoint,
    required this.question,
    required this.practices,
    required this.audienceContextTitle,
    required this.audienceContext,
    required this.historicalContext,
    required this.scholarlyInterpretation,
    required this.exegeticalNotes,
    this.headerLabel,
  });

  String get modalHeader => headerLabel ?? 'I am ${title.toLowerCase()}';
}

const _sayings = [
  _IAmSaying(
    title: 'The Bread of Life',
    reference: 'John 6:35',
    imagePath: 'assets/I Am/The Bread.webp',
    fullVerse:
        '\u201cI am the bread of life; whoever comes to me shall not hunger, and whoever believes in me shall never thirst.\u201d',
    reflection:
        'Jesus is not merely a teacher or guide \u2014 He is the very sustenance of the soul. As bread is essential to physical life, He is essential to eternal life. To come to Him in faith is to be fed in a way that nothing else can satisfy.',
    scripture:
        '\u201cJesus said to them, \u2018I am the bread of life. He who comes to me will not be hungry, and he who believes in me will never be thirsty.\u2019\u201d\n\u2014 John 6:35 (WEB)',
    statementInBrief:
        'At the height of a controversy about bread in the wilderness, Jesus declares himself to be the true bread from heaven \u2014 the living bread that gives eternal life rather than temporary physical sustenance.',
    centralPoint:
        'Just as the body cannot survive without bread, the soul cannot live without Jesus. He is not merely a provider of spiritual nourishment \u2014 he is the nourishment itself. The claim both fulfils the manna given through Moses and surpasses it immeasurably.',
    question:
        'What are you feeding on in your deepest moments of need \u2014 and are you willing to bring that hunger directly to Jesus?',
    practices: [
      'Sit with John 6:25\u201335 in full. Notice the progression from physical bread to the Bread of Life.',
      'Identify one area of life where you feel spiritually hungry or empty. Bring it explicitly to Jesus in prayer.',
      'Fast from one meal this week, using the physical hunger as a prompt to pray for spiritual nourishment.',
      'Memorise John 6:35 and repeat it when you feel any form of lack \u2014 physical, emotional, or spiritual.',
    ],
    audienceContextTitle: 'THE WILDERNESS SETTING AND ITS CROWD',
    audienceContext:
        'The discourse takes place the day after the feeding of the 5,000 (John 6:1\u201315) and the crossing of the sea (6:16\u201321). The crowd has followed Jesus across the lake seeking more bread. Jesus reframes the conversation: they should not labour for food that perishes but for the food that the Son of Man gives (6:27). Their request \u2014 \u2018Give us this bread always\u2019 (6:34) \u2014 mirrors Israel\u2019s craving for manna and sets up the climactic declaration. The scene is set near Passover (6:4), heightening the Exodus typology throughout.',
    historicalContext:
        'Bread (Greek \u1f04\u03c1\u03c4\u03bf\u03c2) was not a luxury but the primary staple of ancient Mediterranean life. Failure of bread supply meant starvation. In Jewish expectation, the Messiah was associated with a second Exodus in which heavenly manna would again be provided. Rabbinical tradition (Midrash Rabbah on Exodus 25:3) preserved the promise that \u2018the same one who caused the manna to descend would again cause the manna to descend.\u2019 Philo of Alexandria had already allegorised manna as the Logos / divine Wisdom. Jesus\u2019 claim both fulfils and radically transcends these expectations.',
    scholarlyInterpretation:
        'Barrett (St John\u2019s Gospel, 1978) observes that John 6:35 opens the Bread of Life discourse with the first of the great predicated \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 sayings and that Jesus\u2019 claim functions simultaneously at the literal (bread), typological (manna), and sapiential (Wisdom) levels. Keener (The Gospel of John, 2003) emphasises the Wisdom tradition backdrop: in Sirach 24:19\u201321 and Proverbs 9:1\u20135, divine Wisdom offers bread and wine to those who come to her \u2014 but warns that those who eat will hunger for more. Jesus\u2019 claim is explicitly superior: the one who comes to him \u2018will not hunger.\u2019 Moloney (Sacra Pagina, 1998) notes that \u2018coming\u2019 and \u2018believing\u2019 in 6:35 are parallel acts describing a single ongoing disposition of trust.',
    exegeticalNotes:
        'The \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 formula appears here with the predicate \u1f41 \u1f04\u03c1\u03c4\u03bf\u03c2 \u03c4\u1fc6\u03c2 \u03b6\u03c9\u1fc6\u03c2 (the bread of life) \u2014 the first of seven predicated uses in John. The double negative \u03bf\u1f50 \u03bc\u1f74 with aorist subjunctive (\u2018will not hunger \u2026 will never thirst\u2019) is the strongest possible negation in Greek idiom. The pairing of hunger and thirst appears in OT wisdom and prophetic literature (Isa 55:1\u20132; Amos 8:11\u201312). The verse also introduces the Johannine pattern of misunderstanding \u2014 the crowd wanting literal bread \u2014 that runs through the discourse to 6:60\u201366.',
  ),
  _IAmSaying(
    title: 'The Light of the World',
    reference: 'John 8:12',
    imagePath: 'assets/I Am/the light.webp',
    fullVerse:
        '\u201cI am the light of the world. Whoever follows me will not walk in darkness, but will have the light of life.\u201d',
    reflection:
        'Light reveals what is hidden, guides the way forward, and drives out darkness. Jesus claims to be the source of all spiritual illumination \u2014 the one who exposes truth, gives direction, and brings life to those who walk in His light.',
    scripture:
        '\u201cAgain, therefore, Jesus spoke to them, saying, \u2018I am the light of the world. He who follows me will not walk in the darkness, but will have the light of life.\u2019\u201d\n\u2014 John 8:12 (WEB)',
    statementInBrief:
        'In the Temple court during the Festival of Tabernacles, Jesus claims to be the ultimate source of spiritual illumination \u2014 not one light among many but the singular light that dispels all darkness and gives life.',
    centralPoint:
        'Light in the ancient world was not incidental \u2014 it was the difference between safety and danger, truth and deception, life and death. To claim to be the light of the world is to claim sovereignty over every domain where darkness operates. Those who follow Jesus will not walk in darkness \u2014 they will have light as a permanent possession.',
    question:
        'In what area of your life are you still navigating by partial light \u2014 your own understanding, other people\u2019s opinions \u2014 rather than walking in the full light of Jesus?',
    practices: [
      'Read John 1:1\u20139 and John 8:12 together. Note how John\u2019s prologue prepares for this claim.',
      'Identify one area of confusion, doubt, or moral fog in your life. Ask Jesus specifically to bring light to it.',
      'Spend ten minutes in silence and ask: what is Jesus illuminating in my life that I am tempted to keep in shadow?',
      'Read Isaiah 42:6\u20137 and 49:6 \u2014 the Servant called to be a light to the nations. Reflect on how Jesus fulfils this.',
    ],
    audienceContextTitle: 'THE FESTIVAL OF TABERNACLES AND THE TEMPLE COURT',
    audienceContext:
        'Jesus makes this declaration \u2018in the treasury\u2019 of the Temple (8:20), most likely the Court of the Women, during or just after the Festival of Tabernacles (Sukkoth). This festival included a dramatic torch-lighting ceremony in the Court of the Women, in which four great golden lampstands were lit to illuminate Jerusalem \u2014 commemorating the pillar of fire that guided Israel in the wilderness. Against this blazing backdrop, Jesus\u2019 claim would have been unmistakable in its audacity.',
    historicalContext:
        'The Festival of Tabernacles was one of the three great pilgrimage festivals of Judaism and combined remembrance of wilderness sojourn with eschatological hope. The torch-lighting ceremony was so spectacular that the Mishnah records: \u2018Anyone who has never seen the joy of the water-drawing ceremony has never seen joy in their life\u2019 (Sukkah 5:1). The pillar of fire in Exodus (13:21\u201322) guided Israel by night; God\u2019s eschatological light was expected in Zechariah 14:7. Jesus positions himself at the intersection of wilderness memory and messianic expectation.',
    scholarlyInterpretation:
        'Brown (The Gospel According to John, AB, 1966) argues that light-and-darkness is the most pervasive symbolic contrast in the Fourth Gospel (see 1:4\u20135; 3:19\u201321; 9:5; 12:35\u201336, 46) and that 8:12 stands as the thematic apex of that motif. Lincoln (BNTC, 2005) notes that the claim is made immediately after the woman caught in adultery episode (7:53\u20138:11), making Jesus\u2019 words an enacted demonstration: he has just brought light into darkness. Bultmann (The Gospel of John, 1971) traced the light-darkness dualism to Gnostic sources, but this has largely been displaced by evidence from the Dead Sea Scrolls, where the same dualism is pervasive in a thoroughly Jewish context.',
    exegeticalNotes:
        'The adverb \u03c0\u03ac\u03bb\u03b9\u03bd (\u2018again\u2019) connects 8:12 to the earlier teaching in 7:37\u201339 (living water), suggesting a continuation of the Tabernacles discourse. The predicate \u1f41 \u03c6\u03ce\u03c2 \u03c4\u03bf\u1fe6 \u03ba\u03cc\u03c3\u03bc\u03bf\u03c5 is definite and exclusive: not \u2018a light\u2019 but \u2018the light.\u2019 \u1f41 \u1f00\u03ba\u03bf\u03bb\u03bf\u03c5\u03b8\u03ce\u03bd \u1f10\u03bc\u03bf\u03af (the one following me) uses a present participle \u2014 ongoing, habitual following is implied. The promise \u2018will have the light of life\u2019 (\u1f15\u03be\u03b5\u03b9 \u03c4\u1f78 \u03c6\u03ce\u03c2 \u03c4\u1fc6\u03c2 \u03b6\u03c9\u1fc6\u03c2) echoes Psalm 36:9 and Isaiah 53:11 (LXX).',
  ),
  _IAmSaying(
    title: 'The Door of the Sheep',
    reference: 'John 10:9',
    imagePath: 'assets/I Am/The gate.webp',
    fullVerse:
        '\u201cI am the door. If anyone enters by me, he will be saved and will go in and out and find pasture.\u201d',
    reflection:
        'There is only one way into the safety of God\u2019s fold, and it is through Jesus. He is not a door among many \u2014 He is the door. To enter through Him is to find salvation, freedom, and abundant provision.',
    scripture:
        '\u201cI am the door. If anyone enters in through me, he will be saved, and will go in and go out, and will find pasture.\u201d\n\u2014 John 10:9 (WEB)',
    statementInBrief:
        'In an allegory about a sheepfold, Jesus identifies himself as the singular door through which sheep enter for safety and go out for nourishment \u2014 declaring that all other entry points are illegitimate.',
    centralPoint:
        'A door is not decoration \u2014 it is the means by which access is either granted or denied. Jesus is not a door among many options but the only legitimate opening into the care of God. The promise is comprehensive: salvation, freedom of movement, and abundant provision all come through this one door.',
    question:
        'Are you entering the life of faith through Jesus himself, or are you trying to find a side entrance \u2014 through performance, religious achievement, or self-sufficiency?',
    practices: [
      'Pray through the three promises of John 10:9 \u2014 being saved, going in and out freely, finding pasture. Ask what each means for your life today.',
      'Journal: what \u2018false doors\u2019 are you tempted to enter \u2014 things that promise security or spiritual life but bypass Jesus?',
      'Read Psalm 23 alongside John 10:1\u201318. Notice the parallel imagery of shepherd, sheep, provision, and safety.',
      'Identify one practice that helps you consciously \u2018enter through the door\u2019 \u2014 a prayer, a rhythm, a moment of surrender \u2014 and commit to it for a week.',
    ],
    audienceContextTitle: 'THE SHEPHERD DISCOURSE AND ITS ADVERSARIES',
    audienceContext:
        'The I Am the Door saying appears within John 10:1\u201318, the Shepherd Discourse, which follows immediately after the healing of the man born blind (John 9) and the confrontation with the Pharisees that closes that chapter (9:40\u201341). The Pharisees who have cast out the healed man are clearly in view as the \u2018thieves and robbers\u2019 of 10:1, 8 who do not enter through the door. The discourse addresses at once those who should have been shepherds of Israel and the sheep who have been failed by them.',
    historicalContext:
        'Sheepfolds in ancient Palestine were stone-walled enclosures, often shared by several flocks, with a single opening. At night, shepherds would sometimes lie across the gap as a living door. The metaphor of God as shepherd and Israel as his flock pervades the Old Testament (Ps 23; 80:1; Ezek 34; Isa 40:11). Ezekiel 34 is especially important \u2014 God condemns the \u2018shepherds of Israel\u2019 who have exploited the flock and promises to come himself to shepherd his people.',
    scholarlyInterpretation:
        'Michaels (NICNT, 2010) notes that 10:7 and 10:9 present two distinct aspects of the door metaphor: as door-for-the-shepherds (10:7) Jesus grants legitimate access to the flock; as door-for-entry (10:9) he is the means of salvation for the sheep themselves. Schnackenburg (1980) observes that the three promises in 10:9 \u2014 salvation, freedom, and pasture \u2014 mirror the full range of Ezekiel 34\u2019s promises of restoration. Carson (PNTC, 1991) argues that \u2018go in and go out\u2019 is an idiom for freedom and security (cf. Num 27:17; Deut 28:6) rather than mere physical movement.',
    exegeticalNotes:
        'The two \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 statements in this passage (10:7, 10:9) are the only doubled use in a single discourse. The use of \u03c3\u03c9\u03b8\u03ae\u03c3\u03b5\u03c4\u03b1\u03b9 (will be saved) is the sole occurrence of this verb in John\u2019s Gospel, making the explicit salvation language striking. The threefold promise structure moves from past act (saved) to ongoing freedom (go in and out) to continued provision (pasture). The phrase \u2018find pasture\u2019 (\u03bd\u03bf\u03bc\u1f74\u03bd \u03b5\u1f51\u03c1\u03ae\u03c3\u03b5\u03b9) echoes the LXX of Ezekiel 34:14.',
  ),
  _IAmSaying(
    title: 'The Good Shepherd',
    reference: 'John 10:11',
    imagePath: 'assets/I Am/the GoodShephard.webp',
    fullVerse:
        '\u201cI am the good shepherd. The good shepherd lays down his life for the sheep.\u201d',
    reflection:
        'The good shepherd knows His sheep by name, leads them to green pastures, and willingly lays down His life for them. This is not management from a distance \u2014 it is costly, personal love. Jesus fulfilled this completely on the cross.',
    scripture:
        '\u201cI am the good shepherd. The good shepherd lays down his life for the sheep.\u201d\n\u2014 John 10:11 (WEB)',
    statementInBrief:
        'Jesus contrasts himself with hired hands who flee when danger comes, declaring himself the true shepherd whose defining act is the voluntary laying down of his own life for the sheep.',
    centralPoint:
        'The defining mark of the good shepherd is not competence or warmth but sacrifice. Jesus insists three times in 10:11\u201318 that he lays down his life voluntarily. This is not tragic fate but purposeful love. The claim anticipates the cross and reveals what true care for others actually costs.',
    question:
        'Where in your relationships or responsibilities are you tempted to play the \u2018hired hand\u2019 \u2014 present for the easy moments but withdrawing when the cost becomes too high?',
    practices: [
      'Meditate on the phrase \u2018lays down his life.\u2019 Sit with the voluntary nature of Jesus\u2019 sacrifice. What does it mean that this was chosen?',
      'Read Ezekiel 34:1\u201316 \u2014 God\u2019s indictment of Israel\u2019s failed shepherds. How does Jesus fulfil what they failed to be?',
      'Identify one relationship where you are called to costly, sacrificial care. Pray for the grace to show up even when it is hard.',
      'Pray Psalm 23 slowly as a prayer to Jesus as your shepherd. Let each phrase sink in.',
    ],
    audienceContextTitle: 'CONTRAST WITH HIRELINGS AND FAILED SHEPHERDS',
    audienceContext:
        'The Good Shepherd declaration is part of the same extended discourse (10:1\u201318) as the Door saying. The contrast shifts from illegitimate shepherds to inadequate ones: the hired hand (\u03bc\u03b9\u03c3\u03b8\u03c9\u03c4\u03cc\u03c2) is not evil but unreliable under pressure \u2014 the sheep are not \u2018his own.\u2019 The discourse then expands the flock: Jesus has \u2018other sheep not of this fold\u2019 (10:16) \u2014 a reference widely understood as Gentile believers who will be brought into one flock under one shepherd.',
    historicalContext:
        'The ideal shepherd in antiquity was expected to know each animal individually, to protect them at personal risk, and to lead rather than drive. The image of the shepherd-king was central in ancient Near Eastern iconography. In Israel, David himself was taken from following the flock to shepherd God\u2019s people (2 Sam 7:8; Ps 78:70\u201372). God\u2019s promise in Ezekiel 34:23\u201324 to send \u2018my servant David\u2019 as shepherd was clearly messianic. Jesus\u2019 claim is royal as well as pastoral.',
    scholarlyInterpretation:
        'Dodd (The Interpretation of the Fourth Gospel, 1953) sees 10:11\u201318 as the interpretive centre of the Shepherd Discourse, where the metaphorical level gives way to direct christological declaration. The emphasis on voluntary death (10:17\u201318) is, Dodd argues, John\u2019s explicit rebuttal of any reading of the crucifixion as defeat or accident. Culpepper (Anatomy of the Fourth Gospel, 1983) notes the ironic structure: those who claim to be Israel\u2019s shepherds have been revealed as blind (9:41), while the blind man who was cast out has become a sheep who hears the shepherd\u2019s voice.',
    exegeticalNotes:
        '\u039a\u03b1\u03bb\u1f78\u03c2 \u03c0\u03bf\u03b9\u03bc\u03ae\u03bd (good shepherd) uses \u03ba\u03b1\u03bb\u03cc\u03c2 not \u1f00\u03b3\u03b1\u03b8\u03cc\u03c2 \u2014 suggesting something visible, admirable, and true. The present tense \u03c4\u03af\u03b8\u03b7\u03c3\u03b9\u03bd (lays down) is used proleptically \u2014 the act lies in the future but is already definitive of Jesus\u2019 identity. The threefold repetition of \u2018lay down\u2019 (10:11, 15, 17\u201318) creates a rhetorical emphasis unparalleled elsewhere in John. The phrase \u2018as the Father knows me and I know the Father\u2019 (10:15) inserts the shepherd-sheep relationship into the mutual knowledge of the Godhead itself.',
  ),
  _IAmSaying(
    title: 'The Resurrection and the Life',
    reference: 'John 11:25',
    imagePath: 'assets/I Am/the Resurrection.webp',
    fullVerse:
        '\u201cI am the resurrection and the life. Whoever believes in me, though he die, yet shall he live, and everyone who lives and believes in me shall never die.\u201d',
    reflection:
        'Standing before a tomb, Jesus made the most audacious claim in human history \u2014 that He himself is the source of resurrection and life. Death is not the final word for those who believe in Him. He does not merely bring resurrection; He is it.',
    scripture:
        '\u201cJesus said to her, \u2018I am the resurrection and the life. He who believes in me will still live, even if he dies. Whoever lives and believes in me will never die. Do you believe this?\u2019\u201d\n\u2014 John 11:25\u201326 (WEB)',
    statementInBrief:
        'Standing outside the tomb of Lazarus, four days dead, Jesus declares that he is not merely the one who raises the dead but that resurrection and life are what he is. The statement ends with a direct personal challenge: \u2018Do you believe this?\u2019',
    centralPoint:
        'Jesus does not say \u2018I will bring resurrection at the last day\u2019 \u2014 he says \u2018I am the resurrection.\u2019 He collapses the future eschatological event into his own present person. Death is not the last word for those who believe, not because circumstances will change but because Jesus himself is life.',
    question:
        'Where are you treating death \u2014 of a relationship, a hope, a future you planned \u2014 as the final word, rather than bringing it to the one who is the resurrection?',
    practices: [
      'Sit with John 11:1\u201344 in full. Notice the timing of Jesus\u2019 arrival, his response to grief, and his prayer before calling Lazarus out.',
      'Identify something in your life that feels dead or beyond hope. Bring it explicitly to Jesus as Martha brought her grief to him.',
      'Reflect on the question Jesus puts to Martha: \u2018Do you believe this?\u2019 Write out your honest answer.',
      'Read 1 Corinthians 15:20\u201326. How does the resurrection of Jesus shape your understanding of death and hope?',
    ],
    audienceContextTitle: 'MARY, MARTHA, AND A DEAD MAN\'S TOMB',
    audienceContext:
        'The setting is Bethany, near Jerusalem, where Lazarus has been entombed for four days. Both sisters send word to Jesus while he is still beyond the Jordan (11:1\u20133). Four days was significant: Jewish tradition held that the soul remained near the body for three days before departing, making any resurrection after that point humanly impossible. Jesus deliberately waits (11:6) \u2014 the delay is not neglect but divine orchestration. The audience is Mary, Martha, and gathered mourners, and later the disciples and the crowd who witness the raising.',
    historicalContext:
        'Jewish belief in bodily resurrection was well-established in the first century (affirmed by Pharisees, contested by Sadducees; Dan 12:2; 2 Macc 7). Martha\u2019s confession \u2014 \u2018I know that he will rise again in the resurrection at the last day\u2019 (11:24) \u2014 reflects mainstream Pharisaic eschatology. Jesus\u2019 response does not deny a future resurrection; he claims to be the source and agent of it, collapsing the future into the present. Jewish mourning customs included wailing, the presence of comforters, and typically lasted seven days.',
    scholarlyInterpretation:
        'Bultmann (1971) argued that 11:25\u201326 distinguishes two groups: those already physically dead (\u2018even if he dies, yet will he live\u2019) and those still alive (\u2018whoever lives and believes in me will never die\u2019), with both registers carrying spiritual as well as physical resonance. Schnackenburg (1980) sees the \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 statement as the theological pivot of chapters 1\u201311 of John \u2014 all the I AM sayings have been building toward this climax. Keener (2003) notes that \u2018I am the resurrection\u2019 (not \u2018I give\u2019 or \u2018I perform\u2019) is the most ontological of the predicated sayings: it identifies Jesus with the reality, not merely the action.',
    exegeticalNotes:
        '\u1f18\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 \u1f21 \u1f00\u03bd\u03ac\u03c3\u03c4\u03b1\u03c3\u03b9\u03c2 \u03ba\u03b1\u1f76 \u1f21 \u03b6\u03c9\u03ae uses two definite nouns \u2014 the resurrection and the life \u2014 both with the definite article, indicating that Jesus is not a type but the very substance of both realities. The two-part promise (11:25b\u201326a) uses conditional clauses covering the full range of mortality: the already-dead and the still-living. The verb \u03b6\u03ae\u03c3\u03b5\u03c4\u03b1\u03b9 (shall live, 11:25) is future active \u2014 pointing to bodily resurrection. \u1f00\u03c0\u03bf\u03b8\u03ac\u03bd\u1fc3 \u03b5\u1f30\u03c2 \u03c4\u1f78\u03bd \u03b1\u1f30\u03ce\u03bd\u03b1 (shall never die, 11:26) employs the double negative with the strong force of eternal negation.',
  ),
  _IAmSaying(
    title: 'The Way, Truth, and Life',
    reference: 'John 14:6',
    imagePath: 'assets/I Am/The Way.webp',
    fullVerse:
        '\u201cI am the way, and the truth, and the life. No one comes to the Father except through me.\u201d',
    reflection:
        'Three claims woven into one: Jesus is the way \u2014 the only path to the Father. He is the truth \u2014 the ultimate reality that every true thing reflects. He is the life \u2014 the source and sustainer of all living. This is perhaps the most comprehensive of all the I AM declarations.',
    scripture:
        '\u201cJesus said to him, \u2018I am the way, the truth, and the life. No one comes to the Father, except through me.\u2019\u201d\n\u2014 John 14:6 (WEB)',
    statementInBrief:
        'In the farewell discourse, responding to Thomas\u2019s question about where Jesus is going, Jesus makes a triple identification that summarises his entire mission: he is the exclusive path to the Father, the definitive revelation of reality, and the source of all life.',
    centralPoint:
        'The three nouns \u2014 way, truth, life \u2014 are not separate claims but a single threefold declaration. Jesus is the way because he is the truth; he is the truth because he is the life. The exclusive clause \u2014 \u2018no one comes to the Father except through me\u2019 \u2014 is not restriction for its own sake but the natural consequence of who Jesus is.',
    question:
        'Which of the three \u2014 the way (direction), the truth (certainty), or the life (vitality) \u2014 do you most need Jesus to be for you right now?',
    practices: [
      'Pray through the three titles one by one: \u2018Be my way in ___. Be my truth about ___. Be my life in ___.\u2019',
      'Read John 14:1\u201314 in full. Notice the context of uncertainty among the disciples. How does Jesus\u2019 answer speak to those same fears in your life?',
      'Identify one belief you are holding onto that may not be consistent with Jesus as the truth. Bring it into the open in prayer.',
      'Reflect on how your daily decisions reflect \u2014 or don\u2019t reflect \u2014 walking along Jesus as the way rather than your own path.',
    ],
    audienceContextTitle: 'THE FAREWELL DISCOURSE AND THOMAS\'S QUESTION',
    audienceContext:
        'John 14\u201317 contains the extended Farewell Discourse, delivered in the upper room on the night of Jesus\u2019 arrest. Thomas asks: \u2018Lord, we don\u2019t know where you are going. How can we know the way?\u2019 (14:5). His question is earnest and practical \u2014 he assumes Jesus is speaking of a physical destination. Jesus\u2019 answer reframes the question entirely: the destination is the Father, and the way is Jesus himself. The audience is the Eleven, who are frightened and confused about Jesus\u2019 imminent departure.',
    historicalContext:
        'In Jewish and Hellenistic thought, \u2018the way\u2019 (Hebrew derek, Greek \u1f41\u03b4\u03cc\u03c2) was a common metaphor for moral life and religious practice. The Dead Sea Scrolls community at Qumran referred to their community as \u2018the Way.\u2019 The early church itself was first called \u2018the Way\u2019 (Acts 9:2; 19:9, 23). \u2018Truth\u2019 in Hebrew thought (emet) carried connotations of faithfulness and reliability, not merely intellectual accuracy. \u2018Life\u2019 (\u03b6\u03c9\u03ae) in John consistently refers to the eschatological life of the age to come, already breaking into the present.',
    scholarlyInterpretation:
        'Carson (1991) argues that the three terms form an ascending climax: way is the most accessible, truth the most comprehensive, life the most ultimate. Beasley-Murray (WBC, 1987) reads them as a chiasm with life at the centre: way \u2192 life \u2190 truth. Brown (AB, 1970) notes that the three titles summarise the functions attributed to divine Wisdom in Jewish literature: she is the way (Prov 3:17; 8:20), the truth (Prov 8:7), and the life (Prov 3:18; 8:35). Lincoln (2005) emphasises that the exclusive clause corresponds to the prologue\u2019s claim that the Word was \u2018with God\u2019 and \u2018was God\u2019 (1:1).',
    exegeticalNotes:
        'The three nouns in 14:6a \u2014 \u1f21 \u1f41\u03b4\u1f78\u03c2 \u03ba\u03b1\u1f76 \u1f21 \u1f00\u03bb\u03ae\u03b8\u03b5\u03b9\u03b1 \u03ba\u03b1\u1f76 \u1f21 \u03b6\u03c9\u03ae \u2014 each carry the definite article, emphasising their exclusive character. No parallel exists in John for such a triadic predicate, making this grammatically distinctive even among the I AM sayings. The negative \u03c0\u03c1\u1f78\u03c2 \u03c4\u1f78\u03bd \u03c0\u03b1\u03c4\u03ad\u03c1\u03b1 \u2026 \u03b5\u1f30 \u03bc\u1f74 \u03b4\u03b9\u2019 \u1f10\u03bc\u03bf\u1fe6 could be rendered \u2018to the Father\u2019s side \u2026 except through me,\u2019 with \u03c0\u03c1\u03cc\u03c2 suggesting personal, relational proximity. Verse 14:7 confirms that the way to the Father is through knowing the person of Jesus, not merely following his teaching.',
  ),
  _IAmSaying(
    title: 'The True Vine',
    reference: 'John 15:5',
    imagePath: 'assets/I Am/The Vine.webp',
    fullVerse:
        '\u201cI am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.\u201d',
    reflection:
        'A branch that is cut from the vine cannot survive, let alone bear fruit. Jesus calls us not merely to follow His example but to remain vitally connected to Him \u2014 drawing life from Him as a branch draws life from the vine. Fruitfulness flows from abiding.',
    scripture:
        '\u201cI am the vine. You are the branches. He who remains in me and I in him bears much fruit, for apart from me you can do nothing.\u201d\n\u2014 John 15:5 (WEB)',
    statementInBrief:
        'On the eve of his arrest, Jesus uses the image of a vine and its branches to describe the relationship between himself and his disciples: an organic, life-giving union without which fruitfulness is impossible.',
    centralPoint:
        'The key word is \u03bc\u03ad\u03bd\u03c9 \u2014 \u2018abide,\u2019 \u2018remain,\u2019 \u2018stay.\u2019 The branch does not generate life; it receives it from the vine. Fruitfulness is not achieved by effort but by remaining. The stark closing clause \u2014 \u2018apart from me you can do nothing\u2019 \u2014 is not a rebuke but a description of spiritual reality.',
    question:
        'What areas of your life are you trying to produce fruit through effort rather than through abiding \u2014 and what would it look like to remain more deeply connected to Jesus?',
    practices: [
      'Read John 15:1\u201317 in full. Note every occurrence of \u2018abide/remain.\u2019 What does Jesus say results from abiding?',
      'Identify one spiritual discipline \u2014 prayer, scripture, worship, community \u2014 that could serve as a means of abiding for you this week. Commit to it daily.',
      'Reflect on one fruit in your life that you recognise as genuinely Spirit-produced rather than self-generated. Give thanks for it.',
      'Pray the phrase \u2018Apart from you I can do nothing\u2019 as a daily morning prayer. Notice how it reorients your approach to the day.',
    ],
    audienceContextTitle: 'THE VINE ALLEGORY IN THE FAREWELL DISCOURSE',
    audienceContext:
        'John 15:1\u201317 is part of the extended Farewell Discourse (John 14\u201317), likely delivered during the walk to Gethsemane (cf. 14:31). The disciples are hours from the arrest and crucifixion. The allegory functions simultaneously as encouragement (you are already in the vine), warning (a branch that does not bear fruit is removed), and promise (ask whatever you wish and it will be done for you \u2014 15:7).',
    historicalContext:
        'The vine was one of the central symbols of Israel in the Old Testament. Israel is called God\u2019s vine in Psalm 80:8\u201316, Isaiah 5:1\u20137 (the Song of the Vineyard), Jeremiah 2:21, Ezekiel 15, and Hosea 10:1. In every case, the vine disappoints \u2014 Israel has failed to produce the fruit God planted it to bear. Jesus\u2019 claim to be the \u2018true vine\u2019 (\u1f21 \u1f04\u03bc\u03c0\u03b5\u03bb\u03bf\u03c2 \u1f21 \u1f00\u03bb\u03b7\u03b8\u03b9\u03bd\u03ae) implicitly addresses this pattern: Israel was the earthly vine that failed; Jesus is the true vine that fulfils everything the vine was meant to be. The vine was also depicted on the Temple facade in Jesus\u2019 day (Josephus, Jewish Antiquities 15.395).',
    scholarlyInterpretation:
        'Schnackenburg (1980) argues that the vine allegory is the climax of the I AM sayings because it includes the disciples within the metaphor: earlier sayings are about Jesus himself; this one describes the believer\u2019s constitutive relationship to Jesus. Hays (Echoes of Scripture in the Gospels, 2016) emphasises the intertextual density of the vine image \u2014 Jesus\u2019 claim implicitly indicts Israel\u2019s failure and replaces it with himself as the faithful covenant partner. Keener (2003) notes the Passover context: vines were associated with the Passover cup, which Jesus had just used to speak of his blood, creating a dense cluster of symbolic meaning.',
    exegeticalNotes:
        'The adjective \u1f00\u03bb\u03b7\u03b8\u03b9\u03bd\u03ae (true, genuine) distinguishes Jesus from the unfaithful vine of Israel\u2019s history \u2014 not \u2018real\u2019 as opposed to metaphorical, but authentic, fulfilling the type. The verb \u03bc\u03ad\u03bd\u03c9 occurs eleven times in 15:1\u201310, making it the structural and theological centre of the allegory. The aorist passive \u1f10\u03ba\u03b2\u03bb\u03ae\u03b8\u03b7 (thrown out, 15:6) describes the condition of the fruitless branch as already accomplished. The promise \u2018ask whatever you wish\u2019 (15:7) is conditioned by \u2018if you abide in me and my words abide in you\u2019 \u2014 desire shaped by union with Jesus is desire aligned with the Father\u2019s will.',
  ),
  _IAmSaying(
    title: 'Before Abraham Was, I Am',
    reference: 'John 8:58',
    imagePath: 'assets/I Am/Before Abraham.webp',
    headerLabel: '\u2018Before Abraham was, I am\u2019',
    fullVerse:
        '\u201cBefore Abraham came into existence, I am.\u201d',
    reflection:
        'Jesus does not merely claim to pre-date Abraham \u2014 He claims to exist in the timeless, present-tense being of God. He does not say \u2018I was\u2019 but \u2018I am.\u2019 This is the most direct claim to divine identity in John\u2019s Gospel, and the crowd understood it immediately: they reached for stones.',
    scripture:
        '\u201cJesus said to them, \u2018Most certainly, I tell you, before Abraham came into existence, I am.\u2019\u201d\n\u2014 John 8:58 (WEB)',
    statementInBrief:
        'In a confrontation with Jewish leaders about his identity, Jesus claims not merely pre-existence before Abraham but the timeless, present-tense existence of God himself \u2014 invoking the divine name revealed to Moses at the burning bush.',
    centralPoint:
        'The shock lies in the grammar: Jesus does not say \u2018before Abraham was, I was\u2019 \u2014 he says \u2018I am.\u2019 The shift from past to present tense is theologically decisive. He does not claim to pre-date Abraham chronologically; he claims to exist in the eternal present that transcends all chronology. This is the most direct claim to divine identity in John\u2019s Gospel.',
    question:
        'Is Jesus merely a figure from history to you, or do you encounter him as the one who simply and presently \u2018is\u2019 \u2014 living, sovereign, and with you now?',
    practices: [
      'Sit with Exodus 3:13\u201315. Note the name God reveals: \u2018I AM WHO I AM.\u2019 Then read John 8:58 again in that light.',
      'Pray using \u2018I AM\u2019 as a name for Jesus \u2014 not as a phrase but as an address. Notice how this changes the character of your prayer.',
      'Read John 8:31\u201359 in full to understand the escalating controversy. What were the religious leaders protecting, and why did this claim provoke them to reach for stones?',
      'Journal: if Jesus is the eternal I AM, what does that mean for your understanding of God?',
    ],
    audienceContextTitle: 'THE CONTROVERSY ABOUT ABRAHAM IN THE TEMPLE',
    audienceContext:
        'John 8:31\u201359 contains one of the most intense controversies in the Gospel, set within the Temple precincts during the Festival of Tabernacles. The dialogue with \u2018those who had believed in him\u2019 (8:31) quickly turns hostile as Jesus challenges their claim to Abrahamic descent while remaining in slavery to sin. The controversy escalates through competing claims about Abraham \u2014 who has truly seen him, who truly descends from him \u2014 until Jesus\u2019 climactic statement in 8:58 provokes an attempt to stone him for blasphemy.',
    historicalContext:
        'Abraham was the supreme figure of Jewish national identity \u2014 father of the covenant, friend of God (Isa 41:8), and recipient of the divine promise. Claims about Abraham were therefore claims about the very basis of Jewish existence. Second-Temple tradition had developed an elaborate portrait of Abraham as pre-eminent prophet, priest, and righteous one (Jubilees; Testament of Abraham; Philo). For Jesus to claim pre-existence over Abraham was to claim a status entirely outside the boundaries of human greatness, however exceptional.',
    scholarlyInterpretation:
        'The reaction \u2014 taking up stones to throw at him (8:59) \u2014 is the clearest indication that the crowd heard Jesus\u2019 claim as an assertion of divine identity, for which blasphemy by stoning was the prescribed penalty (Lev 24:16). Bultmann (1971) sees 8:58 as the culmination of the growing self-revelation of the Logos through chapters 7\u20138. Carson (1991) notes that the absolute \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 without a predicate is the closest verbal parallel to the LXX rendering of Yahweh\u2019s name in Exodus 3:14 and to the repeated first-person declarations of Deutero-Isaiah (Isa 43:10, 13, 25; 46:4; 48:12, LXX: \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9). Harner (The \u2018I Am\u2019 of the Fourth Gospel, 1970) showed that these absolute uses carry the full weight of the divine name.',
    exegeticalNotes:
        'The absolute \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 (without a predicate noun or adjective) in 8:58 stands in sharp contrast to the predicated I AM sayings. The juxtaposition of \u03c0\u03c1\u03af\u03bd \u1f08\u03b2\u03c1\u03b1\u1f70\u03bc \u03b3\u03b5\u03bd\u03ad\u03c3\u03b8\u03b1\u03b9 (before Abraham came into being \u2014 aorist infinitive, marking Abraham\u2019s beginning) with \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 (I am \u2014 present indicative, marking no beginning) is the grammatical form of the theological claim. The present tense is not a solecism; it is the point. Lincoln (2005) notes that John places this absolute ego eimi at the structural turning point of the Gospel (8:24, 28, 58) as a gathering crescendo of revelation.',
  ),
  _IAmSaying(
    title: 'I Am He',
    reference: 'John 18:4\u20138',
    imagePath: 'assets/I Am/I Am He.webp',
    headerLabel: '\u2018I am he\u2019',
    fullVerse:
        '\u201cJesus \u2026 went forward and said to them, \u2018Who are you looking for?\u2019 \u2026 Jesus said to them, \u2018I am he.\u2019 \u2026 When he said to them, \u2018I am he,\u2019 they went backward and fell to the ground.\u201d',
    reflection:
        'At the moment of His arrest, Jesus does not retreat \u2014 He advances. He speaks the divine name and soldiers fall backward. Even here, in the darkest hour, the I AM is sovereign. The cross is not something that happens to Jesus; it is something Jesus walks into with full authority.',
    scripture:
        '\u201cJesus therefore, knowing all the things that were happening to him, went forward and said to them, \u2018Who are you looking for?\u2019 They answered him, \u2018Jesus of Nazareth.\u2019 Jesus said to them, \u2018I am he.\u2019 \u2026 When he said to them, \u2018I am he,\u2019 they went backward and fell to the ground.\u201d\n\u2014 John 18:4\u20136 (WEB)',
    statementInBrief:
        'At the moment of his arrest in Gethsemane, Jesus steps forward and identifies himself \u2014 and the soldiers fall to the ground. The formula \u2018I am he\u2019 carries the full weight of the divine name in the most unexpected of settings: a garden, at night, with armed soldiers.',
    centralPoint:
        'This is not a passive surrender \u2014 it is a sovereign act. Jesus does not wait to be seized; he advances and identifies himself. The falling of the soldiers is John\u2019s sign that even at the moment of apparent defeat, the I AM is not overcome. The repeated \u2018I am he\u2019 \u2014 three times in the passage \u2014 transforms the arrest scene into a scene of divine revelation.',
    question:
        'Do you see the cross as Jesus\u2019 defeat or as his sovereign act? How does the scene in John 18 reshape your understanding of what happened there?',
    practices: [
      'Read John 18:1\u201312 in full. Note every detail John includes that signals Jesus\u2019 sovereignty and intention.',
      'Reflect on the fact that the same words associated with the divine name caused trained soldiers to fall. What does this tell you about the nature of Jesus\u2019 power?',
      'Pray specifically about a situation in which you feel powerless or at risk. Bring it to the one who stepped forward in the garden.',
      'Read Philippians 2:6\u201311 alongside John 18:4\u20138. How does the voluntary self-humbling of Jesus relate to his sovereign \u2018I am he\u2019?',
    ],
    audienceContextTitle: 'THE ARREST IN GETHSEMANE',
    audienceContext:
        'John 18:1\u201312 describes the arrest of Jesus in the garden across the Kidron Valley, after the Farewell Discourse and High-Priestly Prayer (chapters 14\u201317). John\u2019s account includes a \u03c3\u03c0\u03b5\u1f36\u03c1\u03b1 (cohort) \u2014 which could refer to a Roman military unit of several hundred \u2014 alongside officers of the chief priests and Pharisees. The presence of Roman soldiers alongside Jewish religious officers signals the widest possible coalition against Jesus. The moment is the culmination of the entire Gospel\u2019s conflict.',
    historicalContext:
        'Gethsemane (Hebrew: \u2018oil press\u2019) was a garden on the Mount of Olives, a familiar meeting place for Jesus and his disciples. Night arrests were common in the ancient world as a means of avoiding public disorder. The carrying of lanterns, torches, and weapons emphasises the seriousness of the operation. The scene\u2019s irony is sharp: soldiers carry torches to find the Light of the World. A \u03c3\u03c0\u03b5\u1f36\u03c1\u03b1 in military terminology referred to a maniple of 200 soldiers or a cohort of 600; the detail may be hyperbolic or refer to a detachment.',
    scholarlyInterpretation:
        'The falling of the soldiers at Jesus\u2019 self-identification has no parallel in the Synoptic accounts and is widely recognised as a Johannine theological statement. Bauckham (The Testimony of the Beloved Disciple, 2007) sees the scene as a deliberate echo of Old Testament theophanies in which humans fall prostrate before God\u2019s presence (Dan 8:17\u201318; 10:9; Rev 1:17; Ezek 1:28). Lincoln (2005) reads the soldiers\u2019 collapse as John\u2019s ironic inversion: the instruments of Jesus\u2019 arrest are undone by the power of his word. Brown (AB, 1970) notes that the threefold repetition of \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 in 18:5, 6, 8 mirrors the structure of the High-Priestly Prayer.',
    exegeticalNotes:
        '\u1f18\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 in 18:5 and 18:8 is technically translatable as \u2018I am he\u2019 (with the unexpressed referent taken from context), but the falling of the soldiers in 18:6 strongly suggests that the absolute divine resonance is intentional. \u1f00\u03c0\u1fc6\u03bb\u03b8\u03bf\u03bd \u03b5\u1f30\u03c2 \u03c4\u1f70 \u1f40\u03c0\u03af\u03c3\u03c9 \u03ba\u03b1\u1f76 \u1f14\u03c0\u03b5\u03c3\u03b1\u03bd \u03c7\u03b1\u03bc\u03b1\u03af (they went back and fell to the ground) uses the aorist to describe a completed action \u2014 the soldiers fall; they do not merely stumble. The repetition of the question and answer in 18:7\u20138 is a Johannine doubling technique that intensifies the revelation. Lincoln (2005) notes that John places three absolute ego eimi sayings as a structural crescendo: 8:24, 8:28, 8:58, and here \u2014 tripled \u2014 at the Gospel\u2019s climactic hour.',
  ),
];

// ── View ─────────────────────────────────────────────────────────────────────

class IAmSayingsView extends StatelessWidget {
  const IAmSayingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ───────────────────────────────────────────────────
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
                    'assets/I Am/Header.webp',
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
                          'The \u201cI AM\u201d Sayings of Jesus',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '\u2018Before Abraham was, I am.\u2019',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _kAccent.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'John 8:58',
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

          // ── Intro ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In the Gospel of John, Jesus repeatedly opens statements with the words \u201cI am\u201d \u2014 deliberately echoing the divine name God revealed to Moses at the burning bush. Seven of these carry a predicate, a vivid image that reveals something essential about who Jesus is. Two more stand alone, without a predicate, carrying the full weight of the divine name in its most concentrated form.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In each predicated saying, Jesus takes something essential to human life \u2014 bread, light, a gate, a shepherd, resurrection, a road, a vine \u2014 and says: that is what I am to you. These are not metaphors or modest claims. They are declarations of identity. Tap any saying to sit with it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Learn more link
                  GestureDetector(
                    onTap: () => _showLearnMore(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn more about the \u201cI AM\u201ds',
                          style: TextStyle(
                            fontSize: 13,
                            color: MyWalkColor.golden.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: MyWalkColor.golden.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── 2-column image grid ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final saying = _sayings[i];
                  return _IAmCard(
                    saying: saying,
                    onTap: () => _showDetail(context, saying),
                  );
                },
                childCount: _sayings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Learn More modal ──────────────────────────────────────────────────────

  void _showLearnMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: _kAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The \u201cI AM\u201d Sayings of Jesus',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'John\u2019s Gospel \u2014 a scholarly study',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // ── THE I AM STATEMENTS IN JOHN'S GOSPEL ─────────────────
                  _lmSectionHeader('THE I AM STATEMENTS IN JOHN\u2019S GOSPEL'),
                  _lmPara(
                    'Among all the Gospels, it is John who preserves what scholars call the \u2018I AM\u2019 (Greek: \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9) sayings of Jesus \u2014 statements in which Jesus opens a declaration with a formula unmistakably associated, in any Jewish ear of the first century, with the divine name. When God appeared to Moses at the burning bush and was asked for his name, the answer was a form of the verb \u2018to be\u2019: \u2018I AM WHO I AM\u2019 (Exod 3:14, Hebrew: \u05d0\u05b6\u05d4\u05b0\u05d9\u05b6\u05d4 \u05d0\u05b2\u05e9\u05c1\u05b6\u05e8 \u05d0\u05b6\u05d4\u05b0\u05d9\u05b6\u05d4). In the Septuagint \u2014 the Greek translation of the Hebrew Scriptures in wide use in Jesus\u2019 day \u2014 the same name was rendered \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 \u1f41 \u1f64\u03bd, \u2018I am the one who is.\u2019',
                  ),
                  _lmPara(
                    'Scholars customarily distinguish two categories of \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 sayings in John. The first comprises the seven predicated sayings \u2014 statements in which Jesus attaches a symbolic image to the formula: the bread of life (6:35), the light of the world (8:12), the door of the sheep (10:7, 9), the good shepherd (10:11, 14), the resurrection and the life (11:25), the way, the truth, and the life (14:6), and the true vine (15:1, 5). In each case, Jesus takes something elemental and universal \u2014 bread, light, a gate, a shepherd, life itself, a path, a plant \u2014 and claims to be, in his own person, the ultimate reality that these things point toward. The predicated sayings are not merely analogies. They are claims about what Jesus is at the level of essence.',
                  ),
                  _lmPara(
                    'The second category comprises the absolute sayings \u2014 uses of \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 without a predicate \u2014 which carry the most direct weight of the divine name. The most theologically charged occurs in 8:58 (\u2018Before Abraham was, I am\u2019) and in the arrest scene of 18:5\u20138, where Jesus identifies himself three times and the soldiers fall backward. Deutero-Isaiah is the most likely scriptural background: in Isaiah 43:10\u201313 and 45:18, God declares \u2018I am he\u2019 using the Hebrew \u05d0\u05b2\u05e0\u05b4\u05d9 \u05d4\u05d5\u05bc\u05d0 (ani hu), rendered in the Septuagint as \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9. John\u2019s Jesus speaks the same words \u2014 and the Gospel consistently signals that the reader should recognise the identification.',
                  ),
                  const SizedBox(height: 8),
                  _lmDivider(),
                  const SizedBox(height: 16),
                  // ── SCHOLARLY NOTE ────────────────────────────────────────
                  _lmSectionHeader('SCHOLARLY NOTE ON STRUCTURE AND NUMBERING'),
                  _lmPara(
                    'The seven predicated I AM sayings are widely recognised in scholarship (Brown, Bultmann, Barrett, Schnackenburg) as a distinctive Johannine feature with no direct parallel in the Synoptic tradition. The number seven is likely deliberate \u2014 John\u2019s Gospel is deeply structured around sevens (seven signs, seven days of new creation in the prologue). Harner\u2019s seminal study (The \u2018I Am\u2019 of the Fourth Gospel, 1970) distinguished predicated from absolute uses and demonstrated that the absolute \u03b5\u03b3\u03ce \u03b5\u1f30\u03bc\u03b9 sayings function as direct equivalents to Old Testament divine-name formulae. The two absolute sayings (8:58 and 18:5\u20138) are sometimes excluded from popular lists of \u2018the seven I AM sayings,\u2019 but this module includes all nine because the absolute sayings are arguably the most theologically significant of all \u2014 and the arrest scene of 18:5\u20138 is rarely given the careful attention it deserves.',
                  ),
                  const SizedBox(height: 8),
                  _lmDivider(),
                  const SizedBox(height: 16),
                  // ── Works Cited ───────────────────────────────────────────
                  const _IAmWorksCitedExpansion(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail modal ──────────────────────────────────────────────────────────

  void _showDetail(BuildContext context, _IAmSaying saying) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.auto_awesome, size: 18, color: _kAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saying.modalHeader,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          saying.reference,
                          style: TextStyle(
                            fontSize: 12,
                            color: _kAccent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // 1. SCRIPTURE — WORLD ENGLISH BIBLE
                  _detailSectionHeader('SCRIPTURE \u2014 WORLD ENGLISH BIBLE'),
                  GestureDetector(
                    onTap: () => BibleProjectBrowserView.openOrPrompt(
                        context, reference: saying.reference),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: _kAccent.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        saying.scripture,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: MyWalkColor.softGold.withValues(alpha: 0.9),
                          height: 1.65,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. THE STATEMENT IN BRIEF
                  _detailSectionHeader('THE STATEMENT IN BRIEF'),
                  _detailPara(saying.statementInBrief),
                  _detailDivider(),

                  // 3. THE CENTRAL POINT
                  _detailSectionHeader('THE CENTRAL POINT'),
                  _detailPara(saying.centralPoint),
                  _detailDivider(),

                  // 4. THE QUESTION IT ASKS YOU
                  _detailSectionHeader('THE QUESTION IT ASKS YOU'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: MyWalkColor.softGold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MyWalkColor.softGold.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      saying.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                        height: 1.65,
                      ),
                    ),
                  ),
                  _detailDivider(),

                  // 5. Reflection
                  _detailSectionHeader('Reflection'),
                  _detailPara(saying.reflection),
                  _detailDivider(),

                  // 6. SUGGESTED PRACTICES
                  _detailSectionHeader('SUGGESTED PRACTICES'),
                  ...saying.practices.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5, right: 10),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      MyWalkColor.warmWhite.withValues(alpha: 0.75),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  _detailDivider(),

                  // 7. AUDIENCE AND CONTEXT
                  _detailSectionHeader('AUDIENCE AND CONTEXT'),
                  _detailSubHeader(saying.audienceContextTitle),
                  _detailPara(saying.audienceContext),
                  _detailDivider(),

                  // 8. HISTORICAL AND CULTURAL CONTEXT
                  _detailSectionHeader('HISTORICAL AND CULTURAL CONTEXT'),
                  _detailPara(saying.historicalContext),
                  _detailDivider(),

                  // 9. SCHOLARLY INTERPRETATION
                  _detailSectionHeader('SCHOLARLY INTERPRETATION'),
                  _detailPara(saying.scholarlyInterpretation),
                  _detailDivider(),

                  // 10. EXEGETICAL AND LITERARY NOTES
                  _detailSectionHeader('EXEGETICAL AND LITERARY NOTES'),
                  _detailPara(saying.exegeticalNotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _lmSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MyWalkColor.softGold,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _lmPara(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.65,
          ),
        ),
      );

  Widget _lmDivider() => Divider(
        color: MyWalkColor.golden.withValues(alpha: 0.15),
        height: 1,
      );

  Widget _detailSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kAccent.withValues(alpha: 0.9),
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _detailSubHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.65),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _detailPara(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.65,
          ),
        ),
      );

  Widget _detailDivider() => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Divider(
          color: MyWalkColor.golden.withValues(alpha: 0.12),
          height: 1,
        ),
      );
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _IAmCard extends StatelessWidget {
  final _IAmSaying saying;
  final VoidCallback onTap;

  const _IAmCard({required this.saying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: MyWalkColor.golden.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Image.asset(
                  saying.imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, e, s) => Container(
                    color: _kAccent.withValues(alpha: 0.08),
                    child: Center(
                      child: Icon(Icons.auto_awesome,
                          size: 32, color: _kAccent.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                color: MyWalkColor.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I am\u2026',
                      style: TextStyle(
                        fontSize: 9,
                        color: _kAccent.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      saying.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      saying.reference,
                      style: TextStyle(
                        fontSize: 10,
                        color: _kAccent.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Works Cited Expansion ────────────────────────────────────────────────────

class _IAmWorksCitedExpansion extends StatelessWidget {
  const _IAmWorksCitedExpansion();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          title: const Text(
            'Works Cited in the Module',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
            ),
          ),
          iconColor: MyWalkColor.softGold,
          collapsedIconColor: MyWalkColor.softGold,
          children: [
            _entry('Barrett, C.\u00a0K. The Gospel According to St John. 2nd ed. London: SPCK, 1978.'),
            _entry('Bauckham, Richard. The Testimony of the Beloved Disciple. Grand Rapids: Baker Academic, 2007.'),
            _entry('Brown, Raymond E. The Gospel According to John. 2 vols. Anchor Bible 29\u201329A. Garden City: Doubleday, 1966\u201370.'),
            _entry('Bultmann, Rudolf. The Gospel of John: A Commentary. Trans. G.\u00a0R. Beasley-Murray. Oxford: Blackwell, 1971.'),
            _entry('Carson, D.\u00a0A. The Gospel According to John. PNTC. Grand Rapids: Eerdmans, 1991.'),
            _entry('Dodd, C.\u00a0H. The Interpretation of the Fourth Gospel. Cambridge: Cambridge University Press, 1953.'),
            _entry('Harner, Philip B. The \u2018I Am\u2019 of the Fourth Gospel. Philadelphia: Fortress, 1970.'),
            _entry('Keener, Craig S. The Gospel of John: A Commentary. 2 vols. Peabody: Hendrickson, 2003.'),
            _entry('Lincoln, Andrew T. The Gospel According to Saint John. BNTC. London: Continuum, 2005.'),
            _entry('Michaels, J.\u00a0Ramsey. The Gospel of John. NICNT. Grand Rapids: Eerdmans, 2010.'),
            _entry('Moloney, Francis J. The Gospel of John. Sacra Pagina 4. Collegeville: Liturgical Press, 1998.'),
            _entry('Schnackenburg, Rudolf. The Gospel According to St John. 3 vols. London: Burns & Oates, 1968\u201382.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _kAccent.withValues(alpha: 0.18), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A NOTE ON PRIMARY SOURCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.softGold.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ancient sources referenced in the commentary include: Exodus (the Burning Bush narrative), Deutero-Isaiah (Isa 40\u201355), Ezekiel (the Shepherd Discourse, ch.\u00a034), Psalms (23, 36, 80), the Mishnah (Sukkah tractate), Josephus (Jewish Antiquities; Jewish War), and Philo of Alexandria (On the Life of Moses; Allegorical Interpretation). Greek lexical references cite BDAG (Bauer, Danker, Arndt, and Gingrich, A Greek-English Lexicon of the New Testament, 3rd ed., 2000). The Greek New Testament is cited from the Nestle-Aland 28th edition / UBS 5th edition. Scripture quotations are from the World English Bible (WEB), a public-domain translation.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
            height: 1.55,
          ),
        ),
      );
}
