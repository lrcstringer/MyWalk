import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

class FlipCardWidget extends StatefulWidget {
  final TextChunk chunk;
  final String itemTitle;
  final void Function({required bool success, List<String> missedIds}) onResult;

  const FlipCardWidget({
    super.key,
    required this.chunk,
    required this.itemTitle,
    required this.onResult,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _anim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCardWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _ctrl.reset();
      _answered = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_answered || _ctrl.isAnimating || _ctrl.value > 0) return;
    HapticFeedback.selectionClick();
    _ctrl.forward();
  }

  void _onAnswer({required bool knew}) {
    if (_answered) return;
    setState(() => _answered = true);
    if (knew) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    widget.onResult(
      success: knew,
      missedIds: knew ? [] : [widget.chunk.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: _flip,
            onHorizontalDragEnd: (details) {
              if (_answered) return;
              final v = details.primaryVelocity ?? 0;
              if (v > 200) { _onAnswer(knew: true); }
              else if (v < -200) { _onAnswer(knew: false); }
            },
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final angle = _anim.value;
                final isBack = angle > pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _buildBack(),
                        )
                      : _buildFront(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final isBack = _anim.value > pi / 2;
              return Text(
                isBack
                    ? '← Swipe to judge, or use buttons below'
                    : 'Tap to flip  ·  Swipe right if you knew it',
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final isBack = _anim.value > pi / 2;
              if (isBack && !_answered) return _buildAnswerButtons();
              if (!isBack) return const SizedBox(height: 64);
              return const SizedBox.shrink();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chunk.hint,
              style: TextStyle(
                color: MyWalkColor.golden.withValues(alpha: 0.9),
                fontSize: 20,
                fontFamily: 'monospace',
                letterSpacing: 2.5,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.touch_app_outlined,
              color: MyWalkColor.golden.withValues(alpha: 0.3),
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to flip',
              style: TextStyle(
                color: MyWalkColor.golden.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MyWalkColor.warmWhite.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chunk.text,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 20,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.itemTitle,
              style: TextStyle(
                color: MyWalkColor.golden,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _onAnswer(knew: false),
            icon: const Icon(Icons.close, size: 18),
            label: const Text("I didn't know ✗"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _onAnswer(knew: true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('I knew it ✓'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A9E7E),
              foregroundColor: MyWalkColor.charcoal,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
