import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../../../../presentation/views/shared/mywalk_paywall_view.dart';
import '../modes/cloze_mode_widget.dart';
import '../modes/flip_card_widget.dart';
import '../modes/progressive_recall_widget.dart';
import '../modes/recitation_mode_widget.dart';
import '../modes/typing_mode_widget.dart';
import '../widgets/memorization_review_shell.dart';

class ModeSelectionScreen extends StatelessWidget {
  final MemorizationItem item;
  const ModeSelectionScreen({super.key, required this.item});

  static const _modes = [
    _ModeInfo(
      mode: ReviewMode.flipCard,
      icon: Icons.flip,
      title: 'Meditate & Reveal',
      description: 'See the hint, flip to reveal the phrase.',
      premium: false,
    ),
    _ModeInfo(
      mode: ReviewMode.cloze,
      icon: Icons.text_fields,
      title: 'Fill the Word',
      description: 'Tap the missing words to complete each phrase.',
      premium: false,
    ),
    _ModeInfo(
      mode: ReviewMode.progressive,
      icon: Icons.layers_outlined,
      title: 'Step by Step',
      description: 'Reveal the passage one chunk at a time.',
      premium: true,
    ),
    _ModeInfo(
      mode: ReviewMode.typing,
      icon: Icons.keyboard_outlined,
      title: 'Write It Out',
      description: 'Type the phrase from memory.',
      premium: true,
    ),
    _ModeInfo(
      mode: ReviewMode.recitation,
      icon: Icons.mic_outlined,
      title: 'Speak It Aloud',
      description: 'Recite the passage and let AI score it.',
      premium: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // watch so the lock state updates if isPremium changes while screen is open.
    final provider = context.watch<MemorizationProvider>();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Choose a review mode'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _modes.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final info = _modes[i];
          final canUse = provider.canUseMode(info.mode);
          return _ModeTile(
            info: info,
            locked: !canUse,
            onTap: canUse
                ? () => _startReview(context, info.mode)
                : () => _showPremiumSheet(context),
          );
        },
      ),
    );
  }

  void _startReview(BuildContext context, ReviewMode mode) {
    // Recitation handles its own SM2 dispatch — push directly, not via shell.
    if (mode == ReviewMode.recitation) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => RecitationModeWidget(item: item)),
      );
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationReviewShell(
          item: item,
          mode: mode,
          builder: (ctx, chunkIndex, onResult) => switch (mode) {
            ReviewMode.flipCard => FlipCardWidget(
                chunk: item.chunks[chunkIndex],
                onResult: onResult,
              ),
            ReviewMode.cloze => ClozeModeWidget(
                chunk: item.chunks[chunkIndex],
                attemptNumber: item.repetitionCount,
                onResult: onResult,
              ),
            ReviewMode.progressive => ProgressiveRecallWidget(
                item: item,
                chunkIndex: chunkIndex,
                onResult: onResult,
              ),
            ReviewMode.typing => TypingModeWidget(
                chunk: item.chunks[chunkIndex],
                onResult: onResult,
              ),
            ReviewMode.recitation => throw StateError('unreachable'),
          },
        ),
      ),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MyWalkPaywallView(
          contextTitle: 'Premium review modes',
          contextMessage:
              'Unlock Step by Step, Write It Out, and Speak It Aloud — plus unlimited items and analytics.',
        ),
      ),
    );
  }
}

class _ModeInfo {
  final ReviewMode mode;
  final IconData icon;
  final String title;
  final String description;
  final bool premium;

  const _ModeInfo({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.premium,
  });
}

class _ModeTile extends StatelessWidget {
  final _ModeInfo info;
  final bool locked;
  final VoidCallback onTap;

  const _ModeTile({
    required this.info,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: locked
              ? null
              : Border.all(color: MyWalkColor.golden.withValues(alpha: 0.0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked
                    ? Colors.white10
                    : MyWalkColor.golden.withValues(alpha: 0.15),
              ),
              child: Icon(
                info.icon,
                color: locked
                    ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                    : MyWalkColor.golden,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          color: locked
                              ? MyWalkColor.warmWhite.withValues(alpha: 0.4)
                              : MyWalkColor.warmWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (info.premium && locked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MyWalkColor.golden.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: MyWalkColor.golden,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    info.description,
                    style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              color: locked
                  ? MyWalkColor.warmWhite.withValues(alpha: 0.2)
                  : MyWalkColor.warmWhite.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
