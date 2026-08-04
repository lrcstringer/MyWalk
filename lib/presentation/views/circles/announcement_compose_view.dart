import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/circle_notification_provider.dart';
import '../../theme/app_theme.dart';

class AnnouncementComposeView extends StatefulWidget {
  final String circleId;
  final String circleName;

  const AnnouncementComposeView({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  State<AnnouncementComposeView> createState() =>
      _AnnouncementComposeViewState();
}

class _AnnouncementComposeViewState extends State<AnnouncementComposeView> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<CircleNotificationProvider>().sendAnnouncement(
            circleId: widget.circleId,
            message: message,
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
        title: const Text('Send Announcement'),
        leadingWidth: 72,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: const [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(height: 1, child: ColoredBox(color: MyWalkColor.softGold)),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To all members of ${widget.circleName}',
                style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 500,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: MyWalkColor.warmWhite,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your announcement…',
                    hintStyle: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyWalkColor.softGold,
                    foregroundColor: MyWalkColor.charcoal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                      : const Text('Send Announcement',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}
