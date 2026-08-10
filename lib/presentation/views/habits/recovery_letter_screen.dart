import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 5 — Recovery Letter.
/// Free-text letter with soft guidance. Draft saves on every change.
class RecoveryLetterScreen extends StatefulWidget {
  final String habitId;

  const RecoveryLetterScreen({super.key, required this.habitId});

  @override
  State<RecoveryLetterScreen> createState() => _RecoveryLetterScreenState();
}

class _RecoveryLetterScreenState extends State<RecoveryLetterScreen> {
  final TextEditingController _letterCtrl = TextEditingController();
  bool _saving = false;
  bool _showAveIntro = false;
  bool _isResume = false;
  bool _done = false;
  bool _guidanceVisible = true;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _letterCtrl.addListener(_onLetterChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
      if (path == null) return;
      final draft = path.recoveryLetterDraft;
      if (draft != null && draft.trim().isNotEmpty) {
        _letterCtrl.text = draft;
        setState(() => _isResume = true);
      }
      if (!path.module5IntroSeen) {
        setState(() => _showAveIntro = true);
      }
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _letterCtrl.removeListener(_onLetterChanged);
    _letterCtrl.dispose();
    super.dispose();
  }

  void _onLetterChanged() {
    setState(() {});
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        context
            .read<RecoveryPathProvider>()
            .saveRecoveryLetterDraft(widget.habitId, _letterCtrl.text);
      }
    });
  }

  bool get _canSave => _letterCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final letter = _letterCtrl.text.trim();
      final prov = context.read<RecoveryPathProvider>();
      await prov.saveRecoveryLetterDraft(widget.habitId, letter);
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m5RecoveryLetter_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m5RecoveryLetter,
        moduleNumber: 5,
        responseText: letter,
        createdAt: now,
      );
      await prov.saveSession(session);
      if (mounted) setState(() { _saving = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 2400));
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
    if (_done) return _DoneView();

    if (_showAveIntro) {
      return _AveIntroScreen(
        onContinue: () async {
          await context
              .read<RecoveryPathProvider>()
              .markModule5IntroSeen(widget.habitId);
          if (mounted) setState(() => _showAveIntro = false);
        },
      );
    }

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isResume
              ? 'Continue writing your recovery letter'
              : RecoveryModuleContent.m5RecoveryLetterTitle,
          style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Right now, while you\'re clear-headed, write a letter — from the wiser, '
                          'stronger version of yourself to the version of you who has just slipped.',
                          style: TextStyle(
                              fontSize: 14,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                              height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can stop and come back to this — it doesn\'t need to be done in one sitting.',
                          style: TextStyle(
                              fontSize: 13,
                              color: _kRpPurple.withValues(alpha: 0.8),
                              height: 1.5,
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _letterCtrl,
                          minLines: 12,
                          maxLines: null,
                          autofocus: !_isResume,
                          style: const TextStyle(
                              color: MyWalkColor.warmWhite,
                              fontSize: 15,
                              height: 1.7),
                          decoration: InputDecoration(
                            hintText: 'Dear future me…',
                            hintStyle: TextStyle(
                                color: MyWalkColor.warmWhite.withValues(alpha: 0.25),
                                fontSize: 14),
                            filled: true,
                            fillColor: MyWalkColor.surfaceOverlay,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        if (_guidanceVisible) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            decoration: BoxDecoration(
                              color: _kRpPurple.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _kRpPurple.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You might include:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _kRpPurple.withValues(alpha: 0.8)),
                                      ),
                                      const SizedBox(height: 6),
                                      ...const [
                                        '• What you want to remind yourself about who you are',
                                        '• What the research says about slips (a slip is not a relapse)',
                                        '• Which value you want to take the next step toward',
                                        '• What you want to say to your harshest inner voice',
                                      ].map((s) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(s,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: MyWalkColor.warmWhite
                                                        .withValues(alpha: 0.55),
                                                    height: 1.4)),
                                          )),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _guidanceVisible = false),
                                  child: Icon(Icons.close_rounded,
                                      size: 16,
                                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.25),
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
                          : const Text('Save my letter',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
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

// ── AVE education screen (shown once before letter writing) ───────────────────

class _AveIntroScreen extends StatelessWidget {
  final Future<void> Function() onContinue;
  const _AveIntroScreen({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recovery Letter',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Before anything happens — read this.',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Most people who are changing a deeply ingrained pattern will experience '
                    'a slip at some point. That\'s not pessimism — it\'s what the research '
                    'consistently shows.\n\n'
                    'What determines whether a slip becomes a full relapse is almost never '
                    'the slip itself. It\'s what happens in the hour afterward.\n\n'
                    'When a slip happens, the mind tends to catastrophise: "I\'ve failed. '
                    'I have no willpower. I\'ll never change. I might as well give up." '
                    'Researchers call this the Abstinence Violation Effect — and it\'s one '
                    'of the most dangerous things that can happen after a slip, because it '
                    'turns a single moment into a sustained return to the old pattern.\n\n'
                    'These thoughts are not facts. They are the all-or-nothing thinking '
                    'error at its most damaging. And knowing that — right now, before you '
                    'need it — is one of the most useful things you can do.',
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.7),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                          'I\'ve read this — write my letter',
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

class _DoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kRpPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    color: _kRpPurple, size: 26),
              ),
              const SizedBox(height: 20),
              const Text('Letter saved',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.warmWhite)),
              const SizedBox(height: 14),
              Text(
                RecoveryModuleContent.m5LetterSavedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    height: 1.5,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              Text(
                'Phase 2 complete. Phase 3 begins at Day 30.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic),
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
