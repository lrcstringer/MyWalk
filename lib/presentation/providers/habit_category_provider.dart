import 'package:flutter/foundation.dart';
import '../../domain/entities/habit_category_model.dart';
import '../../domain/repositories/habit_category_repository.dart';

class HabitCategoryProvider extends ChangeNotifier {
  final HabitCategoryRepository _repo;

  List<HabitCategoryModel> _categories = [];
  Map<String, List<HabitSubcategoryModel>> _subcategoryMap = {};

  HabitCategoryProvider(this._repo);

  List<HabitCategoryModel> get categories => _categories;

  Future<void> loadCategories() async {
    _categories = await _repo.getCategories();
    final all = await _repo.getAllSubcategories();
    _subcategoryMap = {};
    for (final sub in all) {
      _subcategoryMap.putIfAbsent(sub.categoryId, () => []).add(sub);
    }
    notifyListeners();
  }

  HabitCategoryModel? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<HabitSubcategoryModel> subcategoriesFor(String categoryId) =>
      _subcategoryMap[categoryId] ?? [];

  List<HabitCategoryModel> categoriesByGroup(String group) =>
      _categories.where((c) => c.group == group).toList();
}
