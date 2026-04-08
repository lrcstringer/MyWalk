import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import Anthropic from '@anthropic-ai/sdk';
import * as textToSpeech from '@google-cloud/text-to-speech';
import * as admin from 'firebase-admin';

const anthropicKey = defineSecret('ANTHROPIC_API_KEY');

// ── chunkText ─────────────────────────────────────────────────────────────────
// Calls Claude Haiku to split a passage into 4–6 memorisable phrases.
// Returns: { chunks: [{ text: string, hint: string }] }

export const chunkText = onCall(
  { region: 'us-central1', secrets: [anthropicKey], timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { text } = request.data as { text: string };
    if (!text?.trim()) throw new HttpsError('invalid-argument', 'text required');
    if (text.trim().length > 2000) {
      throw new HttpsError('invalid-argument', 'text exceeds 2000 characters');
    }

    const client = new Anthropic({ apiKey: anthropicKey.value() });

    const systemPrompt = `You are a scripture memorization assistant. Split the provided text into 4–6 natural, memorisable phrases. Each phrase should be a complete thought or clause that can stand alone.

Respond with ONLY a JSON array (no markdown, no explanation):
[{"text":"phrase here","hint":"first letter scaffold, e.g. F G s l t w"},...]

Rules for hints:
- Each word → its first letter, lowercase
- Preserve punctuation attached to the word after the letter (e.g. "loved," → "l,")
- Articles, conjunctions, and prepositions get their first letter too`;

    const message = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: `Split this text into memorisable phrases:\n\n${text.trim()}`,
        },
      ],
      system: systemPrompt,
    });

    const rawContent = message.content[0];
    if (rawContent.type !== 'text') {
      throw new HttpsError('internal', 'Unexpected response from Claude');
    }

    let chunks: Array<{ text: string; hint: string }>;
    try {
      chunks = JSON.parse(rawContent.text.trim());
      if (!Array.isArray(chunks)) throw new Error('not array');
    } catch {
      throw new HttpsError('internal', 'Failed to parse Claude response as JSON');
    }

    // Validate and sanitise
    const validated = chunks
      .filter((c) => typeof c.text === 'string' && c.text.trim().length > 0)
      .slice(0, 8)
      .map((c) => ({
        text: c.text.trim(),
        hint: typeof c.hint === 'string' ? c.hint.trim() : '',
      }));

    return { chunks: validated };
  }
);

// ── generateTts ───────────────────────────────────────────────────────────────
// Generates Google Neural2 TTS for a memorization item's full text.
// Stores MP3 in Firebase Storage under memorization/{uid}/{itemId}.mp3
// Returns: { url: string } — a signed URL valid for 7 days.

export const generateTts = onCall(
  { region: 'us-central1', timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { text, itemId } = request.data as { text: string; itemId: string };
    if (!text?.trim()) throw new HttpsError('invalid-argument', 'text required');
    if (!itemId?.trim()) throw new HttpsError('invalid-argument', 'itemId required');

    const uid = request.auth.uid;

    const ttsClient = new textToSpeech.TextToSpeechClient();
    const [response] = await ttsClient.synthesizeSpeech({
      input: { text: text.trim() },
      voice: {
        languageCode: 'en-US',
        name: 'en-US-Neural2-C', // calm, clear female voice
        ssmlGender: 'FEMALE',
      },
      audioConfig: { audioEncoding: 'MP3' },
    });

    if (!response.audioContent) {
      throw new HttpsError('internal', 'TTS returned no audio content');
    }

    const bucket = admin.storage().bucket();
    const filePath = `memorization/${uid}/${itemId}.mp3`;
    const file = bucket.file(filePath);

    await file.save(Buffer.from(response.audioContent as Uint8Array), {
      contentType: 'audio/mpeg',
      metadata: { cacheControl: 'private, max-age=604800' },
    });

    // Signed URL valid for 7 days
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
    });

    return { url };
  }
);
