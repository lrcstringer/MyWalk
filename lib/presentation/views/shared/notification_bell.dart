import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/circle_notification_provider.dart';
import '../notifications/notification_inbox_view.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CircleNotificationProvider>().unreadCount;
    return IconButton(
      icon: count > 0
          ? Badge(
              label: count > 9 ? const Text('9+') : Text('$count'),
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
      tooltip: 'Notifications',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationInboxView()),
      ),
    );
  }
}
