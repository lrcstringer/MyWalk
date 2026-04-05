import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/circle_notification.dart';
import '../../providers/circle_notification_provider.dart';
import '../../theme/app_theme.dart';

class NotificationInboxView extends StatelessWidget {
  const NotificationInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text('Notifications'),
        centerTitle: false,
      ),
      body: Consumer<CircleNotificationProvider>(
        builder: (context, provider, _) {
          // Show a spinner on first load (no data yet and no error).
          if (provider.notifications.isEmpty && provider.error == null) {
            // The stream emits synchronously from Firestore offline cache on first
            // frame if data is cached; treat an empty list after a brief build as
            // "genuinely empty" rather than "still loading". A FutureBuilder-based
            // shimmer would over-engineer this; a simple check suffices.
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.5), fontSize: 16),
                  ),
                ],
              ),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Text(
                'Could not load notifications',
                style: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.5), fontSize: 15),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, i) {
              final notif = provider.notifications[i];
              return _NotificationTile(
                notification: notif,
                onMarkRead: () => provider.markRead(notif.id),
                onAction: (action) => provider.recordAction(notif.id, action),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final CircleNotification notification;
  final VoidCallback onMarkRead;
  final void Function(NotificationAction) onAction;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;
    final color = _typeColor(n.type);
    final icon = _typeIcon(n.type);
    final timeStr = _formatTime(n.createdAt);

    return InkWell(
      onTap: isUnread ? onMarkRead : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: isUnread
            ? MyWalkColor.warmWhite.withValues(alpha: 0.04)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _typeLabel(n.type),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Sender + circle
                  Text(
                    '${n.senderName} · ${n.circleName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Message
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.45,
                    ),
                  ),
                  // Action buttons
                  if (!n.suppressActions) ...[
                    const SizedBox(height: 10),
                    _ActionRow(
                      notification: n,
                      onAction: onAction,
                    ),
                  ],
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(CircleNotificationType type) {
    switch (type) {
      case CircleNotificationType.sos:
        return const Color(0xFFE05555);
      case CircleNotificationType.prayerRequest:
        return MyWalkColor.softGold;
      case CircleNotificationType.announcement:
        return const Color(0xFF5B8DEF);
    }
  }

  IconData _typeIcon(CircleNotificationType type) {
    switch (type) {
      case CircleNotificationType.sos:
        return Icons.warning_rounded;
      case CircleNotificationType.prayerRequest:
        return Icons.volunteer_activism_rounded;
      case CircleNotificationType.announcement:
        return Icons.campaign_rounded;
    }
  }

  String _typeLabel(CircleNotificationType type) {
    switch (type) {
      case CircleNotificationType.sos:
        return 'SOS';
      case CircleNotificationType.prayerRequest:
        return 'PRAYER REQUEST';
      case CircleNotificationType.announcement:
        return 'ANNOUNCEMENT';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

// ── Action Row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final CircleNotification notification;
  final void Function(NotificationAction) onAction;

  const _ActionRow({required this.notification, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final taken = notification.actionTaken;

    if (taken != null) {
      final label = taken == NotificationAction.pray ? 'Prayed' : "I'm Here — sent";
      return Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: MyWalkColor.softGold.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.softGold.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _ActionButton(
          label: 'Pray',
          icon: Icons.favorite_border_rounded,
          onTap: () => onAction(NotificationAction.pray),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: "I'm Here",
          icon: Icons.handshake_outlined,
          onTap: () => onAction(NotificationAction.imHere),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MyWalkColor.warmWhite.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: MyWalkColor.warmWhite.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
