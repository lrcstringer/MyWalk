import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

class ChunkHeatMap extends StatelessWidget {
  final List<TextChunk> chunks;

  const ChunkHeatMap({super.key, required this.chunks});

  @override
  Widget build(BuildContext context) {
    if (chunks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phrase strength',
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chunks.asMap().entries.map((e) {
            final strength = e.value.strengthScore;
            return _ChunkCell(
              index: e.key,
              chunk: e.value,
              strength: strength,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(color: Colors.red.shade400),
            const SizedBox(width: 4),
            Text('Weak', style: _legendStyle()),
            const SizedBox(width: 12),
            _LegendDot(color: MyWalkColor.golden),
            const SizedBox(width: 4),
            Text('Learning', style: _legendStyle()),
            const SizedBox(width: 12),
            _LegendDot(color: const Color(0xFF7A9E7E)),
            const SizedBox(width: 4),
            Text('Strong', style: _legendStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _legendStyle() => TextStyle(
        color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
        fontSize: 11,
      );
}

class _ChunkCell extends StatelessWidget {
  final int index;
  final TextChunk chunk;
  final double strength;

  const _ChunkCell({
    required this.index,
    required this.chunk,
    required this.strength,
  });

  Color get _color {
    if (chunk.attemptCount == 0) return Colors.white12;
    if (strength >= 0.8) return const Color(0xFF7A9E7E);
    if (strength >= 0.5) return MyWalkColor.golden;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${chunk.text.length > 30 ? '${chunk.text.substring(0, 30)}…' : chunk.text}\n'
          '${(strength * 100).toInt()}% (${chunk.successCount}/${chunk.attemptCount})',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.7),
        ),
      );
}
