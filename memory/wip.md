# WIP: Offline Journal Support

## Goal
Make journals fully offline-capable: read cached entries offline, create/edit offline (sync when back online).

## Approach
Leverage Firestore's existing offline persistence (CACHE_SIZE_UNLIMITED already enabled) by:
1. Switching from `.get()` (fails offline) to `.snapshots()` stream (returns cache immediately)
2. Making writes fire-and-forget with `.ignore()` — Firestore queues internally and syncs when online

## Files
- `lib/domain/repositories/journal_repository.dart` — add `watchEntries()` abstract method
- `lib/data/repositories/firestore_journal_repository.dart` — implement stream, make writes fire-and-forget
- `lib/presentation/providers/journal_provider.dart` — subscribe to stream, remove manual _entries updates

## Progress
- [x] Update domain repository interface
- [x] Implement watchEntries() + fire-and-forget writes in Firestore repo
- [x] Refactor provider to use stream subscription
- [x] dart analyze clean — DONE

---

# Previous WIP: Scripture Discussion Threads

## What we're building
Replace the `ScriptureFocus`/`ScriptureReflection` model with a full discussion thread system.

## Spec
- Multiple threads per circle (not one-per-week)
- Thread = scripture passage + open comment feed
- One-level replies (top-level comment + replies to it, no deeper)
- Comments are plain text
- Passage text uses Quill Delta JSON (already done in SetScriptureFocusSheet)
- Real-time via Firestore streams
- `scriptureFocusPermission` gates who can CREATE a thread
- Users can delete their own comments
- Admin can close thread (hides from members, visible to admin only), delete thread, delete any comment

## Data model
```
circles/{circleId}/scripture_threads/{threadId}
  id, circleId, createdById, createdByDisplayName
  reference, passageText (Delta JSON), translation
  status: 'open' | 'closed'
  createdAt, closedAt?
  commentCount (denormalized)

circles/{circleId}/scripture_threads/{threadId}/comments/{commentId}
  id, threadId, authorId, authorDisplayName
  text (plain), parentId? (null=top-level, set=reply)
  createdAt, deletedAt? (soft delete)
```

## Files to create/modify
1. `lib/domain/entities/circle.dart` — remove ScriptureFocus/ScriptureReflection, add ScriptureThread/ScriptureComment
2. `lib/domain/repositories/circle_repository.dart` — swap scripture methods
3. `lib/data/repositories/firestore_circle_repository.dart` — new stream-based implementations
4. `lib/presentation/providers/scripture_thread_provider.dart` — NEW (replaces scripture_focus_provider.dart)
5. `lib/presentation/providers/scripture_focus_provider.dart` — DELETE (replaced)
6. `lib/presentation/views/circles/scripture_threads_tab.dart` — NEW thread list tab
7. `lib/presentation/views/circles/scripture_thread_detail_view.dart` — NEW thread detail + comments
8. `lib/presentation/views/circles/scripture_focus_tab.dart` — DELETE (replaced)
9. `lib/app.dart` — swap provider registration
10. `lib/presentation/views/circles/circle_detail_view.dart` — swap tab widget

## Progress
- [ ] Read necessary existing files
- [ ] Update circle.dart entities
- [ ] Update repository interface
- [ ] Update Firestore repository implementation
- [ ] Create ScriptureThreadProvider
- [ ] Create scripture_threads_tab.dart
- [ ] Create scripture_thread_detail_view.dart
- [ ] Update app.dart
- [ ] Update circle_detail_view.dart
- [ ] dart analyze clean
