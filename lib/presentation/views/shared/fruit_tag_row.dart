import 'package:flutter/material.dart';
import '../../../domain/entities/fruit.dart';
import '../../theme/app_theme.dart';

/// Compact inline row showing fruit icons for a habit card.
/// Shows up to 3 icons then "+N more" text.
class FruitTagRow extends StatelessWidget {
  final List<FruitType> fruitTags;
  final String? purposeStatement;

  const FruitTagRow({
    super.key,
    required this.fruitTags,
    this.purposeStatement,
  });

  @override
  Widget build(BuildContext context) {
    if (fruitTags.isEmpty) return const SizedBox.shrink();

    const maxVisible = 3;
    final visible = fruitTags.take(maxVisible).toList();
    final overflow = fruitTags.length - maxVisible;

    return GestureDetector(
      onTap: purposeStatement != null ? () => _showTooltip(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visible.map((f) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _fruitDot(f),
              )),
          if (overflow > 0)
            Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 10,
                color: MyWalkColor.softGold.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fruitDot(FruitType fruit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fruit.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fruit.color.withValues(alpha: 0.35), width: 0.75),
      ),
      child: Text(
        fruit.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fruit.color.withValues(alpha: 0.9),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    if (purposeStatement == null || purposeStatement!.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: fruitTags.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(f.icon, size: 14, color: f.color),
                )).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                purposeStatement!,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close',
                      style: TextStyle(color: MyWalkColor.softGold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
