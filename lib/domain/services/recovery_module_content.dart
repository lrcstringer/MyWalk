/// All static copy, prompts, and UI strings for the Recovery Path modules.
/// Views consume this service — prompts are never hardcoded in widgets.
class RecoveryModuleContent {
  RecoveryModuleContent._();

  // ── Module metadata ──────────────────────────────────────────────────────

  static const List<ModuleMeta> modules = [
    ModuleMeta(
      number: 1,
      title: 'Know Your Pattern',
      subtitle: 'Build awareness, one day at a time.',
      icon: '🔍',
      phase: 1,
      isPremium: false,
    ),
    ModuleMeta(
      number: 2,
      title: 'Challenge Your Thinking',
      subtitle: 'Examine the thoughts that fuel the habit.',
      icon: '💡',
      phase: 2,
      isPremium: true,
    ),
    ModuleMeta(
      number: 3,
      title: 'Anchor to Your Values',
      subtitle: 'Let what matters most guide you.',
      icon: '⚓',
      phase: 1,
      isPremium: false,
    ),
    ModuleMeta(
      number: 4,
      title: 'Build Your Guardrails',
      subtitle: 'Remove triggers and create safety plans.',
      icon: '🛡',
      phase: 3,
      isPremium: true,
    ),
    ModuleMeta(
      number: 5,
      title: 'Navigate Lapses',
      subtitle: 'Get back up — every time.',
      icon: '🌱',
      phase: 4,
      isPremium: true,
    ),
  ];

  static ModuleMeta metaFor(int moduleNumber) =>
      modules.firstWhere((m) => m.number == moduleNumber);

  // ── Module 1 — Know Your Pattern ─────────────────────────────────────────

  /// Pool of 7 daily check-in prompts.
  /// Each session picks 2, seeded by the current date so they remain
  /// consistent throughout the day but rotate the next day.
  static const List<String> m1DailyPrompts = [
    'What triggered the urge today, or what kept it away?',
    'Rate your craving level right now (1–10). What do you notice in your body?',
    'What emotion is most present right now? Where do you feel it?',
    'What thought was playing on repeat today?',
    'What helped you stay on track today, even a little?',
    'What situation made your habit feel more tempting today?',
    'What does your body need right now — rest, movement, connection, or something else?',
  ];

  /// Returns the 2 prompts to show today, deterministic for the day.
  /// Uses two independent offsets that are coprime to the list length (7 is
  /// prime, so any offset 1–6 guarantees no collision between first and second).
  static List<String> dailyPromptsForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final n = m1DailyPrompts.length;
    final first = seed % n;
    // Offset of 4 is coprime to 7 — guarantees first != second for all seeds.
    final second = (seed + 4) % n;
    return [m1DailyPrompts[first], m1DailyPrompts[second]];
  }

  /// Weekly pattern-review prompts — unlocked after 7+ check-ins.
  static const List<String> m1WeeklyReviewPrompts = [
    'Looking at this week, what patterns do you notice in your triggers?',
    'Which coping strategy worked best this week? What made it effective?',
    'What changed this week — in stress, sleep, relationships, or routines?',
  ];

  static const String m1CheckInTitle = 'Daily Check-In';
  static const String m1CheckInHint =
      'Write freely — there\'s no wrong answer here.';
  static const String m1WeeklyReviewTitle = 'Weekly Pattern Review';
  static const String m1UnlockMessage =
      'You\'ve done 7 check-ins — your weekly Pattern Review is now unlocked.';

  // ── Module 3 — Anchor to Your Values ─────────────────────────────────────

  /// The 8 life domains used in the values inventory.
  static const List<String> m3ValuesDomains = [
    'Faith & Spiritual Life',
    'Family & Close Relationships',
    'Friendships & Community',
    'Health & Physical Wellbeing',
    'Work & Purpose',
    'Personal Growth & Learning',
    'Joy & Rest',
    'Service & Contribution',
  ];

  static const String m3InventoryIntro =
      'For each area of life, rate how important it is to you and how well '
      'you\'re living it right now. This isn\'t about judgement — it\'s about '
      'seeing where the gaps are.';

  static const String m3ImportanceLabel = 'How important is this to you?';
  static const String m3AlignmentLabel = 'How well are you living it?';

  static const String m3InventoryCompleteMessage =
      'Your values map is saved. The gaps you see are not failures — '
      'they\'re the places where your walk can deepen.';

  /// Weekly compass prompts — shown once a week after inventory is done.
  static const List<String> m3WeeklyCompassPrompts = [
    'Which value felt most alive this week?',
    'Where did you fall short of your values? What got in the way?',
    'What one action this week could bring you closer to living your values?',
  ];

  static const String m3CompassTitle = 'Weekly Values Compass';
  static const String m3CompassHint =
      'Reflect honestly — this is between you and God.';

  // ── Phase labels ─────────────────────────────────────────────────────────

  static String phaseLabel(int phase) {
    switch (phase) {
      case 1:
        return 'Awareness';
      case 2:
        return 'Understanding';
      case 3:
        return 'Anchoring';
      case 4:
        return 'Resilience';
      default:
        return 'Phase $phase';
    }
  }

  // ── Affirmations shown after completing any session ──────────────────────

  static const List<String> sessionAffirmations = [
    '"He who began a good work in you will carry it on to completion." — Phil 1:6',
    'Every honest reflection is an act of courage.',
    'Progress isn\'t always visible — but it\'s always real.',
    '"I can do all this through him who gives me strength." — Phil 4:13',
    'You showed up today. That matters.',
    'Growth happens one honest moment at a time.',
    '"Come to me, all you who are weary and burdened, and I will give you rest." — Matt 11:28',
  ];

  /// Returns a deterministic affirmation for today.
  static String affirmationForDate(DateTime date) {
    final idx =
        (date.year * 10000 + date.month * 100 + date.day) %
            sessionAffirmations.length;
    return sessionAffirmations[idx];
  }

  // ── Recovery Path home screen copy ──────────────────────────────────────

  static const String homeBeginTitle = 'Start Your Freedom Journey';
  static const String homeBeginBody =
      'A structured, private programme to help you understand your patterns, '
      'anchor to what matters, and walk in lasting freedom.';
  static const String homeBeginButton = 'Begin my Freedom Journey';

  static const String lapseEntryLabel = 'Record a setback';

  // ── Module 2 — Challenge Your Thinking ──────────────────────────────────

  /// 5-step thought examination (CBT Socratic questioning).
  static const List<String> m2ThoughtExaminationPrompts = [
    'What thought or belief was playing in your mind before or during the urge?',
    'What evidence supports that thought? What evidence contradicts it?',
    'If a close friend had this thought, what would you tell them?',
    'What is a more balanced, truthful way to see this situation?',
    'Write your counter-response: the statement you can return to next time.',
  ];

  static const String m2Title = 'Challenge Your Thinking';
  static const String m2Hint = 'Think slowly — this is detective work, not self-criticism.';
  static const String m2CounterResponsePrompt =
      'Would you like to save your counter-response to your quick-access library?';
  static const String m2CounterResponseSaved = 'Saved to your library.';

  // ── Module 4 — Build Your Guardrails ────────────────────────────────────

  /// Environmental checklists keyed by the start of the habit name (lowercase).
  /// Falls back to [m4DefaultChecklist] when no match is found.
  static List<String> environmentalChecklistFor(String habitName) {
    final lower = habitName.toLowerCase();
    if (lower.contains('porn') || lower.contains('pornography') ||
        lower.contains('lust') || lower.contains('adult')) {
      return [
        'Put your phone/device in a public room at night',
        'Install a content filter (Covenant Eyes, BlockSite, etc.)',
        'Remove or log out of apps that trigger you',
        'Set up screen-time limits for high-risk hours',
        'Tell your partner which times / locations are highest risk',
      ];
    }
    if (lower.contains('gambl') || lower.contains('bet') || lower.contains('casino')) {
      return [
        'Block gambling websites and apps on all devices',
        'Remove saved payment methods from online platforms',
        'Avoid passing by casinos or betting shops on your usual routes',
        'Give a trusted person control of larger sums of money',
        'Identify the times and emotional states that trigger the urge',
      ];
    }
    if (lower.contains('alcohol') || lower.contains('drink') || lower.contains('beer') ||
        lower.contains('wine') || lower.contains('spirits')) {
      return [
        'Remove alcohol from your home',
        'Identify which social situations reliably lead to drinking',
        'Have a non-alcoholic drink in your hand at events',
        'Let one trusted person know about your commitment',
        'Plan an exit strategy for high-risk social events',
      ];
    }
    if (lower.contains('drug') || lower.contains('substance') || lower.contains('smok') ||
        lower.contains('vap') || lower.contains('nicotine')) {
      return [
        'Remove all substances and paraphernalia from your home',
        'Block contact with suppliers in your phone',
        'Identify which people or places reliably trigger use',
        'Have a substitute activity ready for craving moments',
        'Tell at least one person in your life about your commitment',
      ];
    }
    if (lower.contains('social media') || lower.contains('screen') || lower.contains('phone')) {
      return [
        'Delete or log out of the most triggering apps',
        'Set app time limits in device settings',
        'Move your phone charger out of the bedroom',
        'Designate phone-free times (meals, first hour of day)',
        'Replace the habitual scroll with a specific alternative',
      ];
    }
    return m4DefaultChecklist;
  }

  static const List<String> m4DefaultChecklist = [
    'Identify the three situations most likely to trigger the habit',
    'Make a physical or digital change to reduce access',
    'Identify who in your life knows about this commitment',
    'Plan what you will do in the first 5 minutes of an urge',
    'Remove or reduce any environmental cue associated with the habit',
  ];

  static const String m4ChecklistTitle = 'Environmental Guardrails';
  static const String m4ChecklistBody =
      'Check off the items you\'ve done or are actively doing. '
      'Complete at least 2 to mark this section as done.';

  // HRS plan template labels
  static const String m4HrsPlanTitle = 'High-Risk Situation Plans';
  static const String m4HrsPlanSubtitle =
      'Plan for up to 5 situations you know are high risk. '
      'The more specific, the more useful.';
  static const String m4SituationLabel = 'Describe the situation';
  static const String m4EarlyWarningsLabel = 'What are the early warning signs?';
  static const String m4FirstResponseLabel = 'What will you do first?';
  static const String m4ContactNameLabel = 'Who will you call?';

  // Urge surfing prompts
  static const List<String> m4UrgeSurfingPrompts = [
    'Close your eyes. Notice where the urge lives in your body — chest, stomach, throat? Describe what you feel physically.',
    'Urges are waves. They peak and then subside — usually within 20 minutes. What is the intensity right now, 1–10?',
    'You don\'t have to act on this wave. Just ride it. What do you notice as you sit with the urge without giving in?',
  ];

  static const String m4UrgeSurfingTitle = 'Urge Surfing';
  static const String m4UrgeSurfingHint =
      'Describe what you\'re experiencing in your body and mind.';

  // ── Module 5 — Navigate Lapses ───────────────────────────────────────────

  /// 4-prompt recovery letter flow.
  static const List<String> m5RecoveryLetterPrompts = [
    'What do you most want your future self to know about this struggle — the real, honest version?',
    'What is still true about who you are, despite this habit? What have you not lost?',
    'What has kept you going? What moment, verse, or person comes to mind?',
    'What one thing do you want your future self to do the next time the urge hits?',
  ];

  static const String m5RecoveryLetterTitle = 'Your Recovery Letter';
  static const String m5RecoveryLetterIntro =
      'This letter is from you to you — to be read the next time you\'re struggling. '
      'Write honestly. No one else will see this.';
  static const String m5RecoveryLetterPreviewTitle = 'Review your letter';
  static const String m5RecoveryLetterPreviewBody =
      'This is how your answers come together. Edit if you wish, then save.';
  static const String m5LetterSavedMessage =
      'Your letter is saved. It will be shown to you during the lapse recording flow.';

  /// Builds the stitched letter from 4 answers.
  static String stitchRecoveryLetter(List<String> answers) {
    assert(answers.length == 4);
    return 'What I want you to know:\n${answers[0]}\n\n'
        'What is still true:\n${answers[1]}\n\n'
        'Come back to:\n${answers[2]}\n\n'
        'Your next step:\n${answers[3]}';
  }

  /// 4-prompt quarterly maintenance review.
  static const List<String> m5QuarterlyReviewPrompts = [
    'Looking back over the past 90 days — what has changed in you?',
    'Where have you been most vulnerable? What patterns have you noticed?',
    'What has your faith shown you through this season?',
    'What is one specific thing you want to change or strengthen in the next 90 days?',
  ];

  static const String m5QuarterlyReviewTitle = 'Quarterly Maintenance Review';
  static const String m5QuarterlyReviewHint =
      'Be honest about both the gains and the losses.';

  // ── Lapse flow (3 steps) ─────────────────────────────────────────────────

  static const String lapseFlowAppBarTitle = 'Getting back up';
  static const String lapseSupportMessage =
      'A setback is not the end of your story. '
      'It\'s a moment that can teach you more than ten good days. '
      'Take a breath. You\'re still here. Let\'s look at what happened.';

  static const String lapseFallbackLetter =
      '"My grace is sufficient for you, for my power is made perfect in weakness." '
      '— 2 Cor 12:9\n\n'
      'You are still here. The fact that you opened this app tells you something '
      'about who you are. Come back to your why. This is not your final chapter.';

  static const String lapseStep1Prompt =
      'Take a moment before we look at what happened. '
      'What do you need to hear right now?';

  static const String lapseStep2Title = 'What happened?';
  static const String lapseStep2Body =
      'Walk through the moment honestly — no self-condemnation, just understanding.';
  static const List<String> lapseStep2SubPrompts = [
    'What was going on in the hours before?',
    'What thought or feeling pushed you over the edge?',
    'What could you do differently next time at that exact moment?',
  ];

  static const String lapseStep3Title = 'Back on the path';
  static const String lapseStep3Prompt =
      'You\'re not starting over — you\'re continuing. '
      'What is one thing you will do in the next hour to re-anchor yourself?';
  static const String lapseStep3ValuePrefix = 'Your anchor value: ';
  static const String lapseCompletionMessage =
      'You did the hard thing — you faced it honestly. '
      'That\'s what recovery looks like.';
}

class ModuleMeta {
  final int number;
  final String title;
  final String subtitle;
  final String icon;
  final int phase; // minimum phase required to unlock
  final bool isPremium;

  const ModuleMeta({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.phase,
    required this.isPremium,
  });
}
