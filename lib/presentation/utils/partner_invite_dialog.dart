import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/accountability_repository.dart';
import '../providers/accountability_provider.dart';
import '../theme/app_theme.dart';

/// Shows the full partner-invite flow: email dialog → createInvite → in-app
/// confirmation or share sheet. Identical UX whether triggered from the
/// Today card or the Breaking Free setup screen.
Future<void> showPartnerInviteDialog(
  BuildContext context, {
  required String habitId,
  required String habitName,
  String? habitLabel,
}) async {
  final accountabilityProv = context.read<AccountabilityProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final emailController = TextEditingController();
  final email = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MyWalkColor.charcoal,
      title: const Text(
        'Invite a support partner',
        style: TextStyle(
            color: MyWalkColor.warmWhite,
            fontWeight: FontWeight.w600,
            fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option 1
          const Text(
            'If you know their MyWalk email address:',
            style: TextStyle(
                color: MyWalkColor.sage,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter it below and they will receive an in-app notification immediately.',
            style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'their@email (optional)',
              hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                  fontSize: 13),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.2))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: MyWalkColor.sage)),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: MyWalkColor.warmWhite.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          // Option 2
          const Text(
            "If you don't know their email address:",
            style: TextStyle(
                color: MyWalkColor.sage,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'Just tap Continue and a link will be created that you can share via WhatsApp, Email or SMS.',
            style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel',
              style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
          child:
              const Text('Continue', style: TextStyle(color: MyWalkColor.sage)),
        ),
      ],
    ),
  );
  emailController.dispose();

  // null means user tapped Cancel; empty string means they skipped the email field.
  if (email == null || !context.mounted) return;

  try {
    final result = await accountabilityProv.createInvite(
      habitId: habitId,
      habitName: habitName,
      habitLabel: habitLabel,
      recipientEmail: email.isEmpty ? null : email,
    );
    if (!context.mounted) return;
    if (result.inAppSent) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          "Invitation sent! They'll see it in their MyWalk notifications. "
          'Share code as backup: ${result.shortCode}',
        ),
        duration: const Duration(seconds: 6),
      ));
    } else {
      if (email.isNotEmpty && context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: MyWalkColor.charcoal,
            title: const Text('No account found',
                style: TextStyle(
                    color: MyWalkColor.warmWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            content: const Text(
              "We couldn't find a MyWalk account with that email. Here's a link you can share instead.",
              style: TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Share link',
                    style: TextStyle(color: MyWalkColor.sage)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await _shareInvite(result, habitLabel ?? habitName);
        }
      } else {
        await _shareInvite(result, habitLabel ?? habitName);
      }
    }
  } catch (e) {
    debugPrint('createInvite failed: $e');
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not create invite. Try again.')),
      );
    }
  }
}

Future<void> _shareInvite(InviteResult result, String label) async {
  await Share.share(
    'Please walk with me on my $label journey.\n\n'
    'IF YOU ALREADY HAVE MYWALK ON YOUR MOBILE:\n\n'
    '1) Tap this link: ${result.shareUrl}\n\n'
    'Or\n\n'
    '2) Tap on the Notifications Bell at the top on the app screen and then on the "Have an Invite Code?" card and enter this code: ${result.shortCode}\n\n\n'
    "IF YOU DON'T HAVE MYWALK INSTALLED ON YOUR MOBILE:\n\n"
    'Download it from the Google Play Store or Apple Store.\n\n'
    'Then either:\n\n'
    '1) Come back to this email and tap this link: ${result.shareUrl}\n\n'
    'Or\n\n'
    '2) Tap on the Notifications Bell at the top on the app screen and then on the "Have an Invite Code?" card and enter this code: ${result.shortCode}',
  );
}
