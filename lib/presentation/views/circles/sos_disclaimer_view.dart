import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SOSDisclaimerView extends StatelessWidget {
  final VoidCallback onContinue;

  const SOSDisclaimerView({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text('SOS Prayer Request'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05555).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE05555).withValues(alpha: 0.4),
                      width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Color(0xFFE05555), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This is not an emergency service',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE05555),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'If you or someone else is in immediate danger, call emergency services (10111 SAPS / 10177 Ambulance / 112 from mobile).',
                            style: TextStyle(
                              fontSize: 13,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Crisis Support Lines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              ..._crisisLines.map((line) => _CrisisLine(line: line)),
              const SizedBox(height: 32),
              Text(
                'About SOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sending an SOS notifies your chosen circle members that you need prayer and support right now. Use this when you need your circle to pray for you urgently.',
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE05555),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Send SOS to My Circle',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _CrisisLineData {
  final String name;
  final String number;
  final String? note;
  const _CrisisLineData(this.name, this.number, [this.note]);
}

const _crisisLines = [
  _CrisisLineData('SADAG Suicide Crisis Line', '0800 567 567', '24/7'),
  _CrisisLineData('SMS Crisis Line', '31393', 'SMS only'),
  _CrisisLineData('Lifeline South Africa', '0861 322 322', '24/7'),
  _CrisisLineData('SAPS Emergency', '10111'),
  _CrisisLineData('Ambulance / Medical', '10177'),
  _CrisisLineData('Emergency (mobile)', '112'),
];

class _CrisisLine extends StatelessWidget {
  final _CrisisLineData line;
  const _CrisisLine({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                  ),
                ),
                if (line.note != null)
                  Text(
                    line.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            line.number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.softGold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
