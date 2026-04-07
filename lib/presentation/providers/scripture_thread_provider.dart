import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class ScriptureThreadProvider extends ChangeNotifier {
  final CircleRepository _repo;

  ScriptureThreadProvider(this._repo);

  // ── Thread list ────────────────────────────────────────────────────────────

  final Map<String, List<ScriptureThread>> _threadsByCircle = {};
  final Map<String, StreamSubscription<List<ScriptureThread>>>
      _threadSubs = {};
  // True from first watchThreads() call until the first snapshot arrives.
  final Set<String> _loadingCircles = {};

  List<ScriptureThread> threadsFor(String circleId) =>
      _threadsByCircle[circleId] ?? [];

  bool isLoadingThreads(String circleId) =>
      _loadingCircles.contains(circleId);

  void watchThreads(String circleId, {required bool isAdmin}) {
    // Already subscribed for this circle — nothing to do.
    if (_threadSubs.containsKey(circleId)) return;
    _loadingCircles.add(circleId);
    _threadSubs[circleId] =
        _repo.watchThreads(circleId, isAdmin: isAdmin).listen(
      (threads) {
        _threadsByCircle[circleId] = threads;
        _loadingCircles.remove(circleId);
        notifyListeners();
      },
      onError: (_) {
        _threadsByCircle[circleId] = [];
        _loadingCircles.remove(circleId);
        notifyListeners();
      },
    );
  }

  void stopWatchingThreads(String circleId) {
    _threadSubs[circleId]?.cancel();
    _threadSubs.remove(circleId);
    _threadsByCircle.remove(circleId);
    _loadingCircles.remove(circleId);
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  final Map<String, List<ScriptureComment>> _commentsByThread = {};
  final Map<String, StreamSubscription<List<ScriptureComment>>>
      _commentSubs = {};

  List<ScriptureComment> commentsFor(String threadId) =>
      _commentsByThread[threadId] ?? [];

  void watchComments(String circleId, String threadId) {
    if (_commentSubs.containsKey(threadId)) return;
    _commentSubs[threadId] =
        _repo.watchComments(circleId, threadId).listen(
      (comments) {
        _commentsByThread[threadId] = comments;
        notifyListeners();
      },
      onError: (_) {
        _commentsByThread[threadId] = [];
        notifyListeners();
      },
    );
  }

  void stopWatchingComments(String threadId) {
    _commentSubs[threadId]?.cancel();
    _commentSubs.remove(threadId);
    _commentsByThread.remove(threadId);
  }

  // ── Thread actions ─────────────────────────────────────────────────────────

  Future<void> createThread({
    required String circleId,
    required String reference,
    required String passageText,
    required String translation,
  }) =>
      _repo.createThread(
        circleId: circleId,
        reference: reference,
        passageText: passageText,
        translation: translation,
      );

  Future<void> closeThread(String circleId, String threadId) =>
      _repo.closeThread(circleId, threadId);

  Future<void> deleteThread(String circleId, String threadId) =>
      _repo.deleteThread(circleId, threadId);

  // ── Comment actions ────────────────────────────────────────────────────────

  Future<void> addComment({
    required String circleId,
    required String threadId,
    required String text,
    String? parentId,
  }) =>
      _repo.addComment(
        circleId: circleId,
        threadId: threadId,
        text: text,
        parentId: parentId,
      );

  Future<void> deleteComment(
          String circleId, String threadId, String commentId) =>
      _repo.deleteComment(circleId, threadId, commentId);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final sub in _threadSubs.values) {
      sub.cancel();
    }
    for (final sub in _commentSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
