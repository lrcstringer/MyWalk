# Freedom Plan — Design Decisions Working Document

**Purpose:** Running record of all agreed design decisions as we work through the plan phase by phase. Updated incrementally as decisions are made.

---

## GLOBAL DECISIONS

| # | Decision | Notes |
|---|---|---|
| G1 | All user input is recorded in the Journal | No separate data capture outside the journal |
| G2 | The Journal needs a dedicated Freedom Plan section | Fully designed — see Journal section below. Two sub-views: "My Journey" (chronological) and "My Plan" (module-organised). |
| G3 | Feature is named "Walking Free" | Positive framing, not "Breaking Habits" |
| G4 | Button label for behaviour capture is **"Log a moment"** | Not "Record Behaviour" — avoids clinical/accusatory tone |
| G5 | "Log a moment" is available from Day 2 and continues through all phases unchanged | Never removed, never replaced. Always available on the habit card. |
| G6 | **"I had a moment" button is available from Day 1** | Not from Day 30. A lapse can happen at any time. If Module 5 is not yet unlocked when tapped, it unlocks immediately and runs AVE education + recovery letter first before the lapse protocol. |
| G7 | **Draft and resume policy across all multi-step flows** | See full policy below. |
| G8 | **Push notification policy** | Weekly compass nudge, zero-log weekly nudge, and high-risk period check-ins are in-app prompts only — not push notifications. The only push notification in the Walking Free plan is the accountability partner message notification (already implemented). Milestone tasks (Cue Hierarchy, module unlocks) are surfaced in-app on Today card and Freedom Journey tab — never pushed. |

### Draft and resume policy (G7)

| Flow | Draft behaviour |
|---|---|
| Values Inventory (8 domains) | Save progress per domain. Resume from where the user left off. Never start over — the written content is too valuable to lose. |
| Cue Hierarchy (5 stages) | Save progress per stage. Resume from current stage. |
| HRS Coping Plans (per cue) | Save each completed cue card. Resume from next incomplete cue. |
| Thought examination (5 steps) | Save progress per step. Resume from current step. Prompt on Today card: *"Resume your thought examination."* |
| Lapse response protocol (5 screens) | **Do not auto-resume.** If the user closes mid-flow, on next open surface a gentle prompt: *"It looks like you were working through something earlier. Do you want to continue?"* Yes resumes; No discards. Reason: the lapse protocol is a time-critical emotional intervention — a cold resume the next morning may do more harm than good if the emotional moment has passed. |

---

## PHASE 1 — WEEK 1: Values Inventory + Behaviour Logging Begins

### Week 1, Task 1 — Values Inventory Screen

**Purpose:** Make the invisible visible — establish what each life domain genuinely means to the user before anything else. The data gathered here (importance vs alignment gaps) becomes the motivational foundation for the whole plan.

**Structure:** One screen per life domain (8 domains total), paged with a progress indicator (as per current implementation).

**The 8 Life Domains:**
1. Faith & Spiritual Life
2. Intimate relationship / partnership
3. Family and parenting
4. Friendship and social connection
5. Work, career, and contribution
6. Personal growth and learning
7. Health and physical wellbeing
8. Creative expression and leisure

**Each domain screen contains:**

| Element | Detail |
|---|---|
| **Question 1 — open text** | *"In your own words, what does [domain] mean in your life, and what would living it well look like for you?"* |
| **Slider 1** | "How important is this to you?" (1–10, Not much → Very much) |
| **Slider 2** | "How well are you currently living it?" (1–10, Not much → Very much) |
| **Feedback line** | Dynamic text based on gap between sliders (e.g., "You're living in alignment here" / "There's a meaningful gap here") |
| **Compass selector** | *"Does your current pattern move you toward or away from this?"* — three options: **Toward / Neutral / Away** |

**Decisions:**
- ~~Question 4 (optional action for the coming week)~~ — **Dropped.** Keeps day-one simple; avoids feeling like homework before the user understands the process.
- The open-text question uses a single combined prompt (not two separate prompts) for cleaner mobile UX.
- The tone throughout is non-judgemental: *"This isn't about judgement — it's about seeing where the gaps are."*
- The "Connect values to habit" exercise (originally planned as a separate Week 2 task) is **collapsed into the Week 1 domain screens** as the compass selector. This removes the need for a separate step and makes the values-to-habit connection immediate and personal.
- ~~"Top five values" selection~~ — **Dropped.** Arbitrary, creates unnecessary friction, and the compass selector already identifies which values are most motivationally alive (those marked "Away" with high importance scores).

**Compass selector — UI rules:**
- No option is pre-selected. The user must make a real, deliberate choice.
- "Neutral" is a fully valid, non-stigmatised answer — positioned visually as equal to the other options, not as a lesser or evasive choice.
- The app never challenges or questions the user's selection. No "are you sure?" prompts.

**Edge case — no domains marked "Away":**
This is valid and must be handled gracefully. Two honest reasons this can happen: (1) the user genuinely experiences little values conflict with this habit, or (2) they are not yet fully honest with themselves — which is normal and common at this stage. The app does not push back either way.

The completion text after the inventory adapts accordingly:
- **If one or more domains marked "Away":** *"You can see where this pattern is pulling against what matters to you. That's your compass — not a judgement, just information."*
- **If none marked "Away":** *"You've mapped what matters to you. As you work through this journey, this is your compass — the life you're building toward."*

The values still serve their full purpose (orientation, identity, committed action) in both cases. The weekly compass check later in the plan will surface any drift more honestly than a day-one self-assessment always can.

---

### Week 1, Task 1 — Values Inventory: resume behaviour
If the user closes the app mid-inventory (e.g. after completing 4 of 8 domains), progress is saved per domain. On next open, the inventory resumes from the last incomplete domain. The user never has to start over — the written content in completed domains is preserved.

---

### Week 1, Task 1 — Values Inventory: journal output
The 8 domain responses are saved as **one combined pinned document** — not 8 separate journal entries. Displayed in the Journal under ⚓ Anchor to Your Values as "My Values Inventory" showing all 8 domains with their ratings, written reflections, and compass selections. One document, always editable.

Reason: 8 separate entries on Day 1 would clutter the "My Journey" feed and misrepresent the inventory as multiple events rather than one foundational exercise.

---

### Module 3 — Committed Action (ongoing from Day 1)

**What it is:** For each value domain, identifying one concrete "do" action — not "don't do" — that moves toward that value this week. This is the behavioural component of Module 3, not just reflective.

**How it works in the app:** Committed action is captured as part of the weekly compass check — not a separate flow. The compass check screen includes one field at the end: *"What is one concrete thing you will do this week that moves toward what matters most to you?"* Free text, one sentence is enough.

This keeps committed action lightweight and recurring rather than a one-time exercise, and avoids adding a separate task to an already full Day 1.

Stored as part of each "Values compass" journal entry — not a separate entry type.

---

### Module 1 — Daily Check-in (designed)

**What it is:** A lightweight daily prompt distinct from "Log a moment." The daily check-in maintains ongoing awareness and feeds the Phase 2 unlock condition (14 check-ins logged).

**How it surfaces:** An orange dot on the Recovery Path entry point on the Today card if no check-in has been logged today.

**Two questions only:**
1. *"How are you doing emotionally today?"* — slider 1–10 (Not great → Really well)
2. *"Did you encounter your pattern today?"* — three options: **Yes, I slipped / I felt the urge but didn't act / No, clear day**

That's it. 30 seconds maximum. The daily check-in is not a journalling prompt — it's a data signal and a moment of self-awareness. If the user selects "Yes, I slipped" it surfaces a gentle prompt: *"Do you want to log what happened?"* which opens "Log a moment" pre-filled. If they select "I felt the urge but didn't act" it surfaces: *"Do you want to examine the thought that came up?"* which opens the thought examination flow.

**Stored:** Under 🔍 Know Your Pattern with label "Daily check-in." The emotional rating and outcome are stored as structured data (not just text) so the daily check-in count can drive the Phase 2 unlock condition.

---

### Module 3 — Weekly Compass Check (UX design)

**When:** Weekly from Day 7. Surfaced as an in-app prompt on the Today card — not a push notification.

**Screen flow — three simple steps:**

**Step 1 — Toward or away?**
The user's values from the inventory are shown as a list (domain names only, compact). For each, a simple two-option tap: **→ Toward** or **← Away**. Fast, takes 60 seconds.

**Step 2 — One course correction**
Single text field: *"Where the compass is pointing away — what's one small thing you could do differently this week?"* One sentence is enough.

**Step 3 — Committed action**
Single text field: *"What is one concrete thing you will do this week that moves toward what matters most to you?"*

Total time: 3–5 minutes. Stored under ⚓ Anchor to Your Values with label "Values compass."

**Trigger:** User completes the final domain screen and taps Next/Done.

**Flow:**
1. **Short celebratory dialog** — warm, affirming, brief. e.g.: *"Fantastic — that's the first piece done, and it's foundational to everything that follows."* + a Done/Continue button.
2. **Separate "What happens next" screen** — scrollable, not crammed into the dialog. Explains the behaviour logging task for the coming week.

**Content of the "What happens next" screen:**

> For the next six days there's nothing required except to keep a brief record of any time you slip into the pattern you're working on — or even if you felt a strong urge but didn't act on it.
>
> We're not keeping a record of guilt or wrongs here. We're starting to gather the data we need to see whether there are any patterns — cues that tend to trigger this behaviour — so we can start doing something about them.
>
> Don't try to change anything yet. Just observe and record.
>
> You'll see a **"Log a moment"** button on your habit card. Tap it whenever something happens — the sooner after the moment, the better. You'll be guided through what to capture, so there's nothing to remember now.

---

### Week 1, Days 2–7 — Behaviour Logging ("Log a moment")

**Trigger:** User taps "Log a moment" on the habit card on the Today screen.

**Purpose:** Begin gathering behavioural data — cues, emotional states, thoughts — without any attempt to change behaviour yet. Data feeds Module 1 (Know Your Pattern) and is stored in the Freedom Plan Journal section.

**The 4 capture fields** (user is prompted sequentially — nothing to memorise in advance):

| # | Prompt |
|---|---|
| 1 | Time and location — Where were you? What time of day was it? |
| 2 | What were you doing immediately before? |
| 3 | What were you feeling emotionally? Name it specifically (e.g. lonely, anxious, bored, overwhelmed, restless, flat) — then rate the intensity out of 10. |
| 4 | What thought arose just before? Even a single sentence is fine. |

**Decisions:**
- ~~Field 5 ("how did you feel an hour later?")~~ — **Dropped.** Hard to capture in the moment; complicates the flow.
- All entries are stored in the Freedom Plan Journal section (see G2).
- Tone is consistently non-judgemental and encouraging throughout the capture flow.

---

---

## JOURNAL — FREEDOM PLAN SECTION DESIGN

### Placement
The Freedom Plan Journal lives **inside the existing MyWalk Journal** as a second tab. The Journal tab bar shows:
- **Journal** — existing general entries, unchanged
- **Freedom Journey** — all Freedom Plan content

The "Freedom Journey" tab is only visible once the user has started their Freedom Plan. It does not appear for general MyWalk users.

### Privacy
All behaviour logs and journal entries are **never visible to the accountability partner.** The partner only receives messages the user deliberately sends. This is absolute.

### Inside "Freedom Journey" — two sub-views

A toggle or segmented control at the top switches between:

**"My Journey"** (chronological view)
- Reverse-chronological feed of all entries regardless of type
- Each entry shows: date, a small type label, and a snippet of what was written
- Tappable to expand the full entry
- Answers the question: *"How far have I come?"*

**"My Plan"** (module-organised view)
- Organised by the five path sections using exactly the same names and icons the user saw on the intro screen
- Each section is locked (greyed), active, or complete — mirroring the intro screen behaviour
- Tapping an active section shows all entries of that type plus any pinned living documents for that section
- Answers the question: *"Where am I in the plan and what have I done in each area?"*

### The five sections in "My Plan"

| Icon | Section name |
|---|---|
| 🔍 | Know Your Pattern |
| 💡 | Challenge Your Thinking |
| ⚓ | Anchor to Your Values |
| 🛡 | Build Your Guardrails |
| 🌱 | Navigate Lapses |

### Pinned living documents (within My Plan)

These are not journal entries — they are documents that get built and revised over time. Each is pinned at the top of its section:

| Section | Pinned document |
|---|---|
| Anchor to Your Values | Values Inventory summary (domain ratings + user's own words) |
| Know Your Pattern | Cue Hierarchy (built Week 2) |
| Build Your Guardrails | HRS Coping Plans |
| Challenge Your Thinking | Counter-responses library |
| Navigate Lapses | Recovery Letter |

### Entry type labels (shown in "My Journey" feed)

| Entry type | Label |
|---|---|
| Values domain reflection | "Values — [domain name]" |
| Behaviour log | "Moment logged" |
| Daily check-in | "Daily check-in" |
| Thought record | "Thought examined" |
| Urge surfing | "Urge surfed" |
| Compass check | "Values compass" |
| Lapse record | "Lapse — [date]" |
| Recovery letter | "Recovery letter" |
| Quarterly review | "Quarterly review" |

---

---

## REVISED TIMING SUMMARY — PHASE 1

| Day | What happens |
|---|---|
| Day 1 | Values Inventory (all 8 domains) + completion dialog + "what happens next" screen |
| Days 2–13 | Continuous behaviour logging via "Log a moment" — observe and record only |
| Day 7 | Weekly logging nudge fires if zero logs recorded in the past 7 days |
| Day 8–9 | Mid-point reflection prompt surfaces (3 questions) |
| Day 14 | Cue Hierarchy exercise — if ≥5 logs exist. If not, extend to Day 21. |
| Day 21 | Cue Hierarchy retry — if ≥5 logs exist. If not, extend to Day 28 with logging nudge. |
| Day 28 | Cue Hierarchy hard deadline — proceed with whatever exists, lighter if few entries. |

---

## PHASE 1 — WEEK 2: Continue Logging + Mid-Point Reflection

**Primary activity:** Continue logging moments via "Log a moment" on the habit card. No new tasks, no pressure to change anything. The logging itself is the therapeutic work at this stage.

**Why no Cue Hierarchy yet:** By end of Week 1 the user has at most 6 days of logs — realistically fewer, as not every day will have an episode or urge. That is not enough data for a meaningful cue hierarchy. Forcing that exercise at Day 8 would produce a superficial result or feel pressured. The Cue Hierarchy moves to a firm **Day 14** trigger instead.

**The one Week 2 task — Mid-Point Reflection**

Surfaced as a prompt on **Day 8 or 9**. Three questions, low effort, takes about 5 minutes. Gives the week a sense of purpose and begins the pattern recognition process in the user's own words — without being a formal exercise.

| # | Prompt |
|---|---|
| 1 | Looking at what you've logged so far — does anything surprise you? |
| 2 | Is there a time of day, place, or emotional state that seems to come up more than once? |
| 3 | How are you feeling about this process so far? |

**Where it lives:** Stored in the Journal under "Know Your Pattern." Counts as a journal entry in the "My Journey" feed with the label "Mid-point reflection."

**Tone:** Warm, curious, non-pressuring. The user is not expected to have found a clear pattern yet — any observation, even "I haven't noticed anything yet," is a valid and welcome answer.

---

## PHASE 1 — DAY 14: Cue Hierarchy

**Purpose:** The first formal pattern analysis exercise. The user looks across all their behaviour logs together and identifies the specific combinations of situation and emotional state that most reliably precede the behaviour. The output — the Cue Hierarchy — is a living document pinned in the Journal under "Know Your Pattern" and is used directly in Module 4 (Build Your Guardrails) for building coping responses.

### Minimum threshold — 5 log entries

The exercise requires at least **5 "Log a moment" entries** to be meaningful. Below that, patterns are more likely coincidence than signal.

### Day 14 logic

**If 5 or more entries exist → proceed with the Cue Hierarchy exercise** (see design below).

**If fewer than 5 entries exist → do not force the exercise.** Show a warm, non-judgemental message that acknowledges the possible reasons:

> *"You have [n] moments logged so far. That might mean this pattern isn't happening as often — which could itself be a sign of progress. Or it might mean there are moments that didn't get captured yet. Either way, there's no rush. Keep logging for another week and we'll revisit this on Day 21."*

Auto-extend by one week to **Day 21**, then check again with the same threshold.

**If still under 5 at Day 21 → extend to Day 28** with an additional gentle nudge about the logging habit itself:

> *"It looks like logging moments has been tricky. That's completely normal — building any new habit takes time. Even if you can recall a recent moment now, you can log it retrospectively. Tap 'Log a moment' to try."*

**Day 28 — hard decision point:** If still fewer than 5 entries after 28 days, proceed with whatever exists rather than extending further. By this point the Phase 2 unlock has already triggered (14 days elapsed) and holding the user back indefinitely would feel punishing. The Cue Hierarchy exercise proceeds in a lighter form: *"Here's what you've captured so far — even if it's limited, what patterns if any do you notice?"*

### Weekly logging nudge

If **zero logs are recorded in any 7-day period**, surface a gentle reminder — not guilt-inducing, just a check-in:

> *"It's been a quiet week in your log. Is everything OK? Even a brief note about a moment you navigated well is worth capturing."*

### The Cue Hierarchy exercise — full design

#### Stage 1 — Entry and framing
Surfaced as a prompt on the Today card and in the Freedom Journey tab — not a push notification. The user discovers it in the app rather than being summoned to it.

Screen content:
> *"You've been logging moments for two weeks. That takes honesty and courage. Now let's look at what your logs are telling you — together."*

Single "Let's go" button. Warm, collaborative tone. No clinical language.

#### Stage 2 — Review your logs
The user sees all their logs in chronological order: date, emotional state, situation, thought. Simple, readable. Prompt above the list:
> *"Read through what you've captured. Don't analyse yet — just notice."*

"I've read through them" button advances to Stage 3. Reading back one's own behaviour objectively is itself therapeutic.

#### Stage 3 — AI surfaces candidate patterns
The AI has analysed the logs using the habit-specific rubric and presents 2–4 candidate cues as plain-language statements. Framed tentatively — observations, not conclusions.

Screen heading: *"Here's what we noticed"*

Each cue appears as a card, e.g.:
- *"Late evenings when you're feeling flat or stressed"*
- *"After difficult conversations or conflict"*
- *"When you're alone with time to fill"*

Below the cards: *"These are patterns we spotted — they may not all be right, and there may be things we missed. You know your story better than we do."*

#### Stage 4 — Discovery questions
2–3 questions surfaced about common cues for that habit type that didn't clearly appear in the logs, drawn from the habit-specific rubric. Presented one at a time, each with three response options:
**Yes, this rings true / Sometimes / No, not really**

Example for pornography: *"Research suggests that feeling lonely or disconnected is a common trigger for this pattern. Does that feel true for you?"*

Any "Yes" or "Sometimes" response generates an additional candidate cue card in Stage 5.

#### Stage 5 — Build and rank the hierarchy
All candidate cues appear together as an editable list. The user can:
- **Edit** any card's wording — cues must end up in the user's own language, not the app's
- **Delete** any that don't feel right
- **Add** their own cues that aren't listed
- **Drag to rank** from least to most triggering

**Minimum:** 2 cues required to proceed.
**Maximum:** 6 cues enforced. If more than 6 exist: *"Try to keep this to your six most significant ones — a focused list works better than a long one."*

#### The output — Cue Hierarchy document
Saved as the pinned Cue Hierarchy document in the Journal under "Know Your Pattern." Displayed as a simple ranked list in the user's own words:

> **My Pattern Triggers** *(ranked from least to most triggering)*
> 1. Weekend afternoons when I'm bored and alone
> 2. Late at night after a stressful day
> 3. After an argument with my wife
> 4. When I'm travelling alone for work

Footer: *"This document will be used when you build your coping plans. You can update it at any time as you learn more."*

The document is always editable from the Journal. It is not a one-time exercise.

#### Completion screen
Warm, no gamification:
> *"You've just done something most people never do — looked honestly at your own patterns. This list is the map. Everything that comes next uses it."*

Single button: *"Back to my plan"* — returns to Recovery Path home, where Module 4 (Build Your Guardrails) now shows as fully active and ready.

#### Trigger and timing logic
- Day 14 if ≥5 logs exist; Day 21 or Day 28 otherwise (per threshold logic above)
- Surfaced on Today card and Freedom Journey tab — not a push notification
- Once completed, marked done and does not resurface
- The Cue Hierarchy document remains editable at any time from the Journal

---

---

## HABIT-SPECIFIC CUE RUBRICS

### Purpose
These rubrics serve two functions in the Cue Hierarchy exercise:
1. **AI analysis weighting** — the AI knows what patterns to look for per habit type when scanning logs
2. **Discovery questions** — prompts surfaced to the user for known common cues not yet captured in their logs

All rubrics are grounded in published CBT and behavioural psychology research. Sources noted where key.

---

### 1. Pornography
**Research base:** Extensive — CBT cue reactivity literature, moral incongruence model (Grubbs), classical conditioning research.

**Primary cues:** Internal emotional states dominate — loneliness, stress, anxiety, boredom, disconnection. Device access and privacy (being alone) are key environmental amplifiers. Unlike substance addictions, there is no discrete environment to avoid.

**Discovery questions:**
- Does it tend to happen when you're feeling lonely, stressed, anxious or bored?
- Does being alone — especially with a device — tend to be when it happens?
- Does it happen late at night or at a particular time of day?
- Does it follow conflict or disconnection with someone close to you?
- Is there a particular emotional state that seems to come just before?

---

### 2. Masturbation
**Research base:** Distinct from pornography literature; compulsive masturbation research (Sante Center, BetterAddictionCare clinical reviews); ecological momentary assessment studies (PMC 2024).

**Primary cues:** Primarily internal — physical tension or restlessness, stress relief-seeking, loneliness, boredom, habitual timing (bedtime, morning, after waking). Privacy/solitude is the key environmental condition. Can be entirely independent of pornography or deeply linked to it.

**Key distinction from pornography:** Pornography cues are anchored in external visual stimuli; masturbation cues are more anchored in bodily state and habitual timing. When combined with pornography, the cue network is compounded and more powerful.

**Discovery questions:**
- Does it tend to happen at a specific time of day — morning, bedtime, or when you first wake up?
- Does it happen when you're alone and feeling physically tense or restless?
- Is it usually connected to pornography use, or does it happen independently?
- Does it tend to happen when you're stressed, bored, or emotionally low?
- Is there a physical sensation or feeling that tends to come just before?

---

### 3. Pornography & Masturbation (combined)
**Research base:** Combines both rubrics above. The combined pattern creates a compounded cue network — external visual cues initiate the cycle; internal emotional states sustain it. Moral incongruence (guilt/shame post-episode) is particularly acute in a Christian context. (PMC ecological momentary assessment study, 2024.)

**Primary cues:** External visual/device cues initiating; internal emotional states (loneliness, stress, boredom) sustaining. Privacy is essential. The combined loop is self-reinforcing — shame after an episode can itself become a cue for the next one.

**Discovery questions:** Combination of both rubrics above, plus:
- Does the urge typically start with seeking visual content, or does it start with a feeling in your body?
- Does shame or guilt after an episode sometimes feel like it leads to the next one?

---

### 4. Alcohol (mild to moderate)
**Research base:** Marlatt & Gordon relapse prevention model; extensive CBT literature on alcohol use disorders; social cue reactivity research.

**Primary cues:** Deeply socially embedded — hospitality contexts, social rituals, celebration, commiseration, others drinking around you. Negative emotional states (stress, anxiety, loneliness) and positive social excitement are both established cues. Social pressure is particularly potent because refusal requires active effort and explanation.

**Discovery questions:**
- Does it tend to happen in social situations — meals, gatherings, parties?
- Is it connected to stress or anxiety — does a drink feel like winding down?
- Does it happen when others around you are drinking?
- Are there times of day that are particularly high-risk — after work, evenings?
- Does celebration or commiseration tend to trigger it?

---

### 5. Compulsive Spending
**Research base:** CBT compulsive buying literature; friction-engineering research (Lejoyeux, Müller); ecological momentary assessment studies on impulsive purchasing.

**Primary cues:** External stimuli (retail environments, shopping apps, sale notifications, social media advertising) and internal states (boredom, low mood, social comparison, desire for identity expression or control). The reward is layered — anticipatory pleasure from browsing, transient mood elevation from purchase, then guilt which itself becomes a cue for further spending.

**Discovery questions:**
- Does it tend to happen when you're browsing online — even without intending to buy?
- Does low mood, boredom or restlessness tend to precede it?
- Does it happen after seeing what others have — on social media or in person?
- Do sale notifications or limited-time offers tend to trigger it?
- Does the urge often start as "just looking"?

---

### 6. Disordered Eating
**Research base:** CBT eating disorder literature; DBT research on emotional eating; Fairburn's cognitive model of eating disorders.

**Primary cues:** Both external (food environments, social eating occasions, specific foods, mealtimes, advertising) and internal (negative emotional states, hunger as a cue, body image-related distress). For restrictive patterns, the "reward" is a sense of control. For binge patterns, negative emotions and social isolation are primary cues.

**Discovery questions:**
- Does it tend to happen at particular times of day or around mealtimes?
- Does it happen when you're feeling anxious, sad, bored, or stressed?
- Are social eating situations particularly difficult?
- Does it happen when certain foods are visible or accessible?
- Does how you feel about your body on a given day affect it?

---

### 7. Gambling
**Research base:** DSM-5 gambling disorder criteria; Ladouceur & Walker cognitive model; extensive cue reactivity research in gambling.

**Primary cues:** Financial stress paradoxically triggers gambling ("I need to win it back"). Sports media is a near-continuous cue for sports gamblers. Excitement and risk-seeking are strong internal cues. The gambler's fallacy and illusion of control maintain the loop cognitively.

**Discovery questions:**
- Does financial pressure or money stress tend to trigger the urge?
- Does watching sport or sports coverage act as a trigger?
- Does the feeling of excitement or wanting a rush precede it?
- Does it happen when you're feeling bored or restless?
- Does a near-win or a loss tend to trigger further gambling ("chasing")?

---

### 8. Social Media / Smartphone
**Research base:** Variable-ratio reward schedule research (Skinner); social comparison theory (Festinger); platform cue engineering literature; extensive screen time research.

**Primary cues:** The most diffuse cue profile of all — every moment of boredom, transition, or discomfort. Notifications are engineered cues. Social comparison content and FOMO sustain the loop. The cue-delivery environment and the behaviour-execution environment are the same device.

**Discovery questions:**
- Does it happen in every quiet or waiting moment — queues, transitions, breaks?
- Does a notification arriving tend to pull you in?
- Do you notice it happening when you're avoiding something else?
- Does it tend to happen when you're feeling low or wanting connection?
- Does waking up or going to bed tend to be when it starts?

---

### 9. Procrastination
**Research base:** Pychyl's procrastination research; Steel's temporal motivation theory; ACT-based avoidance model; Sirois & Pychyl (2013) on emotion regulation.

**Primary cues:** The task itself — or the anxiety, overwhelm, perfectionism-related dread, or low self-efficacy the task triggers. The procrastinating behaviour (switching to anything more rewarding) provides relief from that aversion. This is structurally identical to other avoidance-driven habits.

**Discovery questions:**
- Are there specific types of tasks that tend to trigger avoidance?
- Does it happen when a task feels overwhelming or you're unsure where to start?
- Does perfectionism play a role — needing conditions to be right before beginning?
- Does it happen when you're already feeling anxious or low?
- Does the urge to switch to something else come with a physical sense of relief?

---

### 10. Smoking
**Research base:** Extensive nicotine cue reactivity literature; Shiffman's ecological momentary assessment research; CBT smoking cessation protocols.

**Primary cues:** Two distinct cue types — habitual/conditioned sequences (morning coffee, after meals, alcohol) and emotional/stress cues. Social cues (being around smokers, social breaks) are also well-established. Notably, both physiological nicotine need and psychological conditioning operate simultaneously.

**Discovery questions:**
- Does it happen at specific times of day — after meals, with coffee, first thing in the morning?
- Is stress the main trigger, or is it more habitual and routine?
- Does being around other smokers or the smell of cigarettes trigger the urge?
- Does it happen when you're bored, waiting, or in a transition moment?
- Does alcohol increase the urge?

---

### 11. Doom Scrolling
**Research base:** Intolerance of uncertainty research (Satici et al., 2023; Shabahang et al., 2024); anxiety-driven information-seeking literature; algorithmic cue engineering research (Computers in Human Behavior, 2024).

**Primary cues:** Anxiety and intolerance of uncertainty are the primary internal cues — a need to feel informed, to anticipate threats, or to feel in control. Distinct from general social media use in that the content is specifically negative/alarming. Triggered strongly by uncertain or stressful periods (news events, personal crises). Bedtime and waketime are high-risk periods.

**Discovery questions:**
- Does it tend to happen when you're feeling anxious or worried about something?
- Does it happen late at night when you can't sleep?
- Does a stressful news event or personal situation make it much worse?
- Does it feel like you're searching for information to feel more in control?
- Do you notice it starting even when you intended just to check one thing?

---

### 12. Gossip
**Research base:** Dunbar's social bonding research; insecurity and self-esteem literature (Neurolaunch, 2026); Martinescu et al. (2019) on gossip functions; Listen-Hard social psychology reviews.

**Primary cues:** Social situations with particular people or groups are the primary environmental cues. Internal cues include insecurity, a need for social belonging or status, resentment toward someone, anxiety, and boredom. Gossip functions as social currency — it bonds through shared negative opinion, which makes group settings particularly high-risk. Resentment or envy toward a specific person is a strong internal trigger.

**Discovery questions:**
- Does it tend to happen with certain people or in particular group settings?
- Does it happen when you're feeling insecure, anxious, or left out?
- Does resentment or frustration with a specific person tend to precede it?
- Does it feel like a way to bond with someone — sharing information as connection?
- Does it happen when you're bored or when conversation runs dry?

---

### 13. Negative Self-Talk
**Research base:** CBT rumination research; Neff's self-compassion research; Moritz et al. (2011) thought diary studies; competitive environment and failure-trigger literature (Psych at Work, 2023).

**Primary cues:** Failure or perceived failure is the primary trigger — a mistake, criticism received, a comparison with others, or anything that activates core beliefs about self-worth. Stress and fatigue lower the threshold. Competitive environments, performance situations, and social comparison are established situational cues. Unlike most habits, the cue and the behaviour are both entirely internal, making them harder to observe.

**Discovery questions:**
- Does it tend to happen after something goes wrong or doesn't meet your standard?
- Does receiving criticism — even mild — tend to trigger it?
- Does comparing yourself to someone else set it off?
- Does it get worse when you're tired, stressed, or overwhelmed?
- Are there particular people or situations that tend to trigger the inner critic?

---

### 14. Overworking
**Research base:** Andreassen & Pallesen workaholism research; Menghini et al. (2026) daily diary study on situational triggers; anxiety-avoidance model of workaholism (Simply Psychology, 2026); emotional avoidance literature.

**Primary cues:** Two distinct driver types — anxiety/fear-based (working feels safer than stopping; rest triggers guilt; perfectionism; fear of failure or judgement) and avoidance-based (work as escape from relationship tension, emotional discomfort, or home life). Anticipated workload in the morning is a documented daily trigger (Menghini et al., 2026). Organisational culture that valorises overwork is an environmental amplifier.

**Discovery questions:**
- Does the urge to keep working come with a sense that stopping would be dangerous or wrong?
- Does rest or downtime feel uncomfortable — like you should be doing something?
- Does perfectionism play a role — needing to keep going until it's exactly right?
- Is work sometimes a way to avoid something at home or in a relationship?
- Does an anticipated heavy workload first thing make the whole day more compulsive?

---

### THREE-LAYER FALLBACK FOR UNKNOWN OR CUSTOM HABITS

For habits entered as free text that don't match any named rubric:

**Layer 1 — Fuzzy matching (silent)**
The AI attempts to map the custom entry to the closest existing rubric. Examples: "Binge watching" → Social media rubric. "Online shopping" → Compulsive spending. "Rage" or "Anger" → Negative self-talk. "Vaping" → Smoking. If confidence is high, the closest rubric is applied silently without telling the user.

**Layer 2 — Generic rubric (fallback)**
For habits that genuinely don't map to any existing rubric, use this universal set of six cue categories drawn from the habit loop research:

| Cue category | Discovery question |
|---|---|
| Time of day | "Does it tend to happen at a particular time of day?" |
| Emotional state | "What are you usually feeling when the urge hits — stressed, bored, lonely, anxious, flat?" |
| Location / environment | "Is there a particular place where it tends to happen?" |
| Social context | "Are you usually alone, or with certain people?" |
| Preceding activity | "Is there something you typically do just before — a conversation, a task, a routine?" |
| Physical state | "Does tiredness, hunger, or physical discomfort play a role?" |

**Layer 3 — AI from logs regardless**
The AI analysis of actual log entries does not depend on the rubric at all — it pattern-matches across what the user wrote. The rubric supplements this with known common cues. For a genuinely novel habit the AI can still do useful work from the logs alone, with the generic rubric providing the discovery questions.

**Sensitivity flag**
Custom entries that suggest self-harm (cutting, restricting, purging, etc.) trigger a modified response: tone is handled with extra care, the professional support note is surfaced prominently, and discovery questions are gentler and more tentative. This is a separate safety check built into habit setup, not just cue analysis.

---

---

## MODULE 2 — CHALLENGE YOUR THINKING: PLACEMENT & SEQUENCING

### Core principle
Module 2 depends on Module 1's Cue Hierarchy to be maximally useful. Working on automatic thoughts in the abstract — before knowing which cues reliably produce which thoughts — is shallow. The formal Module 2 work therefore activates **after the Cue Hierarchy is complete** (Day 14–28 depending on log volume).

### Two components at different times

**Component A — Thought catching (Day 2 onward, embedded and silent)**

The "Log a moment" capture field *"What thought arose just before?"* IS the beginning of Module 2. The user is already catching automatic thoughts from Day 2. This is never labelled as Module 2 work — it happens quietly, embedded in the behaviour logging flow.

**Component B — Thought examination (post Cue Hierarchy, ~Day 14–28)**

The formal five-step examination, counter-response library, and self-compassion work activate after the Cue Hierarchy is complete. The introduction framing:

> *"Now that you know what triggers your pattern, let's look at the thoughts those triggers produce — because it's the thought, not the cue, that actually drives the behaviour."*

The thought-catching work already done is acknowledged warmly:
> *"You've actually been doing the first part of this already — every time you noted what you were thinking just before, that was the beginning of this work."*

### Post-Cue Hierarchy: two modules activate in parallel

After the Cue Hierarchy is complete, two things activate simultaneously — experienced as a natural deepening, not two separate programmes:

| Module | Focus | Question it answers |
|---|---|---|
| **Module 2** | Thought examination, counter-response library, self-compassion | *"What will I think when cue X arises?"* |
| **Module 4** | Environmental restructuring, coping plans, urge surfing | *"What will I do when cue X arises?"* |

These are two sides of the same preparation and are designed to feel complementary, not parallel clinical tracks.

Module 3 (Values) continues quietly in the background through the weekly compass check — running from Day 1 throughout all phases.

### Module 2 formal tasks (post Cue Hierarchy)

**Task 1 — Review your thought log**
The user is shown all the "thought that arose" fields from their behaviour logs, grouped by cue type where possible. Prompt: *"Look at what you were telling yourself just before. Do you notice any patterns?"* This is a natural bridge from the logging phase into the formal thought work.

**Task 2 — The five-step thought examination**
Introduced as a journalling exercise, not a clinical worksheet. When the user notices a significant thought driving an urge, they work through five steps in their journal:
1. Write the thought exactly as it occurred — raw, not cleaned up
2. Identify the type of thinking error (permission-giving, minimising, catastrophising, all-or-nothing, externalising)
3. Examine the evidence — what does the actual track record say?
4. What would I say to a good friend who believed this thought?
5. Write a more accurate alternative — in my own words, not an affirmation

Stored in the Journal under "Challenge Your Thinking" with the label "Thought examined."

**Task 3 — Build your counter-response library**
Once the user has identified their top 3–5 recurring automatic thoughts through the examination process, they write a specific first-person counter-response for each. These are stored as a pinned living document in the Journal under "Challenge Your Thinking" — the counter-responses library.

Framing: *"These aren't affirmations. They're your own words, drawing on your own evidence, ready for the moments when it's hardest to think straight."*

**Task 4 — Self-compassion anchor (ongoing)**
Introduced alongside Task 2, not as a separate exercise but as a recurring prompt within the thought examination flow. When a harsh self-critical thought is identified, the prompt surfaces: *"What would you say to a good friend who was struggling with exactly this?"* This is not labelled "self-compassion" in the UI — it is just the natural next question.

### Journal outputs from Module 2

| Entry type | Label in Freedom Journey feed |
|---|---|
| Thought examination entry | "Thought examined" |
| Counter-responses library | Pinned living document |

---

---

## MODULE 4 — BUILD YOUR GUARDRAILS: FULL DESIGN

### Design principle
Willpower works worst exactly when most needed — when stressed, tired, and the urge is strong. Module 4 changes the environment and pre-loads responses so the user is executing a plan they already made rather than improvising under pressure.

### Four components in order

The four components happen in a specific sequence — not simultaneously.

| Component | Timing | Trigger |
|---|---|---|
| 1. Environmental Restructuring | Day 14–28 + 1–2 days | Immediately after Cue Hierarchy completion |
| 2. HRS Coping Plans | Day 14–28 + 3–5 days | 2–3 days after Environmental Restructuring |
| 3. Urge Surfing | Day 14–28 + 10–12 days | ~1 week after HRS Coping Plans complete |
| 4. Lifestyle Balance Audit | Day 30 onward | Monthly recurring from Day 30 |

---

### Component 1 — Environmental Restructuring

**Purpose:** Make at least three concrete changes that increase friction between cues and behaviour. Not to make the behaviour impossible — to insert enough delay and decision-points that the automatic chain is interrupted.

**Timing:** Immediately after Cue Hierarchy completion. Creates immediate momentum and agency at a significant emotional moment.

**Screen heading:** *"Change the situation before you need to change your mind."*

**Flow:**
- Short explanation of why environmental change works better than willpower
- The user's top three cues from their Cue Hierarchy are displayed (pulled directly from the pinned document)
- For each cue, one text field: *"What's one concrete thing you could change about this situation to make it harder for the pattern to happen automatically?"*
- Habit-specific suggested examples shown as soft chips below each field — illustrative, not required. User can tap a chip or write their own.
- **Minimum:** One change per cue, three changes total. Empty fields gently blocked: *"Even one small change per trigger makes a real difference."*

**Output:** Saved as the Environmental Restructuring section appended to the existing Cue Hierarchy pinned document in the Journal under "Know Your Pattern." Grows the existing document rather than creating a new entry.

---

### Component 2 — HRS Coping Plans

**Purpose:** A specific pre-written coping plan for each of the user's top cues. When a high-risk situation arises, the user executes a plan already made rather than improvising under pressure. This is the most important and substantial piece of Module 4.

**Timing:** 2–3 days after Environmental Restructuring.

**Flow:**
One screen per cue from the hierarchy, worked through sequentially. The user's cue shown at the top of each screen in their own words — pulled from the Cue Hierarchy document.

Three fields per cue:

| Field | Prompt |
|---|---|
| **Early warning signals** | *"What tells you this situation is developing — before the craving peaks? A physical sensation, a thought, a mood?"* |
| **My first response** | *"What's the specific thing you'll do first — before you need to make any harder decision? Make it concrete, easy, and time-buying."* |
| **Escalation contact** | *"Who will you reach out to if your first response isn't enough?"* |

**On the escalation contact field:** Links to the accountability partner if one is set up. If not, surfaces a gentle prompt: *"This is a good moment to consider setting up a support partner."*

**Vagueness check:** If the "first response" field contains something generic ("think positive," "be strong"), a gentle inline prompt appears: *"The most effective plans are very specific — a concrete action, not a mindset. What exactly will you do?"*

**Output:** Each coping plan saved as a card within the HRS Coping Plans pinned document in the Journal under "Build Your Guardrails." One card per cue — the user ends up with a complete set of pre-made responses for all their top triggers. This is a living document — editable at any time as the user learns more.

---

### Component 3 — Urge Surfing

**Purpose:** A mindfulness-derived practice of riding the arc of an urge rather than acting on it or suppressing it. Urges rise, peak (typically 15–30 minutes), and subside whether or not acted upon. Repeated urge surfing weakens the cue-response association over time through extinction.

**Timing:** ~1 week after HRS Coping Plans complete. Introduced once coping plans exist — so the user has both a practical tool (coping plan) and a mindfulness tool (urge surfing) available simultaneously.

**Introduction screen tone:** Warm, slightly counterintuitive — not clinical.

> *"Here's something counterintuitive: you don't have to fight an urge or give in to it. There's a third option — you can just watch it.*
>
> *Urges aren't commands. They're neurological events with a natural shape — they rise, peak, and pass, usually within 15–30 minutes, whether or not you act on them. Urge surfing is the practice of riding that arc rather than reacting to it.*
>
> *The more you practise this, the weaker the urge becomes over time."*

**The four steps (shown simply, not as a clinical protocol):**
1. **Name it** — "I am having an urge to [behaviour]." Observation, not permission.
2. **Locate it** — Where in your body do you feel it? Chest, throat, stomach?
3. **Watch it** — Observe it without acting. Does it peak and then ease?
4. **Record it** — Log what happened. Was the urge survivable?

**The log entry — "Urge surfed":**
Three quick questions after an urge surfing experience:
- Where did you feel it in your body?
- Did it rise and fall?
- What did it feel like to observe it rather than act?

Stored in the Journal under "Build Your Guardrails" with the label "Urge surfed."

**After introduction:** Becomes a permanent available action — the user can log an urge surfing experience any time from the habit card, alongside "Log a moment."

---

### Component 4 — Lifestyle Balance Audit

**Purpose:** A monthly honest review of the balance between demands (what life takes from you) and genuine rewards (what genuinely nourishes you). Chronic imbalance creates a persistent background state of deprivation that makes the habit's pull much stronger. The goal is to deliberately schedule at least two genuinely pleasurable, non-harmful activities per week.

**Timing:** Monthly recurring prompt from Day 30 onward.

**Tone:** Pastoral, not productivity-focused. *"This isn't about optimising your schedule. It's about making sure your life has enough real goodness in it that the habit doesn't feel like the only available relief."*

**Two-part journal entry:**

**Part 1 — The honest picture**
- *"Looking at your typical week honestly — what is taking from you?"*
- *"What is genuinely nourishing you — not numbing, not obligation, but something you'd actually choose?"*

**Part 2 — One change**
- *"What two activities could you build into the next month that would genuinely nourish you?"*

**Output:** Stored in the Journal under "Build Your Guardrails" with the label "Lifestyle balance review."

---

### Module 4 journal outputs summary

| Entry type | Label in Freedom Journey feed | Type |
|---|---|---|
| Environmental changes | Appended to Cue Hierarchy document | Living document (existing) |
| HRS Coping Plans | Pinned as "My Coping Plans" | Living document (new) |
| Urge surfing log | "Urge surfed" | Journal entry |
| Lifestyle balance review | "Lifestyle balance review" | Journal entry (monthly) |

---

---

## MODULE 5 — NAVIGATE LAPSES: FULL DESIGN

### Core design principle
Module 5 must serve two completely different emotional states. Every design decision must be made with both in mind:

- **Moment A — Clear-headed, before any lapse:** Preparation. The user is calm, engaged, motivated.
- **Moment B — After a lapse has occurred:** Crisis response. The user is likely in shame, self-criticism, or despair. The AVE is firing. Design must interrupt the spiral immediately.

### When Module 5 unlocks
Two triggers — whichever comes first:
- **Day 30** — time-based unlock regardless of whether a lapse has occurred
- **First lapse recorded** — event-based unlock, can happen any time

If a lapse triggers the unlock before Day 30, Module 5 surfaces immediately. The preparation content (AVE education, recovery letter) is presented first — before the lapse response protocol — so the user has the framework to make sense of what just happened.

---

### Part 1 — Preparation (before any lapse)

**Task 1 — Understanding AVE**
One screen, read-only. Heading: *"Before anything happens — read this."*

Content (in the app's voice, not clinical):
> *"Most people who are changing a deeply ingrained pattern will experience a slip at some point. That's not pessimism — it's what the research consistently shows.*
>
> *What determines whether a slip becomes a full relapse is almost never the slip itself. It's what happens in the hour afterward.*
>
> *When a slip happens, the mind tends to catastrophise: 'I've failed. I have no willpower. I'll never change. I might as well give up.' Researchers call this the Abstinence Violation Effect — and it's one of the most dangerous things that can happen after a slip, because it turns a single moment into a sustained return to the old pattern.*
>
> *These thoughts are not facts. They are the all-or-nothing thinking error at its most damaging. And knowing that — right now, before you need it — is one of the most useful things you can do."*

Single "I've read this" button advances to Task 2.

**Task 2 — Write your recovery letter**
The most emotionally significant task in the entire protocol. Research shows self-compassion written in the second person activates different neural responses than internal self-criticism. Many users report this as the most important thing they write in the whole journey.

Introduction:
> *"Right now, while you're clear-headed, write a short letter — from the wiser, stronger version of yourself to the version of you who has just slipped.*
>
> *You know what that moment feels like. You know what your mind will tell you. Write back to it.*
>
> *Keep it honest, warm, and specific to you. This isn't an exercise — it's something you might really need."*

A full-screen journal entry opens with "My recovery letter" pre-loaded as the heading.

Soft dismissible guidance below the text field:
*"You might include: what you want to remind yourself about who you are, what the research says about slips, which value you want to take the next step toward, and what you want to say to your harshest inner voice."*

Saved as the pinned Recovery Letter document in the Journal under "Navigate Lapses." Always accessible, always editable.

**Completion moment after both tasks:**
> *"That's the preparation done. You've given your future self something real to hold onto. Now you know what to do if a hard moment comes — and you have what you need to get back up."*

---

### Part 2 — The lapse response protocol (after a lapse occurs)

**Recording a lapse — button label**
On the habit card. Label must not feel like confession, punishment, or failure registration.
**Decided: "I had a moment"** — honest, human, non-shaming.

**Screen 1 — Stop the spiral**
Full screen. Large, warm text. No form fields. No data entry. Just this:

> *"First — stop.*
>
> *Whatever your mind is telling you right now about what this means, about who you are, about whether change is possible — those thoughts are not facts.*
>
> *One moment is one moment. It is not a verdict.*
>
> *Take a breath. You're still here. That matters."*

Single button: *"I'm ready to continue"*

**Screen 2 — Your recovery letter**
The user's own recovery letter is shown back to them — their own words, written when clear-headed, at exactly the right moment. Not a prompt. Their own voice.

If the letter hasn't been written yet (lapse happened before Day 30 unlock), a brief compassionate version from the app is shown instead, with a prompt to write their own afterward.

Below the letter: *"Read it. Take whatever time you need."*
Button: *"I've read it"*

**Screen 3 — Self-compassion**
One question only:
*"What would you say to a good friend who had just gone through exactly this moment?"*

A text field. Written, saved, not analysed. The act of writing is the intervention.

**Screen 4 — Forensic analysis**
Heading: *"Let's understand what happened — not to judge it, but to learn from it."*

Four sequential fields:
1. *"What was the situation just before? Where were you, what were you doing?"*
2. *"What were you feeling emotionally?"*
3. *"What thought arose just before?"*
4. *"Where did your coping plan not hold — and what do you think got in the way?"*

Mirrors the behaviour log format (familiar) and HRS coping plan structure (diagnostic). The user recognises the pattern.

**Screen 5 — Extract and recommit**
Two questions:
- *"What does this moment teach you about your coping plan that you didn't know before? What would need to be different next time?"*
- *"Which of your values do you want to take the next right step toward — right now, today?"*

Button: *"Update my coping plan"* — opens the relevant HRS coping plan card in the Journal directly, ready to edit. The lapse has improved the plan. That reframe is the most important moment in Module 5.

**Completion moment:**
> *"You didn't give up. You came back. That is what recovery actually looks like — not a straight line, but coming back every time.*
>
> *Your plan is updated. Your values are still yours. Keep going."*

---

### High-risk periods — proactive prompts

Surfaced as gentle check-ins, not warnings.

| High-risk period | When surfaced | Prompt |
|---|---|---|
| Early weeks | Days 7, 14 | *"The early weeks are often the hardest — the old pathway is still firing strongly. How are you doing?"* |
| Honeymoon over-confidence | Day 21 | *"Sometimes when things are going well, vigilance drops. That's normal — just worth noticing."* |
| Sustained stress | When user rates emotional state very high in daily check-in | *"It looks like it's been a difficult stretch. Stressful periods are when the plan matters most. Is your coping plan still working?"* |
| Major life transitions | Quarterly review | Covered in quarterly review |

---

### Quarterly maintenance review

From Day 90 onward. Recurring quarterly prompt. Five questions in a structured journal entry:

1. *"What has genuinely changed since you started this journey?"*
2. *"What is still fragile — where do you feel most vulnerable?"*
3. *"Has your cue hierarchy changed? Are there new triggers, or old ones that have eased?"*
4. *"Does your values compass need recalibrating?"*
5. *"What is one specific thing you will do differently in the next three months?"*

Stored in the Journal under "Navigate Lapses" with the label "Quarterly review."

---

### Module 5 journal outputs summary

| Entry type | Label in Freedom Journey feed | Type |
|---|---|---|
| Recovery letter | Pinned as "My recovery letter" | Living document |
| Lapse record | "Lapse — [date]" | Journal entry |
| Quarterly review | "Quarterly review" | Journal entry (recurring) |

---

## GLOBAL DECISION — NO STREAK-BASED TRACKING

**Decision:** Streak-based tracking is not used anywhere in the Walking Free feature.

**Rationale:** Streak tracking is borrowed from gamification design, not recovery science. It is clinically counterproductive in this context because:
- When a streak breaks, the AVE fires hardest — seeing "streak: 0" at the worst possible moment actively amplifies the catastrophising the entire protocol is designed to prevent
- It implies that the value of the journey lies in an unbroken record rather than in growth, learning, and coming back
- It is fundamentally incompatible with the compassionate, non-shame-based tone of the whole plan
- It is manipulative by design — borrowed from the same behavioural engineering used by the addictive platforms many users are trying to break free from

**What replaces it:** Progress is conveyed through the richness of the journal — the documents built, the coping plans developed, the moments logged, the letters written. The user's sense of progress comes from the depth of their self-knowledge and the strength of their plan, not a number that resets.

Any existing streak display on the abstain habit card is removed or suppressed for Walking Free habits. No streak counter, no "days clean" prominent display, no reset animation on lapse.

---

---

## MODULE 2 — THOUGHT EXAMINATION: UX DESIGN

### Core design principle
One step at a time, sequentially. The user is usually in some emotional activation when they come to this. A wall of fields causes them to close the screen. Each step is one focused question. The whole flow takes 3–5 minutes. A five-dot progress indicator shows position without numbering steps.

### Entry points
Two routes into the flow — both open the same experience:
- **Habit card button** — label: **"Examine a thought"** (alongside "Log a moment" and "Urge surfed")
- **Recovery Path screen** — under Challenge Your Thinking, a prompt card: *"Notice a thought driving an urge? Work through it here."*

### Opening screen
Before any fields. Heading: *"Examine a thought"*

> *"The cue doesn't cause the behaviour — the thought does. This takes about 5 minutes and works best done as soon as possible after you notice the thought."*

Five-dot progress indicator at the top — all unfilled, no step numbers visible. Button: *"Start"*

---

### Step 1 — Write the thought
**Prompt:** *"Write the thought exactly as it occurred — not a cleaned-up version. The raw thing."*

Soft dismissible example below field: *e.g. "I deserve this." / "Just this once." / "No one will know." / "I can't cope without it."*

One-line note below field: *"The uncleaned version is the one that has power. That's the one worth examining."*

Large text field. No character limit. First dot fills on completion.

---

### Step 2 — Name the thinking error
**Prompt:** *"What kind of thought is this?"*

Tap-to-select list — not a free text field. Each category shown with a one-line description in the user's own language (no clinical terminology):

| Label | Description shown |
|---|---|
| Permission-giving | "I deserve this / just this once / a little won't matter" |
| Minimising | "It's not that bad / everyone does it" |
| Catastrophising | "I could never give this up / I have no willpower" |
| All-or-nothing | "I've already slipped, the day is ruined" |
| Externalising | "It's stress / my relationship / work that causes this" |
| Self-condemnation | "I'm broken / weak / hopeless / this is just who I am" |
| Other | Free text field appears |

Single select. Quick recognition step — not analysis. Second dot fills.

---

### Step 3 — Examine the evidence
**Two questions on the same screen** — the only step with two fields. They flow naturally together and the contrast between answers is powerful when immediate.

**Question A:** *"What is the actual evidence for this thought? What does your track record say?"*

**Question B:** *"What would you say to a good friend who told you they believed this?"*

Two separate text fields. Third dot fills.

---

### Step 4 — Write an alternative
**Prompt:** *"Write a more accurate alternative — in your own words, not an affirmation."*

One-line reminder: *"Not 'everything will be fine' — something you actually believe. Something grounded in what your evidence just showed you."*

Soft dismissible example: *e.g. "The evidence from my own history is that once never stays once. The urge will pass in about 20 minutes whether or not I act on it."*

Large text field. Fourth dot fills.

---

### Step 5 — Save to library (optional but prompted)
**Prompt:** *"Is this one of your recurring thoughts — something that comes up again and again?"*

Two options: **Yes, save it** / **No, just this once**

- **Yes** → thought and alternative saved as a pair to the Counter-responses library pinned document. Confirmation: *"Added to your counter-responses — ready for next time."*
- **No** → saved as regular journal entry only.

Fifth dot fills.

---

### Completion screen
> *"Good work. You slowed down a thought that usually moves faster than you can catch it.*
>
> *The more you do this, the more automatic it becomes — until you're doing it in real time, without needing to write it down."*

Two options:
- *"Back to my plan"*
- *"Log this moment too"* — opens "Log a moment" flow pre-filled with today's date, for cases where the thought examination followed an episode not yet logged.

---

### Counter-responses library UX
Pinned living document in the Journal under 💡 Challenge Your Thinking. Each saved pair shown as a card:

**Collapsed:** The automatic thought — user's own words, slightly muted text.

**Expanded:** Thinking error category tag + full alternative response.

Cards can be edited, reordered, or deleted. New pairs can be added directly from the library without going through the full five-step flow — for responses thought of outside the app.

**High-risk moment access:** A button on the habit card — **"My counter-responses"** — opens the library directly. In a moment of high cue activation the user doesn't need to reason from scratch. They find the thought that's firing and read the response they wrote when clear-headed. Same principle as the recovery letter.

---

### Draft and resume behaviour
**Decision:** If the user closes the app mid-flow, the partial entry is saved as a draft and resumed on next open.

A *"Resume your thought examination"* prompt appears on the Today card until the entry is completed or dismissed. Losing partial work mid-activation would be frustrating and counterproductive.

---

### Module 2 journal outputs summary

| Entry type | Label in Freedom Journey feed | Type |
|---|---|---|
| Thought examination | "Thought examined" | Journal entry |
| Counter-responses library | "My Counter-responses" | Living document (pinned) |

---

---

## "MY PLAN" — SECTION VISUAL STATES

### The three states every section must render

**Locked**
The section is visible but inaccessible. The user can see what's coming — creating a sense of journey and anticipation. Visual treatment: section header and icon in muted/greyed colour, small lock icon alongside, one-line explanation of what unlocks it. No content visible inside. Tapping produces a gentle explanation: *"This becomes available [unlock condition]."* No negative framing — nothing implying the user has failed to reach it.

**Active**
The section is open and the user is working in it. Visual treatment: full colour icon and header, tappable, pinned living documents shown at top followed by journal entries in reverse chronological order. Date of last entry shown under section name. If a foundational task is outstanding within the section, a soft prompt card appears at the top: *"Your next step: [task name]."* Not a badge or notification count — a soft card only.

**Complete**
Applicable only to sections with a definable "done" state. Visual treatment: subtle completion indicator alongside section name — a small filled circle or checkmark in the section's colour. No trophy, no badge — wrong tone. Section remains fully accessible and editable. Ongoing entries continue to accumulate after completion.

**Note:** Know Your Pattern and Challenge Your Thinking are inherently ongoing — the user never finishes logging moments or examining thoughts. These sections show only Active or Locked, never Complete.

---

### Section-by-section state logic

| Section | Locked condition | Active condition | Complete condition |
|---|---|---|---|
| 🔍 Know Your Pattern | Never locked | Active from Day 1 | No complete state — ongoing |
| 💡 Challenge Your Thinking | Before Cue Hierarchy complete | After Cue Hierarchy complete | No complete state — ongoing |
| ⚓ Anchor to Your Values | Never locked | Active from Day 1 | Values Inventory submitted |
| 🛡 Build Your Guardrails | Before Cue Hierarchy complete | After Cue Hierarchy complete | HRS Coping Plans written for all cues |
| 🌱 Navigate Lapses | Before Day 30 AND no lapse recorded | Day 30 OR first lapse recorded | Recovery Letter written |

---

### "Next step" prompt card (within active sections)

One soft prompt card maximum per section — the most important outstanding foundational task only. Appears at the top of the section above journal entries. Disappears once the task is done. If no tasks are outstanding, no card appears.

Examples:
- Know Your Pattern, Day 14: *"Your next step: Build your cue hierarchy — your logs are ready."*
- Build Your Guardrails, after Cue Hierarchy: *"Your next step: Map your environmental changes."*
- Navigate Lapses, after unlock: *"Your next step: Write your recovery letter — while you're clear-headed."*

---

### Empty state (active section, no entries yet)

Simple warm one-liner in muted text, shown below any prompt card or alone if no prompt card:

| Section | Empty state text |
|---|---|
| 🔍 Know Your Pattern | *"Your logged moments will appear here."* |
| 💡 Challenge Your Thinking | *"Your thought examinations will appear here."* |
| ⚓ Anchor to Your Values | *"Your values reflections will appear here."* |
| 🛡 Build Your Guardrails | *"Your coping plans and urge logs will appear here."* |
| 🌱 Navigate Lapses | *"Your lapse records and quarterly reviews will appear here."* |

No illustration, no large empty-state graphic. Quiet and non-pressuring.

---

## OPEN QUESTIONS / PENDING DESIGN

| # | Question | Status |
|---|---|---|
| OQ1 | **Plan complete — ready for developer handover** | All design decisions documented. Cross-reference with Freedom_Plan_Master_Timeline.md for the implementation sequence. |

---

*Last updated: working session — Plan complete. All gaps resolved including My Plan visual states. No open questions remain. Ready for developer handover.*
