import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/datasources/remote/auth_service.dart';
import '../../../../domain/entities/memorization_circle.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('New memorization circle'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('Circle name'),
              const SizedBox(height: 8),
              _Field(
                controller: _nameCtrl,
                hint: 'e.g. Sunday Growth Group',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 20),
              _Label('Verse or passage title'),
              const SizedBox(height: 8),
              _Field(
                controller: _titleCtrl,
                hint: 'e.g. Psalm 23',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 20),
              _Label('Text to memorize together'),
              const SizedBox(height: 8),
              _Field(
                controller: _textCtrl,
                hint: 'Paste the passage…',
                maxLines: 6,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Text required' : null,
              ),
              const SizedBox(height: 20),
              _Label('Target date (optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
                      const SizedBox(width: 10),
                      Text(
                        _targetDate == null
                            ? 'Choose a goal date…'
                            : _formatDate(_targetDate!),
                        style: TextStyle(
                          color: _targetDate == null
                              ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                              : MyWalkColor.warmWhite,
                          fontSize: 14,
                        ),
                      ),
                      if (_targetDate != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _targetDate = null),
                          child: Icon(Icons.close,
                              size: 16,
                              color: MyWalkColor.warmWhite
                                  .withValues(alpha: 0.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: MyWalkButtonStyle.primary(),
                  onPressed: _saving ? null : _onCreate,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: MyWalkColor.charcoal),
                        )
                      : const Text('Create circle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MyWalkColor.golden,
            surface: MyWalkColor.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = AuthService.shared.userId;
    if (uid == null) return;

    setState(() => _saving = true);

    try {
      final circle = MemorizationCircle.create(
        name: _nameCtrl.text.trim(),
        createdBy: uid,
        itemText: _textCtrl.text.trim(),
        itemTitle: _titleCtrl.text.trim(),
        targetDate: _targetDate,
      );

      await context.read<MemorizationProvider>().saveCircle(circle);

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: MyWalkColor.warmWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: MyWalkColor.warmWhite),
      maxLines: maxLines,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
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
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
