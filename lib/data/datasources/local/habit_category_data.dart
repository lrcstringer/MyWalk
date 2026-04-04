import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../domain/entities/habit_category_model.dart';

/// Loads and parses [assets/data/habit_categories.json].
/// Returns a record with typed category and subcategory lists.
Future<({List<HabitCategoryModel> categories, List<HabitSubcategoryModel> subcategories})>
    loadHabitCategoryData() async {
  final raw = await rootBundle.loadString('assets/data/habit_categories.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;

  final categories = (json['categories'] as List)
      .map((e) => HabitCategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();

  final subcategories = (json['subcategories'] as List)
      .map((e) => HabitSubcategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();

  return (categories: categories, subcategories: subcategories);
}
