import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/datasources/remote/auth_service.dart';
import '../../../../data/services/chunking_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import 'chunk_review_screen.dart';

class MemorizationInputScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialText;

  const MemorizationInputScreen({super.key, this.initialTitle, this.initialText});

  @override
  State<MemorizationInputScreen> createState() => _MemorizationInputScreenState();
}

class _MemorizationInputScreenState extends State<MemorizationInputScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _textCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isChunking = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _textCtrl = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Add verse or passage'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: _isChunking ? _ChunkingLoader() : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: MyWalkColor.warmWhite),
              decoration: _inputDecoration('e.g. John 3:16'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Text to memorize'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textCtrl,
              style: const TextStyle(color: MyWalkColor.warmWhite, height: 1.6),
              decoration: _inputDecoration(
                'Paste or type the verse or passage…',
              ),
              maxLines: 8,
              minLines: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Text is required';
                if (v.trim().split(RegExp(r'\s+')).length < 3) {
                  return 'Please enter at least a few words';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'AI will suggest how to break this into memorizable phrases.',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: MyWalkButtonStyle.primary(),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Suggest chunks'),
                onPressed: _onSuggestChunks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSuggestChunks() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();

    setState(() => _isChunking = true);

    final chunks = await ChunkingService.instance.chunkText(text);

    if (!mounted) return;

    setState(() => _isChunking = false);

    final uid = AuthService.shared.userId;
    if (uid == null) return;

    final item = MemorizationItem.create(
      userId: uid,
      title: title,
      fullText: text,
      chunks: chunks,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChunkReviewScreen(
          item: item,
          onConfirmed: (confirmedItem) {
            context.read<MemorizationProvider>().createItem(confirmedItem);
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
        filled: true,
        fillColor: MyWalkColor.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MyWalkColor.golden, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: MyWalkColor.warmWhite,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ChunkingLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: MyWalkColor.golden),
            const SizedBox(height: 24),
            Text(
              'Breaking into memorizable phrases…',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
