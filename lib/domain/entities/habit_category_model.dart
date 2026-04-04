class HabitCategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String colourHex;
  final String group;
  final String groupLabel;
  final int sortOrder;
  final bool isCustom;
  final String? categoryVerse;
  final String? categoryVerseRef;

  const HabitCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.colourHex,
    required this.group,
    required this.groupLabel,
    required this.sortOrder,
    required this.isCustom,
    this.categoryVerse,
    this.categoryVerseRef,
  });

  factory HabitCategoryModel.fromJson(Map<String, dynamic> j) => HabitCategoryModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        iconKey: j['iconKey'] as String? ?? 'category',
        colourHex: j['colourHex'] as String,
        group: j['group'] as String,
        groupLabel: j['groupLabel'] as String,
        sortOrder: (j['sortOrder'] as num).toInt(),
        isCustom: j['isCustom'] as bool,
        categoryVerse: j['categoryVerse'] as String?,
        categoryVerseRef: j['categoryVerseRef'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconKey': iconKey,
        'colourHex': colourHex,
        'group': group,
        'groupLabel': groupLabel,
        'sortOrder': sortOrder,
        'isCustom': isCustom,
        if (categoryVerse != null) 'categoryVerse': categoryVerse,
        if (categoryVerseRef != null) 'categoryVerseRef': categoryVerseRef,
      };
}

class SupportingVerse {
  final String text;
  final String ref;

  const SupportingVerse({required this.text, required this.ref});

  factory SupportingVerse.fromJson(Map<String, dynamic> j) => SupportingVerse(
        text: j['text'] as String,
        ref: j['ref'] as String,
      );

  Map<String, dynamic> toJson() => {'text': text, 'ref': ref};
}

class HabitSubcategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String? iconKey;
  final String trackingTypeSuggestion;
  final int? defaultTargetMinutes;
  final int sortOrder;
  final bool isCustom;
  final String yourWhy;
  final String? keyVerse;
  final String? keyVerseRef;
  final List<String> examples;
  final List<SupportingVerse> supportingVerses;

  const HabitSubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.iconKey,
    required this.trackingTypeSuggestion,
    this.defaultTargetMinutes,
    required this.sortOrder,
    required this.isCustom,
    this.yourWhy = '',
    this.keyVerse,
    this.keyVerseRef,
    this.examples = const [],
    this.supportingVerses = const [],
  });

  factory HabitSubcategoryModel.fromJson(Map<String, dynamic> j) => HabitSubcategoryModel(
        id: j['id'] as String,
        categoryId: j['categoryId'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        iconKey: j['iconKey'] as String?,
        trackingTypeSuggestion: j['trackingTypeSuggestion'] as String,
        defaultTargetMinutes: (j['defaultTargetMinutes'] as num?)?.toInt(),
        sortOrder: (j['sortOrder'] as num).toInt(),
        isCustom: j['isCustom'] as bool,
        yourWhy: j['yourWhy'] as String? ?? '',
        keyVerse: j['keyVerse'] as String?,
        keyVerseRef: j['keyVerseRef'] as String?,
        examples: (j['examples'] as List?)?.cast<String>() ?? const [],
        supportingVerses: (j['supportingVerses'] as List?)
                ?.map((e) => SupportingVerse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'iconKey': iconKey,
        'trackingTypeSuggestion': trackingTypeSuggestion,
        'defaultTargetMinutes': defaultTargetMinutes,
        'sortOrder': sortOrder,
        'isCustom': isCustom,
        'yourWhy': yourWhy,
        if (keyVerse != null) 'keyVerse': keyVerse,
        if (keyVerseRef != null) 'keyVerseRef': keyVerseRef,
        'examples': examples,
        'supportingVerses': supportingVerses.map((v) => v.toJson()).toList(),
      };
}
