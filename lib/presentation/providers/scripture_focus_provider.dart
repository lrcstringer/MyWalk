import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_id_service.dart';

class ScriptureFocusProvider extends ChangeNotifier {
  final CircleRepository _repo;

  ScriptureFocusProvider(this._repo);

  final Map<String, ScriptureFocus?> _focusByCircle = {};
  final Map<String, List<ScriptureReflection>> _reflectionsByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  // Tracks which weekIds the current user has already submitted a reflection for.
  final Set<String> _submittedReflectionWeekIds = {};
  bool _settingFocus = false;
  bool _submittingReflection = false;
  String? error;

  ScriptureFocus? focusFor(String circleId) => _focusByCircle[circleId];
  List<ScriptureReflection> reflectionsFor(String circleId) =>
      _reflectionsByCircle[circleId] ?? [];
  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isSettingFocus => _settingFocus;
  bool get isSubmittingReflection => _submittingReflection;

  bool hasSubmittedReflection(String circleId) {
    final focus = _focusByCircle[circleId];
    if (focus == null) return false;
    return _submittedReflectionWeekIds.contains('${circleId}_${focus.id}');
  }

  Future<void> load(String circleId, String uid) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final focus = await _repo.getCurrentScriptureFocus(circleId);
      _focusByCircle[circleId] = focus;

      if (focus != null) {
        final reflections = await _repo.getReflections(circleId, focus.id);
        _reflectionsByCircle[circleId] = reflections;
        // Determine if user has already submitted.
        if (reflections.any((r) => r.isAuthor(uid))) {
          _submittedReflectionWeekIds.add('${circleId}_${focus.id}');
        }
      } else {
        _reflectionsByCircle[circleId] = [];
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<String> fetchPassagePreview(
      String reference, String translation) async {
    return _repo.fetchBiblePassage(reference, translation);
  }

  Future<void> setFocus({
    required String circleId,
    required String reference,
    required String translation,
    required String passageText,
    String? reflectionPrompt,
  }) async {
    _settingFocus = true;
    error = null;
    notifyListeners();

    try {
      await _repo.setScriptureFocus(
        circleId: circleId,
        reference: reference,
        translation: translation,
        passageText: passageText,
        reflectionPrompt: reflectionPrompt,
      );
      // Reload to get server-assigned weekId and timestamps.
      final weekId = WeekIdService.currentWeekId();
      final focus = ScriptureFocus(
        id: weekId,
        circleId: circleId,
        setById: '',
        setByDisplayName: '',
        reference: reference,
        text: passageText,
        translation: translation,
        reflectionPrompt: reflectionPrompt,
        weekStartDate: WeekIdService.weekStart(DateTime.now()).toIso8601String(),
        createdAt: DateTime.now().toIso8601String(),
      );
      _focusByCircle[circleId] = focus;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _settingFocus = false;
      notifyListeners();
    }
  }

  Future<void> submitReflection({
    required String circleId,
    required String weekId,
    required String text,
    required String uid,
    required String displayName,
  }) async {
    _submittingReflection = true;
    error = null;
    notifyListeners();

    try {
      await _repo.submitReflection(
          circleId: circleId, weekId: weekId, text: text);
      // Optimistic local append.
      final newReflection = ScriptureReflection(
        id: uid,
        authorId: uid,
        authorDisplayName: displayName,
        reflectionText: text,
        createdAt: DateTime.now().toIso8601String(),
      );
      final existing = List<ScriptureReflection>.from(
          _reflectionsByCircle[circleId] ?? []);
      existing.add(newReflection);
      _reflectionsByCircle[circleId] = existing;
      _submittedReflectionWeekIds.add('${circleId}_$weekId');
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _submittingReflection = false;
      notifyListeners();
    }
  }
}
