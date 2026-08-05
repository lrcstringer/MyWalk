import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _pendingTab = -1;
  int get pendingTab => _pendingTab;

  void switchToTab(int index) {
    _pendingTab = index;
    notifyListeners();
  }

  void clearPending() {
    _pendingTab = -1;
  }
}
