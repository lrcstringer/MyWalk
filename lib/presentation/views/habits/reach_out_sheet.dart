import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/accountability_partnership.dart';
import '../../../domain/services/micro_action_content.dart';
import '../../providers/accountability_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

/// Half-sheet modal for reaching out to a support/prayer partner.
/// Pre-populates with the user's coping plan. Shows today's micro-action.
/// Max 500 characters. Sends via [AccountabilityProvider.sendReachOut].
class ReachOutSheet extends StatefulWidget {
  final Habit habit;
  final AccountabilityPartnership partnership;

  const ReachOutSheet({
    super.key,
    required this.habit,
    required this.partnership,
  });

  @override
  State<ReachOutSheet> createState() => _ReachOutSheetState();
}

class _ReachOutSheetState extends State<ReachOutSheet> {
  static const _maxChars = 500;

  late final TextEditingController _controller;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.habit.copingPlan);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<AccountabilityProvider>().sendReachOut(
            partnershipId: widget.partnership.id,
            body: body,
          );
      if (!mounted) return;
      setState(() { _sending = false; _sent = true; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't send. Check your connection."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final partner = widget.partnership;
    final remaining = _maxChars - _controller.text.length;
    final microAction =
        MicroActionContent.selectedMicroActionFor(habit.category);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(children: [
              const Icon(Icons.handshake_rounded, size: 18, color: MyWalkColor.sage),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reach out to ${partner.partnerDisplayName ?? 'your partner'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // Micro-action card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: MyWalkColor.sage.withValues(alpha: 0.18), width: 0.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.directions_walk_rounded, size: 12,
                      color: MyWalkColor.sage),
                  const SizedBox(width: 5),
                  const Text('A small step right now',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: MyWalkColor.sage)),
                ]),
                const SizedBox(height: 6),
                Text(microAction,
                    style: const TextStyle(
                        fontSize: 13, color: MyWalkColor.warmWhite, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 10),

            // Counter-response library (M2) — shown only if entries exist
            _CounterResponseLibrary(
              habitId: habit.id,
              onSelect: (text) {
                final current = _controller.text;
                final appended = current.isEmpty ? text : '$current\n$text';
                _controller.text = appended.length <= _maxChars
                    ? appended
                    : appended.substring(0, _maxChars);
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              },
            ),

            const SizedBox(height: 10),

            // Message field
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              maxLength: _maxChars,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'What\'s on your heart right now?',
                hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                    fontSize: 14),
                filled: true,
                fillColor: MyWalkColor.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // Character counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remaining',
                style: TextStyle(
                    fontSize: 11,
                    color: remaining < 50
                        ? MyWalkColor.warmCoral.withValues(alpha: 0.8)
                        : MyWalkColor.warmWhite.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 14),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_sending || _sent || _controller.text.trim().isEmpty)
                    ? null
                    : _send,
                icon: _sent
                    ? const Icon(Icons.check_rounded, size: 16)
                    : _sending
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MyWalkColor.charcoal))
                        : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _sent ? 'Sent' : 'Send to ${partner.partnerDisplayName ?? 'partner'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _sent ? MyWalkColor.sage : MyWalkColor.sage,
                  foregroundColor: MyWalkColor.charcoal,
                  disabledBackgroundColor:
                      MyWalkColor.sage.withValues(alpha: 0.35),
                  disabledForegroundColor:
                      MyWalkColor.charcoal.withValues(alpha: 0.4),
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

// ── Counter-response library ─────────────────────────────────────────────────

/// Shows saved M2 counter-responses as quick-insert chips.
/// Hidden when the recovery path has no counter-responses.
class _CounterResponseLibrary extends StatefulWidget {
  final String habitId;
  final void Function(String text) onSelect;

  const _CounterResponseLibrary({
    required this.habitId,
    required this.onSelect,
  });

  @override
  State<_CounterResponseLibrary> createState() =>
      _CounterResponseLibraryState();
}

class _CounterResponseLibraryState extends State<_CounterResponseLibrary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final path =
        context.watch<RecoveryPathProvider>().pathFor(widget.habitId);
    final responses = path?.counterResponses ?? [];
    if (responses.isEmpty) return const SizedBox.shrink();

    const purple = Color(0xFF8B7EC8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Icon(Icons.psychology_rounded,
                size: 12, color: purple.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text('My counter-responses',
                style: TextStyle(
                    fontSize: 11,
                    color: purple.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: purple.withValues(alpha: 0.5),
            ),
          ]),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: responses
                .take(6)
                .map((r) => GestureDetector(
                      onTap: () {
                        widget.onSelect(r);
                        setState(() => _expanded = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: purple.withValues(alpha: 0.2),
                              width: 0.5),
                        ),
                        child: Text(
                          r.length > 40 ? '${r.substring(0, 40)}…' : r,
                          style: TextStyle(
                              fontSize: 11,
                              color: MyWalkColor.warmWhite
                                  .withValues(alpha: 0.75)),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
