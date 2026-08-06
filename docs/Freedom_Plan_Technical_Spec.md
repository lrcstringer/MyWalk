# Freedom Plan — Technical Implementation Specification
## For Claude Code — MyWalk Flutter App

**Codebase location:** `C:\Users\lance\Documents\MyFlutterProjects\MyWalk`  
**Cross-reference:** `Freedom_Plan_Design_Decisions.md` (rationale) · `Freedom_Plan_Master_Timeline.md` (sequence)  
**Existing implementation reference:** `freedom_plan_journey.md` (current codebase state)

---

## HOW TO USE THIS DOCUMENT

This spec describes **what to build, what to change, and what to keep** in the existing codebase. It is organised into:

1. **Data model changes** — Firestore schema additions and modifications
2. **New session types** — additions to the existing session type enum
3. **Phase progression changes** — replacement of existing unlock logic
4. **Existing screens to modify** — what changes in files that already exist
5. **New screens to build** — files that do not yet exist
6. **Provider and repository changes** — new methods needed
7. **Habit card changes** — Today tab modifications
8. **Journal/Freedom Journey tab** — entirely new
9. **Notification changes** — what to remove and what to add
10. **Build sequence** — recommended order of implementation

**Critical rule:** Read each section fully before implementing. Many changes depend on others. The build sequence in §10 is the correct order.

---

## 1. DATA MODEL CHANGES

### 1a. `recovery_paths/{habitId}` — fields to ADD

The following fields do not exist in the current schema and must be added:

| New field | Type | Default | Purpose |
|---|---|---|---|
| `habitType` | String | `''` | Habit name normalised to rubric key — set on `startPath()`. Used for AI cue analysis. Values: `'pornography'`, `'masturbation'`, `'pornography_masturbation'`, `'alcohol'`, `'compulsive_spending'`, `'disordered_eating'`, `'gambling'`, `'social_media'`, `'procrastination'`, `'smoking'`, `'doom_scrolling'`, `'gossip'`, `'negative_self_talk'`, `'overworking'`, `'generic'` |
| `cueHierarchyDone` | bool | `false` | Set to `true` when Cue Hierarchy exercise is completed |
| `cueHierarchy` | List\<Map\> | `[]` | Each item: `{rank: int, cueText: String, isAiSuggested: bool}` |
| `environmentalChangesDone` | bool | `false` | Set to `true` when environmental restructuring is submitted |
| `hrsPlanDone` | bool | `false` | Set to `true` when HRS plans are saved (replaces no equivalent) |
| `urgeSurfingIntroSeen` | bool | `false` | Set to `true` when urge surfing intro screen is dismissed |
| `module5IntroSeen` | bool | `false` | Set to `true` when AVE education screen is dismissed |
| `lapseButtonAvailableFrom` | Timestamp | `startedAt` | Always = startedAt (lapse button available Day 1). Kept for future configurability. |
| `lastLifestyleAuditAt` | Timestamp? | `null` | Updated each time a lifestyle balance audit is saved |
| `quarterlyReviewDueDays` | List\<int\> | `[90, 180, 270, 360]` | Days on which quarterly review should surface |
| `thoughtExaminationDraftStep` | int | `0` | Current draft step for interrupted thought examination (0 = no draft) |
| `thoughtExaminationDraft` | Map? | `null` | Saved draft: `{step1: String, step2: String, step3a: String, step3b: String, step4: String, createdAt: Timestamp}` |
| `valuesInventoryDraftStep` | int | `0` | Current domain index for interrupted values inventory (0 = not started, 1–8 = in progress) |
| `valuesInventoryDraft` | List\<Map\> | `[]` | Saved per-domain draft entries |
| `cueHierarchyDraftStage` | int | `0` | Current stage for interrupted Cue Hierarchy (0 = not started, 1–5 = in progress) |
| `dailyCheckInEmotionalRating` | int? | `null` | Today's emotional rating from daily check-in (1–10). Reset to null at midnight. |
| `dailyCheckInOutcome` | String? | `null` | Today's outcome: `'slipped'`, `'urge_only'`, `'clear'`. Reset to null at midnight. |

### 1b. `recovery_paths/{habitId}` — fields to MODIFY

| Existing field | Current behaviour | New behaviour |
|---|---|---|
| `module3.valuesInventory` | `List<Map>` with `{domain, importance, alignment}` | **Extended to:** `{domain: String, importance: int, alignment: int, reflectionText: String, compassDirection: String}` where `compassDirection` is `'toward'`, `'neutral'`, or `'away'` |
| `module3.lastCompassAt` | `Timestamp?` | No change to type. Compass check now includes committed action text — store in sessions only. |
| `module4.hrsPlan` | `List<Map>` with `{situation, earlyWarnings, firstResponse, contactName}` | No type change. Each plan now also seeded from `cueHierarchy` items — implementation detail only. |

### 1c. `recovery_paths/{habitId}` — fields to REMOVE / SUPPRESS

| Field | Action | Reason |
|---|---|---|
| `m2NotifSent` | Keep in schema, stop using for new push notifications | Push notifications for module unlocks removed |
| `recoveryLetterDraft` | Keep — still used by lapse flow | No change |

### 1d. `recovery_paths/{habitId}/recovery_sessions/{sessionId}` — new session types

Add these to the valid `sessionType` enum (existing values kept):

| New sessionType | Module | When created |
|---|---|---|
| `m1BehaviourLog` | 1 | "Log a moment" submission (replaces using `m1DailyCheckIn` for detailed logs) |
| `m1DailyCheckIn` | 1 | Daily check-in (2-question lightweight check — **behaviour changed**, see §3) |
| `m1MidPointReflection` | 1 | Mid-point reflection at Day 8–9 (3 questions) |
| `m1CueHierarchy` | 1 | Cue Hierarchy completion — stores the ranked list |
| `m2ThoughtExamination` | 2 | Thought examination 5-step flow (existing type — **prompts changed**, see §5) |
| `m3WeeklyCompass` | 3 | Weekly compass check (existing type — **prompts changed**, see §5) |
| `m3ValuesInventory` | 3 | Values inventory (existing type — **data structure changed**, see §1b) |
| `m4EnvironmentalRestructuring` | 4 | Environmental restructuring submission |
| `m4LifestyleAudit` | 4 | Monthly lifestyle balance audit |
| `m5AveEducation` | 5 | AVE education acknowledgement (no text — just timestamp record) |
| `m5LapseResponse` | 5 | Full lapse response protocol (replaces `lapseRecord` for new lapse flow) |

**Keep existing:** `lapseRecord`, `m4UrgeSurfing`, `m5RecoveryLetter`, `m5QuarterlyReview`, `m1WeeklyReview`

### 1e. `lapseData` map — extended fields

The existing `lapseData` map on `lapseRecord`/`m5LapseResponse` sessions is extended:

| New field | Type | Purpose |
|---|---|---|
| `selfCompassionText` | String? | Screen 3 self-compassion response |
| `copingPlanGapText` | String? | What the user learned about their coping plan gap |
| `recommittedValue` | String? | Which value they chose to take the next step toward |
| `copingPlanUpdated` | bool | Whether user tapped "Update my coping plan" |

---

## 2. PHASE PROGRESSION — REPLACE EXISTING LOGIC

**File to modify:** `lib/domain/services/recovery_phase_calculator.dart`

### Current logic (REPLACE entirely)

```dart
// CURRENT — replace this
Phase 4: totalLapses > 0
Phase 3: dailyCheckInCount >= 7 AND valuesInventoryDone == true
Phase 2: dailyCheckInCount >= 7
Phase 1: default
```

### New logic

```dart
// NEW PHASE LOGIC
// Evaluated in priority order. Write result back to currentPhase on every session save.

RecoveryPhase calculate(RecoveryPath path) {
  final daysSinceStart = DateTime.now().difference(path.startedAt).inDays;
  
  // Phase 4 — Maintenance
  if (daysSinceStart >= 90 && path.module3.valuesInventoryDone) {
    return RecoveryPhase.maintenance; // phase 4
  }
  
  // Phase 3 — Sustained Practice
  if (daysSinceStart >= 30 || path.totalLapses > 0) {
    return RecoveryPhase.sustainedPractice; // phase 3
  }
  
  // Phase 2 — Going Deeper
  // Cue Hierarchy complete OR 14 days elapsed OR 14 check-ins
  if (path.cueHierarchyDone || 
      daysSinceStart >= 14 || 
      path.module1.dailyCheckInCount >= 14) {
    return RecoveryPhase.goingDeeper; // phase 2
  }
  
  // Phase 1 — Getting Started
  return RecoveryPhase.gettingStarted; // phase 1
}
```

### Module unlock rules (REPLACE)

```dart
// NEW MODULE UNLOCK LOGIC

bool isModuleUnlocked(RecoveryPath path, int moduleNumber) {
  switch (moduleNumber) {
    case 1: return true; // always unlocked
    case 2: return path.cueHierarchyDone || 
                   DateTime.now().difference(path.startedAt).inDays >= 28;
    case 3: return true; // always unlocked
    case 4: return path.cueHierarchyDone || 
                   DateTime.now().difference(path.startedAt).inDays >= 28;
    case 5: return DateTime.now().difference(path.startedAt).inDays >= 30 || 
                   path.totalLapses > 0;
    default: return false;
  }
}
```

### Phase labels (UPDATE)

```dart
// UPDATE phase labels in _ActiveBody and wherever phases are displayed
Phase 1: 'Getting Started'      // was 'Awareness'
Phase 2: 'Going Deeper'         // was 'Understanding'  
Phase 3: 'Sustained Practice'   // was 'Anchoring'
Phase 4: 'Maintenance'          // was 'Resilience'
```

---

## 3. DAILY CHECK-IN — REDESIGN

**Current:** `ModuleSessionScreen` with rotating text prompts, journal-style  
**New:** Lightweight 2-question check-in with structured data capture

### Remove
- The rotating prompt pool from Module 1 daily check-in
- The `m1WeeklyReview` trigger (weekly pattern review is now replaced by Cue Hierarchy at Day 14)

### New daily check-in flow

**File:** `lib/presentation/views/habits/daily_check_in_screen.dart` *(new file)*  
**Class:** `DailyCheckInScreen` (StatefulWidget)  
**Session type:** `m1DailyCheckIn`

**UI — two sequential questions:**

**Question 1:**
```
"How are you doing emotionally today?"
Slider: 1–10
Labels: 'Not great' ↔ 'Really well'
```

**Question 2:**
```
"Did you encounter your pattern today?"
Three tap-to-select options (styled as pill chips, single select):
  Option A: 'Yes, I slipped'         → outcome = 'slipped'
  Option B: 'I felt the urge but didn't act'  → outcome = 'urge_only'
  Option C: 'Clear day'              → outcome = 'clear'
```

**After selection:**

If `outcome == 'slipped'`:
- Show inline prompt: *"Do you want to log what happened?"*
- Two buttons: `'Yes, log it'` (opens `BehaviourLogScreen`) / `'Not now'`

If `outcome == 'urge_only'`:
- Show inline prompt: *"Do you want to examine the thought that came up?"*
- Two buttons: `'Yes, examine it'` (opens `ThoughtExaminationScreen`) / `'Not now'`

If `outcome == 'clear'`:
- Proceed directly to save.

**Save behaviour:**
1. Write `path.dailyCheckInEmotionalRating = rating` and `path.dailyCheckInOutcome = outcome`
2. Increment `path.module1.dailyCheckInCount`
3. Update `path.module1.lastCheckInAt`
4. Create `RecoverySession(sessionType: 'm1DailyCheckIn', moduleNumber: 1)`
5. Store `responseText` as JSON: `{"rating": 7, "outcome": "clear"}` (encrypted as normal)
6. Show `_AffirmationView` (reuse existing) then pop

**Note on high-stress detection:**
If `rating <= 3`, after saving, surface inline: *"It looks like it's been a difficult stretch. Stressful periods are when the plan matters most. Is your coping plan still working?"* with link to open `GuardrailsScreen` HRS Plans tab.

---

## 4. BEHAVIOUR LOG ("LOG A MOMENT") — NEW SCREEN

**File:** `lib/presentation/views/habits/behaviour_log_screen.dart` *(new file)*  
**Class:** `BehaviourLogScreen` (StatefulWidget)  
**Session type:** `m1BehaviourLog`  
**Entry point:** "Log a moment" button on habit card (see §7)

**4 sequential fields** (one per screen step, `ModuleSessionScreen`-style pagination):

```
Step 1: "Where were you? What time of day was it?"
        Hint: 'e.g. Home alone, 11pm / Office, after a difficult meeting'
        Text field (free text)

Step 2: "What were you doing immediately before?"
        Hint: 'e.g. Browsing my phone / Just got home from work / Couldn't sleep'
        Text field (free text)

Step 3: "What were you feeling emotionally?"
        Part A: Text field — "Name it specifically"
                Hint: 'e.g. lonely, anxious, bored, overwhelmed, restless, flat'
        Part B: Slider 0–10 — "How intense was it?"
                Labels: 'Mild' ↔ 'Overwhelming'

Step 4: "What thought arose just before? Even a single sentence is fine."
        Hint: 'e.g. "I deserve this." / "Just for a minute." / "No one will know."'
        Text field (free text)
```

**Save behaviour:**
1. Combine all fields into encrypted `responseText` as structured JSON:
   ```json
   {
     "locationTime": "...",
     "activityBefore": "...",
     "emotionName": "...",
     "emotionRating": 7,
     "thoughtArose": "..."
   }
   ```
2. Create and save `RecoverySession(sessionType: 'm1BehaviourLog', moduleNumber: 1)`
3. Show `_AffirmationView` with message: *"Logged. Every honest record brings you closer to understanding your pattern."*

**Draft behaviour:** If user closes app mid-flow, save progress to local SharedPreferences (not Firestore) keyed by `habitId_behaviourLogDraft`. Resume on next open of `BehaviourLogScreen`.

---

## 5. EXISTING SCREENS TO MODIFY

### 5a. `ValuesInventoryScreen` — significant changes

**File:** `lib/presentation/views/habits/values_inventory_screen.dart`

**Domain names — UPDATE to match design spec:**
```dart
// REPLACE current 8 domains with:
1. 'Faith & Spiritual Life'
2. 'Intimate Relationship & Partnership'
3. 'Family & Parenting'
4. 'Friendship & Social Connection'
5. 'Work, Career & Contribution'
6. 'Personal Growth & Learning'
7. 'Health & Physical Wellbeing'
8. 'Creative Expression & Leisure'
```

**Sliders — CHANGE scale from 1–5 to 1–10:**
Both importance and alignment sliders change from 5-point to 10-point scale.

**Reflection text field — ADD:**
Above the sliders on each domain screen, add a multi-line text field:
```
Label: none (just the question as placeholder/hint)
Hint: 'In your own words, what does [domain] mean in your life, and what would 
       living it well look like for you?'
minLines: 3
maxLines: null (expands)
```
This field is required — cannot proceed to next domain without at least 10 characters.

**Compass selector — ADD:**
Below the sliders, add a three-option tap-to-select row:

```
Label: "Does your current pattern move you toward or away from this?"
Options (equal visual weight, none pre-selected):
  [ Toward ]  [ Neutral ]  [ Away ]
```

No option pre-selected. User must make a deliberate choice. Cannot proceed without selecting one.

**Gap feedback — UPDATE:**
```dart
// REPLACE current gap callout logic
final gap = importance - alignment;
if (gap == 0) {
  return 'You\'re living in alignment here.';  // sage tint
} else if (gap > 5) {
  return 'There\'s a meaningful gap here.';    // purple tint  
} else if (gap > 0) {
  return 'Some room to grow here.';            // neutral
} else {
  return 'Living beyond what you value — that\'s also meaningful.'; // sage tint
}
```

**Data save — UPDATE:**
The `prov.saveValuesInventoryEntries()` call must save extended data:
```dart
// Each entry now:
{
  'domain': domainName,
  'importance': importanceValue,   // 1–10
  'alignment': alignmentValue,     // 1–10
  'reflectionText': reflectionText,
  'compassDirection': 'toward' | 'neutral' | 'away',
}
```

**Completion text — UPDATE (conditional):**
```dart
// After saving all 8 domains:
final hasAway = entries.any((e) => e['compassDirection'] == 'away');
if (hasAway) {
  completionBody = 'You can see where this pattern is pulling against what matters to you. '
    'That\'s your compass — not a judgement, just information.';
} else {
  completionBody = 'You\'ve mapped what matters to you. As you work through this journey, '
    'this is your compass — the life you\'re building toward.';
}
```

**Draft resume — ADD:**
On `initState`, check `path.valuesInventoryDraftStep > 0`. If so, restore draft entries from `path.valuesInventoryDraft` and start from `path.valuesInventoryDraftStep`. On each domain completion, call `prov.saveValuesInventoryDraft(habitId, currentStep, entries)` before navigating to next domain.

**Journal output:**
All 8 domain entries saved as one combined session (existing `m3ValuesInventory` session type), not 8 separate sessions.

---

### 5b. `ModuleSessionScreen` — Module 2 prompts REPLACE

**File:** `lib/presentation/views/habits/module_session_screen.dart`

The existing 5-step Module 2 prompts are replaced entirely.

**New session config for `m2ThoughtExamination`:**

```
Title: 'Examine a thought'
Hint: 'This works best done as soon as possible after you notice the thought.'
Number of steps: 5
```

**Step 1:**
```
Prompt: 'Write the thought exactly as it occurred — not a cleaned-up version. The raw thing.'
Note below field: 'The uncleaned version is the one that has power. That\'s the one worth examining.'
Example chips (dismissible, grey): 
  'I deserve this.' | 'Just this once.' | 'No one will know.' | 'I can\'t cope without it.'
Type: multi-line text field
Required: yes
```

**Step 2:**
```
Prompt: 'What kind of thought is this?'
Type: tap-to-select grid (NOT a text field)
Options (each with subtitle):
  'Permission-giving'   → 'I deserve this / just this once / a little won\'t matter'
  'Minimising'         → 'It\'s not that bad / everyone does it'
  'Catastrophising'    → 'I could never give this up / I have no willpower'
  'All-or-nothing'     → 'I\'ve already slipped, the day is ruined'
  'Externalising'      → 'It\'s stress / my relationship / work that causes this'
  'Self-condemnation'  → 'I\'m broken / weak / hopeless / this is just who I am'
  'Other'              → shows text field for custom label
Single select. Required.
```

**Step 3:**
```
Prompt A: 'What is the actual evidence for this thought? What does your track record say?'
Text field A: multi-line, required

Prompt B: 'What would you say to a good friend who told you they believed this?'
Text field B: multi-line, required

Both on same screen. Step 3 of 5.
```

**Step 4:**
```
Prompt: 'Write a more accurate alternative — in your own words, not an affirmation.'
Note below field: 'Not "everything will be fine" — something you actually believe. 
                   Something grounded in what your evidence just showed you.'
Example chip (dismissible): 
  'The evidence from my own history is that once never stays once. 
   The urge will pass in about 20 minutes whether or not I act on it.'
Type: multi-line text field
Required: yes
```

**Step 5:**
```
Prompt: 'Is this one of your recurring thoughts — something that comes up again and again?'
Type: two-button choice (NOT a text field)
  Button A: 'Yes, save it to my library'  → sets saveToLibrary = true
  Button B: 'No, just this once'          → sets saveToLibrary = false
Required: must tap one.
```

**On save:**
- If `saveToLibrary == true`: call `prov.addCounterResponse(habitId, counterResponse)` where `counterResponse` is a Map: `{'thought': step1Text, 'errorType': step2Selection, 'alternative': step4Text, 'createdAt': Timestamp}`
  - **Note:** Counter-responses are now stored as Maps not Strings. Update `counterResponses` field on path doc to `List<Map>`.
- Show affirmation: *"Good work. You slowed down a thought that usually moves faster than you can catch it."*
- After affirmation, show two options:
  - `'Back to my plan'` — pops
  - `'Log this moment too'` — pushes `BehaviourLogScreen` (pre-fills today's date context)

**Draft behaviour:**
On `initState`, check `path.thoughtExaminationDraftStep > 0`. If so, restore draft from `path.thoughtExaminationDraft`. On each step save, write draft to Firestore via `prov.saveThoughtExaminationDraft(habitId, step, draftData)`.

---

### 5c. `ModuleSessionScreen` — Module 3 Weekly Compass prompts REPLACE

**New session config for `m3WeeklyCompass`:**

```
Title: 'Values Compass'
Hint: 'A quick honest check — this takes about 5 minutes.'
```

**Three-step flow (REPLACES existing 3 prompts):**

**Step 1:**
```
Prompt: 'For each of your values, did this week\'s actions move toward or away from it?'
Type: List of domain names from path.module3.valuesInventory
      For each domain: two tap chips side by side: [→ Toward]  [← Away]
      Both start unselected. User must select one per domain.
Required: all domains must have a selection before proceeding.
```

**Step 2:**
```
Prompt: 'Where the compass is pointing away — what\'s one small thing you could 
         do differently this week?'
Type: multi-line text field
Required: no (if all domains marked Toward, show: 'Nothing pointing away this week — 
           that\'s worth noticing.')
```

**Step 3:**
```
Prompt: 'What is one concrete thing you will do this week that moves toward what 
         matters most to you?'
Hint: 'A "do" action — calling someone, exercising, praying, doing the creative work 
       you\'ve been putting off.'
Type: multi-line text field
Required: yes
```

**Save:** Store all three steps' content in the session `responseText` as JSON.

---

### 5d. `RecoveryPathHomeScreen` — significant changes

**File:** `lib/presentation/views/habits/recovery_path_home_screen.dart`

#### Remove
- Module number labels `'M1 —'`, `'M2 —'` etc. from `_ModuleCard` — show module name only
- `'Record a setback'` lapse button label → **replace with** `'I had a moment'`
- `Icons.favorite_border` on lapse button → replace with `Icons.refresh_rounded` or similar
- The `'Premium'` badge on modules — removed entirely (all modules available to all users per new design)
- Phase labels `'Awareness'`, `'Understanding'`, `'Anchoring'`, `'Resilience'` → replace with new labels (§2)

#### Add — "Today's actions" section
Replace the existing `'Today\'s focus'` card with a smarter surfacing system. Show up to 2 action cards based on what's due:

```dart
List<_ActionCard> _pendingActions(RecoveryPath path, int dayNumber) {
  final actions = <_ActionCard>[];
  
  // Daily check-in (always first if not done)
  if (!checkInDoneToday) {
    actions.add(_ActionCard(
      title: 'Daily check-in',
      subtitle: 'Takes 30 seconds',
      onTap: () => _openDailyCheckIn(),
    ));
  }
  
  // Mid-point reflection (Day 8–9, one-time)
  if (dayNumber >= 8 && dayNumber <= 10 && !path.midPointReflectionDone) {
    actions.add(_ActionCard(
      title: 'Mid-point reflection',
      subtitle: 'How are things going so far?',
      onTap: () => _openMidPointReflection(),
    ));
  }
  
  // Cue Hierarchy (Day 14+, threshold met, not done)
  if (dayNumber >= 14 && !path.cueHierarchyDone && _logCount >= 5) {
    actions.add(_ActionCard(
      title: 'Build your cue map',
      subtitle: 'Your logs are ready — this is a big step.',
      onTap: () => _openCueHierarchy(),
    ));
  }
  
  // Weekly compass (not done this week, inventory done)
  if (path.module3.valuesInventoryDone && !compassDoneThisWeek) {
    actions.add(_ActionCard(
      title: 'Weekly values compass',
      subtitle: 'A 5-minute check-in',
      onTap: () => _openModule(3),
    ));
  }
  
  // Environmental restructuring (Cue Hierarchy done, not yet done)
  if (path.cueHierarchyDone && !path.environmentalChangesDone) {
    actions.add(_ActionCard(
      title: 'Change your environment',
      subtitle: 'Use your cue map to make concrete changes',
      onTap: () => _openEnvironmentalRestructuring(),
    ));
  }
  
  // HRS Coping Plans (env done, plans not done)
  if (path.environmentalChangesDone && !path.hrsPlanDone) {
    actions.add(_ActionCard(
      title: 'Build your coping plans',
      subtitle: 'One plan per trigger — pre-made, ready to use',
      onTap: () => _openModule(4),
    ));
  }
  
  // Recovery letter (M5 unlocked, letter not written)
  if (isModuleUnlocked(5) && !path.module5.recoveryLetterWritten) {
    actions.add(_ActionCard(
      title: 'Write your recovery letter',
      subtitle: 'Do this while you\'re clear-headed',
      onTap: () => _openModule(5),
    ));
  }
  
  // Monthly lifestyle audit (30+ days, not done this month)
  if (dayNumber >= 30 && _lifestyleAuditDue(path)) {
    actions.add(_ActionCard(
      title: 'Monthly balance check',
      subtitle: 'What\'s taking from you? What\'s nourishing you?',
      onTap: () => _openLifestyleAudit(),
    ));
  }
  
  // Quarterly review (90+ days, due)
  if (_quarterlyReviewDue(path, dayNumber)) {
    actions.add(_ActionCard(
      title: 'Quarterly review',
      subtitle: 'Reflect on how far you\'ve come',
      onTap: () => _openModule(5),
    ));
  }
  
  return actions.take(2).toList(); // show max 2
}
```

#### Add — Module card "next step" prompt
Each `_ModuleCard` in the active state shows a subtitle prompt when a foundational task is outstanding:

```dart
String? _moduleNextStep(RecoveryPath path, int moduleNumber) {
  switch (moduleNumber) {
    case 1:
      if (!path.cueHierarchyDone && _logCount >= 5 && dayNumber >= 14)
        return 'Your next step: Build your cue map';
      return null;
    case 2:
      return null; // no foundational task, ongoing
    case 3:
      if (!path.module3.valuesInventoryDone)
        return 'Your next step: Complete your values inventory';
      return null;
    case 4:
      if (!path.environmentalChangesDone)
        return 'Your next step: Map your environmental changes';
      if (!path.hrsPlanDone)
        return 'Your next step: Build your coping plans';
      return null;
    case 5:
      if (!path.module5.recoveryLetterWritten)
        return 'Your next step: Write your recovery letter';
      return null;
    default: return null;
  }
}
```

#### Remove from module card display
- `'$count/7 check-ins to unlock weekly review'` subtitle for M1 → replace with `'$count check-ins logged'`
- The `weeklyReview` unlock banner

#### Lapse button — UPDATE
```dart
// CHANGE label from 'Record a setback' to:
label: 'I had a moment'
// CHANGE to be available regardless of module 5 unlock status
// If M5 not unlocked when tapped: unlock M5 and open lapse flow
onTap: () => _openLapseFlow(unlockM5IfNeeded: true),
```

---

### 5e. `LapseRecordingFlow` — significant redesign

**File:** `lib/presentation/views/habits/lapse_recording_flow.dart`

The existing 3-step lapse flow is replaced with a 5-screen flow.

**AppBar:** Keep `'Getting back up'`

#### Screen 0 — Stop the spiral (NEW — replaces existing intro)

Full screen. No form fields. Large warm text.

```
Body text:
"First — stop.

Whatever your mind is telling you right now about what this means, 
about who you are, about whether change is possible — those thoughts 
are not facts.

One moment is one moment. It is not a verdict.

Take a breath. You're still here. That matters."

Button: 'I'm ready to continue'
```

No data saved on this screen. Just advances to Screen 1.

#### Screen 1 — Recovery letter (REPLACES current step 0 self-compassion)

Keep existing `_LetterCard` widget behaviour (shows `recoveryLetterDraft` or fallback scripture).

**UPDATE label on card:** Change `'Your recovery letter'` header — keep.

**UPDATE button label:**
```dart
// Change from 'I'm ready — let's look at what happened' to:
'I\'ve read it'
```

**ADD below the letter card:**
```
Prompt: 'What would you say to a good friend who had just gone through 
         exactly this moment?'
Multi-line text field (required before proceeding)
Button: 'Continue'
```
Store this as `lapseData.selfCompassionText`.

#### Screen 2 — Forensic analysis (REPLACES current step 1)

Keep existing structure but update prompts:

```
Title: 'Let\'s understand what happened — not to judge it, but to learn from it.'

4 sequential mini-fields (keep existing quick-capture structure):
  'What was the situation just before? Where were you, what were you doing?'
  'What were you feeling emotionally?'
  'What thought arose just before?'
  'Where did your coping plan not hold — and what do you think got in the way?'

Button: 'Continue'
```

Remove the large free-text analysis field — the 4 mini-fields replace it.

#### Screen 3 — Extract and recommit (REPLACES current step 2)

```
Title: (none — just the questions)

Question A: 'What does this moment teach you about your coping plan that 
             you didn\'t know before? What would need to be different next time?'
Text field A: multi-line, required

Question B: 'Which of your values do you want to take the next right step 
             toward — right now, today?'
Text field B: multi-line, required

Button: 'Save and update my plan'

Below button (text link): 
  'Update my coping plan →'
  onTap: pushes GuardrailsScreen to HRS Plans tab
```

#### Completion view — UPDATE

```dart
// REPLACE current completion view text:
title: 'You came back'
body: 'You didn\'t give up. You came back. That is what recovery actually looks like '
      '— not a straight line, but coming back every time.\n\n'
      'Your plan is updated. Your values are still yours. Keep going.'
```

#### On save — UPDATE

Keep existing save logic but:
1. Use `m5LapseResponse` session type (not `lapseRecord`) for new lapse records
2. Store extended `lapseData` map (§1e)
3. The `lapseRecord` session type is kept for backwards compatibility with existing records

---

### 5f. `GuardrailsScreen` — changes

**File:** `lib/presentation/views/habits/guardrails_screen.dart`

#### Tab 1 — Environmental Restructuring (REPLACE checklist approach)

**Remove:** The checkbox list approach entirely.

**Replace with:** One text field per cue from the Cue Hierarchy:

```dart
// Build from path.cueHierarchy (ranked list)
// Show top 3 cues (or all if < 3)
// For each cue:
Column(
  children: [
    Text(cue.cueText, style: cueStyle),  // the cue in user's own words
    SizedBox(height: 8),
    TextFormField(
      labelText: 'What concrete change will you make for this trigger?',
      hintText: 'e.g. Move my device out of the bedroom / '
                'Delete the app from my phone',
      minLines: 2,
      maxLines: null,
    ),
    SizedBox(height: 4),
    // Habit-specific suggestion chips (from cue rubric, dismissible)
    _SuggestionChips(habitType: path.habitType, cueIndex: index),
    SizedBox(height: 24),
  ],
)
```

**Validation:** All 3 fields must have content before save is enabled. If vague content detected (< 15 characters or contains only generic phrases), show inline: *"Can you make this more specific — a concrete action, not a mindset?"*

**Save:** Call `prov.markEnvironmentalChangesDone(habitId, changes)` where `changes` is `List<Map<String, String>>` with `{cue, change}` pairs. Creates `m4EnvironmentalRestructuring` session.

**Show if Cue Hierarchy not done yet:** Inline message: *"Complete your cue map first — your guardrails will be built from it."* with link to open Cue Hierarchy flow.

#### Tab 2 — HRS Plans (MODIFY)

Seed each plan's `'Describe the situation'` field from the corresponding ranked cue in `path.cueHierarchy` (if plans not yet saved). So the user's cues pre-fill the situation descriptions.

Add inline vagueness check on the `'What will you do first?'` field: if < 20 characters or generic phrasing, show: *"The most effective plans are very specific — a concrete action, not a mindset. What exactly will you do?"*

On save, set `path.hrsPlanDone = true`.

#### Tab 3 — Urge Surfing (MODIFY)

Add an intro screen shown once (gated by `!path.urgeSurfingIntroSeen`):

```
Heading: 'A different option'
Body: 'You don\'t have to fight an urge or give in to it. There\'s a third 
       option — you can just watch it.

       Urges aren\'t commands. They\'re neurological events with a natural 
       shape — they rise, peak, and pass, usually within 15–30 minutes, 
       whether or not you act on them. Urge surfing is the practice of 
       riding that arc rather than reacting to it.

       The more you practise this, the weaker the urge becomes over time.'

Button: 'Start my first urge surfing session'
```

On dismiss: set `path.urgeSurfingIntroSeen = true`.

**UPDATE urge surfing prompts:**
```
Prompt 1: 'Name it: "I am having an urge to [behaviour]." Write what you\'re 
           experiencing right now — not as a command to act, just as an observation.'

Prompt 2: 'Locate it: Where in your body do you feel it? Chest, throat, stomach, 
           hands? What is its shape and quality?'

Prompt 3: 'Watch it: Did it rise and then begin to ease? Describe what happened 
           to the urge as you observed it. Was it survivable?'
```

---

### 5g. `RecoveryLetterScreen` — changes

**File:** `lib/presentation/views/habits/recovery_letter_screen.dart`

#### Add AVE education screen (shown once before letter writing)

Gate on `!path.module5IntroSeen`:

```
AppBar: 'Navigate Lapses'
Heading: 'Before anything happens — read this.'

Body:
'Most people who are changing a deeply ingrained pattern will experience 
a slip at some point. That\'s not pessimism — it\'s what the research 
consistently shows.

What determines whether a slip becomes a full relapse is almost never the 
slip itself. It\'s what happens in the hour afterward.

When a slip happens, the mind tends to catastrophise: "I\'ve failed. I have 
no willpower. I\'ll never change. I might as well give up." Researchers call 
this the Abstinence Violation Effect — and it\'s one of the most dangerous 
things that can happen after a slip, because it turns a single moment into a 
sustained return to the old pattern.

These thoughts are not facts. They are the all-or-nothing thinking error at 
its most damaging. And knowing that — right now, before you need it — is one 
of the most useful things you can do.'

Button: 'I\'ve read this — write my letter'
```

On button tap: set `path.module5IntroSeen = true`, proceed to existing letter writing flow.

#### Update letter prompts

```dart
// REPLACE existing 4 prompts with:
1. 'Right now, while you\'re clear-headed, write a letter from your wiser self 
    to your struggling self — for the moment after a slip.

    What do you most want to remind yourself about who you are?'

2. 'What does the research say about slips? (Hint: they don\'t have to become 
    relapses. A slip is a data point, not a verdict.)'
    Note: 'Write it in your own words — this is what you\'ll read in your hardest moment.'

3. 'Which of your values do you want to take the next step toward — even today, 
    even now?'

4. 'What do you want to say to your harshest inner voice?'
```

**Intro text above Step 0:**
```
'This letter is from you to you — to be read the next time you\'re struggling. 
Write honestly. No one else will see this.

Many people find this is the most important thing they write in this whole journey.'
```

#### Update completion text
```dart
title: 'Letter saved'
body: 'That\'s the preparation done. You\'ve given your future self something real 
      to hold onto. Now you know what to do if a hard moment comes — and you have 
      what you need to get back up.'
```

---

## 6. NEW SCREENS TO BUILD

### 6a. `MidPointReflectionScreen`

**File:** `lib/presentation/views/habits/mid_point_reflection_screen.dart`  
**Session type:** `m1MidPointReflection`  
**Trigger:** Day 8–9, surfaced from `RecoveryPathHomeScreen` pending actions

```
Title: 'Two weeks in'
Intro: 'You\'ve been logging moments for a little while now. Before looking for 
        patterns, just take a few minutes to reflect honestly.'

3 questions (ModuleSessionScreen-style pagination):
1. 'Looking at what you\'ve logged so far — does anything surprise you?'
   Hint: 'Even if you haven\'t noticed a pattern yet, that\'s worth noting.'

2. 'Is there a time of day, place, or emotional state that seems to come up 
    more than once?'
   Hint: 'Don\'t force a pattern — just notice if anything stands out.'

3. 'How are you feeling about this process so far?'
   Hint: 'Honest is good. Frustrated is fine. There are no wrong answers here.'

Save: Creates m1MidPointReflection session. Sets path.midPointReflectionDone = true.
```

Add `midPointReflectionDone: bool` field to Firestore path doc.

**Completion:**
```
title: 'Reflection saved'
body: 'Keep logging. The pattern will become clearer with more data.'
```

---

### 6b. `CueHierarchyScreen`

**File:** `lib/presentation/views/habits/cue_hierarchy_screen.dart`  
**Session type:** `m1CueHierarchy`  
**Trigger:** Day 14/21/28 threshold met, surfaced from `RecoveryPathHomeScreen`

This is a 5-stage flow managed as a `PageView` or `IndexedStack`.

#### Stage 1 — Entry
```
Icon: path/route icon in purple
Heading: 'You\'ve been logging moments for two weeks. That takes honesty and courage. 
          Now let\'s look at what your logs are telling you — together.'
Button: 'Let\'s go'
```

#### Stage 2 — Review logs
```
Heading: 'Your logged moments'
Subheading: 'Read through what you\'ve captured. Don\'t analyse yet — just notice.'

List: All m1BehaviourLog sessions for this habitId, shown in chronological order.
Each item shows:
  - Date (formatted)
  - emotionName + emotionRating
  - locationTime
  - thoughtArose (truncated to 60 chars, expandable)

Button at bottom: 'I\'ve read through them'
```

#### Stage 3 — AI candidate patterns
```
Heading: 'Here\'s what we noticed'
Subheading: 'These are patterns we spotted — they may not all be right, and there 
             may be things we missed. You know your story better than we do.'

AI analysis call: See §6b AI integration below.

Display: 2–4 candidate cue cards.
Each card shows: cue text in plain language
Each card has: [✓ Keep] [✗ Remove] chips (default: all selected/kept)

Button: 'Continue'
```

**AI integration for Stage 3:**

```dart
// Call Anthropic API (claude-sonnet-4-6) with:
// System prompt:
'You are analysing behaviour logs from a recovery app to identify cue patterns. 
The user is working on overcoming: [habitType].
Based on these logs, identify 2-4 specific cue patterns (combinations of situation 
and emotional state that reliably precede the behaviour). 
Format each as a plain-language statement under 12 words.
Known common cues for this habit type: [rubricCues from habitType].
Respond with ONLY a JSON array of strings. No explanation. Example:
["Late evenings when feeling flat or stressed", "After difficult conversations"]'

// User message:
'Logs: [JSON array of behaviour log data: {date, emotionName, emotionRating, 
locationTime, activityBefore, thoughtArose}]'

// Parse response as List<String>
// If API fails: fall back to rubric-based discovery questions only (Stage 4)
```

The `habitType` field on the path doc is used to select the correct rubric for both AI prompting and discovery questions. Rubric data is stored in `lib/domain/services/cue_rubric_service.dart` (new file — see §6e).

#### Stage 4 — Discovery questions
```
Heading: 'A few more questions'
Subheading: 'Based on what research tells us about [habit type], 
             do any of these ring true?'

Show 2-3 questions from the habit-specific cue rubric that did NOT appear 
clearly in the logs (determined by keyword matching against log content).

Each question:
  Question text
  Three pill chips: [Yes, this rings true] [Sometimes] [No, not really]
  'Yes' or 'Sometimes' → adds candidate cue based on question
  
Button: 'Continue'
```

Discovery question → candidate cue mapping is handled by `CueRubricService` (§6e).

#### Stage 5 — Build and rank
```
Heading: 'Your pattern triggers'
Subheading: 'These are your cues — ranked from least to most triggering. 
             Edit any of them to use your own words.'

Display: All confirmed candidate cues as draggable/reorderable list cards.
Each card:
  - Editable text field (pre-filled with AI suggestion or discovery answer)
  - Drag handle (right side)
  - Delete button (only if > 2 items)

'+ Add your own' button: adds a blank card

Validation:
  - Minimum 2 cues required
  - Maximum 6 cues
  - If 6 reached: show 'That\'s the maximum — a focused list works better than a long one.'
  - All cards must have non-empty text

Button: 'Save my pattern triggers'
```

**Save:**
1. Save ranked list to `path.cueHierarchy` as `List<Map>` with `{rank, cueText, isAiSuggested}`
2. Set `path.cueHierarchyDone = true`
3. Create `m1CueHierarchy` session with JSON of ranked cues
4. Trigger phase recalculation → Phase 2

**Completion screen:**
```
Icon: map/route icon in purple
Heading: 'You\'ve just done something most people never do — looked honestly at 
          your own patterns.'
Body: 'This list is the map. Everything that comes next uses it.'
Button: 'Back to my plan'
```

**Insufficient logs handling:**
```dart
// In RecoveryPathHomeScreen, before opening CueHierarchyScreen:
final logCount = await prov.getBehaviourLogCount(habitId);
final dayNumber = prov.dayNumberFor(habitId);

if (dayNumber < 14) return; // not time yet

if (logCount < 5) {
  if (dayNumber < 21) {
    // Show inline message on today card:
    'You have $logCount moments logged so far. That might mean this pattern 
     isn\'t happening as often — which could itself be a sign of progress. 
     Keep logging and we\'ll revisit this when more data is available.'
  } else if (dayNumber < 28) {
    'It looks like logging moments has been tricky. That\'s completely normal. 
     Even if you can recall a recent moment now, you can log it retrospectively.'
  } else {
    // Day 28+: open CueHierarchyScreen regardless, use lighter Stage 3 prompt:
    'Here\'s what you\'ve captured so far — even if it\'s limited, 
     what patterns if any do you notice?'
  }
} else {
  // Open CueHierarchyScreen normally
}
```

---

### 6c. `ThoughtExaminationScreen`

**Note:** This is actually implemented by modifying `ModuleSessionScreen` with the new `m2ThoughtExamination` config (§5b). The entry point is new — from the habit card button.

Entry points:
1. `'Examine a thought'` button on habit card (§7)
2. Recovery Path screen under Challenge Your Thinking section
3. After daily check-in when `outcome == 'urge_only'`

No new file needed — `ModuleSessionScreen` handles it.

---

### 6d. `EnvironmentalRestructuringScreen`

**File:** `lib/presentation/views/habits/environmental_restructuring_screen.dart`  
**Session type:** `m4EnvironmentalRestructuring`  
**Trigger:** Surfaced from `RecoveryPathHomeScreen` pending actions after Cue Hierarchy done

```
AppBar: 'Change Your Environment'
Heading: 'Change the situation before you need to change your mind.'
Subheading: 'Willpower works worst exactly when you need it most. Making 
             concrete changes to your environment is more effective than 
             relying on willpower in the moment.'

[For each of top 3 cues from path.cueHierarchy:]
  Cue text (displayed, not editable)
  Label: 'What one concrete change will you make?'
  TextFormField (multi-line, required)
  _SuggestionChips widget (habit-specific examples from CueRubricService)

Button: 'Save my changes' (enabled when all 3 fields filled)
```

On save:
1. `prov.markEnvironmentalChangesDone(habitId, changes)`
2. Appends environmental changes to the Cue Hierarchy session (or creates new `m4EnvironmentalRestructuring` session)
3. Sets `path.environmentalChangesDone = true`

Completion: *"Good — you've made it harder for the pattern to happen automatically. Up next: a specific plan for each of your triggers."*

---

### 6e. `CueRubricService`

**File:** `lib/domain/services/cue_rubric_service.dart` *(new file)*

Contains all habit-type rubric data as static data. Used by `CueHierarchyScreen` and `EnvironmentalRestructuringScreen`.

```dart
class CueRubricService {
  // Maps habitType string to CueRubric
  static CueRubric rubricFor(String habitType) { ... }
  
  // Determines habitType from habit name string
  static String habitTypeFrom(String habitName) { ... }
  
  // Returns 2-3 discovery questions for habitType
  // Filters out questions whose keywords appear in existing log content
  static List<DiscoveryQuestion> discoveryQuestionsFor(
    String habitType, 
    List<RecoverySession> existingLogs,
  ) { ... }
  
  // Returns cue text for a 'Yes'/'Sometimes' answer to a discovery question
  static String cueTextFromDiscovery(String habitType, String questionKey) { ... }
  
  // Returns habit-specific environmental change suggestions for a given cue
  static List<String> environmentalSuggestionsFor(String habitType, String cueText) { ... }
}

class CueRubric {
  final List<String> primaryCues;        // known common cues
  final List<DiscoveryQuestion> questions; // discovery questions
  final List<String> environmentalSuggestions; // concrete change suggestions
}

class DiscoveryQuestion {
  final String key;
  final String questionText;
  final String resultingCueText; // if answered Yes/Sometimes
  final List<String> keywords;   // keywords that indicate this was already captured
}
```

**Habit type detection** — `habitTypeFrom(String habitName)`:
```dart
static String habitTypeFrom(String habitName) {
  final lower = habitName.toLowerCase();
  if (lower.contains('porn') || lower.contains('pornography') || lower.contains('lust')) {
    if (lower.contains('masturbat')) return 'pornography_masturbation';
    return 'pornography';
  }
  if (lower.contains('masturbat')) return 'masturbation';
  if (lower.contains('alcohol') || lower.contains('drink') || lower.contains('beer') 
      || lower.contains('wine')) return 'alcohol';
  if (lower.contains('spend') || lower.contains('shop') || lower.contains('buy')) 
    return 'compulsive_spending';
  if (lower.contains('eat') || lower.contains('food') || lower.contains('binge')) 
    return 'disordered_eating';
  if (lower.contains('gambl') || lower.contains('bet') || lower.contains('casino')) 
    return 'gambling';
  if (lower.contains('social media') || lower.contains('instagram') 
      || lower.contains('tiktok') || lower.contains('facebook')) return 'social_media';
  if (lower.contains('procrastinat')) return 'procrastination';
  if (lower.contains('smok') || lower.contains('cigarette') || lower.contains('nicotine') 
      || lower.contains('vap')) return 'smoking';
  if (lower.contains('doom') || lower.contains('scroll') || lower.contains('news')) 
    return 'doom_scrolling';
  if (lower.contains('gossip')) return 'gossip';
  if (lower.contains('self-talk') || lower.contains('self talk') 
      || lower.contains('negative thinking')) return 'negative_self_talk';
  if (lower.contains('overwork') || lower.contains('workahol')) return 'overworking';
  return 'generic'; // fallback
}
```

All 14 rubric datasets (discovery questions, environmental suggestions, primary cues) are stored as static const data within this file. See `Freedom_Plan_Design_Decisions.md` §HABIT-SPECIFIC CUE RUBRICS for the full content of each rubric.

---

### 6f. `LifestyleAuditScreen`

**File:** `lib/presentation/views/habits/lifestyle_audit_screen.dart`  
**Session type:** `m4LifestyleAudit`  
**Trigger:** Monthly from Day 30, surfaced from pending actions

```
AppBar: 'Monthly Balance Check'
Intro: 'This isn\'t about optimising your schedule. It\'s about making sure 
        your life has enough real goodness in it that this habit doesn\'t 
        feel like the only available relief.'

Two-part entry (ModuleSessionScreen-style):

Step 1:
  Prompt A: 'Looking at your typical week honestly — what is taking from you?'
  Text field A (multi-line, required)
  
  Prompt B: 'What is genuinely nourishing you — not numbing, not obligation, 
             but something you\'d actually choose?'
  Text field B (multi-line, required)

Step 2:
  Prompt: 'What two activities could you build into the next month that would 
           genuinely nourish you?'
  Text field (multi-line, required)
  Button: 'Save'

Save: 
  Creates m4LifestyleAudit session.
  Sets path.lastLifestyleAuditAt = now.
```

---

### 6g. `FreedomJourneyTab` — Freedom Journey Journal Section

**File:** `lib/presentation/views/journal/freedom_journey_tab.dart` *(new file)*  
**Placement:** Second tab within the existing Journal screen (`lib/presentation/views/journal/journal_view.dart`)

The Freedom Journey tab is only visible when `habit.hasRecoveryPath == true` for at least one habit.

#### Tab bar

```dart
// In journal_view.dart, add tab when any freedom plan exists:
TabBar(
  tabs: [
    Tab(text: 'Journal'),
    if (hasFreedomPlan) Tab(text: 'Freedom Journey'),
  ],
)
```

#### Sub-views toggle

Inside `FreedomJourneyTab`, a segmented control at top:
```dart
SegmentedButton(
  segments: [
    ButtonSegment(value: 0, label: Text('My Journey')),
    ButtonSegment(value: 1, label: Text('My Plan')),
  ],
)
```

#### "My Journey" view (index 0) — chronological feed

```dart
// Streams all recovery_sessions for this habitId, ordered by createdAt DESC
// Each item rendered as _JourneyEntryCard:

class _JourneyEntryCard extends StatelessWidget {
  final RecoverySession session;
  
  // Shows:
  // - Date (formatted: 'Today', 'Yesterday', 'Mon 14 Jul')
  // - Type label (see label mapping below)
  // - Snippet (first 100 chars of decrypted responseText)
  // - Tap to expand full content
}
```

Session type → label mapping:
```dart
const sessionLabels = {
  'm1DailyCheckIn':         'Daily check-in',
  'm1BehaviourLog':         'Moment logged',
  'm1MidPointReflection':   'Mid-point reflection',
  'm1CueHierarchy':         'Cue map built',
  'm1WeeklyReview':         'Pattern review',
  'm2ThoughtExamination':   'Thought examined',
  'm3ValuesInventory':      'Values inventory',
  'm3WeeklyCompass':        'Values compass',
  'm4EnvironmentalRestructuring': 'Environmental changes',
  'm4UrgeSurfing':          'Urge surfed',
  'm4LifestyleAudit':       'Lifestyle balance review',
  'm5AveEducation':         'Recovery education',
  'm5RecoveryLetter':       'Recovery letter',
  'm5LapseResponse':        'Lapse — came back',
  'lapseRecord':            'Lapse — came back',
  'm5QuarterlyReview':      'Quarterly review',
};
```

#### "My Plan" view (index 1) — module-organised

Five `_PlanSectionCard` widgets, one per module, in order.

```dart
class _PlanSectionCard extends StatelessWidget {
  final int moduleNumber;
  final String title;
  final IconData icon;
  final Color accentColor;
  final ModuleState state; // locked | active | complete
  final List<RecoverySession> sessions;
  final RecoveryPath path;
}
```

**State rendering:**

```dart
// LOCKED:
Opacity(
  opacity: 0.4,
  child: Row(children: [
    Icon(icon, color: accentColor),
    Text(title),
    Icon(Icons.lock_outline, size: 14),
  ]),
)
// Subtitle: unlock condition text
// Non-tappable

// ACTIVE:
Column(
  children: [
    // Section header (full color, tappable, expands)
    Row(children: [Icon(icon, color: accentColor), Text(title), expandIcon]),
    
    // When expanded:
    // 1. Pinned living documents (if any)
    // 2. Next step prompt card (if task outstanding)
    // 3. Session entries list (reverse chronological)
    // 4. Empty state if no sessions
  ],
)

// COMPLETE:
// Same as ACTIVE but with small filled circle indicator next to title
```

**Pinned living documents per section:**

```dart
// Know Your Pattern (M1):
//   - 'My Pattern Triggers' — from path.cueHierarchy
//   - Show as structured card with ranked list

// Anchor to Your Values (M3):
//   - 'My Values Inventory' — from path.module3.valuesInventory
//   - Show as domain cards with ratings and reflection text

// Build Your Guardrails (M4):
//   - 'My Coping Plans' — from path.module4.hrsPlan
//   - Show as plan cards (editable — tap to open GuardrailsScreen)

// Challenge Your Thinking (M2):
//   - 'My Counter-responses' — from path.counterResponses (now List<Map>)
//   - Show as thought/alternative pairs

// Navigate Lapses (M5):
//   - 'My Recovery Letter' — from path.recoveryLetterDraft
//   - Show as read-only letter card with edit button
```

**Empty states per section:**
```dart
const emptyStateTexts = {
  1: 'Your logged moments will appear here.',
  2: 'Your thought examinations will appear here.',
  3: 'Your values reflections will appear here.',
  4: 'Your coping plans and urge logs will appear here.',
  5: 'Your lapse records and quarterly reviews will appear here.',
};
```

**Section unlock conditions (for locked subtitle):**
```dart
const unlockTexts = {
  2: 'Unlocks when your cue map is complete.',
  4: 'Unlocks when your cue map is complete.',
  5: 'Unlocks after 30 days or your first lapse.',
};
```

---

## 7. HABIT CARD CHANGES

**File:** `lib/presentation/views/habits/habit_check_in_card_view.dart`

### 7a. Remove streak display

For habits with `subcategoryId == 'breaking_habits'`:
- Remove `'1 days of freedom'` / `'N days of freedom'` subtitle
- Remove any consecutive-day counter display
- Remove streak reset animation on lapse

Replace with: nothing (no subtitle showing time-based progress).

### 7b. Check-in button — UPDATE

```dart
// For breaking_habits abstain habits:
// Change from 'Stayed strong today?' to:
label: checkInDoneToday ? 'Checked in today ✓' : 'How are you doing today?'
icon: checkInDoneToday ? Icons.check_circle_outline : Icons.circle_outlined
// On tap: opens DailyCheckInScreen (not ModuleSessionScreen)
```

### 7c. Add action buttons row

Below the check-in button and above the partner strip, add a horizontal scrollable row of action buttons:

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      if (!checkInDoneToday)
        _ActionChip(label: 'Check in', onTap: _openDailyCheckIn),
      _ActionChip(label: 'Log a moment', onTap: _openBehaviourLog),
      if (module2Unlocked)
        _ActionChip(label: 'Examine a thought', onTap: _openThoughtExamination),
      if (module4Unlocked && path.urgeSurfingIntroSeen)
        _ActionChip(label: 'Urge surfed', onTap: _openUrgeSurfing),
      if (module2Unlocked && path.counterResponses.isNotEmpty)
        _ActionChip(label: 'My counter-responses', onTap: _openCounterResponseLibrary),
    ],
  ),
)
```

`_ActionChip` style: ghost pill button, small text, amber/gold border.

### 7d. Lapse button — UPDATE

```dart
// In _rpStrip or as a separate strip below:
// REMOVE the faint 'Record a setback' button from RecoveryPathHomeScreen only
// ADD 'I had a moment' as a discrete low-prominence text link on the habit card:
TextButton(
  onPressed: _openLapseFlow,
  child: Text(
    'I had a moment',
    style: TextStyle(
      color: MyWalkColor.warmGold.withOpacity(0.5),
      fontSize: 12,
    ),
  ),
)
// Positioned at very bottom of card, below all other elements
```

### 7e. Freedom Plan strip — UPDATE

```dart
// KEEP existing _rpStrip behaviour (Phase N · Day N display)
// UPDATE orange dot trigger: show orange dot when:
//   - Check-in not done today, OR
//   - Any pending action exists (mid-point reflection, cue hierarchy, weekly compass)
// The orange dot was previously only for check-in — expand to cover any pending action
```

---

## 8. PROVIDER CHANGES

**File:** `lib/presentation/providers/recovery_path_provider.dart`

### New methods to add

```dart
// Behaviour log count (for Cue Hierarchy threshold check)
Future<int> getBehaviourLogCount(String habitId) async {
  return _repo.getSessionCountByType(habitId, 'm1BehaviourLog');
}

// Cue Hierarchy
Future<void> saveCueHierarchy(String habitId, List<Map<String, dynamic>> cues) async {
  // Update path: cueHierarchyDone = true, cueHierarchy = cues
  // Create m1CueHierarchy session
  // Trigger phase recalculation
}

// Cue Hierarchy draft
Future<void> saveCueHierarchyDraft(String habitId, int stage) async { ... }

// Environmental changes
Future<void> markEnvironmentalChangesDone(
  String habitId, 
  List<Map<String, String>> changes,
) async {
  // Update path: environmentalChangesDone = true
  // Create m4EnvironmentalRestructuring session
}

// Values inventory draft
Future<void> saveValuesInventoryDraft(
  String habitId, 
  int step, 
  List<Map<String, dynamic>> entries,
) async { ... }

// Thought examination draft
Future<void> saveThoughtExaminationDraft(
  String habitId,
  int step,
  Map<String, dynamic> draftData,
) async { ... }
Future<void> clearThoughtExaminationDraft(String habitId) async { ... }

// Lifestyle audit
Future<void> saveLifestyleAudit(String habitId, String responseText) async {
  // Create m4LifestyleAudit session
  // Update path: lastLifestyleAuditAt = now
}

// Counter-responses (UPDATE — now stores Maps not Strings)
Future<void> addCounterResponse(
  String habitId, 
  Map<String, dynamic> counterResponse,
) async {
  // counterResponse: {thought, errorType, alternative, createdAt}
  // Append to path.counterResponses (List<Map>)
}

// Module 5 intro
Future<void> markModule5IntroSeen(String habitId) async { ... }

// Mid-point reflection done
Future<void> markMidPointReflectionDone(String habitId) async { ... }

// HRS plan done flag
Future<void> markHrsPlanDone(String habitId) async { ... }
// Called from existing saveHrsPlan() — add flag update there

// Lifestyle audit due check
bool isLifestyleAuditDue(RecoveryPath path) {
  if (path.lastLifestyleAuditAt == null) return true;
  return DateTime.now().difference(path.lastLifestyleAuditAt!.toDate()).inDays >= 30;
}

// Quarterly review due check  
bool isQuarterlyReviewDue(RecoveryPath path, int dayNumber) {
  return path.quarterlyReviewDueDays.any((d) => 
    dayNumber >= d && dayNumber < d + 7 && 
    !_hasQuarterlyReviewForDay(path, d)
  );
}

// Habit type determination (called in startPath)
String _habitTypeFrom(String habitName) {
  return CueRubricService.habitTypeFrom(habitName);
}
```

### Modify existing methods

```dart
// startPath() — ADD:
// Set habitType from habit name
path = path.copyWith(
  habitType: _habitTypeFrom(habit.name),
  lapseButtonAvailableFrom: DateTime.now(),
);

// saveSession() — ADD:
// After saving, check if daily check-in reset needed (new day)
// Reset dailyCheckInEmotionalRating and dailyCheckInOutcome if lastCheckInAt.date != today
```

---

## 9. REPOSITORY CHANGES

**File:** `lib/data/repositories/firestore_recovery_path_repository.dart`

### New methods

```dart
// Session count by type (for log threshold check)
Future<int> getSessionCountByType(String habitId, String sessionType) async {
  final snapshot = await _sessions(habitId)
    .where('sessionType', isEqualTo: sessionType)
    .count()
    .get();
  return snapshot.count;
}

// Get all sessions of a given type (for Cue Hierarchy review)
Future<List<RecoverySession>> getSessionsByType(
  String habitId, 
  String sessionType,
) async { ... }

// Update path fields (partial update)
Future<void> updatePathFields(
  String habitId, 
  Map<String, dynamic> fields,
) async {
  await _paths.doc(habitId).update(fields);
}
```

---

## 10. NOTIFICATION CHANGES

### Remove (Cloud Functions)

Remove these push notification Cloud Functions — they either used streak language or are replaced:

| Function | Action | Reason |
|---|---|---|
| `rpDailyCheckInReminder` | **Remove** | References "streak" in body text |
| `rpMissed3DaysReminder` | **Remove** | References "streak" |
| `rpM2UnlockReminder` | **Remove** | Module unlock no longer push-notified |
| `rpLapseUnlocksM5` | **Remove** | Module unlock no longer push-notified |

### Keep (Cloud Functions)

| Function | Keep? | Changes needed |
|---|---|---|
| `rpWeeklyCompassReminder` | **Keep** | Update body text — remove "3-question" reference, use new flow description |
| `rpQuarterlyReviewReminder` | **Keep** | No changes |

### Keep (Local notifications)

Keep the 7 rotating daily reminder local notifications (IDs 200–206). Update message 1:

```dart
// CHANGE message 1 from:
'Your daily check-in is waiting — a few minutes keeps your progress going.'
// TO:
'Your daily check-in is waiting — a few minutes of honesty every day adds up.'
```

Remove all other messages referencing "streak" (messages 2–7 are fine as-is).

### Add — zero-log weekly nudge (local notification)

```dart
// In RecoveryPathProvider, on each app open:
// Check: any m1BehaviourLog sessions in past 7 days?
// If no: schedule a one-time local notification for 8pm today (if not already sent this week)
// Message: 'It\'s been a quiet week in your log. Is everything OK? '
//          'Even a brief note about a moment you navigated well is worth capturing.'
// ID: 207
```

---

## 11. BUILD SEQUENCE

Implement in this exact order. Each task should be implemented and tested before proceeding to the next. Each task is independently testable.

### Task 1 — Data model and phase logic
- Add all new fields to `RecoveryPath` model and `fromFirestore`/`toFirestore`
- Replace `RecoveryPhaseCalculator` with new logic
- Update `isModuleUnlocked()` 
- Update phase labels everywhere they appear
- **Test:** Path creation, phase transitions, module unlock conditions

### Task 2 — `CueRubricService`
- Create `lib/domain/services/cue_rubric_service.dart`
- Implement all 14 rubrics as static const data
- Implement `habitTypeFrom()` matching logic
- **Test:** All habit type strings resolve correctly, discovery questions returned correctly

### Task 3 — `ValuesInventoryScreen` changes
- Add reflection text field
- Change slider scale to 1–10
- Add compass selector
- Update domain names
- Update completion text (conditional)
- Add draft resume behaviour
- Update save data structure
- **Test:** All 8 domains complete correctly, data saves correctly, draft resumes

### Task 4 — Daily check-in redesign
- Build `DailyCheckInScreen`
- Wire up from habit card check-in button
- Remove old `ModuleSessionScreen` check-in flow
- **Test:** Both outcomes (slipped / urge / clear), linking to BehaviourLog and ThoughtExamination

### Task 5 — `BehaviourLogScreen`
- Build new screen with 4 sequential fields
- Wire up from new "Log a moment" habit card button
- Add draft behaviour (SharedPreferences)
- **Test:** All fields save correctly, draft persists on app close

### Task 6 — `MidPointReflectionScreen`
- Build screen
- Add `midPointReflectionDone` field to path model
- Wire up from `RecoveryPathHomeScreen` pending actions
- **Test:** Surfaces at Day 8–9, saves correctly, doesn't resurface

### Task 7 — `CueHierarchyScreen` (stages 1, 2, 5 only — no AI yet)
- Build screen with all 5 stages
- Stage 3: Use placeholder "Analysing your logs..." loading state, then show hardcoded test cues
- Stage 4: Use discovery questions from `CueRubricService`
- Stage 5: Full drag-to-rank UI
- Save to Firestore, set flags, trigger phase recalculation
- **Test:** Full flow completion, minimum/maximum cue validation, draft behaviour

### Task 8 — AI integration for CueHierarchyScreen Stage 3
- Integrate Anthropic API call
- Parse response, handle errors, fall back gracefully
- **Test:** API call succeeds, fallback works when API fails

### Task 9 — `EnvironmentalRestructuringScreen`
- Build screen, seeding from `cueHierarchy`
- Wire up from pending actions
- Habit-specific suggestion chips from `CueRubricService`
- **Test:** Cue hierarchy seeding, saves correctly

### Task 10 — `GuardrailsScreen` changes
- Replace Tab 1 checkbox approach with cue-seeded text fields
- Seed Tab 2 HRS plans from cue hierarchy
- Add urge surfing intro screen
- Update urge surfing prompts
- **Test:** All three tabs work correctly

### Task 11 — Module 2 thought examination
- Update `ModuleSessionScreen` prompts for `m2ThoughtExamination`
- Implement tap-to-select thinking error grid (Step 2)
- Implement draft behaviour
- Update counter-response save to Map format
- **Test:** Full 5-step flow, draft resume, library save

### Task 12 — Module 3 weekly compass
- Update `ModuleSessionScreen` prompts for `m3WeeklyCompass`
- Implement domain list with Toward/Away chips (Step 1)
- **Test:** All domains selectable, saves correctly

### Task 13 — `LapseRecordingFlow` redesign
- Implement 5-screen flow
- "I had a moment" button label and availability
- Update completion text
- Add "Update my coping plan" link
- **Test:** Full flow, recovery letter display, all data saved

### Task 14 — `RecoveryLetterScreen` changes
- Add AVE education intro screen
- Update letter prompts
- Update completion text
- **Test:** Intro shown once, letter saves correctly

### Task 15 — `LifestyleAuditScreen`
- Build screen
- Wire up from pending actions (monthly trigger)
- **Test:** Monthly trigger logic, saves correctly

### Task 16 — `RecoveryPathHomeScreen` changes
- Implement pending actions system
- Update module card subtitles and next-step prompts
- Update lapse button label
- Remove Premium badges
- **Test:** All action states surface correctly

### Task 17 — Habit card changes
- Remove streak display for breaking_habits
- Update check-in button
- Add action buttons row
- Add "I had a moment" text link
- Update Freedom Plan strip orange dot trigger
- **Test:** All card states, all button links

### Task 18 — `FreedomJourneyTab`
- Build new tab and wire into journal view
- My Journey chronological feed
- My Plan module-organised view with all 5 sections
- Pinned living documents
- State logic (locked/active/complete) per section
- **Test:** All session types appear correctly, pinned docs render, state transitions

### Task 19 — Notification changes
- Remove streak-referencing Cloud Functions
- Update weekly compass Cloud Function message
- Add zero-log weekly nudge local notification
- Update daily reminder message 1
- **Test:** Notifications fire at correct times, old functions removed

### Task 20 — Final integration testing
- Full end-to-end flow from habit setup through Day 90+
- Lapse flow at various stages (before M5 unlocked, after)
- Freedom Journey journal completeness
- Phase transitions at correct day counts
- All draft/resume scenarios

---

## 12. FILES CHANGED SUMMARY

| File | Action | Notes |
|---|---|---|
| `lib/domain/models/recovery_path.dart` | **Modify** | Add new fields to model and serialisation |
| `lib/domain/services/recovery_phase_calculator.dart` | **Replace** | New phase logic entirely |
| `lib/domain/services/cue_rubric_service.dart` | **New** | All 14 rubrics + habitType detection |
| `lib/presentation/views/habits/values_inventory_screen.dart` | **Modify** | Major changes |
| `lib/presentation/views/habits/module_session_screen.dart` | **Modify** | New M2 and M3 compass prompts |
| `lib/presentation/views/habits/recovery_path_home_screen.dart` | **Modify** | Pending actions, card changes |
| `lib/presentation/views/habits/guardrails_screen.dart` | **Modify** | Tab 1 replace, Tab 2 seeding, Tab 3 intro |
| `lib/presentation/views/habits/lapse_recording_flow.dart` | **Modify** | 5-screen redesign |
| `lib/presentation/views/habits/recovery_letter_screen.dart` | **Modify** | AVE intro, new prompts |
| `lib/presentation/views/habits/habit_check_in_card_view.dart` | **Modify** | Remove streak, new buttons |
| `lib/presentation/views/journal/journal_view.dart` | **Modify** | Add Freedom Journey tab |
| `lib/presentation/providers/recovery_path_provider.dart` | **Modify** | New methods |
| `lib/data/repositories/firestore_recovery_path_repository.dart` | **Modify** | New methods |
| `lib/presentation/views/habits/daily_check_in_screen.dart` | **New** | |
| `lib/presentation/views/habits/behaviour_log_screen.dart` | **New** | |
| `lib/presentation/views/habits/mid_point_reflection_screen.dart` | **New** | |
| `lib/presentation/views/habits/cue_hierarchy_screen.dart` | **New** | |
| `lib/presentation/views/habits/environmental_restructuring_screen.dart` | **New** | |
| `lib/presentation/views/habits/lifestyle_audit_screen.dart` | **New** | |
| `lib/presentation/views/journal/freedom_journey_tab.dart` | **New** | |
| `functions/src/callables/recovery_path_notify.ts` | **Modify** | Remove 4 functions, update 1 |

---

## 13. THINGS TO PRESERVE UNCHANGED

The following existing functionality must not be broken or altered:

- Accountability partner flow (`partner_invite_dialog.dart`, `partnership_detail_screen.dart`, `partner_acceptance_screen.dart`) — no changes
- `BreakingFreeIntroScreen` — no changes
- `AddHabitView` breaking free mode — no changes
- `AES-256 encryption` on all session `responseText` — preserve exactly
- `EncryptionService` — no changes
- All accountability partnership Cloud Functions — no changes
- `PendingPartnerTokenService` deep-link handling — no changes
- Non-breaking-habits abstain habits — these should be completely unaffected by all changes above. All changes are gated on `subcategoryId == 'breaking_habits'` or `habitType != null`.

---

*Cross-reference: Freedom_Plan_Design_Decisions.md · Freedom_Plan_Master_Timeline.md*  
*Existing codebase reference: freedom_plan_journey.md*
