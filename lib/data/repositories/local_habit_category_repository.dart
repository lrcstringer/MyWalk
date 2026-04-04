import '../../domain/entities/habit_category_model.dart';
import '../../domain/repositories/habit_category_repository.dart';
import '../datasources/local/habit_category_data.dart';

class LocalHabitCategoryRepository implements HabitCategoryRepository {
  List<HabitCategoryModel>? _categories;
  List<HabitSubcategoryModel>? _subcategories;
  Future<void>? _loadFuture;

  // Race-safe: all concurrent callers await the same Future.
  Future<void> _ensureLoaded() => _loadFuture ??= _doLoad();

  Future<void> _doLoad() async {
    final data = await loadHabitCategoryData();
    _categories = data.categories;
    _subcategories = data.subcategories;
  }

  @override
  Future<List<HabitCategoryModel>> getCategories() async {
    await _ensureLoaded();
    return List.unmodifiable(_categories!);
  }

  @override
  Future<List<HabitSubcategoryModel>> getSubcategories(String categoryId) async {
    await _ensureLoaded();
    return _subcategories!.where((s) => s.categoryId == categoryId).toList();
  }

  @override
  Future<List<HabitSubcategoryModel>> getAllSubcategories() async {
    await _ensureLoaded();
    return List.unmodifiable(_subcategories!);
  }
}
