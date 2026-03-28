import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/habit_provider.dart';
import '../../data/datasources/local/notification_service.dart'; // used in _loadOnboardingState
import '../../domain/services/week_cycle_manager.dart';
import 'content_view.dart';
import 'onboarding/onboarding_container_view.dart';

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  bool _onboardingComplete = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('tribute_onboarding_complete') ?? false;
      _ready = true;
    });

    if (_onboardingComplete && mounted) {
      final habits = context.read<HabitProvider>().habits;
      await NotificationService.shared.refreshAllNotifications(habits);
    }
  }

  Future<void> _completeOnboarding() async {
    // Notification permission and scheduling are handled by NotificationPreferencesScreen
    // (step 8 of onboarding). Do not repeat them here — a second requestAuthorization()
    // call can throw and would prevent the app from ever transitioning out of onboarding.
    try {
      final wcm = context.read<WeekCycleManager>();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tribute_onboarding_complete', true);
      await prefs.setInt('tribute_onboarding_date', DateTime.now().millisecondsSinceEpoch);
      await wcm.dedicateCurrentWeek();
    } catch (_) {
      // Always complete onboarding — errors here must not leave the user stuck.
    }
    if (mounted) setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A843))),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _onboardingComplete
          ? ContentView(key: const ValueKey('content'))
          : OnboardingContainerView(
              key: const ValueKey('onboarding'),
              onComplete: _completeOnboarding,
            ),
    );
  }
}
