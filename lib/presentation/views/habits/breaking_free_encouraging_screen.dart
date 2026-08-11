import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';

/// S03-ENC — Encouraging screen shown after Values Inventory when the user
/// did NOT select a Freedom Plan during setup.
class BreakingFreeEncouragingScreen extends StatelessWidget {
  const BreakingFreeEncouragingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        automaticallyImplyLeading: false,
        title: const Text(
          'Breaking Patterns',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            '🤝',
                            style: TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Changing difficult patterns alone can be hard. We encourage you to find a Support / Accountability partner and strongly suggest you set up your Freedom Plan when you are ready — it will take you through a structured journey to help you break the pattern rather than trying alone.',
                          style: TextStyle(
                              fontSize: 15,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.82),
                              height: 1.65),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'You can start your Freedom Plan at any time from your breaking patterns card on the Today screen.',
                          style: TextStyle(
                              fontSize: 14,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<NavigationProvider>().switchToTab(0);
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyWalkColor.sage,
                        foregroundColor: MyWalkColor.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Take me to my Practice',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
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
}
