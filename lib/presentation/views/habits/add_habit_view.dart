import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../utils/category_icons.dart';
import '../../providers/habit_provider.dart';
import '../../providers/habit_category_provider.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/day_of_week_picker.dart';
import '../shared/fruit_tag_chip.dart';
import '../shared/mywalk_paywall_view.dart';
import '../practices/breaking_free_intro_screen.dart';

class AddHabitView extends StatefulWidget {
  final ScrollController? scrollController;
  final String? prefilledCategoryId;
  final String? prefilledCategoryName;
  final String? prefilledSubcategoryName;
  final HabitCategoryModel? startCategoryModel;
  final HabitSubcategoryModel? startSubcategoryModel;
  final bool forBreakingFree;

  const AddHabitView({
    super.key,
    this.scrollController,
    this.prefilledCategoryId,
    this.prefilledCategoryName,
    this.prefilledSubcategoryName,
    this.startCategoryModel,
    this.startSubcategoryModel,
    this.forBreakingFree = false,
  });

  @override
  State<AddHabitView> createState() => _AddHabitViewState();
}

class _AddHabitViewState extends State<AddHabitView> {
  // Step: 1=category grid, 2=subcategory picker, 3=set it up
  int _step = 1;

  // New two-level category selection
  HabitCategoryModel? _selectedCategoryModel;
  HabitSubcategoryModel? _selectedSubcategoryModel;
  String? _categoryId;
  String? _subcategoryId;
  String? _categoryName;
  String? _subcategoryName;

  // Legacy enum kept for backward-compat with trigger chips / purpose defaults
  HabitCategory _selectedCategory = HabitCategory.custom;

  bool get _isPreFilled =>
      widget.prefilledCategoryId != null || widget.forBreakingFree;

  @override
  void initState() {
    super.initState();
    _notesController = QuillController.basic();
    if (widget.forBreakingFree) {
      _selectedCategory = HabitCategory.abstain;
      _trackingType = HabitTrackingType.abstain;
      _subcategoryId = 'breaking_habits';
      _categoryName = 'Breaking Free';
      _purposeStatement = HabitCategory.abstain.defaultPurpose;
      _selectedCategoryModel = widget.startCategoryModel;
      _selectedSubcategoryModel = widget.startSubcategoryModel;
      _step = 3;
    } else if (widget.startCategoryModel != null) {
      final cat = widget.startCategoryModel!;
      _selectedCategoryModel = cat;
      _selectedCategory = _toOldEnum(cat.id, null);
      final sub = widget.startSubcategoryModel;
      if (sub != null) {
        final legacyEnum = _toOldEnum(cat.id, sub.id);
        final trackingType = _trackingTypeFromSuggestion(sub.trackingTypeSuggestion);
        _selectedSubcategoryModel = sub;
        _categoryId = cat.id;
        _subcategoryId = sub.id;
        _categoryName = cat.name;
        _subcategoryName = sub.isCustom ? '' : sub.name;
        _selectedCategory = legacyEnum;
        _trackingType = trackingType;
        _dailyTarget = sub.defaultTargetMinutes?.toDouble() ?? _defaultTarget(legacyEnum);
        _targetUnit = trackingType == HabitTrackingType.timed ? 'minutes' : '';
        _habitName = sub.isCustom ? '' : sub.name;
        _purposeStatement = sub.yourWhy.isNotEmpty ? sub.yourWhy : legacyEnum.defaultPurpose;
        _suggestedFruits = FruitSuggestionService.suggestForSubcategory(sub.id);
        if (_suggestedFruits.isEmpty) {
          _suggestedFruits = FruitSuggestionService.suggest(legacyEnum);
        }
        _step = 3;
      } else if (cat.isCustom) {
        _categoryId = cat.id;
        _subcategoryId = 'custom';
        _categoryName = cat.name;
        _subcategoryName = '';
        _purposeStatement = HabitCategory.custom.defaultPurpose;
        _step = 3;
      } else {
        _step = 2;
      }
    } else if (widget.prefilledCategoryId != null) {
      _categoryId = widget.prefilledCategoryId;
      _categoryName = widget.prefilledCategoryName;
      _subcategoryId = 'custom';
      _subcategoryName = widget.prefilledSubcategoryName ?? '';
      _purposeStatement = HabitCategory.custom.defaultPurpose;
      _step = 3;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _notesScrollController.dispose();
    _referenceUrlController.dispose();
    _customPatternCtrl.dispose();
    for (final c in _pinControllers) c.dispose();
    for (final f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  // Habit form fields
  String _habitName = '';
  String _purposeStatement = '';
  HabitTrackingType _trackingType = HabitTrackingType.checkIn;
  double _dailyTarget = 1;
  String _targetUnit = '';
  Set<int> _activeDays = {1, 2, 3, 4, 5, 6, 7};
  String _trigger = '';
  String _copingPlan = '';
  String _displayAlias = '';
  bool _wantsPartner = false;
  bool _wantsRecoveryPath = false;
  List<FruitType> _selectedFruits = [];
  String _fruitPurposeStatement = '';
  List<FruitType> _suggestedFruits = [];
  late QuillController _notesController;
  bool _notesExpanded = false;
  final FocusNode _notesFocusNode = FocusNode();
  final ScrollController _notesScrollController = ScrollController();
  final TextEditingController _referenceUrlController = TextEditingController();
  final TextEditingController _customPatternCtrl = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  String _pin = '';

  // ── App bar ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;

    String title;
    Widget leading;

    if (_step == 1) {
      title = 'Choose a Practice';
      leading = IconButton(
        icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
        onPressed: () => Navigator.pop(context),
      );
    } else if (_step == 2) {
      title = _selectedCategoryModel?.name ?? '';
      leading = IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: MyWalkColor.warmWhite, size: 18),
        onPressed: () {
          if (widget.startCategoryModel != null) {
            Navigator.pop(context);
          } else {
            setState(() => _step = 1);
          }
        },
      );
    } else {
      title = widget.forBreakingFree ? 'New Practice' : 'Set It Up';
      leading = widget.forBreakingFree
          ? const SizedBox.shrink()
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: MyWalkColor.warmWhite, size: 18),
              onPressed: () {
                if (_isPreFilled || widget.startSubcategoryModel != null) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _step = (_selectedCategoryModel?.isCustom ?? true) ? 1 : 2;
                  });
                }
              },
            );
    }

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: MyWalkColor.softGold.withValues(alpha: 0.8))),
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: _step == 1
                  ? _step1Content()
                  : _step == 2
                      ? _subcategoryPicker()
                      : _habitDetails(isPremium),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Category grid + Breaking Patterns card ──────────────────────

  Widget _step1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _categoryGrid(),
        const SizedBox(height: 12),
        _createMyOwnPracticeCard(),
      ],
    );
  }

  Widget _createMyOwnPracticeCard() {
    final isPremium = context.watch<StoreProvider>().isPremium;
    return GestureDetector(
      onTap: () {
        if (!isPremium) {
          _showPaywall();
          return;
        }
        final cats = context.read<HabitCategoryProvider>().categories;
        final customCat = cats.where((c) => c.isCustom).firstOrNull;
        if (customCat != null) _selectCategoryModel(customCat);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: MyWalkColor.golden.withValues(alpha: isPremium ? 0.25 : 0.12),
              width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyWalkColor.golden.withValues(alpha: 0.12),
              ),
              child: Icon(
                isPremium
                    ? Icons.add_circle_outline_rounded
                    : Icons.lock_rounded,
                color: MyWalkColor.golden.withValues(alpha: isPremium ? 1.0 : 0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Create my own Practice',
                style: TextStyle(
                  color: isPremium
                      ? MyWalkColor.warmWhite
                      : Colors.white.withValues(alpha: 0.35),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isPremium)
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3), size: 20)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: MyWalkColor.golden.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: MyWalkColor.golden.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => const MyWalkPaywallView(),
    );
  }

  Widget _categoryGrid() {
    const hiddenCategoryIds = {'fruit_of_the_spirit', 'the_beatitudes'};
    final categories = context
        .watch<HabitCategoryProvider>()
        .categories
        .where((c) => !hiddenCategoryIds.contains(c.id) && !c.isCustom)
        .toList();
    final store = context.watch<StoreProvider>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        ...categories.map((cat) {
          final catColor = Color(
            int.parse('FF${cat.colourHex.replaceAll('#', '')}', radix: 16),
          );
          final isFree = store.isFreeCategory(
            categoryId: cat.id,
            subcategoryId: null,
          );
          return GestureDetector(
            onTap: () => isFree ? _selectCategoryModel(cat) : _showPaywall(),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MyWalkColor.cardBackground,
                        isFree
                            ? catColor.withValues(alpha: 0.22)
                            : catColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFree
                          ? catColor.withValues(alpha: 0.65)
                          : catColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: catColor.withValues(alpha: isFree ? 0.18 : 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: catColor.withValues(alpha: isFree ? 0.15 : 0.07),
                        ),
                        child: Icon(
                          iconForKey(cat.iconKey),
                          size: 24,
                          color: catColor.withValues(alpha: isFree ? 1.0 : 0.4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFree
                              ? MyWalkColor.warmWhite
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isFree)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: MyWalkColor.golden.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: MyWalkColor.golden.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 9, color: MyWalkColor.golden.withValues(alpha: 0.8)),
                          const SizedBox(width: 3),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: MyWalkColor.golden.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        _breakingPatternsGridCard(),
      ],
    );
  }

  Widget _breakingPatternsGridCard() {
    const color = Color(0xFF922B2B);
    return GestureDetector(
      onTap: () {
        final nav = Navigator.of(context);
        nav.pop();
        nav.push(MaterialPageRoute(builder: (_) => const BreakingFreeIntroScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MyWalkColor.cardBackground, color.withValues(alpha: 0.22)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.shield_rounded, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            const Text(
              'Breaking Patterns & Recovery/Freedom Plan',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Subcategory picker ───────────────────────────────────────────

  Widget _subcategoryPicker() {
    final subcategories = context
        .read<HabitCategoryProvider>()
        .subcategoriesFor(_selectedCategoryModel!.id);

    return Column(
      children: [
        ...subcategories.map((sub) => _subcategoryCard(sub)),
        _customSubcategoryCard(),
      ],
    );
  }

  Widget _subcategoryCard(HabitSubcategoryModel sub) {
    final catColor = _selectedCategoryModel != null
        ? Color(int.parse(
            'FF${_selectedCategoryModel!.colourHex.replaceAll('#', '')}',
            radix: 16))
        : MyWalkColor.golden;

    return GestureDetector(
      onTap: () {
        if (sub.id == 'breaking_habits') {
          final nav = Navigator.of(context);
          nav.pop();
          nav.push(MaterialPageRoute(
            builder: (_) => BreakingFreeIntroScreen(
              categoryModel: _selectedCategoryModel,
              subcategoryModel: sub,
            ),
          ));
        } else {
          _selectSubcategory(sub);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              catColor.withValues(alpha: 0.10),
              MyWalkColor.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: catColor.withValues(alpha: 0.75), width: 3),
            top: BorderSide(color: catColor.withValues(alpha: 0.15), width: 0.5),
            right: BorderSide(color: catColor.withValues(alpha: 0.15), width: 0.5),
            bottom: BorderSide(color: catColor.withValues(alpha: 0.15), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: catColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(iconForKey(sub.iconKey), size: 18, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sub.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
            if (sub.yourWhy.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub.yourWhy,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
            if (sub.keyVerseRef != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.format_quote, size: 12,
                      color: MyWalkColor.golden.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    sub.keyVerseRef!,
                    style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.golden.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _customSubcategoryCard() {
    final isPremium = context.watch<StoreProvider>().isPremium;
    return GestureDetector(
      onTap: isPremium ? _selectCustomSubcategory : _showPaywall,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: isPremium ? 0.3 : 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPremium ? Icons.add_circle_outline : Icons.lock_rounded,
              size: 20,
              color: MyWalkColor.golden.withValues(alpha: isPremium ? 1.0 : 0.45),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create My Own Practice',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPremium
                          ? MyWalkColor.warmWhite
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPremium
                        ? 'Name it, set a goal, and make it yours.'
                        : 'Available with Premium',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            if (isPremium)
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.white.withValues(alpha: 0.3))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: MyWalkColor.golden.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: MyWalkColor.golden.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Set It Up ────────────────────────────────────────────────────

  Widget _habitDetails(bool isPremium) {
    final isAbstain = _subcategoryId == 'breaking_habits' ||
        _selectedCategory == HabitCategory.abstain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category/subcategory chips
        _categoryChipsRow(),
        const SizedBox(height: 20),

        // ── CHOOSE THE PATTERN (abstain only) ─────────────────────────────
        if (isAbstain && _selectedSubcategoryModel != null)
          _sectionHeader('CHOOSE THE PATTERN YOU WISH TO BREAK', MyWalkColor.eventPurple),

        // Subcategory content card (Key Verse, Examples, Supporting Verses)
        if (_selectedSubcategoryModel != null && !(_selectedCategoryModel?.isCustom ?? true))
          _subcategoryContentCard(_selectedSubcategoryModel!),

        // ── ABOUT THIS PRACTICE ───────────────────────────────────────────
        _sectionHeader('ABOUT THIS PRACTICE', MyWalkColor.sage),

        // Practice Name — read-only display for abstain (driven by chip/custom field)
        _label('Practice Name'),
        const SizedBox(height: 8),
        if (isAbstain)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: MyWalkColor.surfaceOverlay,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _habitName.isNotEmpty
                  ? _habitName
                  : 'Select a pattern above or enter your own',
              style: TextStyle(
                color: _habitName.isNotEmpty
                    ? MyWalkColor.warmWhite
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          )
        else
          _textField(
            hint: 'e.g. Morning run',
            value: _habitName,
            onChanged: (v) => setState(() => _habitName = v),
          ),

        if (_subcategoryId == 'breaking_habits') ...[
          const SizedBox(height: 16),
          _label('You can enter a practice name that will appear on your Today screen if you don\'t want one of the defined names to appear (optional)'),
          const SizedBox(height: 8),
          _textField(
            hint: 'e.g. "My battle" · Leave blank to use the practice name',
            value: _displayAlias,
            onChanged: (v) => setState(() => _displayAlias = v),
          ),
          const SizedBox(height: 6),
          Text(
            'Useful if you prefer a private name that others won\'t recognise.',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          _label('Privacy PIN — optional', inline: true),
          const SizedBox(height: 4),
          Text(
            'Set a 4-digit PIN to lock this card on the Today screen. '
            'Make a note of it — it cannot be recovered.',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 8),
          _pinSetupRow(),
        ],
        const SizedBox(height: 20),

        // Purpose
        _label(isAbstain ? 'Your Why – enter why breaking this pattern is important to you.' : 'Your Why', inline: true),
        const SizedBox(height: 8),
        _textField(
          hint: 'Why does this matter to you and to God?',
          value: _purposeStatement,
          onChanged: (v) => setState(() => _purposeStatement = v),
          maxLines: 3,
        ),
        const SizedBox(height: 20),

        // Fruit tags
        _fruitTagSection(),
        const SizedBox(height: 20),

        // Notes (collapsible)
        _notesSection(),
        const SizedBox(height: 20),

        // Reference URL
        _referenceUrlSection(),
        const SizedBox(height: 28),

        // ── SCHEDULE & TRACKING ───────────────────────────────────────────
        _sectionHeader('SCHEDULE & TRACKING', MyWalkColor.eventPurple),

        // Tracking type (not for abstain)
        if (!isAbstain) ...[
          _label('Tracking Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              HabitTrackingType.checkIn,
              HabitTrackingType.timed,
              HabitTrackingType.count,
            ].map((type) {
              final selected = _trackingType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setTrackingType(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? MyWalkColor.golden : MyWalkColor.surfaceOverlay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _trackingTypeLabel(type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Timed goal
        if (_trackingType == HabitTrackingType.timed) ...[
          _label('Daily Goal (minutes)'),
          const SizedBox(height: 8),
          Row(
            children: [15.0, 30.0, 45.0, 60.0].map((mins) {
              final selected = _dailyTarget == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _dailyTarget = mins),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? MyWalkColor.golden : MyWalkColor.surfaceOverlay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${mins.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Count goal
        if (_trackingType == HabitTrackingType.count) ...[
          _label('Daily Goal'),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: MyWalkColor.surfaceOverlay,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          _dailyTarget > 1 ? () => setState(() => _dailyTarget--) : null,
                      icon: const Icon(Icons.remove, size: 18, color: MyWalkColor.softGold),
                    ),
                    Text(
                      '${_dailyTarget.toInt()}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.golden),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _dailyTarget++),
                      icon: const Icon(Icons.add, size: 18, color: MyWalkColor.softGold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  hint: 'Unit (e.g. glasses)',
                  value: _targetUnit,
                  onChanged: (v) => setState(() => _targetUnit = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Day of week picker
        DayOfWeekPicker(
          selected: _activeDays,
          onChanged: (days) => setState(() => _activeDays = days),
          isAbstain: isAbstain,
        ),
        const SizedBox(height: 20),

        // Anchoring/trigger section
        _anchoringSection(isAbstain),
        const SizedBox(height: 28),

        // Support options (abstain only)
        if (isAbstain) ...[
          _sectionHeader('SELECT SUPPORT OPTIONS', MyWalkColor.eventPurple),
          _partnerSection(),
          const SizedBox(height: 20),
          _recoveryPathTeaserCard(),
          const SizedBox(height: 28),
        ],

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _habitName.trim().isEmpty ? null : _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(isAbstain ? 'Save my practice' : 'Set this practice',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: color.withValues(alpha: 0.18),
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Subcategory content card (Step 3) ────────────────────────────────────

  Widget _subcategoryContentCard(HabitSubcategoryModel sub) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: MyWalkColor.surfaceOverlay,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: MyWalkColor.golden.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Verse
              if (sub.keyVerse != null && sub.keyVerseRef != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote,
                        size: 16, color: MyWalkColor.golden.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.keyVerse!,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '— ${sub.keyVerseRef!}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.golden.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Supporting Verses link — right under the verse
                if (sub.supportingVerses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showSupportingVerses(sub),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 14, color: MyWalkColor.golden.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'Supporting Verses (${sub.supportingVerses.length})',
                          style: TextStyle(
                            fontSize: 12,
                            color: MyWalkColor.golden.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: MyWalkColor.golden.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(
                    color: MyWalkColor.golden.withValues(alpha: 0.12), thickness: 0.5),
                const SizedBox(height: 12),
              ],

              // Examples
              if (sub.examples.isNotEmpty) ...[
                Text(
                  'Select a pre-defined pattern or enter your own',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sub.examples.map((ex) => GestureDetector(
                    onTap: () => setState(() {
                      _habitName = ex;
                      _customPatternCtrl.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _habitName == ex && _customPatternCtrl.text.isEmpty
                            ? MyWalkColor.golden.withValues(alpha: 0.2)
                            : MyWalkColor.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _habitName == ex && _customPatternCtrl.text.isEmpty
                              ? MyWalkColor.golden.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        ex,
                        style: TextStyle(
                          fontSize: 12,
                          color: _habitName == ex && _customPatternCtrl.text.isEmpty
                              ? MyWalkColor.golden
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customPatternCtrl,
                  onChanged: (v) => setState(() => _habitName = v),
                  style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your own practice…',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                    filled: true,
                    fillColor: MyWalkColor.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: MyWalkColor.golden.withValues(alpha: 0.4), width: 1),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSupportingVerses(HabitSubcategoryModel sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 18, color: MyWalkColor.golden.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${sub.name} — Supporting Verses',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: MyWalkColor.golden.withValues(alpha: 0.15), height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: sub.supportingVerses.length + 1,
                separatorBuilder: (_, i) => i == 0
                    ? const SizedBox(height: 16)
                    : Divider(color: Colors.white.withValues(alpha: 0.07), height: 24),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Text(
                      'These verses are to spur your thinking, but it\'s good practice to always read a verse within its context and not isolated from its surrounding Scripture.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    );
                  }
                  final v = sub.supportingVerses[i - 1];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '— ${v.ref}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MyWalkColor.golden.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChipsRow() {
    if (_categoryId == null || _isPreFilled || widget.startCategoryModel != null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_categoryName != null)
          _categoryChip(
            label: _categoryName!,
            onTap: () => setState(() => _step = 1),
          ),
        if (_subcategoryName != null && _subcategoryName!.isNotEmpty)
          _categoryChip(
            label: _subcategoryName!,
            onTap: () => setState(() => _step = 2),
          ),
      ],
    );
  }

  Widget _categoryChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.9))),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined,
                size: 11, color: MyWalkColor.golden.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  // ── Selection handlers ───────────────────────────────────────────────────

  void _selectCategoryModel(HabitCategoryModel cat) {
    final legacyEnum = _toOldEnum(cat.id, null);
    if (cat.isCustom) {
      // Skip subcategory step for "Create My Own"
      setState(() {
        _selectedCategoryModel = cat;
        _selectedSubcategoryModel = null;
        _selectedCategory = legacyEnum;
        _categoryId = cat.id;
        _subcategoryId = 'custom';
        _categoryName = cat.name;
        _subcategoryName = '';
        _trackingType = HabitTrackingType.checkIn;
        _habitName = '';
        _purposeStatement = legacyEnum.defaultPurpose;
        _dailyTarget = 1;
        _targetUnit = '';
        _suggestedFruits = FruitSuggestionService.suggest(legacyEnum);
        _selectedFruits = [];
        _fruitPurposeStatement = '';
        _step = 3;
      });
    } else {
      setState(() {
        _selectedCategoryModel = cat;
        _selectedCategory = legacyEnum;
        _step = 2;
      });
    }
  }

  void _selectCustomSubcategory() {
    final legacyEnum = _toOldEnum(_selectedCategoryModel!.id, null);
    setState(() {
      _selectedSubcategoryModel = null;
      _selectedCategory = legacyEnum;
      _categoryId = _selectedCategoryModel!.id;
      _subcategoryId = 'custom';
      _categoryName = _selectedCategoryModel!.name;
      _subcategoryName = '';
      _trackingType = HabitTrackingType.checkIn;
      _dailyTarget = 1;
      _targetUnit = '';
      _habitName = '';
      _purposeStatement = legacyEnum.defaultPurpose;
      _suggestedFruits = FruitSuggestionService.suggest(legacyEnum);
      _selectedFruits = [];
      _fruitPurposeStatement = '';
      _step = 3;
    });
  }

  void _selectSubcategory(HabitSubcategoryModel sub) {
    final legacyEnum = _toOldEnum(_selectedCategoryModel!.id, sub.id);
    final trackingType = _trackingTypeFromSuggestion(sub.trackingTypeSuggestion);
    final isCustomSub = sub.isCustom;

    setState(() {
      _selectedSubcategoryModel = sub;
      _categoryId = _selectedCategoryModel!.id;
      _subcategoryId = sub.id;
      _categoryName = _selectedCategoryModel!.name;
      _subcategoryName = isCustomSub ? '' : sub.name;

      _trackingType = trackingType;
      _dailyTarget = sub.defaultTargetMinutes?.toDouble() ?? _defaultTarget(legacyEnum);
      _targetUnit = trackingType == HabitTrackingType.timed ? 'minutes' : '';
      _habitName = isCustomSub ? '' : sub.name;
      _purposeStatement = sub.yourWhy.isNotEmpty ? sub.yourWhy : legacyEnum.defaultPurpose;
      _suggestedFruits = FruitSuggestionService.suggestForSubcategory(sub.id);
      if (_suggestedFruits.isEmpty) {
        _suggestedFruits = FruitSuggestionService.suggest(legacyEnum);
      }
      _selectedFruits = [];
      _fruitPurposeStatement = '';
      _step = 3;
    });
  }

  // ── Notes section ────────────────────────────────────────────────────────

  Widget _notesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — tapping toggles collapse
        GestureDetector(
          onTap: () => setState(() => _notesExpanded = !_notesExpanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: MyWalkColor.eventPurple.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.eventPurple.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: MyWalkColor.eventPurple.withValues(alpha: 0.18),
                  thickness: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _notesExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: MyWalkColor.eventPurple.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),

        if (_notesExpanded) ...[
          const SizedBox(height: 4),
          Text(
            'Personal notes, reminders, or reflections for this habit.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MyWalkColor.golden.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuillSimpleToolbar(
                    controller: _notesController,
                    config: QuillSimpleToolbarConfig(
                      color: Colors.transparent,
                      multiRowsDisplay: false,
                      showDividers: false,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showListBullets: true,
                      showListNumbers: true,
                      showListCheck: false,
                      showUndo: true,
                      showRedo: true,
                      showHeaderStyle: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showClearFormat: false,
                      showStrikeThrough: false,
                      showInlineCode: false,
                      showLink: false,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showSmallButton: false,
                      showFontFamily: false,
                      showFontSize: false,
                      showAlignmentButtons: false,
                      showLeftAlignment: false,
                      showCenterAlignment: false,
                      showRightAlignment: false,
                      showJustifyAlignment: false,
                      showIndent: false,
                      showQuote: false,
                      showCodeBlock: false,
                      showDirection: false,
                      iconTheme: QuillIconTheme(
                        iconButtonUnselectedData: IconButtonData(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                        ),
                        iconButtonSelectedData: IconButtonData(
                          color: MyWalkColor.golden,
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: MyWalkColor.golden.withValues(alpha: 0.12),
                  ),
                  QuillEditor.basic(
                    controller: _notesController,
                    focusNode: _notesFocusNode,
                    scrollController: _notesScrollController,
                    config: QuillEditorConfig(
                      placeholder: 'Add personal notes…',
                      minHeight: 100,
                      maxHeight: 200,
                      scrollable: true,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _notesExpanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: MyWalkColor.golden.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_outlined,
                      size: 16, color: MyWalkColor.softGold.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Text(
                    'Add personal notes…',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Support/Accountability Partner section ───────────────────────────────

  Widget _partnerSection() {
    const cardColor = Color(0xFF2E6B5E);
    const iconColor = Color(0xFF7EC8B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardColor.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.handshake_rounded, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Support/Accountability Partner (optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: iconColor),
                ),
                const SizedBox(height: 3),
                Text(
                  'Do you want to invite someone to walk with you? They can be notified when you need support.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (context.read<StoreProvider>().canInvitePartner) ...[
          Text(
            '(You can set this up later if you don\'t want to now)',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pillChip(label: 'Yes', selected: _wantsPartner, onTap: () => setState(() => _wantsPartner = true)),
              const SizedBox(width: 8),
              _pillChip(label: 'No — set up later', selected: !_wantsPartner, onTap: () => setState(() => _wantsPartner = false)),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: MyWalkColor.charcoal,
                builder: (_) => const MyWalkPaywallView(
                  contextTitle: 'Upgrade to invite a Support Partner',
                ),
              ),
              icon: const Icon(Icons.lock_rounded, size: 16),
              label: const Text(
                'Support Partner — Premium',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6B5E).withValues(alpha: 0.3),
                foregroundColor: Colors.white.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Recovery/Freedom Plan opt-in card ───────────────────────────────────

  Widget _recoveryPathTeaserCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4FA0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF6B4FA0).withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4FA0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.route_rounded,
                  size: 16, color: Color(0xFFB39DDB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Recovery/Freedom Plan (optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB39DDB)),
                ),
                const SizedBox(height: 3),
                Text(
                  'A guided programme to understand your patterns, anchor to your values, and build guardrails.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(
          '(You can set this up later if you don\'t want to now)',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35), fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _pillChip(label: 'Yes', selected: _wantsRecoveryPath, onTap: () => setState(() => _wantsRecoveryPath = true)),
            const SizedBox(width: 8),
            _pillChip(label: 'No — set up later', selected: !_wantsRecoveryPath, onTap: () => setState(() => _wantsRecoveryPath = false)),
          ],
        ),
      ],
    );
  }

  Widget _pillChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? MyWalkColor.sage.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? MyWalkColor.sage.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? MyWalkColor.sage
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _referenceUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('REFERENCE LINK', MyWalkColor.eventPurple),
        Text(
          'Attach an article, video, or resource that inspires this habit.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _referenceUrlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: MyWalkColor.cardBackground,
            hintText: 'https://…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: MyWalkColor.sage, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Icon(Icons.link_rounded,
                size: 18, color: MyWalkColor.softGold.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  // ── Content safety guard ────────────────────────────────────────────────

  static const _crisisPhrases = [
    'cutting', 'cut myself', 'self harm', 'self-harm', 'selfharm',
    'suicide', 'suicidal', 'kill myself', 'killing myself', 'end my life',
    'jump off a bridge', 'jump off a building', 'take my life',
    'hurt myself', 'harming myself', 'want to die', 'don\'t want to live',
  ];

  static const _eatingDisorderPhrases = [
    'anorexia', 'bulimia', 'purge', 'purging', 'binge and purge',
    'not eating', 'starving myself', 'eating disorder', 'restrictive eating',
  ];

  bool _hasCrisisContent(String text) {
    final lower = text.toLowerCase();
    return _crisisPhrases.any(lower.contains);
  }

  bool _hasEatingDisorderContent(String text) {
    final lower = text.toLowerCase();
    return _eatingDisorderPhrases.any(lower.contains);
  }

  Future<bool> _runContentSafetyCheck() async {
    if (_subcategoryId != 'breaking_habits') return false;
    final combined = '$_habitName $_purposeStatement'.trim();
    if (_hasCrisisContent(combined)) {
      await _showSafetyDialog(
        title: 'This needs more than an app',
        message:
            'What you\'ve described sounds like it may need real professional support. '
            'This app isn\'t designed to help with self-harm or thoughts of suicide — '
            'please reach out to your doctor, a counsellor, or a crisis helpline. '
            'You deserve proper care.',
      );
      return true;
    }
    if (_hasEatingDisorderContent(combined)) {
      await _showSafetyDialog(
        title: 'This needs specialist support',
        message:
            'Eating disorders are serious medical conditions that need specialist care. '
            'This app isn\'t designed to support recovery from eating disorders — '
            'please speak with your doctor or a specialist who can give you the right help.',
      );
      return true;
    }
    return false;
  }

  Future<void> _showSafetyDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: MyWalkColor.warmWhite,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: MyWalkColor.softGold.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHabit() async {
    final trimmed = _habitName.trim();
    if (trimmed.isEmpty) return;
    if (await _runContentSafetyCheck()) return;
    if (!mounted) return;
    final isPremium = context.read<StoreProvider>().isPremium;
    final purpose = isPremium ? _purposeStatement : _selectedCategory.defaultPurpose;
    final plainNotes = _notesController.document.toPlainText().trim();
    final notesJson = plainNotes.isEmpty
        ? ''
        : jsonEncode(_notesController.document.toDelta().toJson());
    final refUrl = _referenceUrlController.text.trim();
    final habitProvider = context.read<HabitProvider>();
    final fruitProvider = context.read<FruitPortfolioProvider>();
    final habit = await habitProvider.addHabit(
      name: trimmed,
      category: _selectedCategory,
      trackingType: _trackingType,
      purpose: purpose,
      dailyTarget: _dailyTarget,
      targetUnit: _targetUnit,
      activeDays: _activeDays,
      trigger: _trigger,
      copingPlan: _copingPlan,
      fruitTags: _selectedFruits,
      fruitPurposeStatement:
          _fruitPurposeStatement.trim().isEmpty ? null : _fruitPurposeStatement.trim(),
      categoryId: _categoryId,
      subcategoryId: _subcategoryId,
      categoryName: _categoryName,
      subcategoryName: _subcategoryName?.trim().isEmpty ?? true
          ? null
          : _subcategoryName,
      notes: notesJson,
      referenceUrl: refUrl,
      displayAlias: _displayAlias.trim().isEmpty ? null : _displayAlias.trim(),
      pin: _pin.length == 4 ? _pin : null,
    );
    if (_selectedFruits.isNotEmpty) {
      fruitProvider.onHabitTagsChanged([], _selectedFruits);
    }
    if (!mounted) return;
    if (widget.forBreakingFree) {
      Navigator.pop(context, {
        'saved': true,
        'habitId': habit.id,
        'habitName': habit.name,
        'wantsPartner': _wantsPartner,
        'wantsRecoveryPath': _wantsRecoveryPath,
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  HabitCategory _toOldEnum(String categoryId, String? subcategoryId) {
    // Subcategory-level precision first
    if (subcategoryId != null) {
      return switch (subcategoryId) {
        'gods_word'     => HabitCategory.scripture,
        'prayer'        => HabitCategory.scripture,
        'church_life'   => HabitCategory.scripture,
        'evangelism'    => HabitCategory.scripture,
        'worship'       => HabitCategory.gratitude,
        'fasting'       => HabitCategory.fasting,
        'exercise'      => HabitCategory.exercise,
        'health_and_nutrition' => HabitCategory.health,
        'rest_and_renewal'     => HabitCategory.rest,
        'reading_and_learning' => HabitCategory.study,
        'creativity'    => HabitCategory.custom,
        'stewardship'   => HabitCategory.custom,
        'breaking_habits'      => HabitCategory.abstain,
        'service_and_generosity'   => HabitCategory.service,
        'connection_and_community' => HabitCategory.connection,
        _               => HabitCategory.custom,
      };
    }
    // Category-level fallback
    return switch (categoryId) {
      'loving_the_lord'   => HabitCategory.scripture,
      'caring_for_myself' => HabitCategory.health,
      'caring_for_others' => HabitCategory.service,
      _                   => HabitCategory.custom,
    };
  }

  HabitTrackingType _trackingTypeFromSuggestion(String suggestion) {
    return switch (suggestion) {
      'timed'   => HabitTrackingType.timed,
      'count'   => HabitTrackingType.count,
      'abstain' => HabitTrackingType.abstain,
      _         => HabitTrackingType.checkIn,
    };
  }

  void _setTrackingType(HabitTrackingType type) {
    setState(() {
      _trackingType = type;
      if (type == HabitTrackingType.timed) {
        _dailyTarget = 30;
        _targetUnit = 'minutes';
      } else if (type == HabitTrackingType.count) {
        _dailyTarget = 8;
        _targetUnit = '';
      } else {
        _dailyTarget = 1;
        _targetUnit = '';
      }
    });
  }

  double _defaultTarget(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return 30;
      case HabitCategory.scripture:
        return 15;
      case HabitCategory.study:
        return 30;
      case HabitCategory.health:
        return 8;
      default:
        return 1;
    }
  }

  // ── Anchoring section ────────────────────────────────────────────────────

  Widget _anchoringSection(bool isAbstain) {
    if (isAbstain) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('When I feel tempted, I will\u2026'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse',
                      'Journal it out']
                  .map((s) => _chipButton(s, _copingPlan == s, MyWalkColor.warmCoral,
                      () => setState(() => _copingPlan = s)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _textField(
            hint: 'Or enter your own action\u2026',
            value: _copingPlan,
            onChanged: (v) => setState(() => _copingPlan = v),
          ),
        ],
      );
    }

    final chips = _triggerChips(_selectedCategory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('When will you do this?'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((s) => _chipButton(
                    s, _trigger == s, MyWalkColor.golden, () => setState(() => _trigger = s)))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        _textField(
          hint: 'Or type your own trigger\u2026',
          value: _trigger,
          onChanged: (v) => setState(() => _trigger = v),
        ),
      ],
    );
  }

  // ── Fruit tag section ────────────────────────────────────────────────────

  Widget _fruitTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What fruit is this cultivating?'),
        const SizedBox(height: 4),
        Text(
          'Connect this habit to your spiritual growth. (Optional)',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FruitType.values.map((fruit) {
            return FruitTagChip(
              fruit: fruit,
              isSelected: _selectedFruits.contains(fruit),
              isSuggested: false,
              onTap: () {
                setState(() {
                  if (_selectedFruits.contains(fruit)) {
                    _selectedFruits =
                        _selectedFruits.where((f) => f != fruit).toList();
                  } else {
                    _selectedFruits = [..._selectedFruits, fruit];
                  }
                  if (_selectedFruits.isNotEmpty && _fruitPurposeStatement.isEmpty) {
                    _fruitPurposeStatement = FruitPurposeStatements.defaultFor(
                      _selectedCategory,
                      _selectedFruits.first,
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedFruits.isNotEmpty) ...[
          const SizedBox(height: 12),
          _label('Spiritual purpose (optional)'),
          const SizedBox(height: 6),
          _textField(
            hint: 'Why does this habit matter to you spiritually?',
            value: _fruitPurposeStatement,
            onChanged: (v) => setState(() => _fruitPurposeStatement = v),
            maxLines: 2,
          ),
        ],
        if (_selectedFruits.isEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _suggestedFruits = []),
            child: Text(
              "I'll decide later",
              style: TextStyle(
                fontSize: 11,
                color: MyWalkColor.softGold.withValues(alpha: 0.45),
                decoration: TextDecoration.underline,
                decorationColor: MyWalkColor.softGold.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Small widgets ────────────────────────────────────────────────────────

  Widget _label(String text, {bool inline = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: MyWalkColor.softGold.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _textField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.surfaceOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _pinSetupRow() {
    final borderSide = BorderSide(
      color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
      width: 0.75,
    );
    final focusedBorder = const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: MyWalkColor.eventPurple, width: 1.5),
    );
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
            child: TextField(
              controller: _pinControllers[i],
              focusNode: _pinFocusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: MyWalkColor.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: borderSide,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: borderSide,
                ),
                focusedBorder: focusedBorder,
              ),
              onChanged: (v) {
                if (v.length == 1 && i < 3) {
                  _pinFocusNodes[i + 1].requestFocus();
                } else if (v.isEmpty && i > 0) {
                  _pinFocusNodes[i - 1].requestFocus();
                }
                setState(() {
                  _pin = _pinControllers.map((c) => c.text).join();
                });
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _chipButton(
      String label, bool selected, Color activeColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor : MyWalkColor.surfaceOverlay,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
            ),
          ),
        ),
      ),
    );
  }

  String _trackingTypeLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.checkIn:
        return 'Yes/No';
      case HabitTrackingType.timed:
        return 'Timed';
      case HabitTrackingType.count:
        return 'Count';
      case HabitTrackingType.abstain:
        return 'Abstain';
    }
  }

  List<String> _triggerChips(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return ['After my morning coffee', 'Before work', 'During lunch break', 'After dinner'];
      case HabitCategory.scripture:
        return ['First thing in the morning', 'Before bed', 'During lunch', 'After prayer'];
      case HabitCategory.rest:
        return ['At 10pm', 'After dinner', 'When I feel tired'];
      case HabitCategory.fasting:
        return ['After morning prayer', 'On Wednesdays', 'Weekly'];
      case HabitCategory.study:
        return ['After dinner', 'Morning routine', 'Lunch break'];
      case HabitCategory.service:
        return ['After church', 'On weekends', 'When I see a need'];
      case HabitCategory.connection:
        return ['Sunday afternoon', 'After dinner', 'During commute'];
      case HabitCategory.health:
        return ['With every meal', 'First thing in the morning', 'After exercise', 'Before bed'];
      default:
        return ['In the morning', 'After lunch', 'Before bed'];
    }
  }
}
