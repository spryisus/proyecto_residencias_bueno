import 'package:flutter/material.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/inventory_usecases.dart';

class InventoryController extends ChangeNotifier {
  final GetInventoryByCategory _getInventoryByCategory;
  final CreateInventoryItem _createInventoryItem;
  final GenerateInventoryReport _generateInventoryReport;
  final ExportInventory _exportInventory;

  InventoryController(
    this._getInventoryByCategory,
    this._createInventoryItem,
    this._generateInventoryReport,
    this._exportInventory,
  );

  // Estado
  List<InventoryItem> _items = [];
  String _selectedCategory = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<InventoryItem> get items => _items;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Métodos
  Future<void> loadItemsByCategory(String category) async {
    _setLoading(true);
    _error = null;
    
    try {
      _items = await _getInventoryByCategory(category);
      _selectedCategory = category;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createItem(InventoryItem item) async {
    _setLoading(true);
    _error = null;
    
    try {
      final createdItem = await _createInventoryItem(item);
      _items.add(createdItem);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> generateReport({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      return await _generateInventoryReport(
        category: category ?? _selectedCategory,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> exportData(String format) async {
    _setLoading(true);
    _error = null;
    
    try {
      return await _exportInventory(format, category: _selectedCategory);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
