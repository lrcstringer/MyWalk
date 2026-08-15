import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  String? _lifeDifference;
  String? _appQuality;
  final Set<String> _suggestAreas = {};
  final _suggestDetailCtrl = TextEditingController();
  final _featureRequestCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  static const _areas = [
    'Today', 'Practices', 'Journal', 'Kingdom', 'Groups', 'Content', 'Other',
  ];

  bool get _canSubmit =>
      _lifeDifference != null && _appQuality != null && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'lifeDifference': _lifeDifference,
        'appQuality': _appQuality,
        'suggestAreas': _suggestAreas.toList(),
        'suggestDetail': _suggestDetailCtrl.text.trim(),
        'featureRequest': _featureRequestCtrl.text.trim(),
        'other': _otherCtrl.text.trim(),
        'replyEmail': _emailCtrl.text.trim(),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit. Please try again.',
                style: const TextStyle(color: MyWalkColor.warmWhite)),
            backgroundColor: MyWalkColor.cardBackground,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _suggestDetailCtrl.dispose();
    _featureRequestCtrl.dispose();
    _otherCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: MyWalkColor.charcoal,
                title: const Text('Provide Feedback to Us',
                    style: TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                floating: true,
                snap: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_submitted) _thankYouCard() else ..._formWidgets(),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _formWidgets() => [
        _introText(),
        const SizedBox(height: 24),
        _questionCard(
          question: 'Has MyWalk made a difference to your life?',
          child: _chipRow(
            options: const ['Not at all', 'Somewhat', 'A lot'],
            selected: _lifeDifference,
            onTap: (v) => setState(() => _lifeDifference = v),
            activeColor: MyWalkColor.sage,
          ),
        ),
        const SizedBox(height: 16),
        _questionCard(
          question: 'How do you rate the quality of the MyWalk app?',
          child: _chipRow(
            options: const ['Needs work', 'Acceptable', 'Excellent'],
            selected: _appQuality,
            onTap: (v) => setState(() => _appQuality = v),
            activeColor: MyWalkColor.golden,
          ),
        ),
        const SizedBox(height: 16),
        _questionCard(
          question:
              'What aspect of MyWalk would you like to suggest changes to?',
          subtitle: 'Select all that apply (optional)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _areas.map((a) {
                  final sel = _suggestAreas.contains(a);
                  return GestureDetector(
                    onTap: () => setState(() =>
                        sel ? _suggestAreas.remove(a) : _suggestAreas.add(a)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? MyWalkColor.eventPurple.withValues(alpha: 0.25)
                            : MyWalkColor.surfaceOverlay,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? MyWalkColor.eventPurple.withValues(alpha: 0.6)
                              : MyWalkColor.warmWhite.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(a,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: sel
                                ? MyWalkColor.warmWhite
                                : MyWalkColor.warmWhite.withValues(alpha: 0.55),
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _textArea(
                controller: _suggestDetailCtrl,
                hint: 'Tell us more about what you\'d like to see changed…',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _questionCard(
          question:
              'Are there other functions or content you would like to see added to MyWalk?',
          subtitle: 'Optional',
          child: _textArea(
            controller: _featureRequestCtrl,
            hint: 'e.g. devotionals, accountability features, prayer tools…',
          ),
        ),
        const SizedBox(height: 16),
        _questionCard(
          question: 'Anything else you would like us to know?',
          subtitle: 'Optional',
          child: _textArea(
            controller: _otherCtrl,
            hint: 'Share anything on your heart…',
          ),
        ),
        const SizedBox(height: 16),
        _questionCard(
          question: 'Would you like a response from us?',
          subtitle: 'Optional — enter your email and we\'ll get back to you',
          child: _textArea(
            controller: _emailCtrl,
            hint: 'your@email.com',
            maxLines: 1,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 28),
        if (_lifeDifference == null || _appQuality == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Please answer the first two questions to submit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.sage,
              foregroundColor: MyWalkColor.charcoal,
              disabledBackgroundColor: MyWalkColor.sage.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MyWalkColor.charcoal))
                : const Text('Submit Feedback',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ];

  Widget _introText() {
    return Text(
      'Your feedback helps us make MyWalk better for everyone. '
      'It only takes a couple of minutes.',
      style: TextStyle(
          fontSize: 14,
          color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
          height: 1.5),
    );
  }

  Widget _questionCard({
    required String question,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite,
                  height: 1.4)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _chipRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onTap,
    required Color activeColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = o == selected;
        return GestureDetector(
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: sel
                  ? activeColor.withValues(alpha: 0.2)
                  : MyWalkColor.surfaceOverlay,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? activeColor.withValues(alpha: 0.7)
                    : MyWalkColor.warmWhite.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(o,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: sel
                      ? activeColor
                      : MyWalkColor.warmWhite.withValues(alpha: 0.55),
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
    int maxLines = 3,
    TextInputType keyboardType = TextInputType.multiline,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.25), fontSize: 13),
        filled: true,
        fillColor: MyWalkColor.surfaceOverlay,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.1), width: 0.75),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.1), width: 0.75),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: MyWalkColor.sage, width: 1),
        ),
      ),
    );
  }

  Widget _thankYouCard() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(28),
      decoration: MyWalkDecorations.card,
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded,
              color: MyWalkColor.sage, size: 40),
          const SizedBox(height: 16),
          const Text('Thank you!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 10),
          Text(
            'Your feedback means a lot to us and helps us build '
            'a better MyWalk for everyone.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.sage,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
