import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../../../../presentation/views/shared/mywalk_paywall_view.dart';
import '../modes/cloze_mode_widget.dart';
import '../modes/fill_mode_widget.dart';
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
      premium: true,
      color: Color(0xFF9B8EC8), // lavender
    ),
    _ModeInfo(
      mode: ReviewMode.cloze,
      icon: Icons.text_fields,
      title: 'Fill the Word',
      description: 'Tap the missing words to complete each phrase.',
      premium: true,
      color: Color(0xFF6B9FD4), // sky blue
    ),
    _ModeInfo(
      mode: ReviewMode.progressive,
      icon: Icons.layers_outlined,
      title: 'Step by Step',
      description: 'Reveal the passage one chunk at a time.',
      premium: true,
      color: Color(0xFF7A9E7E), // sage green
    ),
    _ModeInfo(
      mode: ReviewMode.typing,
      icon: Icons.keyboard_outlined,
      title: 'Write It Out',
      description: 'Type the phrase from memory.',
      premium: true,
      color: Color(0xFFD4836B), // warm coral
    ),
    _ModeInfo(
      mode: ReviewMode.recitation,
      icon: Icons.mic_outlined,
      title: 'Speak It Aloud',
      description: 'Recite the passage and let AI score it.',
      premium: true,
      color: Color(0xFFD4A843), // golden amber
    ),
    _ModeInfo(
      mode: ReviewMode.fill,
      icon: Icons.edit_outlined,
      title: 'Fill the Letters',
      description: 'Type the missing letters one by one.',
      premium: true,
      color: Color(0xFF5BA8A0), // teal
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // watch so the lock state updates if isPremium changes while screen is open.
    final provider = context.watch<MemorizationProvider>();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(
          'Choose a review mode',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyWalkColor.warmWhite,
              ),
        ),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          ListView.separated(
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
        ],
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
                itemTitle: item.title,
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
            ReviewMode.fill => FillModeWidget(
                chunk: item.chunks[chunkIndex],
                onResult: onResult,
              ),
            ReviewMode.recitation => throw StateError('unreachable'),
            ReviewMode.session => throw StateError('unreachable'),
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
              'Premium unlocks all 6 review modes, unlimited verses, and full analytics.',
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
  final Color color;

  const _ModeInfo({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.premium,
    required this.color,
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
    final accent = locked ? MyWalkColor.warmWhite.withValues(alpha: 0.25) : info.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              locked
                  ? MyWalkColor.cardBackground
                  : info.color.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: locked
                ? const Color(0x14FFFFFF)
                : info.color.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: locked ? 0.08 : 0.18),
              ),
              child: Icon(
                info.icon,
                color: accent,
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
                      color: locked
                          ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                          : MyWalkColor.warmWhite.withValues(alpha: 0.65),
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
                  : info.color.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
