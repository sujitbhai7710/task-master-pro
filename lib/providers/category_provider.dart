import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _api.getCategories();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Category?> createCategory(Map<String, dynamic> categoryData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final category = await _api.createCategory(categoryData);
      _categories.add(category);
      _isLoading = false;
      notifyListeners();
      return category;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Category?> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedCategory = await _api.updateCategory(categoryId, categoryData);
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      _isLoading = false;
      notifyListeners();
      return updatedCategory;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
