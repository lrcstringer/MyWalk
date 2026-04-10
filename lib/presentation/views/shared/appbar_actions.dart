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
      icon: Icon(Icons.psychology, color: iconColor),
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

/// Info / Help icon for any screen. [color] defaults to the standard warm-white.
Widget infoIconAction(
  BuildContext context,
  Widget helpView, {
  Color? color,
}) {
  return IconButton(
    icon: Icon(
      Icons.info_outline,
      color: color ?? MyWalkColor.warmWhite.withValues(alpha: 0.7),
    ),
    onPressed: () => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => helpView),
    ),
    tooltip: 'Help',
  );
}

/// Standalone Bible icon for screens that use a theme-aware color (e.g. Journal).
Widget bibleBrowserAction(BuildContext context, Color color) {
  return IconButton(
    icon: Icon(Icons.menu_book_outlined, color: color),
    onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
    tooltip: 'Bible',
  );
}
