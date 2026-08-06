# Freedom Plan Journey — Complete Implementation Reference

**Generated:** 2026-08-05  
**Codebase:** MyWalk Flutter app + Firebase Cloud Functions

---

## Table of Contents

1. [Overview](#1-overview)
2. [Entry Points — How Users Reach the Feature](#2-entry-points)
3. [Breaking Free Intro Screen](#3-breaking-free-intro-screen)
4. [Practice Setup — AddHabitView (Breaking Free mode)](#4-practice-setup)
5. [Post-Setup Flows](#5-post-setup-flows)
6. [Today Tab — Practice Card Strips](#6-today-tab-strips)
7. [Freedom Plan Home Screen](#7-freedom-plan-home-screen)
8. [Module 1 — Know Your Pattern](#8-module-1)
9. [Module 2 — Challenge Your Thinking](#9-module-2)
10. [Module 3 — Anchor to Your Values](#10-module-3)
11. [Module 4 — Build Your Guardrails](#11-module-4)
12. [Module 5 — Navigate Lapses](#12-module-5)
13. [Lapse Recording Flow](#13-lapse-recording-flow)
14. [Support/Accountability Partner Flow](#14-partner-flow)
15. [Phase Progression System](#15-phase-system)
16. [Notifications](#16-notifications)
17. [Data Model — Firestore Structure](#17-data-model)
18. [Named Routes](#18-routes)
19. [Provider & Repository Layer](#19-providers)

---

## 1. Overview

The Freedom Plan (internally also called "Recovery Path") is a structured, private, multi-phase programme attached to a **Breaking Patterns** practice (a special habit of tracking type `abstain`, subcategory `breaking_habits`). It is designed to help users break unwanted habits through:

- Daily awareness check-ins (Module 1)
- Cognitive reframing exercises (Module 2 — Premium)
- Values mapping and weekly compass (Module 3)
- Environmental guardrails and urge-surfing (Module 4 — Premium)
- Lapse navigation and resilience building (Module 5 — Premium)
- An optional voluntary accountability/support partner

All session responses are **AES-256 encrypted** before being written to Firestore. The path and its sessions are stored under `recovery_paths/{habitId}` in Firestore.

---

## 2. Entry Points

Users can reach the Breaking Free / Freedom Plan feature from three places:

### 2a. Practices Tab → Add Practice → Breaking Patterns category card

**File:** `lib/presentation/views/habits/add_habit_view.dart`

In Step 1 of the `AddHabitView` wizard there is a special grid card:

- **Label:** `'Breaking Patterns & Recovery/Freedom Plan'`
- **Colour:** `Color(0xFF922B2B)` (deep red)
- **Icon:** `Icons.shield_rounded`
- **On tap:** closes `AddHabitView` and pushes `BreakingFreeIntroScreen` via `MaterialPageRoute`

### 2b. Practices Tab → Add Practice → Subcategory picker for `breaking_habits`

If a user navigates into the category picker and selects a subcategory whose `id == 'breaking_habits'`, the same intercept fires: the view closes and `BreakingFreeIntroScreen` is pushed with the resolved `categoryModel` and `subcategoryModel`.

### 2c. Today Tab — Freedom Plan card strip

Once a Breaking Patterns practice exists, the Today card shows:

- **"Freedom Plan — Begin"** strip (purple) if no path has been started yet
- **"Freedom Plan · Phase N · Day N"** strip if already started

Tapping either opens the Freedom Plan Home Screen via:

```dart
Navigator.pushNamed('/recovery-path', arguments: {'habitId': ..., 'habitName': ...})
```

---

## 3. Breaking Free Intro Screen

**File:** `lib/presentation/views/practices/breaking_free_intro_screen.dart`  
**Class:** `BreakingFreeIntroScreen` (StatelessWidget)  
**AppBar title:** `'Breaking Free'`

### Screen content (verbatim)

**Hero icon:** `Icons.shield_rounded` in sage-coloured circle (72×72)

**Headline:** `'You were made for freedom.'`

**Verse (italic, gold):** `'It is for freedom that Christ has set us free.'`  
**Reference:** `'Galatians 5:1'`

**Three info blocks:**

| Icon | Title | Body |
|------|-------|------|
| `Icons.shield_rounded` (sage) | `'A daily practice'` | `'You will add a Breaking Free practice to your Today tab. Each day you check in — staying strong is the practice.'` |
| `Icons.handshake_rounded` (softGold) | `'An accountability partner'` | `'Invite someone to walk with you. They will be notified when you reach out for support.'` |
| `Icons.route_rounded` (purple `#8B7EC8`) | `'A recovery path'` | `'A guided programme to understand your patterns, anchor to your values, and build guardrails for lasting freedom.'` |

**CTA button:** `'Set up my Breaking Free practice'` (sage, full-width)

### What happens on CTA tap

1. If `categoryModel`/`subcategoryModel` were not passed in, the screen reads them from `HabitCategoryProvider` (looks up `caring_for_myself` / `breaking_habits`).
2. Opens `AddHabitView` as a `DraggableScrollableSheet` modal bottom sheet:
   - `initialChildSize: 0.9`, `maxChildSize: 0.95`, `minChildSize: 0.6`
   - `forBreakingFree: true` is passed
3. Awaits the result map from `AddHabitView`.
4. If result contains `'saved': true`, proceeds to post-setup flows (see §5).

---

## 4. Practice Setup — AddHabitView (Breaking Free mode)

**File:** `lib/presentation/views/habits/add_habit_view.dart`  
**Triggered with:** `forBreakingFree: true`

When this flag is set, `initState` skips steps 1 and 2 of the normal wizard and **goes directly to Step 3 (details form)** with these values pre-set:

| Field | Value |
|-------|-------|
| `_selectedCategory` | `HabitCategory.abstain` |
| `_trackingType` | `HabitTrackingType.abstain` |
| `_subcategoryId` | `'breaking_habits'` |
| `_categoryName` | `'Breaking Free'` |
| `_purposeStatement` | `'God made me for freedom.'` |

**AppBar title:** `'Set up Breaking Free Practice'`  
**Save button label:** `'Set this practice'`

### Fields shown (Step 3 for abstain/Breaking Free)

1. **Practice name** — free text field; label: `'Name your practice'` (e.g., "Gossip")

2. **Purpose statement** — pre-filled `'God made me for freedom.'`; editable.

3. **Fruit of the Spirit** — chip selection from the 9 fruits. For `abstain` category, defaults are `selfControl` and `faithfulness`.

4. **Notes** (optional) — multi-line text field.

5. **Reference URL** (optional) — link field.

6. **Day-of-week schedule** — which days the practice is active.

7. **Reminder time** — optional time picker.

8. **Support/Accountability Partner section:**
   - Header: `'Support/Accountability Partner'`
   - Description: `'Do you want to invite someone to walk with you? They can be notified when you need support.'`
   - Note: `'(You can set this up later if you don\'t want to now)'`
   - Two toggle chips: `'Yes'` / `'No'` — sets `_wantsPartner` bool.

9. **Recovery/Freedom Plan section:**
   - Header: `'Recovery/Freedom Plan'`
   - Description: `'A guided programme to understand your patterns, anchor to your values, and build guardrails.'`
   - Note: `'(You can set this up later if you don\'t want to now)'`
   - Two toggle chips: `'Yes'` / `'No'` — sets `_wantsRecoveryPath` bool.

10. **Coping plan chips** (when I feel tempted, I will…):
    - `'Pray first'`
    - `'Call a friend'`
    - `'Go for a walk'`
    - `'Read my verse'`
    - `'Journal it out'`

### On save

Calls `HabitProvider.addHabit(...)` then pops the sheet with:

```dart
{
  'saved': true,
  'habitId': habit.id,
  'habitName': habit.name,
  'wantsPartner': _wantsPartner,
  'wantsRecoveryPath': _wantsRecoveryPath,
}
```

The habit is saved to Firestore with:
- `subcategoryId: 'breaking_habits'`
- `categoryId: 'caring_for_myself'`
- `subcategoryName: 'Breaking Patterns'`
- `trackingType: HabitTrackingType.abstain`
- `hasRecoveryPath: false` (initially)

---

## 5. Post-Setup Flows

**File:** `lib/presentation/views/practices/breaking_free_intro_screen.dart` — `_startPractice()` method

After `AddHabitView` returns with `'saved': true`, two optional flows run sequentially:

### 5a. Partner invite (if `wantsPartner == true`)

Calls:
```dart
showPartnerInviteDialog(
  context,
  habitId: habitId,
  habitName: habitName,
  habitLabel: 'Breaking Patterns: $habitName',
)
```

See §14 for the full partner invite dialog flow.

### 5b. Freedom Plan confirmation (if `wantsRecoveryPath == true`)

Shows an `AlertDialog`:
- **Background:** `MyWalkColor.charcoal`
- **Title:** `'Freedom Plan Created'`
- **Body:** `'The Freedom Plan has been created for you. You can access it by tapping the "Freedom Plan" link in the practice card on your Today screen.'`
- **Action button:** `'OK'`

> **Note:** Despite the dialog saying "created", the `RecoveryPath` Firestore document is **not** created here. The dialog is informational only. The actual `startPath()` call happens when the user taps "Begin my Freedom Journey" on the Freedom Plan Home Screen (see §7).

After the dialog is dismissed:
- `NavigationProvider.switchToTab(0)` is called → Today tab becomes active
- `BreakingFreeIntroScreen` is popped

---

## 6. Today Tab — Practice Card Strips

**File:** `lib/presentation/views/habits/habit_check_in_card_view.dart`

Breaking Patterns cards appear on the Today tab with a distinctive layout. They are only rendered for habits with `trackingType == HabitTrackingType.abstain` and `!isRetroactive`.

### Card header

- **Title:** `'Breaking Patterns: {habitName}'`
- **No subtitle line** (purposeStatement suppressed for breaking_habits)
- **Fruit tags:** coloured name pills (e.g., "Self-Control", "Faithfulness")

### Check-in button

**Label:** `'Stayed strong today?'` (with `Icons.shield_rounded` icon)  
Retroactive version: `'Were you strong on {dayName}?'`

After checking in, the completed subtitle reads: `'I walked freely today ✓'`

### Partner strip (`_partnerStrip`)

Rendered **below** the check-in button.

| State | Display |
|-------|---------|
| No partnership | `'Add a support/prayer partner'` (with `+` icon) → taps `showPartnerInviteDialog` |
| Creating invite | `'Creating invite…'` (non-interactive) |
| Partnership pending | `'Waiting for partner…'` (hourglass icon, non-interactive) |
| Partnership active | `'Reach out to {partnerName}'` (handshake icon, sage, chevron right) → navigates to `/partnership-detail` |

### Freedom Plan strip (`_rpStrip`)

Rendered **below** the partner strip. Both strips only appear on abstain cards and not in retroactive mode.

| State | Display | Colour |
|-------|---------|--------|
| Path not started, habit not flagged | `'Freedom Plan — Begin'` + right chevron | Purple `#8B7EC8` |
| Path starting (loading) | Hidden (`SizedBox.shrink()`) | — |
| Path loaded, check-in pending today | `'Freedom Plan · Phase N · Day N'` + warm coral dot (7px) | Purple |
| Path loaded, caught up today | `'Freedom Plan · Phase N · Day N'` + right chevron | Purple |

Tapping any active state navigates to `/recovery-path`.

---

## 7. Freedom Plan Home Screen

**File:** `lib/presentation/views/habits/recovery_path_home_screen.dart`  
**Class:** `RecoveryPathHomeScreen`  
**Route:** `'/recovery-path'`  
**Arguments:** `Map<String, String>` — `{'habitId': ..., 'habitName': ...}`

### States

| State | What is shown |
|-------|--------------|
| Loading | `CircularProgressIndicator` in purple |
| Load error | `'Couldn\'t load your Recovery Path.\nCheck your connection.'` + `'Try again'` button |
| No path yet | `_BeginBody` |
| Path active | `_ActiveBody` |

---

### _BeginBody (Path not yet started)

- **Icon:** `Icons.route_rounded` in purple box
- **Title:** `'Start Your Freedom Journey'`
- **Body:** `'A structured, private programme to help you understand your patterns, anchor to what matters, and walk in lasting freedom.'`
- **Module preview list:** 5 `_ModulePreviewRow` widgets showing each module's emoji, title, and subtitle. Premium-only modules (M2, M4, M5) show a `'Premium'` badge if user is not subscribed.
- **Begin button:** `'Begin my Freedom Journey'` (purple, full-width, disabled while starting)

**On `'Begin my Freedom Journey'` tap — `_begin()` method:**
1. Calls `RecoveryPathProvider.startPath(habitId)` which:
   - Calls `FirestoreRecoveryPathRepository.startPath()` → creates `recovery_paths/{habitId}` document
   - Sets `module1.lastCheckInAt` to epoch so CF reminder fires immediately
   - Sets `m2NotifSent: false` sentinel field
   - Returns a `RecoveryPath` object
2. Calls `HabitProvider.updateHabit(habit.copyWith(hasRecoveryPath: true))` → updates the habit doc so the Today card knows a path exists
3. Schedules local daily reminder notifications (9:00 AM, IDs 200–206)

---

### _ActiveBody (Path started)

**Header line:** `'Day $day  ·  Phase $phase — {phaseLabel}'` in purple text

Phase labels:
- Phase 1: `'Awareness'`
- Phase 2: `'Understanding'`
- Phase 3: `'Anchoring'`
- Phase 4: `'Resilience'`

**"Today's focus" card:** shows the first pending module action. Tapping opens that module. When all modules are caught up: `'You\'re all caught up today'` card.

**Five module cards** (`_ModuleCard`):

| # | Format | When locked | When unlocked |
|---|--------|-------------|---------------|
| 1 | `'M1 — Know Your Pattern'` | Never locked | Check-in count subtitle |
| 2 | `'M2 — Challenge Your Thinking'` | Phase < 2 | Always available once unlocked |
| 3 | `'M3 — Anchor to Your Values'` | Never locked | Inventory/compass status |
| 4 | `'M4 — Build Your Guardrails'` | Phase < 3 | Always available once unlocked |
| 5 | `'M5 — Navigate Lapses'` | Phase < 4 | Always available once unlocked |

Locked modules: dimmed, `Icons.lock_outline` icon, no tap handler.  
Unlocked modules: chevron icon, tappable.

**M1 subtitle when unlocked:**
- `'$count/7 check-ins to unlock weekly review'` (if < 7 check-ins and weekly review not done)
- `'$count check-ins complete'` (if >= 7)

**M3 subtitle when unlocked:**
- `'Values inventory done'`
- `'Values inventory not yet done'`

**Lapse entry button** (very faint, below module list):
- Icon: `Icons.favorite_border`
- Label: `'Record a setback'`
- Opens `LapseRecordingFlow`

---

## 8. Module 1 — Know Your Pattern

**Metadata:** Emoji `🔍` · Phase 1 (always unlocked) · Free

### Daily Check-In

**Opened by:** `_openModule(1)` when `checkInDoneToday == false`  
**Screen:** `ModuleSessionScreen`  
**Session type:** `m1DailyCheckIn`  
**Title:** `'Daily Check-In'`  
**Hint:** `'Write freely — there\'s no wrong answer here.'`  
**Number of prompts:** 2 (selected deterministically by date from pool of 7)

**Prompt pool (7):**
1. `'What triggered the urge today, or what kept it away?'`
2. `'Rate your craving level right now (1–10). What do you notice in your body?'`
3. `'What emotion is most present right now? Where do you feel it?'`
4. `'What thought was playing on repeat today?'`
5. `'What helped you stay on track today, even a little?'`
6. `'What situation made your habit feel more tempting today?'`
7. `'What does your body need right now — rest, movement, connection, or something else?'`

**After saving:** `dailyCheckInCount` incremented, `lastCheckInAt` updated, `_checkInDoneToday` set to `true`.

**If check-in already done today (< 7 check-ins):**  
SnackBar: `'Daily check-in already done — come back tomorrow.'`

### Weekly Pattern Review

**Opened by:** `_openModule(1)` when `checkInDoneToday == true AND dailyCheckInCount >= 7`  
**Session type:** `m1WeeklyReview`  
**Title:** `'Weekly Pattern Review'`  
**Number of prompts:** 3

**Prompts:**
1. `'Looking at this week, what patterns do you notice in your triggers?'`
2. `'Which coping strategy worked best this week? What made it effective?'`
3. `'What changed this week — in stress, sleep, relationships, or routines?'`

**Unlock banner shown once:** `'You\'ve done 7 check-ins — your weekly Pattern Review is now unlocked.'`

### Module Session Screen (shared)

**File:** `lib/presentation/views/habits/module_session_screen.dart`

**UI elements:**
- Step dots row (pill = active/18px wide, dot = done/8px, purple)
- Prompt text (large)
- Multi-line text field
- Back button: previous step or pop
- Action button: `'Next'` (not last step) / `'Save reflection'` (last step)
- Button disabled when current text field is empty

**On save (`_save()`):**
1. Combines all prompt+answer pairs as `'{prompt}\n{answer}'` joined by `'\n\n'`
2. Creates `RecoverySession(id: '{habitId}_{sessionType}_{millis}')`
3. Calls `RecoveryPathProvider.saveSession(session)` → encrypts + writes to Firestore
4. Calls optional `onSaved(combinedText)` callback
5. Shows `_AffirmationView` for 2200ms, then pops

**_AffirmationView:**
- Purple check-circle icon
- Title: `'Saved'`
- Affirmation text (one of 7, selected deterministically by date):
  1. `'"He who began a good work in you will carry it on to completion." — Phil 1:6'`
  2. `'Every honest reflection is an act of courage.'`
  3. `'Progress isn\'t always visible — but it\'s always real.'`
  4. `'"I can do all this through him who gives me strength." — Phil 4:13'`
  5. `'You showed up today. That matters.'`
  6. `'Growth happens one honest moment at a time.'`
  7. `'"Come to me, all you who are weary and burdened, and I will give you rest." — Matt 11:28'`

---

## 9. Module 2 — Challenge Your Thinking

**Metadata:** Emoji `💡` · Phase 2 (unlocks at 7 check-ins) · **Premium**  
**File:** `lib/presentation/views/habits/module_session_screen.dart`  
**Session type:** `m2ThoughtExamination`  
**Title:** `'Challenge Your Thinking'`  
**Hint:** `'Think slowly — this is detective work, not self-criticism.'`  
**Number of prompts:** 5

**Prompts:**
1. `'What thought or belief was playing in your mind before or during the urge?'`
2. `'What evidence supports that thought? What evidence contradicts it?'`
3. `'If a close friend had this thought, what would you tell them?'`
4. `'What is a more balanced, truthful way to see this situation?'`
5. `'Write your counter-response: the statement you can return to next time.'`

### Counter-response save dialog

After saving, the `onSaved` callback shows a dialog:
- **Title:** `'Save to library?'`
- **Content:** the user's last answer (quoted)
- **Actions:** `'Skip'` (faint white) / `'Save'` (purple)
- If saved: `RecoveryPathProvider.addCounterResponse(habitId, response)` appends to `counterResponses` on the path doc, then SnackBar: `'Saved to your library.'`

---

## 10. Module 3 — Anchor to Your Values

**Metadata:** Emoji `⚓` · Phase 1 (always unlocked) · Free

### Values Inventory (first time)

**Opened by:** `_openModule(3)` when `valuesInventoryDone == false`  
**File:** `lib/presentation/views/habits/values_inventory_screen.dart`  
**Session type:** `m3ValuesInventory`

**Intro text (shown on step 0):**  
`'For each area of life, rate how important it is to you and how well you\'re living it right now. This isn\'t about judgement — it\'s about seeing where the gaps are.'`

**8 life domains (one per step after intro):**
1. `'Faith & Spiritual Life'`
2. `'Family & Close Relationships'`
3. `'Friendships & Community'`
4. `'Health & Physical Wellbeing'`
5. `'Work & Purpose'`
6. `'Personal Growth & Learning'`
7. `'Joy & Rest'`
8. `'Service & Contribution'`

**Per-domain UI:**
- Domain name (heading)
- Slider 1 — **Importance** (purple, 1–5): `'How important is this to you?'` — labels `'Not much'` ↔ `'Very much'`
- Slider 2 — **Alignment** (sage, 1–5): `'How well are you living it?'` — labels `'Not much'` ↔ `'Very much'`
- Gap callout (below sliders):
  - Gap = 0: `'You\'re living in alignment here.'` (sage-tinted)
  - Gap < 0: `'Living beyond what you value — that\'s also meaningful.'` (sage-tinted)
  - Gap > 0: `'Gap of {gap} — room to grow here.'` (purple-tinted)

**Navigation:** `'Next'` button (or `'Save my values map'` on final step); back button.

**On save:**
1. Calls `prov.saveValuesInventoryEntries(habitId, entries)` → writes inventory + sets `valuesInventoryDone = true` on path doc
2. Creates a session with text summary per domain: `'{domain}: importance={x}, alignment={y}, gap={z}'`
3. Calls `prov.saveSession(session)`
4. Shows `_CompletionView` for 2500ms then pops

**_CompletionView:**
- Anchor icon in purple circle
- Title: `'Values Map Saved'`
- Body: `'Your values map is saved. The gaps you see are not failures — they\'re the places where your walk can deepen.'`

### Weekly Values Compass (subsequent visits)

**Opened by:** `_openModule(3)` when `valuesInventoryDone == true AND compassDoneThisWeek == false`  
**Session type:** `m3WeeklyCompass`  
**Title:** `'Weekly Values Compass'`  
**Hint:** `'Reflect honestly — this is between you and God.'`  
**Number of prompts:** 3

**Prompts:**
1. `'Which value felt most alive this week?'`
2. `'Where did you fall short of your values? What got in the way?'`
3. `'What one action this week could bring you closer to living your values?'`

**If compass already done this week:**  
SnackBar: `'Weekly compass done — check back next week.'`

---

## 11. Module 4 — Build Your Guardrails

**Metadata:** Emoji `🛡` · Phase 3 · **Premium**  
**File:** `lib/presentation/views/habits/guardrails_screen.dart`  
**AppBar:** `'Build Your Guardrails'`

Three-tab layout: **Guardrails | HRS Plans | Urge Surfing**

### Tab 1 — Guardrails (Environmental Checklist)

Checklist content is **habit-name-sensitive** — determined by `RecoveryModuleContent.environmentalChecklistFor(habitName)`.

Pattern matching (case-insensitive substrings):
- `porn / pornography / lust / adult` → pornography-specific checklist
- `gambl / bet / casino` → gambling-specific checklist
- `alcohol / drink / beer / wine / spirits` → alcohol-specific checklist
- `drug / substance / smok / vap / nicotine` → substance/smoking checklist
- `social media / screen / phone` → screen-time checklist
- Anything else → generic 5-item checklist

**Generic checklist (5 items):** generic prompts about removing triggers, access, contacts, safety plans, and environmental cues.

**UI behaviour:**
- `CheckboxListTile` for each item (purple active color)
- `'Guardrails marked as done.'` banner (sage-tinted) if already saved
- Save button enabled only when `doneCount >= 2 AND !alreadySaved`
- Button labels: `'Check at least 2 items to continue'` / `'Mark guardrails as done'` / `'Already saved'`
- On save: calls `prov.markEnvironmentalChecklistDone(habitId)` + SnackBar `'Guardrails saved.'`

### Tab 2 — HRS Plans (High-Risk Situation Plans)

**Intro:** `'Plan for up to 5 situations you know are high risk. The more specific, the more useful.'`

Up to 5 `_PlanCard` forms, each with:
- `'Describe the situation'`
- `'What are the early warning signs?'`
- `'What will you do first?'`
- `'Who will you call?'`

Controls:
- **Add plan:** `'+ Add another plan'` TextButton (hidden at 5 plans)
- **Remove plan:** `×` button (hidden when only 1 plan remains)
- **Save:** `'Save plans'` → `prov.saveHrsPlan(habitId, plans)` → SnackBar `'Plans saved.'`
- Plans are seeded from `path.module4.hrsPlan` on open.

### Tab 3 — Urge Surfing

**Description:** `'Urges are waves. They peak and pass — usually within 20 minutes. Use this guided session to ride the wave without acting on it.'`

**Button:** `'Start urge surfing session'` → pushes `ModuleSessionScreen`:
- Session type: `m4UrgeSurfing`
- Title: `'Urge Surfing'`
- Hint: `'Describe what you\'re experiencing in your body and mind.'`
- Number of prompts: 3

**Prompts:**
1. `'Close your eyes. Notice where the urge lives in your body — chest, stomach, throat? Describe what you feel physically.'`
2. `'Urges are waves. They peak and then subside — usually within 20 minutes. What is the intensity right now, 1–10?'`
3. `'You don\'t have to act on this wave. Just ride it. What do you notice as you sit with the urge without giving in?'`

---

## 12. Module 5 — Navigate Lapses

**Metadata:** Emoji `🌱` · Phase 4 (unlocks after first lapse is recorded) · **Premium**

### Recovery Letter (first visit, M5 not yet done)

**File:** `lib/presentation/views/habits/recovery_letter_screen.dart`  
**Session type:** `m5RecoveryLetter`

**6-step flow:** Steps 0–3 (prompts) → Step 4 (preview) → Step 5 (done/auto-pop)

**Intro text (shown above Step 0 prompt):**  
`'This letter is from you to you — to be read the next time you\'re struggling. Write honestly. No one else will see this.'`

**4 prompts:**
1. `'What do you most want your future self to know about this struggle — the real, honest version?'`
2. `'What is still true about who you are, despite this habit? What have you not lost?'`
3. `'What has kept you going? What moment, verse, or person comes to mind?'`
4. `'What one thing do you want your future self to do the next time the urge hits?'`

**Navigation:** `'Next'` / `'Preview my letter'` (last prompt step); button disabled when field empty.

**Preview screen:**
- Label: `'Review your letter'`
- Body: `'This is how your answers come together. Edit if you wish, then save.'`
- Editable multi-line field showing stitched letter:

```
What I want you to know:
{answer 1}

What is still true:
{answer 2}

Come back to:
{answer 3}

Your next step:
{answer 4}
```

- Button: `'Save my letter'`

**On save:**
1. `prov.saveRecoveryLetterDraft(habitId, letter)` — stores plain text on path doc at `recoveryLetterDraft`
2. Creates `RecoverySession(sessionType: m5RecoveryLetter)` with same text
3. `prov.saveSession(session)` — **AES-256 encrypted** write to Firestore

**Done view (auto-pops after 2400ms):**
- Mail outline icon (purple)
- Title: `'Letter saved'`
- Body (italic): `'Your letter is saved. It will be shown to you during the lapse recording flow.'`

### Quarterly Maintenance Review (M5 letter already written)

**Session type:** `m5QuarterlyReview`  
**Title:** `'Quarterly Maintenance Review'`  
**Hint:** `'Be honest about both the gains and the losses.'`  
**Number of prompts:** 4

**Prompts:**
1. `'Looking back over the past 90 days — what has changed in you?'`
2. `'Where have you been most vulnerable? What patterns have you noticed?'`
3. `'What has your faith shown you through this season?'`
4. `'What is one specific thing you want to change or strengthen in the next 90 days?'`

---

## 13. Lapse Recording Flow

**File:** `lib/presentation/views/habits/lapse_recording_flow.dart`  
**Opened from:** `RecoveryPathHomeScreen` lapse button  
**Session type:** `lapseRecord`  
**AppBar:** `'Getting back up'`

**Support message shown at top of screen:**  
`'A setback is not the end of your story. It\'s a moment that can teach you more than ten good days. Take a breath. You\'re still here. Let\'s look at what happened.'`

### Step 0 — Self-Compassion ("Take a breath")

- `_LetterCard` widget shows the user's recovery letter if `recoveryLetterDraft` is set on the path, otherwise the fallback scripture:

  **Fallback letter text:**  
  `'"My grace is sufficient for you, for my power is made perfect in weakness." — 2 Cor 12:9\n\nYou are still here. The fact that you opened this app tells you something about who you are. Come back to your why. This is not your final chapter.'`

  If recovery letter exists: shown in a card labeled `'Your recovery letter'` with mail icon.

- **Step 0 prompt:** `'Take a moment before we look at what happened. What do you need to hear right now?'`
- **Button:** `'I\'m ready — let\'s look at what happened'`

### Step 1 — Forensic Analysis ("What happened?")

- **Title:** `'What happened?'`
- **Body:** `'Walk through the moment honestly — no self-condemnation, just understanding.'`
- **3 bullet sub-prompts:**
  - `'• What was going on in the hours before?'`
  - `'• What thought or feeling pushed you over the edge?'`
  - `'• What could you do differently next time at that exact moment?'`
- **Free-text field:** hint `'Write freely — no judgement here.'`
- **Quick capture section** (4 mini-fields):
  - `'Time (approx.)'`
  - `'Where were you?'`
  - `'What triggered it?'`
  - `'Emotional state before'`
- **Button:** `'Continue'`

### Step 2 — Re-orientation ("Back on the path")

- **Title:** `'Back on the path'`
- If M3 values inventory is done: shows the top-gap domain (highest `importance - alignment`) in a sage-tinted card with anchor icon:
  `'Your anchor value: {topDomainName}'`
- **Prompt:** `'You\'re not starting over — you\'re continuing. What is one thing you will do in the next hour to re-anchor yourself?'`
- **Text field:** hint `'One specific thing…'`
- **Button:** `'Save and get back up'`

### On save (`_save()`)

1. Combines: `'What happened:\n{analysisText}\n\nRe-orientation:\n{reorientText}'`
2. Creates `LapseData(time, location, trigger, emotion)` from the 4 quick-capture fields
3. Creates `RecoverySession(sessionType: lapseRecord, moduleNumber: 5, lapseData: lapseData)`
4. Calls `prov.saveSession(session)`:
   - Increments `totalLapses` on path
   - Updates `lastLapseAt`
   - Triggers `_maybeWriteBackPhase()` → if `totalLapses > 0`, sets phase to 4 (Resilience)
5. Shows `_CompletionView` for 2800ms then pops

**_CompletionView:**
- Heart/favourite icon (purple)
- Title: `'You did it'`
- Body: `'You did the hard thing — you faced it honestly. That\'s what recovery looks like.'`

### Phase promotion via lapse

After the first lapse is saved, `RecoveryPhaseCalculator.calculate()` returns 4 (Resilience). `_maybeWriteBackPhase()` writes this back to Firestore. The `rpLapseUnlocksM5` Cloud Function (Firestore trigger) then sends a push notification: `'Module 5 is unlocked'`.

---

## 14. Support/Accountability Partner Flow

### Inviting a partner

**File:** `lib/presentation/utils/partner_invite_dialog.dart`  
**Function:** `showPartnerInviteDialog(context, {habitId, habitName, habitLabel?})`

Called from:
- `BreakingFreeIntroScreen._startPractice()` (with `habitLabel: 'Breaking Patterns: $habitName'`)
- `_partnerStrip()` in `HabitCheckInCardView` (with same label for breaking_habits)
- `EditHabitView._inviteRow()` (with label for breaking_habits)

**Dialog — "Invite a support partner":**
- **Background:** `MyWalkColor.charcoal`
- **Title:** `'Invite a support partner'`

- **Section heading 1 (sage, bold):** `'If you know their MyWalk email address:'`
- **Description:** `'Enter it below and they will receive an in-app notification immediately.'`
- **Email field:** hint `'their@email (optional)'`

- **Divider**

- **Section heading 2 (sage, bold):** `'If you don\'t know their email address:'`
- **Description:** `'Just tap Continue and a link will be created that you can share via WhatsApp, Email or SMS.'`

- **Buttons:** `'Cancel'` (faint) / `'Continue'` (sage)

**After tapping Continue — `createInvite` call:**

Calls `AccountabilityProvider.createInvite(habitId, habitName, habitLabel?, recipientEmail?)` → calls Cloud Function `accountabilityCreateInvite`.

**Result handling:**

| Scenario | What happens |
|----------|-------------|
| `inAppSent == true` | SnackBar: `"Invitation sent! They'll see it in their MyWalk notifications. Share code as backup: {shortCode}"` |
| `inAppSent == false`, email provided | "No account found" dialog → `'Cancel'` or `'Share link'` → opens share sheet |
| `inAppSent == false`, no email | Opens share sheet immediately |

**Share sheet message:**

```
Please walk with me on my {habitLabel} journey.

IF YOU ALREADY HAVE MYWALK ON YOUR MOBILE:

1) Tap this link: {shareUrl}

Or

2) Tap on the Notifications Bell at the top on the app screen and then on the 
   "Have an Invite Code?" card and enter this code: {shortCode}


IF YOU DON'T HAVE MYWALK INSTALLED ON YOUR MOBILE:

Download it from the Google Play Store or Apple Store.

Then either:

1) Come back to this email and tap this link: {shareUrl}

Or

2) Tap on the Notifications Bell at the top on the app screen and then on the 
   "Have an Invite Code?" card and enter this code: {shortCode}
```

Share URL format: `https://mywalk.faith/accountability/accept/{inviteToken}`

---

### Accepting a partner invite

**File:** `lib/presentation/views/habits/partner_acceptance_screen.dart`  
**Class:** `PartnerAcceptanceScreen`  
**Route:** Pushed from `ContentView` via `PendingPartnerTokenService` (deep-link or notification tap)

Deep-link patterns handled in `root_view.dart`:
- `mywalk://accountability/accept?token=TOKEN`
- `https://mywalk.faith/accountability/accept/{token}`

**States:**

| State | Display |
|-------|---------|
| Loading | Golden spinner |
| Own invite | `'This is your own invite link. Share it with a friend to invite them as your prayer partner.'` |
| Not found / expired | `'This invite link is no longer valid.'` |
| Generic error | `'Something went wrong. Please try again.'` |
| Valid invite | `_inviteState` |
| Done | `_doneState` |

**_inviteState:**
- Sage handshake icon
- `'{ownerDisplayName} wants you to walk with them'`
- `'Habit: {habitName}'`
- Legal disclaimer card titled "Before you accept":
  ```
  By accepting, you agree to:
  
  • Receive messages from {name} through MyWalk when they need support.
  
  • Keep the contents of your conversations private and confidential.
  
  • Understand that this is a voluntary support relationship, not a professional 
    counselling or crisis service. If you or {name} are in immediate danger, 
    contact emergency services.
  
  Either person can end this partnership at any time.
  ```
- **Buttons:** `'Accept'` (sage, full-width) / `'Decline'` (faint text)

**_doneState (accepted):**
- Check-circle icon (sage)
- `'You\'re walking together'`
- `"You'll be notified when {ownerName} reaches out."`
- `'Done'` button (pops)

**_doneState (declined):**
- Cancel icon (faint)
- `'Invite declined'`
- `'You can always connect with people in your Prayer Groups.'`
- `'Done'` button

---

### Partner messaging

**File:** `lib/presentation/views/habits/partnership_detail_screen.dart`  
**Route:** `'/partnership-detail'` (argument: `AccountabilityPartnership`)

Reached by tapping `'Reach out to {partnerName}'` on the Today card.

**AppBar:** partner name (line 1) + habit name (line 2, faint) + `'Back'` in golden

**Actions menu:** `'End partnership'` / `'Leave partnership'` (coral)

Confirmation dialog:
- Title: `'End partnership?'`
- Body: `'This will end your accountability partnership with {partnerName}. Messages will no longer be visible.'`
- Buttons: `'Cancel'` / `'End'`

**Message thread:**

Empty state:
- Handshake icon
- `'You and {partnerName} are walking together.'`
- `'Send your first message below.'`

Messages:
- Grouped by date chips: `'Today'`, `'Yesterday'`, `'Jan'`, `'Feb'`, etc.
- My messages: right-aligned, sage-tinted bubble
- Their messages: left-aligned, faint white bubble
- Time shown below each bubble

**Compose bar:**
- Hint: `'Share what\'s on your heart…'`
- Max 500 characters
- Remaining count shown when < 80 remaining (coral when < 30)
- Send: circular sage button with `Icons.send_rounded`

**Ended partnership banner:**
- `'This partnership has ended.'`
- `'The invitation was declined.'`
- `'This invitation was cancelled.'`

Auto-scrolls to bottom on new messages. Uses live partnership stream so status changes update immediately.

---

### Cloud Functions — Partnership (from `functions/src/callables/accountability.ts`)

| Function | Behaviour |
|----------|-----------|
| `accountabilityCreateInvite` | Blocks if active partnership exists for habit. Cancels any existing pending invite. Creates partnership doc with UUID `inviteToken` + 6-char `shortCode`. If recipient email → in-app `partnership_invite` notification + push nudge. Returns `{partnershipId, shareUrl, shortCode, inAppSent}`. |
| `accountabilityAcceptInvite` | Finds pending doc by token. Updates: `status→active`, `partnerId`, `partnerDisplayName`, `participantIds (arrayUnion)`, `acceptedAt`. Writes `partnership_accepted` in-app notification + push to owner. Notification: label `'SUPPORT PARTNER ACCEPTED'`, title `'{partnerName} · {habitLabel}'`, body `'{partnerName} accepted your support partner invite for your "{habitLabel}" practice'`. Push: `'{partnerName} accepted your support partner invite'`. |
| `accountabilityDeclineInvite` | Updates `status→declined`. Push to owner. |
| `accountabilityEndForHabit` | Ends active (`status→ended`) + cancels pending (`status→cancelled`) partnerships for the habit. Notifies active partners in-app + push. Called with `reason: 'deleted'` or `'archived'`. |
| `accountabilityNotifyParticipant` | Sends `partner_message` in-app notification + push to the other participant. Fire-and-forget. |

---

## 15. Phase Progression System

**File:** `lib/domain/services/recovery_phase_calculator.dart`

### Phase calculation rules (evaluated in priority order)

| Phase | Label | Condition |
|-------|-------|-----------|
| 4 | Resilience | `totalLapses > 0` |
| 3 | Anchoring | `dailyCheckInCount >= 7 AND valuesInventoryDone == true` |
| 2 | Understanding | `dailyCheckInCount >= 7` |
| 1 | Awareness | Default (always) |

### Module unlock rules

| Module | Unlocks at |
|--------|-----------|
| M1 — Know Your Pattern | Always unlocked |
| M2 — Challenge Your Thinking | Phase ≥ 2 (7 check-ins done) |
| M3 — Anchor to Your Values | Always unlocked |
| M4 — Build Your Guardrails | Phase ≥ 3 (7 check-ins + values inventory done) |
| M5 — Navigate Lapses | Phase ≥ 4 (first lapse recorded) |

### Day number

`dayNumberFor(habitId)` = `(DateTime.now().difference(path.startedAt).inDays) + 1`

### Phase write-back

`RecoveryPathProvider._maybeWriteBackPhase()` recalculates phase after every session save. If the calculated phase differs from `path.currentPhase`, it calls `_repo.updatePath(path.copyWith(currentPhase: newPhase))` automatically.

---

## 16. Notifications

### Local notifications (scheduled on device)

**Scheduled by:** `RecoveryPathProvider.startPath()` → `NotificationService.shared.scheduleRecoveryPathReminder()`  
**IDs:** 200–206 (one per day of week)  
**Default time:** 9:00 AM  
**Android channel:** `'recovery_path_reminder'` / `'Recovery Path Reminders'`

7 rotating messages (one per weekday, deterministic):
1. `'Your daily check-in is waiting — a few minutes keeps your progress going.'`
2. `'Take a moment today for your Recovery Path check-in.'`
3. `'Small daily steps lead to lasting change — check in when you\'re ready.'`
4. `'Your Recovery Path check-in is here whenever you need it.'`
5. `'A brief reflection today keeps momentum on your recovery journey.'`
6. `'Check in with yourself — your Recovery Path is ready.'`
7. `'Today\'s check-in is a gift to your future self.'`

**Cancelled by:** `NotificationService.shared.cancelRecoveryPathReminder()` (called when path deleted)

---

### Cloud Function push notifications (from `functions/src/callables/recovery_path_notify.ts`)

All push notifications use `channel: 'partnerships'` (Android FCM channel).  
FCM tokens fetched from `users/{uid}.fcmToken`.

| Function | Schedule | Query | Push title | Push body |
|----------|----------|-------|-----------|-----------|
| `rpDailyCheckInReminder` | Daily 09:00 UTC | `module1.lastCheckInAt < startOfToday` | `'Your daily check-in is waiting'` | `'A few minutes of reflection keeps your streak going — tap to continue.'` |
| `rpMissed3DaysReminder` | Daily 10:00 UTC | `module1.lastCheckInAt < threeDaysAgo` (filters: `startedAt >= threeDaysAgo`) | `'It\'s been a few days'` | `'Recovery isn\'t about a streak — it\'s about coming back. A check-in takes 2 minutes.'` |
| `rpWeeklyCompassReminder` | Monday 08:00 UTC | `module3.valuesInventoryDone == true` | `'Time for your weekly values compass'` | `'A quick 3-question check-in to keep your values front and centre.'` |
| `rpLapseUnlocksM5` | Firestore trigger (session create) | `sessionType == 'lapseRecord' AND path.totalLapses == 0` | `'Module 5 is unlocked'` | `'Navigate Lapses is now available on your Recovery Path. You\'re not alone.'` |
| `rpQuarterlyReviewReminder` | Daily 11:00 UTC | `startedAt >= 91DaysAgo AND < 90DaysAgo` | `'90 days on your Recovery Path'` | `'Time for your quarterly review — reflect on how far you\'ve come.'` |
| `rpM2UnlockReminder` | Daily 09:30 UTC | `module1.dailyCheckInCount >= 7 AND m2NotifSent == false` | `'Module 2 is unlocked'` | `'Challenge Your Thinking is now available — a powerful next step.'` — then sets `m2NotifSent: true` |

---

## 17. Data Model — Firestore Structure

### `recovery_paths/{habitId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | String | = habitId |
| `userId` | String | |
| `habitId` | String | |
| `startedAt` | Timestamp | Set on `startPath()` |
| `currentPhase` | int | 1–4, written back by `_maybeWriteBackPhase` |
| `module1` | Map | See below |
| `module3` | Map | See below |
| `module4` | Map | See below |
| `module5` | Map | See below |
| `totalLapses` | int | Incremented per lapse session |
| `lastLapseAt` | Timestamp? | |
| `recoveryLetterDraft` | String? | Plain text (not encrypted) |
| `counterResponses` | List\<String\> | M2 saved counter-responses |
| `m2NotifSent` | bool | CF sentinel; written by `startPath`, cleared by CF |

**`module1` map:**

| Field | Type | Notes |
|-------|------|-------|
| `dailyCheckInCount` | int | Total lifetime check-ins |
| `lastCheckInAt` | Timestamp | Epoch on creation; updated each check-in |

**`module3` map:**

| Field | Type | Notes |
|-------|------|-------|
| `valuesInventoryDone` | bool | |
| `valuesInventory` | List\<Map\> | One per domain: `{domain, importance, alignment}` |
| `lastCompassAt` | Timestamp? | |

**`module4` map:**

| Field | Type | Notes |
|-------|------|-------|
| `environmentalChecklistDone` | bool | |
| `hrsPlan` | List\<Map\> | Each: `{situation, earlyWarnings, firstResponse, contactName}` |
| `urgeSurfingCount` | int | |

**`module5` map:**

| Field | Type | Notes |
|-------|------|-------|
| `recoveryLetterWritten` | bool | |
| `quarterlyReviewCount` | int | |

---

### `recovery_paths/{habitId}/recovery_sessions/{sessionId}`

Session ID format: `'{habitId}_{sessionType}_{millisSinceEpoch}'`

| Field | Type | Notes |
|-------|------|-------|
| `habitId` | String | |
| `sessionType` | String | Enum name (e.g., `'m1DailyCheckIn'`) |
| `moduleNumber` | int | |
| `responseText` | String | **AES-256 encrypted** via `EncryptionService` |
| `createdAt` | Timestamp | |
| `lapseData` | Map? | Only for `lapseRecord` sessions |

**`lapseData` map (lapseRecord only):**

| Field | Type |
|-------|------|
| `time` | String? |
| `location` | String? |
| `trigger` | String? |
| `emotion` | String? |

**Valid `sessionType` values:**
`m1DailyCheckIn`, `m1WeeklyReview`, `m2ThoughtExamination`, `m3ValuesInventory`, `m3WeeklyCompass`, `m4UrgeSurfing`, `m5RecoveryLetter`, `m5QuarterlyReview`, `lapseRecord`

---

### `accountability_partnerships/{partnershipId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | String | UUID, = doc ID |
| `ownerId` | String | |
| `ownerDisplayName` | String | |
| `partnerId` | String? | Set on accept |
| `partnerDisplayName` | String? | Set on accept |
| `habitId` | String | |
| `habitName` | String | |
| `habitLabel` | String | e.g., `'Breaking Patterns: Gossip'` |
| `status` | String | `pending`, `active`, `declined`, `cancelled`, `ended` |
| `inviteToken` | String | UUID |
| `shortCode` | String | 6-char uppercase, for manual entry |
| `participantIds` | List\<String\> | `[ownerId]` → `[ownerId, partnerId]` on accept |
| `createdAt` | Timestamp | |
| `acceptedAt` | Timestamp? | |
| `lastMessagePreview` | String? | Truncated to 80 chars + `'…'` |
| `lastMessageAt` | Timestamp? | |

---

### `accountability_partnerships/{partnershipId}/partner_messages/{msgId}`

| Field | Type |
|-------|------|
| `partnershipId` | String |
| `senderId` | String |
| `senderDisplayName` | String |
| `body` | String |
| `sentAt` | Timestamp (serverTimestamp) |
| `isRead` | bool |

---

### `users/{uid}/notifications/{notifId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | String | UUID |
| `type` | String | `partnership_invite`, `partnership_accepted`, `partner_message` |
| `senderUid` | String | |
| `senderName` | String | |
| `circleId` | String | = partnershipId |
| `circleName` | String | = habitLabel (e.g., `'Breaking Patterns: Gossip'`) |
| `message` | String | Human-readable body |
| `partnerInviteToken` | String? | Only for `partnership_invite` |
| `isRead` | bool | |
| `suppressActions` | bool | `false` for invite, `true` for others |
| `createdAt` | Timestamp | |

---

## 18. Named Routes

**File:** `lib/app.dart` — `MyWalkApp.onGenerateRoute`

| Route | Argument type | Destination |
|-------|--------------|-------------|
| `'/recovery-path'` | `Map<String, String>` (`habitId`, `habitName`) | `RecoveryPathHomeScreen` |
| `'/partnership-detail'` | `AccountabilityPartnership` | `PartnershipDetailScreen` |

**MaterialPageRoute pushes (not named routes):**
- `BreakingFreeIntroScreen` — pushed from `AddHabitView`
- `ModuleSessionScreen` — pushed from `RecoveryPathHomeScreen._openModule()`
- `ValuesInventoryScreen` — pushed from `RecoveryPathHomeScreen._openModule(3)`
- `GuardrailsScreen` — pushed from `RecoveryPathHomeScreen._openModule(4)`
- `RecoveryLetterScreen` — pushed from `RecoveryPathHomeScreen._openModule(5)`
- `LapseRecordingFlow` — pushed from `RecoveryPathHomeScreen._openLapseFlow()`
- `PartnerAcceptanceScreen` — pushed from `ContentView` on deep-link/notification

---

## 19. Provider & Repository Layer

### Registration (`lib/main.dart`)

```dart
final recoveryPathRepository = FirestoreRecoveryPathRepository();

Provider<RecoveryPathRepository>.value(value: recoveryPathRepository),
ChangeNotifierProvider<RecoveryPathProvider>(
  create: (_) => RecoveryPathProvider(recoveryPathRepository),
),

Provider<AccountabilityRepository>.value(value: accountabilityRepository),
ChangeNotifierProvider<AccountabilityProvider>(
  create: (_) => AccountabilityProvider(accountabilityRepository),
),

ChangeNotifierProvider<NavigationProvider>(
  create: (_) => NavigationProvider(),
),
```

### `RecoveryPathProvider` key methods

| Method | What it does |
|--------|-------------|
| `loadPath(habitId)` | Loads from Firestore; refreshes daily/weekly status flags; triggers phase write-back |
| `startPath(habitId)` | Creates Firestore doc; sets `habit.hasRecoveryPath = true`; schedules local reminders |
| `saveSession(session)` | Encrypts + writes session; updates in-memory path state; triggers phase write-back |
| `phaseFor(habitId)` | `RecoveryPhaseCalculator.calculate(path)` |
| `dayNumberFor(habitId)` | `(now - startedAt).inDays + 1` |
| `isModuleUnlocked(habitId, moduleNumber)` | Based on phase; M1/M3 always unlocked |
| `checkInDoneToday(habitId)` | Queried fresh on load; updated optimistically on session save |
| `compassDoneThisWeek(habitId)` | Same |

### `FirestoreRecoveryPathRepository` collections

| Reference | Firestore path |
|-----------|---------------|
| `_paths` | `recovery_paths` |
| `_sessions(habitId)` | `recovery_paths/{habitId}/recovery_sessions` |

All session reads decrypt via `EncryptionService.decryptField(encrypted, uid)`.  
All session writes encrypt via `EncryptionService.encryptField(text, uid)`.

---

*End of document.*
