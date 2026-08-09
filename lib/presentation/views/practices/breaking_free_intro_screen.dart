import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../providers/habit_category_provider.dart';
import '../habits/add_habit_view.dart';
import '../habits/values_inventory_screen.dart';

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
    const setupTeal = Color(0xFF4A8FA4);

    return Scaffold(
      backgroundColor: setupTeal,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero icon
                    Center(
                      child: Text(
                        '🛡',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Headline
                    const Text(
                      'You were made for freedom.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Scripture
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'It is for freedom that Christ has set us free; stand firm therefore, and do not submit again to a yoke of slavery.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Galatians 5:1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // What this is
                    _block(
                      icon: Icons.shield_rounded,
                      color: Colors.white,
                      title: 'A daily practice',
                      body:
                          'You will add a Breaking Patterns practice to your Today tab. Each day you check in — staying strong is the practice.',
                    ),
                    const SizedBox(height: 16),
                    _block(
                      icon: Icons.handshake_rounded,
                      color: Colors.white,
                      title: 'A Support / Accountability Partner',
                      optional: true,
                      body:
                          'Invite someone to walk with you. They will be notified when you reach out for support.',
                    ),
                    const SizedBox(height: 16),
                    _block(
                      icon: Icons.route_rounded,
                      color: Colors.white,
                      title: 'A Recovery / Freedom Plan',
                      optional: true,
                      body:
                          'A guided programme to understand your patterns, anchor to your values, and build guardrails for lasting freedom.',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Pinned CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startPractice(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: setupTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Set up my Breaking Patterns practice',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
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
    bool optional = false,
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
              Row(
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  if (optional) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(Optional)',
                      style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ],
              ),
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
      final catMatches =
          provider.categories.where((c) => c.id == 'caring_for_myself');
      catModel = catMatches.isEmpty ? null : catMatches.first;
      if (catModel != null) {
        final subMatches = provider
            .subcategoriesFor('caring_for_myself')
            .where((s) => s.id == 'breaking_habits');
        subModel = subMatches.isEmpty ? null : subMatches.first;
      }
    }

    // S02 — full-screen push (not modal)
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHabitView(
          startCategoryModel: catModel,
          startSubcategoryModel: subModel,
          forBreakingFree: true,
        ),
      ),
    );

    if (result is! Map || result['saved'] != true) return;
    if (!context.mounted) return;

    final habitId = result['habitId'] as String;
    final habitName = result['habitName'] as String;
    final wantsPartner = result['wantsPartner'] as bool;
    final wantsRecoveryPath = result['wantsRecoveryPath'] as bool;

    // S03 — Values Inventory: immediately after S02, cannot be skipped.
    // Partner invite + WHN/ENC conditional paths are handled inside ValuesInventoryScreen.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ValuesInventoryScreen(
          habitId: habitId,
          habitName: habitName,
          setupMode: true,
          wantsPartner: wantsPartner,
          wantsRecoveryPath: wantsRecoveryPath,
        ),
      ),
    );
  }
}

