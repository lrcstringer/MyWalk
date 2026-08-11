import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../providers/habit_category_provider.dart';
import '../../theme/app_theme.dart';
import '../habits/add_habit_view.dart';
import '../habits/values_inventory_screen.dart';

const _kAmber = Color(0xFFF59E0B);
const _kPurple = Color(0xFF8B7EC8);

class BreakingFreeIntroScreen extends StatelessWidget {
  final HabitCategoryModel? categoryModel;
  final HabitSubcategoryModel? subcategoryModel;
  // When provided, the habit already exists — skip AddHabitView and go
  // straight to ValuesInventoryScreen for this habit.
  final String? habitId;
  final String? habitName;

  const BreakingFreeIntroScreen({
    super.key,
    this.categoryModel,
    this.subcategoryModel,
    this.habitId,
    this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Breaking Patterns',
          style: TextStyle(
            color: MyWalkColor.warmWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E3228),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFF5A8A6A),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Headline
                    const Text(
                      'You were made for freedom.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scripture — abbreviated, no card
                    const Text(
                      'It is for freedom that Christ has set us free.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.warmWhite,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Galatians 5:1',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kAmber,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Feature blocks
                    _IntroBlock(
                      icon: Icons.shield_rounded,
                      iconBg: const Color(0xFF1E3228),
                      iconColor: const Color(0xFF5A8A6A),
                      titleColor: const Color(0xFF5A8A6A),
                      title: 'A daily practice',
                      body: 'You will add a Breaking Patterns practice to your Today tab. Each day you check in — staying strong is the practice.',
                    ),
                    const SizedBox(height: 20),
                    _IntroBlock(
                      icon: Icons.handshake_rounded,
                      iconBg: const Color(0xFF2C2610),
                      iconColor: const Color(0xFF9A7C30),
                      titleColor: _kAmber,
                      title: 'An accountability partner (optional)',
                      body: 'Invite someone to walk with you. They will be notified when you reach out for support.',
                    ),
                    const SizedBox(height: 20),
                    _IntroBlock(
                      icon: Icons.route_rounded,
                      iconBg: const Color(0xFF1E1A38),
                      iconColor: _kPurple,
                      titleColor: _kPurple,
                      title: 'A recovery path (optional)',
                      body: 'A guided programme to understand your patterns, anchor to your values, and build guardrails for lasting freedom.',
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
                    backgroundColor: const Color(0xFF8BAF8A),
                    foregroundColor: const Color(0xFF1A2A1A),
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
        ],
      ),
    );
  }

  Future<void> _startPractice(BuildContext context) async {
    // Existing habit — skip AddHabitView and go straight to Values Inventory.
    // wantsRecoveryPath: false — the user will activate the plan separately via
    // "Freedom Plan — Begin" on the card strip → RecoveryPathHomeScreen.
    if (habitId != null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ValuesInventoryScreen(
            habitId: habitId!,
            habitName: habitName ?? '',
            setupMode: true,
            wantsRecoveryPath: false,
          ),
        ),
      );
      return;
    }

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

    final newHabitId = result['habitId'] as String;
    final newHabitName = result['habitName'] as String;
    final wantsPartner = result['wantsPartner'] as bool;
    final wantsRecoveryPath = result['wantsRecoveryPath'] as bool;

    // S03 — Values Inventory: immediately after S02, cannot be skipped.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ValuesInventoryScreen(
          habitId: newHabitId,
          habitName: newHabitName,
          setupMode: true,
          wantsPartner: wantsPartner,
          wantsRecoveryPath: wantsRecoveryPath,
        ),
      ),
    );
  }
}

class _IntroBlock extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;
  final String title;
  final String body;

  const _IntroBlock({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titleColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
