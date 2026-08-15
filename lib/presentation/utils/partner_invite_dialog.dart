import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/accountability_repository.dart';
import '../providers/accountability_provider.dart';
import '../theme/app_theme.dart';

// ── Full-screen partner invite (used in setup flow) ───────────────────────────

enum _InviteStatus { idle, loading, inAppSent, noAccount, readyToShare }

class PartnerInviteScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  final String? habitLabel;

  const PartnerInviteScreen({
    super.key,
    required this.habitId,
    required this.habitName,
    this.habitLabel,
  });

  @override
  State<PartnerInviteScreen> createState() => _PartnerInviteScreenState();
}

class _PartnerInviteScreenState extends State<PartnerInviteScreen> {
  final _emailController = TextEditingController();
  _InviteStatus _status = _InviteStatus.idle;
  InviteResult? _result;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prov = context.read<AccountabilityProvider>();
    final email = _emailController.text.trim();
    setState(() => _status = _InviteStatus.loading);
    try {
      final result = await prov.createInvite(
        habitId: widget.habitId,
        habitName: widget.habitName,
        habitLabel: widget.habitLabel,
        recipientEmail: email.isEmpty ? null : email,
      );
      if (!mounted) return;
      if (result.inAppSent) {
        setState(() { _status = _InviteStatus.inAppSent; _result = result; });
      } else if (email.isNotEmpty) {
        setState(() { _status = _InviteStatus.noAccount; _result = result; });
      } else {
        setState(() { _status = _InviteStatus.readyToShare; _result = result; });
      }
    } catch (e) {
      debugPrint('createInvite failed: $e');
      if (mounted) setState(() => _status = _InviteStatus.idle);
    }
  }

  void _goToSharePreview() {
    setState(() => _status = _InviteStatus.readyToShare);
  }

  Future<void> _doShare() async {
    if (_result != null) {
      await _shareInvite(_result!, widget.habitLabel ?? widget.habitName);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: MyWalkColor.warmWhite),
        title: const Text(
          'Invite a support partner',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_status == _InviteStatus.idle || _status == _InviteStatus.loading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Skip',
                  style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      fontSize: 14)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _InviteStatus.loading:
        return const Center(child: CircularProgressIndicator(color: MyWalkColor.sage));

      case _InviteStatus.inAppSent:
        return _SuccessView(
          shortCode: _result!.shortCode,
          onDone: () => Navigator.of(context).pop(),
        );

      case _InviteStatus.noAccount:
        return _NoAccountView(
          onShare: _goToSharePreview,
          onCancel: () => Navigator.of(context).pop(),
        );

      case _InviteStatus.readyToShare:
        return _ReadyToShareView(
          result: _result!,
          label: widget.habitLabel ?? widget.habitName,
          onShare: _doShare,
        );

      case _InviteStatus.idle:
        return _FormView(
          emailController: _emailController,
          onSubmit: _submit,
          onSkip: () => Navigator.of(context).pop(),
        );
    }
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  const _FormView({
    required this.emailController,
    required this.onSubmit,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'If you know their MyWalk email address:',
          style: TextStyle(
              color: MyWalkColor.sage,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter it below and they will receive an in-app notification immediately.',
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 28),
        Divider(color: MyWalkColor.warmWhite.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 24),
        const Text(
          "If you don't know their MyWalk email address:",
          style: TextStyle(
              color: MyWalkColor.sage,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          'Just tap Continue and a link will be created that you can share via WhatsApp, Email or SMS.',
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.sage,
              foregroundColor: MyWalkColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String shortCode;
  final VoidCallback onDone;

  const _SuccessView({required this.shortCode, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, color: MyWalkColor.sage, size: 64),
        const SizedBox(height: 20),
        const Text(
          'Invitation sent',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 22,
              fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "They'll see it in their MyWalk notifications.",
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Backup share code: $shortCode',
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.sage,
              foregroundColor: MyWalkColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _NoAccountView extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onCancel;

  const _NoAccountView({required this.onShare, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5), size: 48),
        const SizedBox(height: 20),
        const Text(
          'No account found',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 22,
              fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "We couldn't find a MyWalk account with that email. Share a link instead — they can use it once they've installed the app.",
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.sage,
              foregroundColor: MyWalkColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Share link',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel',
              style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                  fontSize: 14)),
        ),
      ],
    );
  }
}

class _ReadyToShareView extends StatelessWidget {
  final InviteResult result;
  final String label;
  final VoidCallback onShare;

  const _ReadyToShareView({
    required this.result,
    required this.label,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final message = _buildShareMessage(result, label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your invitation is ready',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how to send it to your support partner — WhatsApp, email, SMS, and more.',
          style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Choose how to send',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.sage,
              foregroundColor: MyWalkColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

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
            "If you don't know their MyWalk email address:",
            style: TextStyle(
                color: MyWalkColor.sage,
                fontSize: 15,
                fontWeight: FontWeight.w900,
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
          await _showSharePreviewSheet(context, result, habitLabel ?? habitName);
        }
      } else {
        await _showSharePreviewSheet(context, result, habitLabel ?? habitName);
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

String _buildShareMessage(InviteResult result, String label) =>
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
    '2) Tap on the Notifications Bell at the top on the app screen and then on the "Have an Invite Code?" card and enter this code: ${result.shortCode}';

Future<void> _shareInvite(InviteResult result, String label) async {
  await Share.share(_buildShareMessage(result, label));
}

Future<void> _showSharePreviewSheet(
    BuildContext context, InviteResult result, String label) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: MyWalkColor.charcoal,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SharePreviewSheet(result: result, label: label),
  );
}

class _SharePreviewSheet extends StatelessWidget {
  final InviteResult result;
  final String label;

  const _SharePreviewSheet({required this.result, required this.label});

  @override
  Widget build(BuildContext context) {
    final message = _buildShareMessage(result, label);
    final height = MediaQuery.of(context).size.height * 0.8;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text(
              'Your invitation is ready',
              style: TextStyle(
                  color: MyWalkColor.warmWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to send it to your support partner — WhatsApp, email, SMS, and more.',
              style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Share.share(message);
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Choose how to send',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.sage,
                  foregroundColor: MyWalkColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
