import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class CircleEventsProvider extends ChangeNotifier {
  final CircleRepository _repo;

  CircleEventsProvider(this._repo);

  final Map<String, List<CircleEvent>> _eventsByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _creating = false;
  String? error;

  List<CircleEvent> eventsFor(String circleId) =>
      _eventsByCircle[circleId] ?? [];

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isCreating => _creating;

  Future<void> load(String circleId) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final events = await _repo.getUpcomingEvents(circleId);
      _eventsByCircle[circleId] = events;
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String circleId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
    String? meetingLink,
  }) async {
    _creating = true;
    error = null;
    notifyListeners();

    try {
      await _repo.createEvent(
        circleId: circleId,
        title: title,
        eventDate: eventDate,
        description: description,
        location: location,
        meetingLink: meetingLink,
      );
      await load(circleId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent({
    required String circleId,
    required String eventId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
    String? meetingLink,
  }) async {
    try {
      await _repo.updateEvent(
        circleId: circleId,
        eventId: eventId,
        title: title,
        eventDate: eventDate,
        description: description,
        location: location,
        meetingLink: meetingLink,
      );
      await load(circleId);
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteEvent(String circleId, String eventId) async {
    // Optimistic removal.
    final prev = _eventsByCircle[circleId];
    if (prev != null) {
      _eventsByCircle[circleId] =
          prev.where((e) => e.id != eventId).toList();
      notifyListeners();
    }

    try {
      await _repo.deleteEvent(circleId, eventId);
    } catch (_) {
      // Roll back.
      if (prev != null) {
        _eventsByCircle[circleId] = prev;
        notifyListeners();
      }
    }
  }
}
