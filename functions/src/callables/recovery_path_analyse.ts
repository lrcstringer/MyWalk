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

    const systemPrompt = `You are analysing behaviour logs from a recovery app to identify cue patterns.
The user is working on overcoming: ${habitType}.
Based on these logs, identify 2-4 specific cue patterns — combinations of situation and emotional state that reliably precede the behaviour.
Format each pattern as a plain-language statement under 12 words, written as a situation description (not advice).
Known common cues for this habit type: ${JSON.stringify(primaryCues)}
Respond with ONLY a JSON array of strings. No explanation. No markdown. Example:
["Late evenings when feeling flat or stressed","After difficult conversations at work"]`;

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
      const parsed = JSON.parse(rawContent.text.trim());
      if (!Array.isArray(parsed)) throw new Error('not an array');
      cues = parsed
        .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
        .slice(0, 4);
      if (cues.length === 0) throw new Error('empty cue list');
    } catch {
      throw new HttpsError('internal', 'Failed to parse cue suggestions from Claude');
    }

    return { cues };
  }
);
