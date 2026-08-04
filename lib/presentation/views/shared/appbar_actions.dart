import 'package:flutter/material.dart';
import '../kingdom_life/bible_project_browser_view.dart';
import '../settings/settings_view.dart';
import 'notification_bell.dart';
import '../../theme/app_theme.dart';

/// Standard AppBar actions for Today, Practices, Kingdom Life, and Circles screens.
/// Order: Bible | Notifications | Settings | ⋮ (Help)
List<Widget> standardAppBarActions(BuildContext context, {Widget? helpView}) {
  final iconColor = MyWalkColor.warmWhite.withValues(alpha: 0.7);
  return [
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
    if (helpView != null)
      IconButton(
        icon: Icon(Icons.info_outline, color: iconColor),
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => helpView),
        ),
        tooltip: 'Help',
      ),
  ];
}

/// Info / Help icon — kept for screens that don't use standardAppBarActions
/// (e.g. Journal which uses a theme-aware color).
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
