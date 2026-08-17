import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

// Fill Mode: type the missing letters of a chunk.
// Parses chunk.hint (underscores mark blank positions) against chunk.text.
// First-attempt scoring: correct on first try → green + advance;
// wrong → red, user must clear and retype (first fail already recorded).
// Score ≥ 60% → success.

class FillModeWidget extends StatefulWidget {
  final TextChunk chunk;
  final void Function({required bool success, List<String> missedIds}) onResult;

  const FillModeWidget({
    super.key,
    required this.chunk,
    required this.onResult,
  });

  @override
  State<FillModeWidget> createState() => _FillModeWidgetState();
}

class _FillModeWidgetState extends State<FillModeWidget> {
  late List<_DispItem> _items;
  late List<_BlankSlot> _slots;
  int _currentSlotIndex = 0;
  int _successCount = 0;
  bool _allFilled = false;
  bool _programmaticClear = false;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _buildItems();
    _autoFocus();
  }

  @override
  void didUpdateWidget(FillModeWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _ctrl.clear();
      _buildItems();
      _autoFocus();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _autoFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_allFilled) _focus.requestFocus();
    });
  }

  void _buildItems() {
    _items = [];
    _slots = [];
    _successCount = 0;
    _currentSlotIndex = 0;
    _allFilled = false;

    final hint = widget.chunk.hint;
    final text = widget.chunk.text;
    final len = hint.length < text.length ? hint.length : text.length;

    for (var i = 0; i < len; i++) {
      if (hint[i] == '_') {
        final slot = _BlankSlot(expected: text[i].toLowerCase());
        _items.add(slot);
        _slots.add(slot);
      } else {
        _items.add(_StaticChar(hint[i]));
      }
    }

    if (_slots.isEmpty) _allFilled = true;
  }

  void _onChanged(String value) {
    if (_programmaticClear) return;
    if (value.length == 1) {
      _processChar(value[0]);
    } else if (value.isEmpty) {
      _handleBackspaceFromField();
    } else {
      _processChar(value[value.length - 1]);
    }
  }

  void _processChar(String char) {
    if (_allFilled || _currentSlotIndex >= _slots.length) return;
    final slot = _slots[_currentSlotIndex];
    if (slot.locked) return;

    final isCorrect = char.toLowerCase() == slot.expected;

    if (!slot.firstAttemptMade) {
      slot.firstAttemptMade = true;
      slot.firstAttemptCorrect = isCorrect;
      if (isCorrect) _successCount++;
    }

    setState(() => slot.currentInput = char.toLowerCase());

    if (isCorrect) {
      _programmaticClear = true;
      _ctrl.clear();
      _programmaticClear = false;

      final nextIdx =
          _slots.indexWhere((s) => !s.locked, _currentSlotIndex + 1);
      if (nextIdx == -1) {
        setState(() {
          _allFilled = true;
          _currentSlotIndex = _slots.length;
        });
        _focus.unfocus();
      } else {
        setState(() => _currentSlotIndex = nextIdx);
        _focus.requestFocus();
      }
    }
  }

  void _handleBackspaceFromField() {
    if (_allFilled || _currentSlotIndex >= _slots.length) return;
    final slot = _slots[_currentSlotIndex];
    if (slot.currentInput != null && !slot.locked) {
      setState(() => slot.currentInput = null);
    }
  }

  void _backspaceButton() {
    if (_allFilled) return;
    final slot =
        _currentSlotIndex < _slots.length ? _slots[_currentSlotIndex] : null;

    if (slot != null && slot.currentInput != null && !slot.locked) {
      setState(() => slot.currentInput = null);
      _programmaticClear = true;
      _ctrl.clear();
      _programmaticClear = false;
      _focus.requestFocus();
      return;
    }

    for (var i = _currentSlotIndex - 1; i >= 0; i--) {
      if (!_slots[i].locked && _slots[i].currentInput != null) {
        setState(() {
          _slots[i].currentInput = null;
          _currentSlotIndex = i;
        });
        _programmaticClear = true;
        _ctrl.clear();
        _programmaticClear = false;
        _focus.requestFocus();
        return;
      }
    }
  }

  void _submit() {
    final total = _slots.length;
    final pct = total > 0 ? _successCount / total : 1.0;
    final success = pct >= 0.6;

    if (success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    widget.onResult(
      success: success,
      missedIds: success ? [] : [widget.chunk.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _slots.length;
    final pct = total > 0 ? ((_successCount / total) * 100).round() : 100;

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fill in the missing letters',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            _buildPuzzle(),
            const SizedBox(height: 16),
            if (!_allFilled) ...[
              SizedBox(
                height: 1,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLength: 1,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                  style: const TextStyle(
                      color: Colors.transparent, fontSize: 1),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: _onChanged,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _backspaceButton,
                    icon: const Icon(Icons.backspace_outlined, size: 16),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      side: BorderSide(
                          color:
                              MyWalkColor.warmWhite.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (pct >= 60
                              ? const Color(0xFF7A9E7E)
                              : Colors.orange.shade400)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (pct >= 60
                                ? const Color(0xFF7A9E7E)
                                : Colors.orange.shade400)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$_successCount / $total correct',
                      style: TextStyle(
                        color: pct >= 60
                            ? const Color(0xFF7A9E7E)
                            : Colors.orange.shade400,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    pct >= 60 ? 'Great work!' : 'Keep practising',
                    style: TextStyle(
                      color: pct >= 60
                          ? const Color(0xFF7A9E7E)
                          : Colors.orange.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: MyWalkButtonStyle.primary(),
                  onPressed: _submit,
                  child: const Text('Next'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzle() {
    final wordUnits = <Widget>[];
    var current = <_DispItem>[];

    for (final item in _items) {
      if (item is _StaticChar && item.char == ' ') {
        if (current.isNotEmpty) {
          wordUnits.add(_buildWordUnit(current));
          current = [];
        }
      } else {
        current.add(item);
      }
    }
    if (current.isNotEmpty) wordUnits.add(_buildWordUnit(current));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: wordUnits,
      ),
    );
  }

  Widget _buildWordUnit(List<_DispItem> items) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items.map((item) {
        if (item is _StaticChar) return _buildStaticChar(item.char);
        return _buildSlotBox(item as _BlankSlot);
      }).toList(),
    );
  }

  Widget _buildStaticChar(String char) {
    final isLetter = RegExp(r'[a-zA-Z]').hasMatch(char);
    return SizedBox(
      width: isLetter ? 14 : 7,
      child: Text(
        char,
        style: TextStyle(
          color: isLetter
              ? MyWalkColor.warmWhite
              : MyWalkColor.warmWhite.withValues(alpha: 0.55),
          fontSize: 18,
          fontFamily: 'monospace',
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSlotBox(_BlankSlot slot) {
    final idx = _slots.indexOf(slot);
    final isActive =
        !_allFilled && !slot.locked && idx == _currentSlotIndex;

    Color borderColor;
    Color textColor;
    Color? bgColor;

    if (slot.locked) {
      borderColor = const Color(0xFF7A9E7E);
      textColor = const Color(0xFF7A9E7E);
      bgColor = const Color(0xFF7A9E7E).withValues(alpha: 0.12);
    } else if (slot.currentInput != null) {
      borderColor = Colors.red.shade400;
      textColor = Colors.red.shade300;
      bgColor = Colors.red.shade900.withValues(alpha: 0.15);
    } else if (isActive) {
      borderColor = MyWalkColor.golden;
      textColor = Colors.transparent;
      bgColor = MyWalkColor.golden.withValues(alpha: 0.06);
    } else {
      borderColor = MyWalkColor.warmWhite.withValues(alpha: 0.2);
      textColor = Colors.transparent;
      bgColor = null;
    }

    return GestureDetector(
      onTap: () {
        if (!_allFilled) _focus.requestFocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 18,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom:
                BorderSide(color: borderColor, width: isActive ? 2.0 : 1.5),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          slot.currentInput ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _DispItem {}

class _StaticChar extends _DispItem {
  final String char;
  _StaticChar(this.char);
}

class _BlankSlot extends _DispItem {
  final String expected;
  bool firstAttemptMade = false;
  bool firstAttemptCorrect = false;
  String? currentInput;

  bool get locked =>
      currentInput != null && currentInput!.toLowerCase() == expected;

  _BlankSlot({required this.expected});
}
