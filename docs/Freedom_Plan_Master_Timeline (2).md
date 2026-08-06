# Freedom Plan — Master Timeline
## Complete sequence of all modules, tasks, prompts, and triggers from Day 1 through maintenance

---

> **How to read this document:** Each row is a discrete event — a task, a prompt, a unlock, or a recurring action. Events are ordered chronologically. Where timing is conditional (depends on log count, lapse occurrence, etc.), the condition is stated explicitly. All journal output types are noted for each event.

---

## PHASE 1 — GETTING STARTED (Days 1–28)

### Day 1

| Event | Type | Detail |
|---|---|---|
| **Values Inventory** | Task — one-time | User works through all 8 life domains sequentially. Each domain screen: open text question, importance slider (1–10), alignment slider (1–10), dynamic feedback line, compass selector (Toward / Neutral / Away — no pre-selection). |
| **Completion dialog** | System prompt | Short celebratory dialog: *"Fantastic — that's the first piece done, and it's foundational to everything that follows."* |
| **"What happens next" screen** | Onboarding screen | Separate scrollable screen explaining behaviour logging. Introduces the "Log a moment" button. Sets expectation: observe and record only, don't try to change anything yet. |
| **Values Inventory saved** | Journal output | Saved as **one combined pinned document** under ⚓ Anchor to Your Values — "My Values Inventory." All 8 domains in one document (not 8 separate entries). Always editable. |
| **Module 1 active** | System | Know Your Pattern unlocks. Daily check-in prompt begins. Orange dot appears on Today card if no check-in logged today. |
| **Module 3 active** | System | Anchor to Your Values unlocks. Weekly compass check begins from Day 7. |
| **Module 4 partial** | System | Build Your Guardrails shows as seeded from setup screen coping plan chips. Not yet fully active — becomes fully active after Cue Hierarchy. |
| **"I had a moment" button active** | System | Available from Day 1. If tapped before Module 5 unlocks, Module 5 unlocks immediately and runs AVE education + recovery letter first. |

---

### Days 2–6 — Behaviour Logging Begins

| Event | Type | Detail |
|---|---|---|
| **Daily check-in available** | Recurring action (daily, all phases) | Orange dot on Today card if not yet done today. Two questions: (1) How are you doing emotionally today? (slider 1–10). (2) Did you encounter your pattern today? (Yes I slipped / Felt the urge but didn't act / Clear day). If "Yes I slipped" → prompts to open "Log a moment." If "Felt the urge" → prompts to open thought examination. Stored under 🔍 Know Your Pattern with label "Daily check-in." Count feeds Phase 2 unlock condition. |
| **"Log a moment" available** | Recurring action (all phases) | Button on habit card. Available from Day 2 through all phases — never removed. User taps whenever an episode or strong urge occurs. Captures 4 fields sequentially: (1) Time and location, (2) What were you doing before, (3) Emotional state — name it specifically + rate intensity 0–10, (4) Thought that arose just before. |
| **Log entries saved** | Journal output | Each entry saved under 🔍 Know Your Pattern with label "Moment logged" |
| **No pressure to change anything** | Design principle | The app makes no suggestions, no interventions, no prompts about coping in this window. Observe and record only. |

---

### Day 7

| Event | Type | Detail |
|---|---|---|
| **Weekly compass check prompt** | Recurring prompt (weekly from Day 7) | Three-step flow. Step 1: for each value domain, tap Toward or Away (60 seconds). Step 2: *"Where the compass is pointing away — what's one small thing you could do differently this week?"* Step 3: *"What is one concrete thing you will do this week that moves toward what matters most to you?"* (committed action — captured here, not separately). Stored under ⚓ Anchor to Your Values with label "Values compass." |
| **Zero-log nudge** | Conditional prompt | If zero "Log a moment" entries recorded in the past 7 days: *"It's been a quiet week in your log. Is everything OK? Even a brief note about a moment you navigated well is worth capturing."* |

---

### Days 8–9 — Mid-Point Reflection

| Event | Type | Detail |
|---|---|---|
| **Mid-point reflection prompt** | Task — one-time | Surfaced on Day 8 or 9. Three questions: (1) Looking at what you've logged so far — does anything surprise you? (2) Is there a time of day, place, or emotional state that seems to come up more than once? (3) How are you feeling about this process so far? |
| **Mid-point reflection saved** | Journal output | Stored under 🔍 Know Your Pattern with label "Mid-point reflection" |

---

### Day 14 — Cue Hierarchy (conditional)

**Condition: 5 or more "Log a moment" entries exist → proceed. Fewer than 5 → extend to Day 21.**

| Event | Type | Detail |
|---|---|---|
| **Cue Hierarchy prompt surfaces** | Task — one-time | Surfaced on Today card and in Freedom Journey tab. Not a push notification — discovered in the app. |
| **Stage 1 — Entry and framing** | Screen | *"You've been logging moments for two weeks. That takes honesty and courage. Now let's look at what your logs are telling you — together."* Single "Let's go" button. |
| **Stage 2 — Review logs** | Screen | All behaviour logs shown chronologically: date, emotional state, situation, thought. Prompt: *"Read through what you've captured. Don't analyse yet — just notice."* |
| **Stage 3 — AI candidate patterns** | Screen | AI analyses logs using habit-specific cue rubric. Presents 2–4 candidate cues as plain-language cards. Heading: *"Here's what we noticed."* Framed as observations, not conclusions. |
| **Stage 4 — Discovery questions** | Screen | 2–3 questions about known common cues for this habit type not clearly appearing in logs. Each with three options: Yes this rings true / Sometimes / No not really. "Yes" or "Sometimes" generates additional candidate cue. |
| **Stage 5 — Build and rank** | Screen | All candidate cues shown as editable list. User can edit wording, delete, add their own, drag to rank. Minimum 2, maximum 6. Cues must end in user's own language. |
| **Cue Hierarchy saved** | Journal output | Saved as pinned living document under 🔍 Know Your Pattern — "My Pattern Triggers" (ranked list). Always editable. |
| **Completion screen** | System | *"You've just done something most people never do — looked honestly at your own patterns. This list is the map. Everything that comes next uses it."* |
| **Module 2 activates** | System | Challenge Your Thinking unlocks. |
| **Module 4 fully activates** | System | Build Your Guardrails becomes fully active. Environmental Restructuring task surfaces within 1–2 days. |
| **Phase 2 begins** | System | currentPhase → 2 (Going Deeper) |

---

### Day 21 — Cue Hierarchy retry (conditional)

**Condition: Day 14 threshold not met (fewer than 5 logs). Check again at Day 21.**

| Event | Type | Detail |
|---|---|---|
| **Day 21 check** | System | If ≥5 logs now exist → proceed with Cue Hierarchy (same flow as Day 14). If still fewer than 5 → extend to Day 28 with additional logging nudge. |
| **Logging nudge (if extending)** | Conditional prompt | *"It looks like logging moments has been tricky. That's completely normal — building any new habit takes time. Even if you can recall a recent moment now, you can log it retrospectively. Tap 'Log a moment' to try."* |

---

### Day 28 — Cue Hierarchy hard deadline (conditional)

**Condition: Day 21 threshold still not met. Proceed regardless.**

| Event | Type | Detail |
|---|---|---|
| **Day 28 hard proceed** | System | Cue Hierarchy exercise proceeds with whatever logs exist. Exercise runs in lighter form: *"Here's what you've captured so far — even if it's limited, what patterns if any do you notice?"* AI analysis runs on available data; generic rubric discovery questions supplement. |
| **Module 2 activates** | System | Unlocks regardless of log count at Day 28. |
| **Module 4 fully activates** | System | Unlocks regardless of log count at Day 28. |

---

## PHASE 2 — GOING DEEPER (Days 14/28 onward)

*Phase 2 begins when the Cue Hierarchy is complete. Modules 2 and 4 are now active alongside the continuing Module 1 daily check-in and Module 3 weekly compass.*

---

### Days 14/28 + 1–2 days — Environmental Restructuring

| Event | Type | Detail |
|---|---|---|
| **Environmental Restructuring task surfaces** | Task — one-time | Surfaced 1–2 days after Cue Hierarchy completion. Screen heading: *"Change the situation before you need to change your mind."* |
| **Flow** | Screen | User's top 3 cues shown from Cue Hierarchy. For each: one text field asking what concrete change they will make. Habit-specific suggested examples shown as soft chips. Minimum one change per cue (3 total). |
| **Vagueness check** | Inline validation | If response is too generic, gentle prompt: *"Even one small change per trigger makes a real difference — can you make it more specific?"* |
| **Output saved** | Journal output | Appended to existing Cue Hierarchy document under 🔍 Know Your Pattern. Grows the existing document. |

---

### Days 14/28 + 3–5 days — HRS Coping Plans

| Event | Type | Detail |
|---|---|---|
| **HRS Coping Plans task surfaces** | Task — one-time | Surfaced 2–3 days after Environmental Restructuring. One screen per cue, worked through sequentially. |
| **Flow per cue** | Screen | User's cue shown in their own words at top. Three fields: (1) Early warning signals — what tells you this is developing before craving peaks? (2) My first response — specific, concrete, time-buying action. (3) Escalation contact — who to reach if first response doesn't hold. |
| **Vagueness check** | Inline validation | If first response field is generic ("think positive," "be strong"): *"The most effective plans are very specific — a concrete action, not a mindset. What exactly will you do?"* |
| **Accountability partner link** | Conditional | Escalation contact field links to existing partner if set up. If not: *"This is a good moment to consider setting up a support partner."* |
| **HRS Coping Plans saved** | Journal output | Saved as pinned living document under 🛡 Build Your Guardrails — "My Coping Plans." One card per cue. Always editable. |

---

### Days 14/28 + 3–5 days (parallel) — Module 2 formal tasks begin

| Event | Type | Detail |
|---|---|---|
| **Task 1 — Review thought log** | Task — one-time | User shown all "thought that arose" fields from their behaviour logs, grouped by cue type where possible. Prompt: *"Look at what you were telling yourself just before. Do you notice any patterns?"* Bridge from logging phase into formal thought work. |
| **Task 2 — Five-step thought examination introduced** | Onboarding | Introduced as a journalling exercise. Entry points: "Examine a thought" button on habit card, and prompt card in Recovery Path. Five sequential steps: (1) Write the thought raw, (2) Name the thinking error (tap-to-select list), (3) Examine the evidence + friend question, (4) Write an accurate alternative, (5) Save to library option. Five-dot progress indicator. Draft saved if app closed mid-flow. Full UX detail in Freedom_Plan_Design_Decisions.md. |
| **Thought examination — recurring** | Recurring action | Available any time from habit card ("Examine a thought") or Recovery Path. Each entry stored under 💡 Challenge Your Thinking with label "Thought examined." |
| **Self-compassion anchor** | Embedded | Embedded in Step 3 of thought examination flow — the friend question. Never labelled "self-compassion" in the UI. |

---

### Days 14/28 + 10–12 days — Urge Surfing introduced

| Event | Type | Detail |
|---|---|---|
| **Urge Surfing introduction** | Task — one-time | Surfaced ~1 week after HRS Coping Plans complete. Introduction screen explains the urge arc (rise, peak, subside — typically 15–30 minutes) in warm, non-clinical language. |
| **Four steps introduced** | Onboarding screen | (1) Name it — observation not permission. (2) Locate it — where in your body? (3) Watch it — observe without acting. (4) Record it — log what happened. |
| **"Urge surfed" log entry — recurring** | Recurring action | Available any time from the habit card alongside "Log a moment." Three quick questions: Where did you feel it in your body? Did it rise and fall? What did it feel like to observe it rather than act? Stored under 🛡 Build Your Guardrails with label "Urge surfed." |

---

### Task 3 — Counter-response library (Module 2, ongoing from ~Day 21/35)

| Event | Type | Detail |
|---|---|---|
| **Counter-response library task surfaces** | Task — one-time prompt, ongoing action | Once 3–5 thought examinations have been completed, a prompt surfaces: *"You've examined several thoughts now. Let's build your counter-response library — your own words, ready for the moments when it's hardest to think straight."* |
| **Flow** | Screen | User reviews their top recurring automatic thoughts identified through examinations. For each, writes a specific first-person counter-response — their own words, drawing on their own evidence. |
| **Counter-responses saved** | Journal output | Saved as pinned living document under 💡 Challenge Your Thinking — "My Counter-responses." Always editable and growable. |

---

### Day 30 — Module 5 unlocks (time-based) + Lifestyle Balance Audit begins

| Event | Type | Detail |
|---|---|---|
| **Module 5 activates** | System | Navigate Lapses unlocks. Phase 3 begins (Sustained Practice). |
| **AVE education screen** | Task — one-time | Heading: *"Before anything happens — read this."* Explains lapse vs relapse distinction, the Abstinence Violation Effect, and why the response to a slip matters more than the slip itself. |
| **Recovery letter task** | Task — one-time | User writes a personal letter from their wiser self to their struggling self. Full-screen journal entry with soft guidance. Saved as pinned living document under 🌱 Navigate Lapses — "My recovery letter." |
| **"I had a moment" button activates** | System | Button now appears on habit card. Triggers the lapse response protocol when tapped. |
| **Lifestyle Balance Audit — first** | Task — recurring monthly | First instance surfaces at Day 30. Two-part journal entry: (1) What is taking from you? What is genuinely nourishing you? (2) What two activities will you build into this month? Stored under 🛡 Build Your Guardrails with label "Lifestyle balance review." |
| **Phase 3 begins** | System | currentPhase → 3 (Sustained Practice). All five modules now active. |

---

### Day 21 (ongoing) — Honeymoon over-confidence check

| Event | Type | Detail |
|---|---|---|
| **Proactive prompt** | Conditional prompt | *"Sometimes when things are going well, vigilance drops. That's normal — just worth noticing."* Surfaces at Day 21. Not alarming — just a gentle awareness nudge. |

---

## IF A LAPSE OCCURS (any time after "I had a moment" activates)

*This flow can occur at any point — Day 5 or Day 500. The protocol is the same.*

| Event | Type | Detail |
|---|---|---|
| **"I had a moment" tapped** | User action | Button on habit card. |
| **If Module 5 not yet unlocked** | Conditional | Module 5 unlocks immediately. AVE education and recovery letter shown first before lapse response protocol. |
| **Screen 1 — Stop the spiral** | Screen | Full screen, large warm text. No form fields. *"First — stop. Whatever your mind is telling you right now... those thoughts are not facts. One moment is one moment. It is not a verdict. Take a breath. You're still here. That matters."* Single button: "I'm ready to continue." |
| **Screen 2 — Recovery letter** | Screen | User's own recovery letter shown back to them. If not written yet, brief compassionate version from app shown. *"Read it. Take whatever time you need."* |
| **Screen 3 — Self-compassion** | Screen | One question: *"What would you say to a good friend who had just gone through exactly this moment?"* Text field. Written and saved. |
| **Screen 4 — Forensic analysis** | Screen | Four sequential fields: (1) Situation just before, (2) Emotional state, (3) Thought that arose, (4) Where did the coping plan not hold? |
| **Screen 5 — Extract and recommit** | Screen | Two questions: What does this teach you about your coping plan? Which value do you want to take the next right step toward? Button: "Update my coping plan" → opens relevant HRS coping plan card directly. |
| **Completion moment** | Screen | *"You didn't give up. You came back. That is what recovery actually looks like — not a straight line, but coming back every time. Your plan is updated. Your values are still yours. Keep going."* |
| **Lapse saved** | Journal output | Stored under 🌱 Navigate Lapses with label "Lapse — [date]" |

---

## PHASE 3 — SUSTAINED PRACTICE (Day 30–90)

### Recurring daily and weekly actions (all phases)

| Action | Frequency | Detail |
|---|---|---|
| **"Log a moment"** | As needed | Available any time on habit card. 4-field behaviour capture. |
| **"Urge surfed"** | As needed | Available any time on habit card. 3-question log. |
| **Thought examination** | As needed | Available from Recovery Path. 5-step journal entry. |
| **Weekly values compass** | Weekly (from Day 7) | 5-minute review of top values, toward/away rating, one course correction. |
| **Zero-log nudge** | Weekly check | If zero logs in past 7 days, gentle check-in surfaces. |
| **Lifestyle Balance Audit** | Monthly (from Day 30) | Two-part journal entry on demands vs genuine rewards. |

### Proactive high-risk prompts

| Trigger | Prompt |
|---|---|
| Days 7 and 14 | *"The early weeks are often the hardest — the old pathway is still firing strongly. How are you doing?"* |
| Day 21 | *"Sometimes when things are going well, vigilance drops. That's normal — just worth noticing."* |
| User rates emotional state very high in daily check-in | *"It looks like it's been a difficult stretch. Stressful periods are when the plan matters most. Is your coping plan still working?"* |

---

## PHASE 4 — MAINTENANCE (Day 90+)

### Day 90 — Phase 4 unlock

**Condition:** 90 days elapsed AND Module 3 Values Inventory complete (which it will be from Day 1).

| Event | Type | Detail |
|---|---|---|
| **Phase 4 begins** | System | currentPhase → 4 (Maintenance). All modules remain active. Emphasis shifts to quarterly review. |
| **First quarterly review surfaces** | Task — recurring quarterly | Five questions: (1) What has genuinely changed? (2) What is still fragile? (3) Has your cue hierarchy changed? (4) Does your values compass need recalibrating? (5) What one thing will you do differently in the next three months? Stored under 🌱 Navigate Lapses with label "Quarterly review." |

### Ongoing recurring actions (Phase 4)

| Action | Frequency |
|---|---|
| Weekly values compass | Weekly |
| Lifestyle Balance Audit | Monthly |
| Quarterly review | Every 90 days |
| "Log a moment" | As needed |
| "Urge surfed" | As needed |
| Thought examination | As needed |
| "I had a moment" | As needed — lapse protocol always available |

---

## COMPLETE JOURNAL OUTPUT REFERENCE

| Entry type | Journal label | Section | Type |
|---|---|---|---|
| Values Inventory | "My Values Inventory" | ⚓ Anchor to Your Values | Living document (pinned) — one combined document for all 8 domains |
| Values compass check | "Values compass" | ⚓ Anchor to Your Values | Journal entry (weekly) — includes committed action |
| Daily check-in | "Daily check-in" | 🔍 Know Your Pattern | Journal entry (daily) — structured data (rating + outcome) |
| Behaviour log | "Moment logged" | 🔍 Know Your Pattern | Journal entry |
| Mid-point reflection | "Mid-point reflection" | 🔍 Know Your Pattern | Journal entry (one-time) |
| Cue Hierarchy | "My Pattern Triggers" | 🔍 Know Your Pattern | Living document (pinned) |
| Thought examination | "Thought examined" | 💡 Challenge Your Thinking | Journal entry |
| Counter-responses library | "My Counter-responses" | 💡 Challenge Your Thinking | Living document (pinned) |
| Environmental changes | Appended to Cue Hierarchy | 🔍 Know Your Pattern | Living document (existing) |
| HRS Coping Plans | "My Coping Plans" | 🛡 Build Your Guardrails | Living document (pinned) |
| Urge surfing log | "Urge surfed" | 🛡 Build Your Guardrails | Journal entry |
| Lifestyle balance review | "Lifestyle balance review" | 🛡 Build Your Guardrails | Journal entry (monthly) |
| Recovery letter | "My recovery letter" | 🌱 Navigate Lapses | Living document (pinned) |
| Lapse record | "Lapse — [date]" | 🌱 Navigate Lapses | Journal entry |
| Quarterly review | "Quarterly review" | 🌱 Navigate Lapses | Journal entry (quarterly) |

---

## PHASE PROGRESSION SUMMARY

| Phase | Name | Condition to enter | Active modules |
|---|---|---|---|
| 1 | Getting Started | Path created (Day 1) | M1 + M3 + M4 (partial) |
| 2 | Going Deeper | Cue Hierarchy complete (Day 14–28) | M1 + M2 + M3 + M4 (full) |
| 3 | Sustained Practice | Day 30 OR first lapse recorded | All five modules |
| 4 | Maintenance | Day 90 AND Values Inventory complete | All five modules, quarterly emphasis |

---

## KEY DESIGN RULES (summary for implementation)

| Rule | Detail |
|---|---|
| No streak tracking | No streak counter, no "days clean" display, no reset animation. Removed/suppressed for Walking Free habits. |
| No push notifications for milestone tasks | Cue Hierarchy, module unlocks, compass nudges, high-risk prompts — all surfaced in-app only. Only push notification is accountability partner messages. |
| All user input lives in the Journal | No data capture outside the Freedom Journey journal section. |
| Accountability partner never sees journal | Journal entries are private absolutely. Partner only receives messages user deliberately sends. |
| Cues end in user's own language | AI suggestions and chip selections are starting points only. The saved Cue Hierarchy must reflect the user's own words. |
| Coping plans must be specific | Generic responses gently blocked with inline prompt. |
| "I had a moment" available from Day 1 | Not Day 30. If tapped before Module 5 unlocks, Module 5 unlocks immediately. AVE education and recovery letter shown first. |
| Lapse response is never a form | First screen after "I had a moment" is always a full-screen compassionate statement — never a data entry screen. |
| Draft and resume | Values Inventory, Cue Hierarchy, HRS Coping Plans, Thought examination — all save progress and resume. Lapse protocol does NOT auto-resume — prompts user to choose whether to continue on next open. |
| Values Inventory is one combined document | All 8 domains saved as one pinned document, not 8 separate journal entries. |
| Daily check-in is distinct from "Log a moment" | Check-in = 2 questions, 30 seconds, daily habit. Log a moment = 4 fields, detailed situational capture, as needed. Both available throughout all phases. |
| Tone throughout | Warm, curious, non-judgemental, non-clinical. No module numbers visible to the user. No clinical terminology in UI. |

---

*Last updated: working session — Full plan review applied. All inconsistencies resolved. Cross-reference with Freedom_Plan_Design_Decisions.md for full rationale behind each decision.*
