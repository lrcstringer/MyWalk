import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/repositories/iap_repository.dart';
import '../../../domain/repositories/user_preferences_repository.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/network_error_dialog.dart';
import '../shared/terms_view.dart';
import 'paywall_screen.dart';
import '../../../data/services/referral_service.dart';

enum _Mode { newUser, signIn }

enum _Plan { free, premium }

class AuthScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  final Future<void> Function() onBeginOnboarding;
  const AuthScreen({
    super.key,
    required this.onComplete,
    required this.onBeginOnboarding,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode _mode = _Mode.newUser;
  _Plan _selectedPlan = _Plan.free;
  bool _processing = false;
  bool _showNameField = false;
  final _nameCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  String? _tokenError;
  String? _referralError;

  static const _freeFeatures = [
    (Icons.volunteer_activism_rounded, 'Daily Gratitude', ''),
    (Icons.checklist_rounded, '2 Custom Daily Practices',
        'Includes Breaking Patterns path + accountability partner (2 mo.)'),
    (Icons.auto_stories_rounded, 'Kingdom Life',
        'Fruit of the Spirit · How to Pray · How to Read the Bible (2 mo.)'),
    (Icons.book_rounded, 'Journal', '2 months access'),
    (Icons.groups_rounded, 'Groups & Community', '2 months access'),
    (Icons.menu_book_rounded, 'Bible in a Year', ''),
  ];

  static const _premiumFeatures = [
    (Icons.all_inclusive_rounded, 'Unlimited Daily Practices', ''),
    (Icons.shield_rounded, 'Breaking Patterns Recovery Path', ''),
    (Icons.book_rounded, 'Unlimited Journal', ''),
    (Icons.groups_rounded, 'Unlimited Groups', ''),
    (Icons.auto_stories_rounded, 'Full Kingdom Life Access',
        'The Beatitudes · Parables of Jesus · Women of Valor · I AM Sayings of Jesus'),
    (Icons.menu_book_rounded, 'Bible in a Year', ''),
    (Icons.format_quote_rounded, 'Scripture Memorization', ''),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final auth = context.read<AuthService>();
    await auth.signIn();
    if (!mounted) return;
    if (auth.isOfflineError) {
      await NetworkErrorDialog.show(context);
      return;
    }
    if (!auth.isAuthenticated) return;
    setState(() => _processing = true);
    await _handleAuthComplete();
  }

  Future<void> _handleAuthComplete() async {
    if (!mounted) return;
    try {
      final auth = context.read<AuthService>();

      // Firebase tells us definitively whether this is a brand-new account.
      // When true, always show the name screen regardless of any local cache.
      if (!auth.isNewUser) {
        final userPrefs = context.read<UserPreferencesRepository>();
        await userPrefs.init();
        final isComplete =
            await userPrefs.getBool('tribute_onboarding_complete') ?? false;
        if (isComplete) {
          if (!mounted) return;
          setState(() => _processing = false);
          await widget.onComplete();
          return;
        }
      }

      // New user (or returning user with incomplete onboarding) — capture name.
      if (!mounted) return;
      _nameCtrl.text = auth.givenName ?? '';
      setState(() {
        _processing = false;
        _showNameField = true;
      });
    } catch (_) {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _processing = true;
      _tokenError = null;
      _referralError = null;
    });
    try {
      await AuthService.shared.updateProfile(firstName: name);
      if (!mounted) return;

      // Apply referral code (non-fatal — proceed even on failure).
      final referralCode = _referralCtrl.text.trim();
      if (referralCode.isNotEmpty) {
        final refResult = await ReferralService.shared.applyReferralCode(referralCode);
        if (!mounted) return;
        if (refResult != ApplyReferralResult.success) {
          setState(() => _referralError = _referralErrorMessage(refResult));
        }
      }

      // Token path takes priority over plan selection.
      final tokenCode = _tokenCtrl.text.trim();
      if (tokenCode.isNotEmpty) {
        final result =
            await context.read<StoreProvider>().redeemToken(tokenCode);
        if (!mounted) return;
        if (result != TokenRedemptionResult.success) {
          setState(() {
            _processing = false;
            _tokenError = _tokenErrorMessage(result);
            _tokenCtrl.clear();
            // Don't push paywall on retry — user was trying a token, not paying.
            _selectedPlan = _Plan.free;
          });
          return;
        }
        // Success — Firestore stream updates StoreProvider.isPremium automatically.
        await widget.onBeginOnboarding();
        return;
      }

      // No token — show paywall if premium plan was selected.
      if (_selectedPlan == _Plan.premium && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => Scaffold(
              backgroundColor: MyWalkColor.charcoal,
              body: SafeArea(
                child: PaywallScreen(onNext: () => Navigator.pop(context)),
              ),
            ),
          ),
        );
      }

      if (mounted) await widget.onBeginOnboarding();
    } catch (_) {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _referralErrorMessage(ApplyReferralResult result) => switch (result) {
        ApplyReferralResult.invalidCode =>
          "That referral code wasn't recognised. You can continue without it.",
        ApplyReferralResult.selfReferral =>
          "You can't use your own referral code.",
        ApplyReferralResult.alreadyApplied =>
          "A referral code has already been applied to your account.",
        _ =>
          "Couldn't apply the referral code right now — you can continue.",
      };

  String _tokenErrorMessage(TokenRedemptionResult result) => switch (result) {
        TokenRedemptionResult.invalidToken =>
          'That code wasn\'t recognised. Tap Continue to proceed with the free plan.',
        TokenRedemptionResult.notYetActive =>
          'That code isn\'t active yet. Tap Continue to proceed with the free plan.',
        TokenRedemptionResult.expired =>
          'That code has expired. Tap Continue to proceed with the free plan.',
        TokenRedemptionResult.fullyRedeemed =>
          'That code has already been fully redeemed. Tap Continue to proceed with the free plan.',
        _ =>
          'Something went wrong with that code. Tap Continue to proceed with the free plan.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          Image.asset('assets/feet2 - Copy_edited.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showNameField ? _nameView() : _mainView(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main view (plan selection + auth) ─────────────────────────────────────

  Widget _mainView() {
    final auth = context.watch<AuthService>();
    final isApple = AuthService.isApplePlatform;
    final isLoading = auth.isLoading || _processing;

    return SingleChildScrollView(
      key: const ValueKey('main'),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          // Branding
          const Text(
            'MyWalk',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: MyWalkColor.warmWhite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A daily walk with God.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.softGold.withValues(alpha: 0.95),
            ),
          ),

          const SizedBox(height: 32),

          // New here / Sign in toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xCC1E1B1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _tab('New here?', _mode == _Mode.newUser,
                    () => setState(() => _mode = _Mode.newUser),
                    activeColor: MyWalkColor.golden),
                _tab('Sign in', _mode == _Mode.signIn,
                    () => setState(() => _mode = _Mode.signIn)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Plan cards + promo code (new user only)
          if (_mode == _Mode.newUser) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _planCard(
                    title: 'FREE',
                    isSelected: _selectedPlan == _Plan.free,
                    isGold: false,
                    features: _freeFeatures,
                    onTap: () => setState(() => _selectedPlan = _Plan.free),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _planCard(
                    title: 'PREMIUM',
                    isSelected: _selectedPlan == _Plan.premium,
                    isGold: true,
                    features: _premiumFeatures,
                    topLabel: 'Everything in Free, plus:',
                    onTap: () => setState(() => _selectedPlan = _Plan.premium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 8),

          // Auth button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _signIn,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.charcoal),
                    )
                  : Icon(
                      isApple ? Icons.apple : Icons.g_mobiledata,
                      size: 22,
                    ),
              label: Text(
                _mode == _Mode.newUser
                    ? (isApple ? 'Sign up with Apple' : 'Sign up with Google')
                    : (isApple ? 'Sign in with Apple' : 'Sign in with Google'),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          if (auth.error != null) ...[
            const SizedBox(height: 10),
            Text(
              auth.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: MyWalkColor.warmCoral),
            ),
          ],

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () => TermsView.show(context),
            child: Text(
              'By continuing you agree to our Terms of Service and Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.3),
                height: 1.5,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap,
      {Color activeColor = MyWalkColor.golden}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? MyWalkColor.charcoal
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required bool isSelected,
    required bool isGold,
    required List<(IconData, String, String)> features,
    String? topLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isGold
                  ? MyWalkColor.golden.withValues(alpha: 0.13)
                  : const Color(0xFF302B25))
              : const Color(0xCC272320),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isGold
                    ? MyWalkColor.golden.withValues(alpha: 0.75)
                    : MyWalkColor.softGold.withValues(alpha: 0.55))
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isGold
                        ? MyWalkColor.golden
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected
                      ? (isGold ? MyWalkColor.golden : MyWalkColor.softGold)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
            if (topLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                topLabel,
                style: TextStyle(
                  fontSize: 9,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.5),
                        child: Icon(
                          f.$1,
                          size: 11,
                          color: isGold
                              ? MyWalkColor.golden.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$2,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: isSelected
                                    ? (isGold
                                        ? MyWalkColor.warmWhite
                                        : Colors.white.withValues(alpha: 0.8))
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            if (f.$3.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  f.$3,
                                  style: TextStyle(
                                    fontSize: 9,
                                    height: 1.4,
                                    color: isSelected
                                        ? (isGold
                                            ? MyWalkColor.softGold.withValues(alpha: 0.65)
                                            : Colors.white.withValues(alpha: 0.5))
                                        : Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Name capture view ─────────────────────────────────────────────────────

  Widget _dotRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final isActive = i == 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 10 : 7,
          height: isActive ? 10 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? MyWalkColor.golden
                : Colors.white.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }

  Widget _nameView() {
    final buttonLabel =
        _tokenError != null ? 'Continue as Free' : 'Continue';

    return Padding(
      key: const ValueKey('name'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _dotRow()),
          const SizedBox(height: 28),
          const Text(
            'What should we\ncall you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.warmWhite,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'We\'ll use your first name to personalise your experience.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Your first name',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _tokenCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              labelText: 'If you have a promo code enter it here',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              hintText: 'ENTER CODE',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 2,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          if (_tokenError != null) ...[
            const SizedBox(height: 10),
            Text(
              _tokenError!,
              style: const TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmCoral,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _referralCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              labelText: 'Referred by a friend? Enter their code',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              hintText: 'ENTER CODE',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 2,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          if (_referralError != null) ...[
            const SizedBox(height: 10),
            Text(
              _referralError!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_nameCtrl.text.trim().isEmpty || _processing)
                      ? null
                      : _saveName,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.charcoal),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                disabledBackgroundColor:
                    MyWalkColor.golden.withValues(alpha: 0.25),
                disabledForegroundColor:
                    MyWalkColor.charcoal.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
