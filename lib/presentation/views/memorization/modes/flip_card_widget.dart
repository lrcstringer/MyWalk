import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

class FlipCardWidget extends StatefulWidget {
  final TextChunk chunk;
  final void Function({required bool success, List<String> missedIds}) onResult;

  const FlipCardWidget({
    super.key,
    required this.chunk,
    required this.onResult,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _flipped = false;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(FlipCardWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _ctrl.reset();
      _flipped = false;
      _answered = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_answered) return;
    if (_flipped) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _flipped = !_flipped);
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
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                final angle = _anim.value * math.pi;
                final isBack = angle > math.pi / 2;
                final displayAngle = isBack ? angle - math.pi : angle;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(displayAngle),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 160),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isBack
                          ? MyWalkColor.golden.withValues(alpha: 0.1)
                          : MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: isBack
                          ? Border.all(
                              color: MyWalkColor.golden.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Center(
                      child: isBack
                          ? Text(
                              widget.chunk.text,
                              style: const TextStyle(
                                color: MyWalkColor.warmWhite,
                                fontSize: 20,
                                height: 1.7,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.chunk.hint,
                                  style: TextStyle(
                                    color: MyWalkColor.golden.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Icon(
                                  Icons.touch_app_outlined,
                                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to reveal',
                                  style: TextStyle(
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          if (_flipped && !_answered) ...[
            Text(
              'Did you know it?',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onAnswer(knew: false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Didn't know"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade300,
                      side: BorderSide(color: Colors.red.shade300),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onAnswer(knew: true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Knew it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A9E7E),
                      foregroundColor: MyWalkColor.charcoal,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!_flipped) ...[
            const SizedBox(height: 64),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  void _onAnswer({required bool knew}) {
    setState(() => _answered = true);
    widget.onResult(
      success: knew,
      missedIds: knew ? [] : [widget.chunk.id],
    );
  }
}
