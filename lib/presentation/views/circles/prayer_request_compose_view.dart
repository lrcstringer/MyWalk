import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/circle.dart';
import '../../providers/circle_notification_provider.dart';
import '../../theme/app_theme.dart';

class PrayerRequestComposeView extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;

  const PrayerRequestComposeView({
    super.key,
    required this.circleId,
    required this.members,
  });

  @override
  State<PrayerRequestComposeView> createState() =>
      _PrayerRequestComposeViewState();
}

class _PrayerRequestComposeViewState extends State<PrayerRequestComposeView> {
  final _controller = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty && _selectedIds.isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => _sending = true);
    try {
      await context.read<CircleNotificationProvider>().sendPrayerRequest(
            circleId: widget.circleId,
            message: _controller.text.trim(),
            recipientIds: _selectedIds.toList(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text('Prayer Request'),
        actions: [
          TextButton(
            onPressed: (_canSend && !_sending) ? _send : null,
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Send',
                    style: TextStyle(
                      color: _canSend
                          ? MyWalkColor.softGold
                          : MyWalkColor.softGold.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 500,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: MyWalkColor.warmWhite,
                  fontSize: 15,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your prayer request…',
                  hintStyle: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                ),
              ),
            ),
            Divider(color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Send to',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedIds.length == widget.members.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds
                              .addAll(widget.members.map((m) => m.userId));
                        }
                      });
                    },
                    child: Text(
                      _selectedIds.length == widget.members.length
                          ? 'Deselect all'
                          : 'Select all',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.softGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.members.length,
                itemBuilder: (context, i) {
                  final member = widget.members[i];
                  final selected = _selectedIds.contains(member.userId);
                  return CheckboxListTile(
                    value: selected,
                    activeColor: MyWalkColor.softGold,
                    checkColor: MyWalkColor.charcoal,
                    title: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName
                          : member.userId,
                      style: const TextStyle(
                          color: MyWalkColor.warmWhite, fontSize: 14),
                    ),
                    subtitle: member.isAdmin
                        ? Text(
                            'Admin',
                            style: TextStyle(
                                fontSize: 11,
                                color: MyWalkColor.softGold
                                    .withValues(alpha: 0.7)),
                          )
                        : null,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(member.userId);
                        } else {
                          _selectedIds.remove(member.userId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
