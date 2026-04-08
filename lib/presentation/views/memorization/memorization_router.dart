import 'package:flutter/material.dart';
import '../../../domain/entities/memorization_item.dart';
import 'screens/memorization_home_screen.dart';
import 'screens/memorization_input_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/item_dashboard_screen.dart';

class MemorizationRouter {
  MemorizationRouter._();

  static Future<void> pushHome(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationHomeScreen()),
    );
  }

  static Future<void> pushNewItem(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationInputScreen()),
    );
  }

  static Future<void> pushModeSelection(
    BuildContext context,
    MemorizationItem item,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ModeSelectionScreen(item: item)),
    );
  }

  static Future<void> pushItemDashboard(
    BuildContext context,
    MemorizationItem item,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ItemDashboardScreen(item: item)),
    );
  }
}
