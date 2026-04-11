import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../kingdom_life/bible_project_browser_view.dart';
import '../memorization/memorization_router.dart';
import '../settings/settings_view.dart';
import 'notification_bell.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';

/// Standard AppBar actions for Today, Progress, Kingdom Life, and Circles screens.
/// Order: Bible | Memorization (Premium) | Notifications | Settings | ⋮ (Help)
List<Widget> standardAppBarActions(BuildContext context, {Widget? helpView}) {
  final iconColor = MyWalkColor.warmWhite.withValues(alpha: 0.7);
  final isPremium = context.watch<StoreProvider>().isPremium;
  return [
    IconButton(
      icon: Icon(Icons.menu_book_outlined, color: iconColor),
      onPressed: () => BibleProjectBrowserView.openOrPrompt(context),
      tooltip: 'Bible',
    ),
    if (isPremium)
      IconButton(
        icon: Icon(Icons.psychology, color: iconColor),
        onPressed: () => MemorizationRouter.pushHome(context),
        tooltip: 'Memorization',
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
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: iconColor),
        color: MyWalkColor.cardBackground,
        onSelected: (value) {
          if (value == 'help') {
            Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => helpView),
            );
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'help',
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: MyWalkColor.warmWhite.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
                const Text('Help',
                    style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 14)),
              ],
            ),
          ),
        ],
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
