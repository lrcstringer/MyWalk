import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/entities/habit.dart' show PrayerItemStatus;
import '../../domain/repositories/circle_repository.dart';

class GroupPrayerListProvider extends ChangeNotifier {
  final CircleRepository _repo;

  GroupPrayerListProvider(this._repo);

  final Map<String, CirclePrayerList?> _listByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  String? error;

  CirclePrayerList? listFor(String circleId) => _listByCircle[circleId];
  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;

  Future<void> load(String circleId) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();
    try {
      _listByCircle[circleId] = await _repo.getGroupPrayerList(circleId);
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> createList(String circleId, List<String> visibleToMemberIds) async {
    final list = CirclePrayerList(
      circleId: circleId,
      visibleToMemberIds: visibleToMemberIds,
    );
    await _repo.saveGroupPrayerList(list);
    await load(circleId);
  }

  Future<void> updateVisibility(
      String circleId, List<String> visibleToMemberIds) async {
    final current = _listByCircle[circleId];
    if (current == null) return;
    await _repo.saveGroupPrayerList(
      CirclePrayerList(
        circleId: current.circleId,
        createdBy: current.createdBy,
        createdAt: current.createdAt,
        visibleToMemberIds: visibleToMemberIds,
        items: current.items,
      ),
    );
    await load(circleId);
  }

  Future<void> addItem(String circleId, String text) async {
    // Use wall-clock millis as order: monotonically increasing, no TOCTOU,
    // and two concurrent admin writes get distinct values in all but
    // sub-millisecond races (acceptable for a manually curated list).
    final nextOrder = DateTime.now().millisecondsSinceEpoch;
    final item = CirclePrayerItem.create(text, nextOrder);
    await _repo.upsertGroupPrayerItem(circleId, item);
    await load(circleId);
  }

  Future<void> updateItemStatus(
      String circleId, CirclePrayerItem item, PrayerItemStatus status) async {
    final answeredAt = status == PrayerItemStatus.answered
        ? DateTime.now().toIso8601String()
        : null;
    await _repo.upsertGroupPrayerItem(
        circleId, item.copyWith(status: status, answeredAt: answeredAt));
    await load(circleId);
  }

  Future<void> updateItemMemo(
      String circleId, CirclePrayerItem item, String memo) async {
    await _repo.upsertGroupPrayerItem(
        circleId, item.copyWith(memo: memo.isEmpty ? null : memo));
    await load(circleId);
  }

  Future<void> updateItemText(
      String circleId, CirclePrayerItem item, String text) async {
    await _repo.upsertGroupPrayerItem(circleId, item.copyWith(text: text));
    await load(circleId);
  }

  Future<void> shareGratitude({
    required String circleId,
    required String text,
    required bool isAnonymous,
  }) =>
      _repo.shareGratitude(
        circleIds: [circleId],
        gratitudeText: text,
        isAnonymous: isAnonymous,
      );

  Future<void> deleteItem(String circleId, String itemId) async {
    await _repo.deleteGroupPrayerItem(circleId, itemId);
    // Capture once to avoid TOCTOU between null-check and field access.
    final current = _listByCircle[circleId];
    if (current != null) {
      _listByCircle[circleId] = CirclePrayerList(
        circleId: circleId,
        createdBy: current.createdBy,
        createdAt: current.createdAt,
        visibleToMemberIds: current.visibleToMemberIds,
        items: current.items.where((i) => i.id != itemId).toList(),
      );
    }
    notifyListeners();
  }
}
