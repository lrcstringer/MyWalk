import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../providers/habit_category_provider.dart';
import '../../theme/app_theme.dart';
import '../habits/add_habit_view.dart';

class BreakingFreeIntroScreen extends StatelessWidget {
  final HabitCategoryModel? categoryModel;
  final HabitSubcategoryModel? subcategoryModel;

  const BreakingFreeIntroScreen({
    super.key,
    this.categoryModel,
    this.subcategoryModel,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8B7EC8);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
        title: const Text(
          'Breaking Free',
          style: TextStyle(
            color: MyWalkColor.warmWhite,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyWalkColor.sage.withValues(alpha: 0.12),
                  border: Border.all(
                      color: MyWalkColor.sage.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: MyWalkColor.sage, size: 34),
              ),
            ),
            const SizedBox(height: 24),

            // Headline
            const Text(
              'You were made for freedom.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'It is for freedom that Christ has set us free.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.softGold.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            Text(
              'Galatians 5:1',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.golden.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // What this is
            _block(
              icon: Icons.shield_rounded,
              color: MyWalkColor.sage,
              title: 'A daily practice',
              body:
                  'You will add a Breaking Free practice to your Today tab. Each day you check in — staying strong is the practice.',
            ),
            const SizedBox(height: 16),
            _block(
              icon: Icons.handshake_rounded,
              color: MyWalkColor.softGold,
              title: 'An accountability partner',
              body:
                  'Invite someone to walk with you. They will be notified when you reach out for support.',
            ),
            const SizedBox(height: 16),
            _block(
              icon: Icons.route_rounded,
              color: purple,
              title: 'A recovery path',
              body:
                  'A guided programme to understand your patterns, anchor to your values, and build guardrails for lasting freedom.',
            ),
            const SizedBox(height: 40),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startPractice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.sage,
                  foregroundColor: MyWalkColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Set up my Breaking Free practice',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 4),
              Text(body,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startPractice(BuildContext context) async {
    HabitCategoryModel? catModel = categoryModel;
    HabitSubcategoryModel? subModel = subcategoryModel;

    if (catModel == null || subModel == null) {
      final provider = context.read<HabitCategoryProvider>();
      final catMatches = provider.categories.where((c) => c.id == 'caring_for_myself');
      catModel = catMatches.isEmpty ? null : catMatches.first;
      if (catModel != null) {
        final subMatches = provider.subcategoriesFor('caring_for_myself')
            .where((s) => s.id == 'breaking_habits');
        subModel = subMatches.isEmpty ? null : subMatches.first;
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (ctx, sc) => AddHabitView(
          scrollController: sc,
          startCategoryModel: catModel,
          startSubcategoryModel: subModel,
          forBreakingFree: catModel == null,
        ),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}
