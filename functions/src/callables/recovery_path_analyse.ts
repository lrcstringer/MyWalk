import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import Anthropic from '@anthropic-ai/sdk';

const anthropicKey = defineSecret('ANTHROPIC_API_KEY');

interface LogEntry {
  date?: string;
  locationTime?: string;
  activityBefore?: string;
  emotionName?: string;
  emotionRating?: number;
  thoughtArose?: string;
}

// ── rpAnalyseCues ─────────────────────────────────────────────────────────────
// Callable function. Analyses a user's behaviour logs and returns 2-4 candidate
// cue patterns as plain-language strings.
//
// Input: { habitType: string, logs: LogEntry[], primaryCues: string[] }
// Output: { cues: string[] }
//
// On any API or parse error, throws HttpsError so the Flutter caller can catch
// it and fall through to discovery questions without crashing.

export const rpAnalyseCues = onCall(
  { region: 'us-central1', secrets: [anthropicKey], timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { habitType, logs, primaryCues } = request.data as {
      habitType: string;
      logs: LogEntry[];
      primaryCues: string[];
    };

    if (!habitType?.trim()) throw new HttpsError('invalid-argument', 'habitType required');
    if (!Array.isArray(logs) || logs.length === 0) {
      throw new HttpsError('invalid-argument', 'logs must be a non-empty array');
    }

    // Situational-only prompt: never names the habit or behaviour, only analyses
    // the context fields (when/where/emotion/thought) to find trigger patterns.
    const systemPrompt = `You are a clinical support tool for a behaviour-change recovery app.
Your task is to analyse journal entries from a person working to identify the situational triggers that precede a compulsive behaviour they are trying to change.

Each journal entry records only the CONTEXT before the moment — not the behaviour itself. Focus exclusively on:
- When and where they were (locationTime)
- What they were doing immediately before (activityBefore)
- Their emotional state (emotionName, emotionRating 1–10)
- Any thought that arose (thoughtArose)

Identify 2–4 recurring situational patterns across these entries. Each pattern should describe a specific combination of situation and emotional state that appears as a reliable trigger context.

Common trigger contexts to watch for: ${JSON.stringify(primaryCues)}

Rules:
- Each pattern must be under 12 words
- Write as a situation description, not advice
- Focus on WHEN/WHERE/HOW the person feels — not on any behaviour
- Respond with ONLY a JSON array of strings, no markdown, no explanation

Example output: ["Late evenings when feeling flat or stressed","After difficult conversations at work"]`;

    const userMessage = JSON.stringify(
      logs.map((l) => ({
        date: l.date ?? '',
        locationTime: l.locationTime ?? '',
        activityBefore: l.activityBefore ?? '',
        emotionName: l.emotionName ?? '',
        emotionRating: l.emotionRating ?? 0,
        thoughtArose: l.thoughtArose ?? '',
      }))
    );

    const client = new Anthropic({ apiKey: anthropicKey.value() });

    const message = await client.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 512,
      system: systemPrompt,
      messages: [{ role: 'user', content: userMessage }],
    });

    const rawContent = message.content[0];
    if (rawContent.type !== 'text') {
      throw new HttpsError('internal', 'Unexpected response type from Claude');
    }

    let cues: string[];
    try {
      const rawText = rawContent.text.trim();
      console.log('[rpAnalyseCues] raw response:', rawText.slice(0, 500));
      // Extract the first JSON array from anywhere in the response
      const match = rawText.match(/\[[\s\S]*?\]/);
      if (!match) throw new Error('no JSON array found');
      const parsed = JSON.parse(match[0]);
      if (!Array.isArray(parsed)) throw new Error('not an array');
      cues = parsed
        .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
        .slice(0, 4);
      if (cues.length === 0) throw new Error('empty cue list');
    } catch (e) {
      console.error('[rpAnalyseCues] parse error:', e);
      throw new HttpsError('internal', 'Failed to parse cue suggestions from Claude');
    }

    return { cues };
  }
);
