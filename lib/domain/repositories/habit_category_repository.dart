import '../entities/habit_category_model.dart';

abstract class HabitCategoryRepository {
  Future<List<HabitCategoryModel>> getCategories();
  Future<List<HabitSubcategoryModel>> getSubcategories(String categoryId);
  Future<List<HabitSubcategoryModel>> getAllSubcategories();
}
