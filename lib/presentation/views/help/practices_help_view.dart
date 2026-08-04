import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'help_widgets.dart';

class PracticesHelpView extends StatelessWidget {
  const PracticesHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = MyWalkColor.sage;
    const golden = MyWalkColor.golden;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Practices — Help'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HelpHero(
              icon: Icons.checklist_rounded,
              accentColor: golden,
              title: 'Practices',
              subtitle:
                  'Discover and manage your daily spiritual disciplines.',
            ),

            const HelpSectionTitle(title: 'What you can do here'),
            HelpFeatureGrid(
              cards: const [
                HelpFeatureCard(
                  icon: Icons.checklist_rounded,
                  iconColor: golden,
                  iconBg: Color(0x26D4A843),
                  title: 'Your Practices',
                  description:
                      'See everything you are currently doing. Tap any practice to view or edit its details.',
                ),
                HelpFeatureCard(
                  icon: Icons.explore_outlined,
                  iconColor: accent,
                  iconBg: Color(0x267A9E7E),
                  title: 'Daily Practices',
                  description:
                      'Browse disciplines by category — prayer, scripture, fasting, service, and more.',
                ),
                HelpFeatureCard(
                  icon: Icons.shield_rounded,
                  iconColor: accent,
                  iconBg: Color(0x267A9E7E),
                  title: 'Breaking Free',
                  description:
                      'Overcome challenges with a dedicated practice, an accountability partner, and a recovery path.',
                ),
                HelpFeatureCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: golden,
                  iconBg: Color(0x26D4A843),
                  title: 'Bible in a Year',
                  description:
                      'A 52-week reading plan covering all 66 books of the Bible.',
                ),
                HelpFeatureCard(
                  icon: Icons.psychology,
                  iconColor: golden,
                  iconBg: Color(0x26D4A843),
                  title: 'Scripture Memorization',
                  description:
                      'Hide His word in your heart. Add verses and practise them daily. Premium feature.',
                ),
              ],
            ),

            const HelpSectionTitle(title: 'How it works'),
            const HelpStep(
              number: 1,
              icon: Icons.explore_outlined,
              accentColor: golden,
              title: 'Discover a practice',
              description:
                  'Browse the category grid or the programme cards below it. Tap any tile to set up a new practice.',
            ),
            const HelpStep(
              number: 2,
              icon: Icons.today_outlined,
              accentColor: accent,
              title: 'It appears in Today',
              description:
                  'Once added, your practice shows up every day on the Today tab for you to check in.',
            ),
            const HelpStep(
              number: 3,
              icon: Icons.edit_outlined,
              accentColor: golden,
              title: 'Manage from here',
              description:
                  'Tap any practice in the Your Practices section to view details, edit, or stop the practice.',
            ),
            const HelpStep(
              number: 4,
              icon: Icons.calendar_today_outlined,
              accentColor: accent,
              title: 'Reflect each Sunday',
              description:
                  'At the end of each week, the Sunday reflection asks how your practices went and invites you to dedicate the week ahead.',
              isLast: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
        ],
      ),
    );
  }
}
