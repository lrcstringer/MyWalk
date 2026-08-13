import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'my_freedom_plan_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Shown once when a user transitions to a new phase.
/// Phase 1→2: encouraging intro listing the 5 tasks.
/// Phase 4: celebration screen.
class PhaseTransitionScreen extends StatelessWidget {
  final int fromPhase;
  final int toPhase;
  final String habitId;
  final String habitName;

  const PhaseTransitionScreen({
    super.key,
    required this.fromPhase,
    required this.toPhase,
    required this.habitId,
    required this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    if (fromPhase == 1 && toPhase == 2) {
      return _Phase1To2Screen(habitId: habitId, habitName: habitName);
    }
    if (toPhase == 4) {
      return const _Phase4CelebrationScreen();
    }
    return const SizedBox.shrink();
  }
}

// ── Phase 1→2 ─────────────────────────────────────────────────────────────────

class _Phase1To2Screen extends StatelessWidget {
  final String habitId;
  final String habitName;
  const _Phase1To2Screen({required this.habitId, required this.habitName});

  static const _tasks = [
    'Map your pattern cues',
    'Examine your thoughts',
    'Change your environment',
    'Build your coping plans',
    'Write your recovery letter',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Going Deeper · Week 3–4',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kRpPurple.withValues(alpha: 0.9),
                          letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.layers_rounded,
                        color: _kRpPurple, size: 26),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "You've reached Phase 2.",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'The first two weeks were about building awareness — logging moments honestly, '
                    "mapping what's happening before the urge takes over.\n\n"
                    'Now you go deeper. Phase 2 has five sections, worked through one at a time. '
                    "You can take as long as you need — come back to it whenever you're ready.",
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.7),
                  ),
                  const SizedBox(height: 32),
                  ..._tasks.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kRpPurple.withValues(alpha: 0.4)),
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _kRpPurple.withValues(alpha: 0.8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              e.value,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: MyWalkColor.warmWhite
                                      .withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MyFreedomPlanScreen(
                              habitId: habitId,
                              habitName: habitName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Let's begin",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Phase 4 Celebration ───────────────────────────────────────────────────────

class _Phase4CelebrationScreen extends StatelessWidget {
  const _Phase4CelebrationScreen();

  static const _bluePhase4 = Color(0xFF5B8DB8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _bluePhase4.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Phase 4 · Maintenance',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _bluePhase4.withValues(alpha: 0.9),
                          letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _bluePhase4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.anchor_rounded,
                        color: _bluePhase4, size: 26),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ninety days.',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Look what you\'ve built:',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 12),
                  ...const [
                    '· A map of what triggers your pattern',
                    '· Skills for examining the thoughts that drive it',
                    '· An environment that makes it harder to slip',
                    '· Plans for every high-risk situation',
                    '· A recovery letter for the hard moments',
                    '· A weekly compass keeping you anchored to what matters',
                  ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 14,
                                color: MyWalkColor.warmWhite
                                    .withValues(alpha: 0.7),
                                height: 1.5)),
                      )),
                  const SizedBox(height: 20),
                  Text(
                    'This isn\'t the end of the work — it\'s where the work becomes habit.\n\n'
                    'Stay steady. Keep coming back. The pattern gets weaker every time you '
                    "don't act on it, and every time you do, you know how to come back.",
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No trophies. No badges. No streak count. Just acknowledgement of what has genuinely been built.',
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bluePhase4,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
