import 'package:flutter/material.dart';
import '../../../../presentation/theme/app_theme.dart';

// Celebration confetti widget shown after completing the initial memorization
// session or mastering an item. Uses a simple animated particle system to avoid
// the confetti package dependency until it is added in Sprint 5.

class MemorizationCelebration extends StatefulWidget {
  final String message;
  final String subtitle;
  final VoidCallback onContinue;
  final VoidCallback? onShare;

  const MemorizationCelebration({
    super.key,
    required this.message,
    required this.subtitle,
    required this.onContinue,
    this.onShare,
  });

  @override
  State<MemorizationCelebration> createState() => _MemorizationCelebrationState();
}

class _MemorizationCelebrationState extends State<MemorizationCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _scaleCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyWalkColor.golden.withValues(alpha: 0.15),
                      border: Border.all(color: MyWalkColor.golden, width: 2),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      size: 48,
                      color: MyWalkColor.golden,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: MyWalkColor.warmWhite,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"Thy word have I hid in mine heart,\nthat I might not sin against thee."',
                        style: TextStyle(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '— Psalm 119:11',
                        style: TextStyle(
                          color: MyWalkColor.golden,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.onShare != null) ...[
                  OutlinedButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share with my circle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MyWalkColor.warmWhite,
                      side: BorderSide(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  style: MyWalkButtonStyle.primary(),
                  onPressed: widget.onContinue,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
