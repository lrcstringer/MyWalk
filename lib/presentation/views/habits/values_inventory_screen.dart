import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// 8-step values inventory for Module 3.
/// Each step shows one life domain with two sliders: importance and alignment.
/// On completing all 8 domains: saves a session + updates the recovery path.
class ValuesInventoryScreen extends StatefulWidget {
  final String habitId;
  const ValuesInventoryScreen({super.key, required this.habitId});

  @override
  State<ValuesInventoryScreen> createState() => _ValuesInventoryScreenState();
}

class _ValuesInventoryScreenState extends State<ValuesInventoryScreen> {
  final List<String> _domains = RecoveryModuleContent.m3ValuesDomains;
  late final List<int> _importance; // 1–5
  late final List<int> _alignment;  // 1–5
  int _step = 0;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _importance = List.filled(_domains.length, 3);
    _alignment = List.filled(_domains.length, 3);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final entries = List.generate(
        _domains.length,
        (i) => ValuesInventoryEntry(
          domain: _domains[i],
          importance: _importance[i],
          alignment: _alignment[i],
        ),
      );

      // Build text summary for the session responseText.
      final summary = entries
          .map((e) =>
              '${e.domain}: importance=${e.importance}, alignment=${e.alignment}, gap=${e.gap}')
          .join('\n');

      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m3ValuesInventory_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m3ValuesInventory,
        moduleNumber: 3,
        responseText: summary,
        createdAt: now,
      );

      // Write inventory entries first (sets valuesInventoryDone + stores entries
      // in a single path update), then save the encrypted session doc.
      // This order ensures the path is fully consistent even if saveSession fails.
      await prov.saveValuesInventoryEntries(widget.habitId, entries);
      await prov.saveSession(session);

      if (mounted) setState(() { _saving = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Check your connection.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _CompletionView();

    final domain = _domains[_step];
    final isLast = _step == _domains.length - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Values Inventory',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro text (first step only)
            if (_step == 0) ...[
              Text(
                RecoveryModuleContent.m3InventoryIntro,
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    height: 1.5),
              ),
              const SizedBox(height: 16),
            ],

            // Progress dots
            Row(
              children: List.generate(_domains.length, (i) {
                final active = i == _step;
                final done = i < _step;
                return Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: active ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: done || active
                        ? _kRpPurple
                        : _kRpPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Domain name
            Text(
              domain,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite,
                  height: 1.3),
            ),
            const SizedBox(height: 28),

            // Importance slider
            _SliderRow(
              label: RecoveryModuleContent.m3ImportanceLabel,
              value: _importance[_step],
              color: _kRpPurple,
              onChanged: (v) => setState(() => _importance[_step] = v),
            ),
            const SizedBox(height: 20),

            // Alignment slider
            _SliderRow(
              label: RecoveryModuleContent.m3AlignmentLabel,
              value: _alignment[_step],
              color: MyWalkColor.sage,
              onChanged: (v) => setState(() => _alignment[_step] = v),
            ),

            // Gap callout
            const SizedBox(height: 20),
            _GapCallout(
              gap: _importance[_step] - _alignment[_step],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () {
                        if (isLast) {
                          _save();
                        } else {
                          setState(() => _step++);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRpPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isLast ? 'Save my values map' : 'Next',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not much',
                style: TextStyle(
                    fontSize: 10,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3))),
            Text('Very much',
                style: TextStyle(
                    fontSize: 10,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3))),
          ],
        ),
      ],
    );
  }
}

class _GapCallout extends StatelessWidget {
  final int gap;
  const _GapCallout({required this.gap});

  @override
  Widget build(BuildContext context) {
    if (gap <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.sage.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          gap == 0
              ? 'You\'re living in alignment here.'
              : 'Living beyond what you value — that\'s also meaningful.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Gap of $gap — room to grow here.',
        style: TextStyle(
            fontSize: 12,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _kRpPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.anchor_rounded,
                    color: _kRpPurple, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('Values Map Saved',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.warmWhite)),
              const SizedBox(height: 14),
              Text(
                RecoveryModuleContent.m3InventoryCompleteMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    height: 1.5,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
