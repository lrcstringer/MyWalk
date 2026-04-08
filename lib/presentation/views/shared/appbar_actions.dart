import 'package:flutter/material.dart';
import '../kingdom_life/bible_project_browser_view.dart';
import '../memorization/memorization_router.dart';
import '../settings/settings_view.dart';
import 'notification_bell.dart';
import '../../theme/app_theme.dart';

/// Standard AppBar actions for Today, Progress, Kingdom Life, and Circles screens.
/// Order: Memorization | Bible | Notifications | Settings
List<Widget> standardAppBarActions(BuildContext context) {
  final iconColor = MyWalkColor.warmWhite.withValues(alpha: 0.7);
  return [
    IconButton(
      icon: Icon(Icons.auto_stories_outlined, color: iconColor),
      onPressed: () => MemorizationRouter.pushHome(context),
      tooltip: 'Memorization',
    ),
    IconButton(
      icon: Icon(Icons.menu_book_outlined, color: iconColor),
      onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
      tooltip: 'Bible',
    ),
    const NotificationBell(),
    IconButton(
      icon: Icon(Icons.settings_outlined, color: iconColor),
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const SettingsView()),
      ),
      tooltip: 'Settings',
    ),
  ];
}

/// Standalone Bible icon for screens that use a theme-aware color (e.g. Journal).
Widget bibleBrowserAction(BuildContext context, Color color) {
  return IconButton(
    icon: Icon(Icons.menu_book_outlined, color: color),
    onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
    tooltip: 'Bible',
  );
}
