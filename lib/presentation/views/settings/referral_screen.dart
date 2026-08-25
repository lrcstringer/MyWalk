import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/services/referral_service.dart';
import '../../theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  StreamSubscription<ReferralData>? _sub;
  ReferralData _data = const ReferralData(
    code: null,
    confirmedCount: 0,
    tier1Granted: false,
    tier2Granted: false,
  );
  bool _loadingCode = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _sub = ReferralService.shared.watchReferralData().listen((data) {
      if (mounted) setState(() => _data = data);
      // If no code yet, generate one on first view.
      if (data.code == null && !_loadingCode) _fetchCode();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchCode() async {
    setState(() => _loadingCode = true);
    await ReferralService.shared.generateReferralCode();
    if (mounted) setState(() => _loadingCode = false);
  }

  Future<void> _copy() async {
    final code = _data.code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _share() {
    final code = _data.code;
    if (code == null) return;
    Share.share(
      "I've been walking with God daily using MyWalk — a faith app that's really helped me stay consistent. "
      "Download it and use my code $code when you sign up. "
      "It's available on the App Store and Google Play.",
      subject: 'Join me on MyWalk',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: MyWalkColor.warmWhite, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite Friends',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.warmWhite),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(),
            const SizedBox(height: 24),
            _rewardCard(
              tier: 1,
              needed: 3,
              current: _data.confirmedCount,
              granted: _data.tier1Granted,
              title: '50% off next renewal',
              body: 'Get 3 friends to subscribe and your next annual renewal is half price.',
            ),
            const SizedBox(height: 12),
            _rewardCard(
              tier: 2,
              needed: 5,
              current: _data.confirmedCount,
              granted: _data.tier2Granted,
              title: 'Free lifetime upgrade',
              body: 'Get 5 friends to subscribe and your account is upgraded to lifetime — free.',
            ),
            const SizedBox(height: 24),
            _howItWorksCard(),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    final code = _data.code;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your referral code',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: MyWalkColor.softGold,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingCode || code == null)
            const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: MyWalkColor.golden),
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: MyWalkColor.golden,
                    letterSpacing: 6,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Icon(Icons.check_rounded,
                            key: ValueKey('check'),
                            color: MyWalkColor.golden,
                            size: 22)
                        : Icon(Icons.copy_rounded,
                            key: const ValueKey('copy'),
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 22),
                  ),
                ),
              ],
            ),
          if (code != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share with friends',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rewardCard({
    required int tier,
    required int needed,
    required int current,
    required bool granted,
    required String title,
    required String body,
  }) {
    final filled = (current.clamp(0, needed));
    final pct = filled / needed;
    final done = granted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? MyWalkColor.golden.withValues(alpha: 0.5)
              : MyWalkColor.cardBorder,
          width: done ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: done
                      ? MyWalkColor.golden.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$needed referrals',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: done
                        ? MyWalkColor.golden
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const Spacer(),
              if (done)
                const Icon(Icons.check_circle_rounded,
                    color: MyWalkColor.golden, size: 18)
              else
                Text(
                  '$filled / $needed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.warmWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.45,
            ),
          ),
          if (!done) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(MyWalkColor.golden),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _howItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: MyWalkColor.softGold,
            ),
          ),
          const SizedBox(height: 12),
          _step('1', 'Share your code with friends who don\'t have MyWalk.'),
          const SizedBox(height: 10),
          _step('2', 'Your friend enters your code when they sign up.'),
          const SizedBox(height: 10),
          _step('3', 'Once they subscribe and 30 days pass, it counts as a confirmed referral.'),
          const SizedBox(height: 10),
          _step('4', 'Hit the thresholds above to unlock your rewards.'),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: MyWalkColor.golden.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.golden,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
