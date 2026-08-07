import '../entities/recovery_session.dart';

class CueRubric {
  final List<String> primaryCues;
  final List<DiscoveryQuestion> questions;
  final List<String> environmentalSuggestions;

  const CueRubric({
    required this.primaryCues,
    required this.questions,
    required this.environmentalSuggestions,
  });
}

class DiscoveryQuestion {
  final String key;
  final String questionText;
  final String resultingCueText;
  final List<String> keywords;

  const DiscoveryQuestion({
    required this.key,
    required this.questionText,
    required this.resultingCueText,
    required this.keywords,
  });
}

/// Pure static service — no constructor, no state.
/// Maps habit names to rubrics and provides discovery questions + environmental
/// suggestions for the Cue Hierarchy exercise.
class CueRubricService {
  CueRubricService._();

  // ── Habit type resolution ────────────────────────────────────────────────

  /// Maps a free-text habit name to one of 14 type keys, or 'generic'.
  /// Evaluated in priority order — combined check before individual checks.
  static String habitTypeFrom(String habitName) {
    final n = habitName.toLowerCase();
    if ((n.contains('porn') || n.contains('pornography')) && n.contains('masturbat')) {
      return 'pornMasturbation';
    }
    if (n.contains('porn') || n.contains('pornography') ||
        n.contains('lust') || n.contains('adult content')) {
      return 'pornography';
    }
    if (n.contains('masturbat')) return 'masturbation';
    if (n.contains('alcohol') || n.contains('drink') || n.contains('beer') ||
        n.contains('wine') || n.contains('spirits') || n.contains('liquor')) {
      return 'alcohol';
    }
    if (n.contains('gambl') || n.contains('betting') || n.contains('casino') ||
        n.contains('poker') || n.contains('lottery')) {
      return 'gambling';
    }
    if (n.contains('spend') || n.contains('compulsive buy') ||
        n.contains('online shop') || n.contains('impulse buy')) {
      return 'compulsiveSpending';
    }
    if (n.contains('binge eat') || n.contains('disordered eat') || n.contains('bulimi') ||
        n.contains('anorexi') || n.contains('eating disorder') || n.contains('food addict')) {
      return 'disorderedEating';
    }
    // Doom scrolling before social media (more specific keyword set).
    if (n.contains('doom scroll') || n.contains('doomscroll') || n.contains('news addict')) {
      return 'doomScrolling';
    }
    if (n.contains('social media') || n.contains('instagram') || n.contains('facebook') ||
        n.contains('twitter') || n.contains('tiktok') || n.contains('youtube') ||
        n.contains('scroll') || n.contains('screen time') || n.contains('binge watch') ||
        n.contains('phone addict') || n.contains('streaming')) {
      return 'socialMedia';
    }
    if (n.contains('procrastinat')) return 'procrastination';
    if (n.contains('smok') || n.contains('nicotine') || n.contains('cigarette') ||
        n.contains('vap') || n.contains('tobacco')) {
      return 'smoking';
    }
    if (n.contains('gossip')) return 'gossip';
    if (n.contains('self-talk') || n.contains('self talk') || n.contains('self-critic') ||
        n.contains('inner critic') || n.contains('negative thought') ||
        n.contains('self-hate') || n.contains('self loath') ||
        n.contains('rage') || n.contains('anger outburst')) {
      return 'negativeSelfTalk';
    }
    if (n.contains('overwork') || n.contains('workaholic') || n.contains('work addict')) {
      return 'overworking';
    }
    // Fuzzy fallbacks per design doc.
    if (n.contains('shopping') || n.contains('online shopping')) return 'compulsiveSpending';
    if (n.contains('eat') || n.contains('food')) return 'disorderedEating';
    if (n.contains('anger') || n.contains('rage')) return 'negativeSelfTalk';
    return 'generic';
  }

  // ── Public API ───────────────────────────────────────────────────────────

  static CueRubric rubricFor(String habitType) =>
      _rubrics[habitType] ?? _rubrics['generic']!;

  /// Returns up to 3 discovery questions whose keywords do NOT appear in
  /// any existing log's responseText (case-insensitive substring match).
  static List<DiscoveryQuestion> discoveryQuestionsFor(
    String habitType,
    List<RecoverySession> existingLogs,
  ) {
    final combined =
        existingLogs.map((s) => s.responseText).join(' ').toLowerCase();
    return rubricFor(habitType)
        .questions
        .where((q) =>
            !q.keywords.any((kw) => combined.contains(kw.toLowerCase())))
        .take(3)
        .toList();
  }

  /// Returns the resultingCueText for the given discovery question key.
  static String cueTextFromDiscovery(String habitType, String questionKey) {
    return rubricFor(habitType)
        .questions
        .firstWhere(
          (q) => q.key == questionKey,
          orElse: () => const DiscoveryQuestion(
            key: '',
            questionText: '',
            resultingCueText: '',
            keywords: [],
          ),
        )
        .resultingCueText;
  }

  /// Returns habit-specific environmental change suggestions.
  static List<String> environmentalSuggestionsFor(
          String habitType, String cueText) =>
      rubricFor(habitType).environmentalSuggestions;

  // ── Rubric index ─────────────────────────────────────────────────────────

  static const Map<String, CueRubric> _rubrics = {
    'pornography': _pornography,
    'masturbation': _masturbation,
    'pornMasturbation': _pornMasturbation,
    'alcohol': _alcohol,
    'compulsiveSpending': _compulsiveSpending,
    'disorderedEating': _disorderedEating,
    'gambling': _gambling,
    'socialMedia': _socialMedia,
    'procrastination': _procrastination,
    'smoking': _smoking,
    'doomScrolling': _doomScrolling,
    'gossip': _gossip,
    'negativeSelfTalk': _negativeSelfTalk,
    'overworking': _overworking,
    'generic': _generic,
  };

  // ── 1. Pornography ───────────────────────────────────────────────────────

  static const _pornography = CueRubric(
    primaryCues: [
      "Loneliness or feeling disconnected from others",
      "Stress, anxiety, or emotional flatness",
      "Being alone with a device — especially at night",
      "After conflict or disconnection with a partner",
      "Boredom without stimulation",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'lonely_stressed',
        questionText:
            "Research suggests that feeling lonely, stressed, or anxious is one of the most common triggers for this pattern. Does that ring true for you?",
        resultingCueText: "When feeling lonely, stressed, or anxious",
        keywords: ['lonely', 'stress', 'anxious', 'anxiety', 'disconnected'],
      ),
      DiscoveryQuestion(
        key: 'alone_device',
        questionText:
            "Does being alone — especially with a device nearby — tend to be when it happens?",
        resultingCueText: "Alone with a device, especially at night",
        keywords: ['alone', 'device', 'phone', 'private', 'solitude'],
      ),
      DiscoveryQuestion(
        key: 'late_night',
        questionText:
            "Does it tend to happen late at night, or at a particular predictable time of day?",
        resultingCueText: "Late at night or a specific predictable time of day",
        keywords: ['night', 'evening', 'late', 'time of day', 'predictable'],
      ),
      DiscoveryQuestion(
        key: 'after_conflict',
        questionText:
            "Does it tend to follow conflict or emotional disconnection with someone close to you?",
        resultingCueText: "After conflict or disconnection with someone close",
        keywords: ['conflict', 'argue', 'argument', 'disconnect', 'fight', 'tension'],
      ),
    ],
    environmentalSuggestions: [
      "Put your phone or device in a different room at night",
      "Enable a content filter on all your devices (e.g. Covenant Eyes, Bark)",
      "Log out of all triggering platforms after each use",
      "Set screen time limits for your highest-risk hours",
      "Move your phone charger out of the bedroom",
    ],
  );

  // ── 2. Masturbation ──────────────────────────────────────────────────────

  static const _masturbation = CueRubric(
    primaryCues: [
      "Specific habitual times of day — bedtime, morning, or breaks",
      "Physical tension or restlessness in the body",
      "Loneliness or emotional low",
      "Being alone with privacy and solitude",
      "Boredom without stimulation",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'specific_time',
        questionText:
            "Does it tend to happen at a specific time of day — first thing in the morning, at bedtime, or at another predictable time?",
        resultingCueText: "At a specific predictable time of day",
        keywords: ['morning', 'night', 'bedtime', 'time', 'routine', 'specific time'],
      ),
      DiscoveryQuestion(
        key: 'tension_restless',
        questionText:
            "Does it happen when you are physically tense or restless — a body sensation rather than just a mood?",
        resultingCueText: "When physically tense or restless",
        keywords: ['tension', 'restless', 'physical', 'body', 'tense', 'sensation'],
      ),
      DiscoveryQuestion(
        key: 'linked_to_porn',
        questionText:
            "Is it usually connected to viewing pornography, or does it happen independently of it?",
        resultingCueText: "Often connected to viewing pornography first",
        keywords: ['porn', 'pornography', 'video', 'content', 'image'],
      ),
      DiscoveryQuestion(
        key: 'alone_low',
        questionText:
            "Does it tend to happen when you are alone and feeling emotionally low, bored, or flat?",
        resultingCueText: "When alone and emotionally low or bored",
        keywords: ['alone', 'lonely', 'low', 'sad', 'bored', 'flat', 'empty'],
      ),
    ],
    environmentalSuggestions: [
      "Move your phone out of the bathroom and bedroom at night",
      "Identify your 1–2 highest-risk times of day and plan a specific alternative activity",
      "Keep a consistent sleep routine — irregular hours increase vulnerability",
      "Tell a trusted person about this commitment",
      "Keep your bedroom door open when alone at home",
    ],
  );

  // ── 3. Pornography & Masturbation (combined) ─────────────────────────────

  static const _pornMasturbation = CueRubric(
    primaryCues: [
      "Loneliness, stress, or feeling emotionally flat",
      "Being alone with a device at night",
      "Visual content as the entry point",
      "Shame or guilt after an episode feeding the next one",
      "After conflict or disconnection with a partner",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'start_visual',
        questionText:
            "Does the urge typically start with seeking visual content, or does it begin with a feeling in your body first?",
        resultingCueText: "Usually starts by seeking visual content",
        keywords: ['visual', 'video', 'content', 'seeking', 'search', 'image'],
      ),
      DiscoveryQuestion(
        key: 'shame_cycle',
        questionText:
            "Does shame or guilt after an episode sometimes feel like it leads directly into the next one?",
        resultingCueText: "Shame or guilt after an episode can trigger the next",
        keywords: ['shame', 'guilt', 'failure', 'worthless', 'broken', 'disgust'],
      ),
      DiscoveryQuestion(
        key: 'alone_device_night',
        questionText:
            "Does being alone with a device — especially at night — tend to be when the cycle begins?",
        resultingCueText: "Alone with a device at night",
        keywords: ['alone', 'device', 'night', 'private', 'bedroom'],
      ),
      DiscoveryQuestion(
        key: 'emotional_low',
        questionText:
            "Does it tend to happen when you are feeling lonely, stressed, anxious, or emotionally flat?",
        resultingCueText: "When feeling lonely, stressed, or emotionally flat",
        keywords: ['lonely', 'stress', 'anxious', 'flat', 'empty', 'disconnected'],
      ),
    ],
    environmentalSuggestions: [
      "Put your device in a different room at night",
      "Enable a content filter on all devices",
      "Keep your bedroom phone-free",
      "Log out of all triggering platforms at the end of each day",
      "Plan a specific alternative activity for your highest-risk time",
    ],
  );

  // ── 4. Alcohol ───────────────────────────────────────────────────────────

  static const _alcohol = CueRubric(
    primaryCues: [
      "Social situations — meals, gatherings, celebrations",
      "Stress or anxiety — drinking to wind down",
      "Others around you drinking",
      "After work in the evening",
      "Celebration or commiseration — whether things go well or badly",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'social',
        questionText:
            "Does it tend to happen in social situations — meals, gatherings, parties, or celebrations?",
        resultingCueText: "Social situations and gatherings",
        keywords: ['social', 'friend', 'party', 'meal', 'event', 'gather', 'celebrat'],
      ),
      DiscoveryQuestion(
        key: 'stress_wind_down',
        questionText:
            "Is it connected to stress or anxiety — does having a drink feel like winding down after a hard day?",
        resultingCueText: "After a stressful day — winding down",
        keywords: ['stress', 'wind down', 'relax', 'after work', 'unwind', 'hard day'],
      ),
      DiscoveryQuestion(
        key: 'others_drinking',
        questionText:
            "Does it tend to happen when people around you are drinking — even if you had not planned to?",
        resultingCueText: "When others around you are drinking",
        keywords: ['others', 'people drinking', 'offered', 'pressure', 'everyone'],
      ),
      DiscoveryQuestion(
        key: 'commiseration',
        questionText:
            "Does celebration or commiseration tend to be a reliable trigger — whether things go well or badly?",
        resultingCueText: "Celebrating success or commiserating difficulty",
        keywords: ['celebrat', 'commiserat', 'success', 'failure', 'bad day', 'good day'],
      ),
    ],
    environmentalSuggestions: [
      "Remove alcohol from your home",
      "Tell the people you socialise with most about your commitment",
      "Have a non-alcoholic alternative in your hand at events",
      "Plan an exit strategy for high-risk social situations before you go",
      "Identify the 2–3 situations where you are most at risk",
    ],
  );

  // ── 5. Compulsive Spending ───────────────────────────────────────────────

  static const _compulsiveSpending = CueRubric(
    primaryCues: [
      '"Just browsing" — no intention to buy',
      "Low mood, boredom, or restlessness",
      "Social comparison — seeing what others have",
      "Sale notifications or limited-time offers",
      "As a reward or treat after a difficult period",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'browsing',
        questionText:
            "Does it tend to start with just browsing — even without any intention to buy?",
        resultingCueText: '"Just browsing" without intention to buy',
        keywords: ['browse', 'browsing', 'just looking', 'window shop', 'just checking'],
      ),
      DiscoveryQuestion(
        key: 'low_mood_boredom',
        questionText:
            "Does it tend to happen when you are bored, in a low mood, or feeling restless?",
        resultingCueText: "When bored, in a low mood, or restless",
        keywords: ['bored', 'low mood', 'sad', 'restless', 'empty', 'flat'],
      ),
      DiscoveryQuestion(
        key: 'social_comparison',
        questionText:
            "Does seeing what others have — on social media or in person — tend to trigger the urge?",
        resultingCueText: "After seeing what others have — social comparison",
        keywords: ['others', 'social media', 'comparison', 'envy', 'they have', 'everyone'],
      ),
      DiscoveryQuestion(
        key: 'notifications',
        questionText:
            "Do sale notifications, limited-time offers, or discount alerts tend to pull you in?",
        resultingCueText: "Sale notifications or limited-time offers",
        keywords: ['notification', 'sale', 'offer', 'discount', 'limited', 'deal'],
      ),
    ],
    environmentalSuggestions: [
      "Delete shopping apps from your phone",
      "Remove saved payment methods from online accounts",
      "Unsubscribe from retail email lists and all sale notifications",
      "Introduce a 48-hour rule — wait before buying anything non-essential",
      "Give a trusted person visibility of larger purchases",
    ],
  );

  // ── 6. Disordered Eating ─────────────────────────────────────────────────

  static const _disorderedEating = CueRubric(
    primaryCues: [
      "Specific times of day — evenings, late night, or around mealtimes",
      "Negative emotional states — anxiety, boredom, loneliness, stress",
      "Social eating situations",
      "Specific foods being visible or available",
      "Body image-related distress on a difficult day",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'specific_times',
        questionText:
            "Does it tend to happen at particular times of day — around meals, in the evening, or late at night?",
        resultingCueText: "Specific times of day or around mealtimes",
        keywords: ['evening', 'night', 'meal', 'lunch', 'dinner', 'breakfast', 'time of day'],
      ),
      DiscoveryQuestion(
        key: 'emotional_eating',
        questionText:
            "Does it happen when you are feeling anxious, sad, bored, or stressed — food as a way to manage a feeling?",
        resultingCueText: "When anxious, sad, bored, or stressed",
        keywords: ['anxious', 'sad', 'bored', 'stress', 'emotion', 'feeling', 'mood'],
      ),
      DiscoveryQuestion(
        key: 'social_eating',
        questionText:
            "Are social eating situations — meals with others, restaurants, celebrations — particularly difficult?",
        resultingCueText: "Social eating situations and meals with others",
        keywords: ['social', 'restaurant', 'meal with', 'others', 'party', 'gather', 'family meal'],
      ),
      DiscoveryQuestion(
        key: 'body_image',
        questionText:
            "Does how you feel about your body on a given day affect the pattern?",
        resultingCueText: "Negative feelings about your body or appearance",
        keywords: ['body', 'weight', 'appearance', 'look', 'fat', 'thin', 'mirror'],
      ),
    ],
    environmentalSuggestions: [
      "Keep triggering foods out of easy reach or out of the house entirely",
      "Plan your meals for the week in advance to reduce in-the-moment decisions",
      "Eat at a table, not in front of a screen",
      "Identify the three foods or situations that are highest risk",
      "Consider telling one trusted person who can offer non-judgemental support",
    ],
  );

  // ── 7. Gambling ──────────────────────────────────────────────────────────

  static const _gambling = CueRubric(
    primaryCues: [
      'Financial pressure — "I need to win it back"',
      "Watching sport or sports media",
      "Boredom and excitement-seeking",
      "After a near-win or a loss — chasing",
      "Feeling invincible after a win",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'financial_stress',
        questionText:
            "Does financial pressure or money stress tend to trigger the urge — even when the logic says it would make things worse?",
        resultingCueText: "Under financial pressure or money stress",
        keywords: ['money', 'debt', 'financial', 'broke', 'bills', 'afford', 'cash'],
      ),
      DiscoveryQuestion(
        key: 'sport_media',
        questionText:
            "Does watching sport or sports coverage act as a trigger — even passively?",
        resultingCueText: "Watching sport or sports coverage",
        keywords: ['sport', 'football', 'match', 'game', 'race', 'odds', 'score'],
      ),
      DiscoveryQuestion(
        key: 'excitement_seeking',
        questionText:
            "Does the feeling of wanting excitement or a rush tend to come just before?",
        resultingCueText: "Seeking excitement or a rush",
        keywords: ['excite', 'rush', 'thrill', 'adrenaline', 'bored', 'boring'],
      ),
      DiscoveryQuestion(
        key: 'chasing',
        questionText:
            "Does a near-win or a loss tend to trigger further gambling — a feeling that you need to win it back?",
        resultingCueText: "After a near-win or a loss — chasing",
        keywords: ['near win', 'almost', 'chase', 'win back', 'make up', 'recover'],
      ),
    ],
    environmentalSuggestions: [
      "Block all gambling websites and apps on all your devices",
      "Remove saved payment methods from any gambling platforms",
      "Add a self-exclusion to any betting accounts you use",
      "Avoid watching live sport alone during high-risk evenings",
      "Give a trusted person oversight of larger sums during high-risk periods",
    ],
  );

  // ── 8. Social Media / Smartphone ────────────────────────────────────────

  static const _socialMedia = CueRubric(
    primaryCues: [
      "Every quiet or transitional moment — automatic reflex",
      "A notification arriving — immediate pull",
      "Avoiding something uncomfortable — a task, conversation, or decision",
      "First thing on waking or last thing before sleep",
      "Feeling low or seeking connection",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'every_quiet_moment',
        questionText:
            "Does it happen in every quiet moment — while waiting, during transitions, on breaks — almost automatically?",
        resultingCueText: "Every quiet or transitional moment — an automatic reflex",
        keywords: ['wait', 'queue', 'bored', 'transition', 'break', 'automatic', 'habit'],
      ),
      DiscoveryQuestion(
        key: 'notification',
        questionText:
            "Does a notification arriving tend to pull you in, even when you were doing something else?",
        resultingCueText: "A notification arriving — an immediate pull",
        keywords: ['notif', 'ping', 'alert', 'message', 'update', 'buzz'],
      ),
      DiscoveryQuestion(
        key: 'avoidance',
        questionText:
            "Do you notice it happening when you are avoiding something else — a task, a conversation, a decision?",
        resultingCueText: "Avoiding something uncomfortable — a task or decision",
        keywords: ['avoid', 'procrastinat', 'task', 'instead', 'something else'],
      ),
      DiscoveryQuestion(
        key: 'wakeup_bedtime',
        questionText:
            "Does waking up or going to bed tend to be when it starts?",
        resultingCueText: "First thing on waking or last thing before sleep",
        keywords: ['wake', 'morning', 'bedtime', 'before sleep', 'alarm'],
      ),
    ],
    environmentalSuggestions: [
      "Delete the most triggering apps (you can still use the web version as a friction barrier)",
      "Turn off all social media notifications on your phone",
      "Move your phone charger out of the bedroom",
      "Set app time limits in your phone's screen time settings",
      "Designate phone-free times — meals, first hour of the day, last hour before bed",
    ],
  );

  // ── 9. Procrastination ───────────────────────────────────────────────────

  static const _procrastination = CueRubric(
    primaryCues: [
      "Specific types of tasks that trigger avoidance",
      "Overwhelming or unclear tasks — not knowing where to start",
      "Perfectionism — waiting for the right conditions",
      "Already feeling anxious or in a low mood",
      "Tasks involving risk of judgement or failure",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'specific_tasks',
        questionText:
            "Are there specific types of tasks that reliably trigger avoidance — certain projects, certain kinds of work?",
        resultingCueText: "Specific types of tasks that trigger avoidance",
        keywords: ['type of work', 'specific project', 'that kind', 'that type', 'particular task'],
      ),
      DiscoveryQuestion(
        key: 'overwhelming',
        questionText:
            "Does it happen when a task feels overwhelming or you are unsure where to start?",
        resultingCueText: "When a task feels overwhelming or unclear where to start",
        keywords: ['overwhelm', 'unsure', 'where to start', 'too much', 'confus', 'beginning'],
      ),
      DiscoveryQuestion(
        key: 'perfectionism',
        questionText:
            "Does perfectionism play a role — a sense that conditions need to be just right before you can begin?",
        resultingCueText: "Perfectionism — waiting for the right conditions",
        keywords: ['perfect', 'right conditions', 'ready', 'just right', 'good enough'],
      ),
      DiscoveryQuestion(
        key: 'anxiety_low',
        questionText:
            "Does it happen when you are already feeling anxious or low — making the task feel even more impossible?",
        resultingCueText: "When already anxious or in a low mood",
        keywords: ['anxious', 'low mood', 'worried', 'afraid', 'anxiety already'],
      ),
    ],
    environmentalSuggestions: [
      "Close all unnecessary browser tabs and apps before starting work",
      "Use a physical timer — commit to 25 minutes of work before any break",
      "Write out your specific first step the night before, not the whole task",
      "Work somewhere different when avoidance is strongest — a library or café",
      "Remove the easiest escape routes from your immediate work environment",
    ],
  );

  // ── 10. Smoking ──────────────────────────────────────────────────────────

  static const _smoking = CueRubric(
    primaryCues: [
      "After meals, with coffee, or at other habitual times",
      "Under stress — cigarette as the pressure release",
      "Being around other smokers",
      "Transition moments — finishing work, breaks",
      "Alcohol",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'habitual_times',
        questionText:
            "Does it tend to happen at specific times of day — after meals, with coffee, first thing in the morning, or during breaks?",
        resultingCueText: "Specific habitual times — after meals, with coffee, at breaks",
        keywords: ['after meal', 'coffee', 'morning', 'break', 'routine', 'after lunch'],
      ),
      DiscoveryQuestion(
        key: 'stress',
        questionText:
            "Is stress the main trigger — does smoking feel like the only way to manage pressure in the moment?",
        resultingCueText: "Under stress — smoking as the pressure valve",
        keywords: ['stress', 'pressure', 'tense', 'anxious', 'overwhelm'],
      ),
      DiscoveryQuestion(
        key: 'social_smokers',
        questionText:
            "Does being around other smokers, or the smell of cigarettes, act as a reliable trigger?",
        resultingCueText: "Being around other smokers or the smell of cigarettes",
        keywords: ['others smoking', 'friend smok', 'smell', 'break room', 'colleague smok'],
      ),
      DiscoveryQuestion(
        key: 'alcohol',
        questionText:
            "Does alcohol tend to dramatically increase the urge — making it much harder to refuse?",
        resultingCueText: "Alcohol — dramatically increases the urge to smoke",
        keywords: ['alcohol', 'drink', 'beer', 'wine', 'pub', 'bar', 'drinking'],
      ),
    ],
    environmentalSuggestions: [
      "Remove all cigarettes and lighters from your home, car, and workplace",
      "Tell your main social contacts about your commitment",
      "Plan a specific replacement activity for each of your 2–3 highest-risk situations",
      "Have a substitute ready for craving moments — gum, water, something for your hands",
      "Avoid alcohol in the early weeks if it significantly increases the urge",
    ],
  );

  // ── 11. Doom Scrolling ───────────────────────────────────────────────────

  static const _doomScrolling = CueRubric(
    primaryCues: [
      "Anxiety and intolerance of uncertainty",
      "Late at night — unable to sleep, reaching for the phone",
      "During stressful news events or personal crises",
      '"Just checking one thing" — losing control of it',
      "A need to feel informed or in control",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'anxiety_uncertainty',
        questionText:
            "Does it tend to happen when you are feeling anxious or worried — as if more information will help you feel in control?",
        resultingCueText: "When anxious — seeking information to feel in control",
        keywords: ['anxious', 'worry', 'uncertain', 'inform', 'control', 'know what'],
      ),
      DiscoveryQuestion(
        key: 'late_night',
        questionText:
            "Does it tend to happen late at night when you are unable to sleep?",
        resultingCueText: "Late at night — unable to sleep, reaching for the phone",
        keywords: ['night', 'sleep', 'insomnia', 'late', 'awake in bed', 'before sleep'],
      ),
      DiscoveryQuestion(
        key: 'stressful_event',
        questionText:
            "Does a stressful news event or personal crisis make the pattern significantly worse?",
        resultingCueText: "During stressful news events or personal crises",
        keywords: ['news event', 'crisis', 'global', 'situation', 'happening in the world'],
      ),
      DiscoveryQuestion(
        key: 'one_thing',
        questionText:
            "Do you notice it starting even when you only intended to check one thing — and then not being able to stop?",
        resultingCueText: "Started intending to check one thing — couldn't stop",
        keywords: ['one thing', 'quick check', 'just a moment', 'brief look'],
      ),
    ],
    environmentalSuggestions: [
      "Remove news apps from your phone — use a desktop browser instead to add friction",
      "Set a specific news reading window — one or two times per day, not continuous",
      "Turn off all news and breaking-story alerts on your phone",
      "Move your phone charger out of the bedroom",
      "Replace the automatic news-reach with a specific alternative",
    ],
  );

  // ── 12. Gossip ───────────────────────────────────────────────────────────

  static const _gossip = CueRubric(
    primaryCues: [
      "Specific people or group settings",
      "Feeling insecure, anxious, or left out",
      "Resentment or frustration with a specific person",
      "As social bonding — sharing information as connection",
      "Boredom or when conversation runs dry",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'certain_people',
        questionText:
            "Does it tend to happen with certain people or in particular group settings — specific relationships or situations?",
        resultingCueText: "With certain people or in specific group settings",
        keywords: ['certain person', 'specific person', 'that group', 'those people', 'particular friend'],
      ),
      DiscoveryQuestion(
        key: 'insecure',
        questionText:
            "Does it happen when you are feeling insecure, anxious, or as if you are on the outside of something?",
        resultingCueText: "When feeling insecure, anxious, or left out",
        keywords: ['insecure', 'anxious', 'left out', 'excluded', 'outside', 'belong'],
      ),
      DiscoveryQuestion(
        key: 'resentment',
        questionText:
            "Does resentment or frustration with a specific person tend to come just before?",
        resultingCueText: "Resentment or frustration with a specific person",
        keywords: ['resent', 'frustrat', 'angry at', 'unfair', 'annoyed', 'bitter'],
      ),
      DiscoveryQuestion(
        key: 'bonding',
        questionText:
            "Does it feel like a way of bonding — sharing information as a form of connection or intimacy?",
        resultingCueText: "As a way of bonding — sharing as connection",
        keywords: ['bond', 'connect', 'intimacy', 'bring us closer', 'common ground'],
      ),
    ],
    environmentalSuggestions: [
      "Identify the 2–3 situations where gossip is most likely and make a specific plan for each",
      "Have a prepared redirect when the conversation starts to go that direction",
      "When resentment is building, find a healthy outlet for it before it comes out sideways",
      "Be honest about which relationships tend to fuel the pattern",
      "After a difficult conversation, spend 2 minutes reflecting on what you could have done differently",
    ],
  );

  // ── 13. Negative Self-Talk ───────────────────────────────────────────────

  static const _negativeSelfTalk = CueRubric(
    primaryCues: [
      "After a failure, mistake, or falling short of your own standard",
      "Receiving criticism — even mild or well-intentioned",
      "Comparing yourself to someone else",
      "When tired, stressed, or overwhelmed — a lower threshold",
      "Competitive or performance situations",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'failure_mistake',
        questionText:
            "Does it tend to happen after something goes wrong, doesn't meet your standard, or you make a mistake?",
        resultingCueText: "After a failure, mistake, or falling short of your standard",
        keywords: ['went wrong', 'mistake', 'fail', 'standard', 'error', 'not good enough'],
      ),
      DiscoveryQuestion(
        key: 'criticism',
        questionText:
            "Does receiving criticism — even mild, even well-intentioned — tend to trigger the inner critic?",
        resultingCueText: "After receiving criticism — even mild",
        keywords: ['criticism', 'criticis', 'feedback', 'told me', 'commented on', 'pointed out'],
      ),
      DiscoveryQuestion(
        key: 'comparison',
        questionText:
            "Does comparing yourself to someone else tend to set it off — seeing their success, ability, or appearance?",
        resultingCueText: "After comparing yourself to someone else",
        keywords: ['compare', 'comparison', 'their success', 'better than me', 'less than', 'envy'],
      ),
      DiscoveryQuestion(
        key: 'tired_stressed',
        questionText:
            "Does the inner critic get significantly worse when you are tired, stressed, or overwhelmed?",
        resultingCueText: "When tired, stressed, or overwhelmed — a lower threshold",
        keywords: ['tired', 'stress', 'exhausted', 'overwhelm', 'depleted', 'running on empty'],
      ),
    ],
    environmentalSuggestions: [
      "Notice which environments or relationships trigger the harshest inner voice — and plan for each",
      "Keep a simple running record when you catch the inner critic: what triggered it, what it said",
      "Identify one person who knows your inner critic well and can offer an honest outside perspective",
      "Reduce time on social media accounts that consistently trigger comparison",
      "When perfectionism is involved, name it: \"That's perfectionism, not a fair assessment.\"",
    ],
  );

  // ── 14. Overworking ──────────────────────────────────────────────────────

  static const _overworking = CueRubric(
    primaryCues: [
      "Anxiety when not working — stopping feels dangerous",
      "Rest or downtime triggering guilt",
      "Perfectionism — needing it to be exactly right before stopping",
      "Work as avoidance of home or relationship tension",
      "Anticipated heavy workload driving a compulsive early start",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'stopping_dangerous',
        questionText:
            "Does the urge to keep working come with a sense that stopping would be wrong, unsafe, or that something bad would happen?",
        resultingCueText: "Stopping feels dangerous — anxiety when not working",
        keywords: ['stop', 'stopping feels', 'unsafe', 'what if I stop', "can't stop"],
      ),
      DiscoveryQuestion(
        key: 'rest_discomfort',
        questionText:
            "Does rest or downtime feel uncomfortable — like you should be doing something?",
        resultingCueText: "Rest feels wrong — a persistent \"should be doing something\"",
        keywords: ['rest', 'relax', 'should be doing', 'guilt', 'idle', 'doing nothing'],
      ),
      DiscoveryQuestion(
        key: 'perfectionism',
        questionText:
            "Does perfectionism play a role — needing to keep going until it is exactly right before you can stop?",
        resultingCueText: "Perfectionism — needing it to be exactly right before stopping",
        keywords: ['perfect', 'exactly right', 'standard', 'good enough', 'until it'],
      ),
      DiscoveryQuestion(
        key: 'avoidance_home',
        questionText:
            "Is work sometimes a way to avoid something at home or in a relationship — easier to stay in the office?",
        resultingCueText: "Work as avoidance — easier than going home",
        keywords: ['avoid home', 'relationship tension', 'stay late', "don't want to go home", 'escape'],
      ),
    ],
    environmentalSuggestions: [
      "Set a firm finish time and make it visible — calendar block, alarm, commitment to someone",
      "Put your work phone or laptop in a different room after your finish time",
      "Plan something you genuinely want to do after work — not absence of work but presence of something",
      "Tell someone who will ask whether you stopped — an accountability question",
      "When perfectionism is extending the work, name it and set a 'good enough' threshold",
    ],
  );

  // ── Generic fallback ─────────────────────────────────────────────────────

  static const _generic = CueRubric(
    primaryCues: [
      "A specific time of day",
      "A particular emotional state",
      "A specific place or environment",
      "Certain social contexts or people",
      "A specific preceding activity",
      "Physical tiredness, hunger, or discomfort",
    ],
    questions: [
      DiscoveryQuestion(
        key: 'time_of_day',
        questionText:
            "Does it tend to happen at a particular time of day — morning, afternoon, evening, or night?",
        resultingCueText: "At a specific time of day",
        keywords: ['morning', 'afternoon', 'evening', 'night', 'time of day', 'specific time'],
      ),
      DiscoveryQuestion(
        key: 'emotional_state',
        questionText:
            "What are you usually feeling when the urge hits — stressed, bored, lonely, anxious, flat, or overwhelmed?",
        resultingCueText: "When in a particular emotional state",
        keywords: ['stressed', 'bored', 'lonely', 'anxious', 'flat', 'overwhelm', 'emotion'],
      ),
      DiscoveryQuestion(
        key: 'location',
        questionText:
            "Is there a particular place where it tends to happen — home, work, a specific room, while commuting?",
        resultingCueText: "In a particular place or environment",
        keywords: ['home', 'work', 'place', 'room', 'location', 'commut', 'office'],
      ),
      DiscoveryQuestion(
        key: 'social_context',
        questionText:
            "Are you usually alone, or does it tend to happen with certain people or in certain social situations?",
        resultingCueText: "In a specific social context — alone or with certain people",
        keywords: ['alone', 'people', 'social', 'others', 'together', 'with someone'],
      ),
      DiscoveryQuestion(
        key: 'preceding_activity',
        questionText:
            "Is there something you typically do just before — finishing work, a conversation, watching TV, or another activity?",
        resultingCueText: "After a specific preceding activity",
        keywords: ['after', 'finish', 'following', 'just did', 'right after'],
      ),
      DiscoveryQuestion(
        key: 'physical_state',
        questionText:
            "Does tiredness, hunger, or physical discomfort play a role?",
        resultingCueText: "When physically tired, hungry, or uncomfortable",
        keywords: ['tired', 'hungry', 'uncomfortable', 'pain', 'physical', 'exhausted'],
      ),
    ],
    environmentalSuggestions: [
      "Identify the single most reliable cue and make one concrete change to interrupt it",
      "Tell at least one person about your commitment",
      "Plan a specific alternative activity for your highest-risk moments",
      "Add friction between the cue and the behaviour — make it harder to reach",
      "Plan exactly what you will do in the first 5 minutes after the urge hits",
    ],
  );
}
