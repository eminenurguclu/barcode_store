import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'product_model.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Product> _allProducts = [];
  List<Product> _products = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String? _lastSearchedBarcode;
  String _sortMode = 'none';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get lastSearchedBarcode => _lastSearchedBarcode;
  List<String> _history = [];
  List<String> get history => _history;

  // Dynamic Categories from loaded products
  List<String> get categories {
    final Set<String> uniqueCats = {'All', 'Electronics', 'Food', 'Clothes', 'Other'};
    if (_allProducts.isNotEmpty) {
      uniqueCats.addAll(_allProducts.map((p) => p.category));
    }
    return uniqueCats.toList();
  }

  String generateBarcode() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

// Uygulama her açıldığında loadAllProducts içinden kontrol edelim
  bool _hasSeeded = false;

  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Seed once per session to ensure missing examples are added
      if (!_hasSeeded) {
        await seedDatabase();
        _hasSeeded = true;
      }
      
      _allProducts = await _db.getAllProducts();
      _lastSearchedBarcode = null;
      _applyFilters();
    } catch (e) {
      debugPrint("Hata: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    Iterable<Product> list = _allProducts;
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory);
    }
    _products = list.toList();
    _applySortOnList(_products);
  }

  void _applySortOnList(List<Product> list) {
    if (_sortMode == 'name_asc') list.sort((a, b) => a.productName.compareTo(b.productName));
    else if (_sortMode == 'name_desc') list.sort((a, b) => b.productName.compareTo(a.productName));
    else if (_sortMode == 'price_asc') list.sort((a, b) => a.price.compareTo(b.price));
    else if (_sortMode == 'price_desc') list.sort((a, b) => b.price.compareTo(a.price));
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();
    final results = await _db.searchProducts(query);
    _products = results;
    _lastSearchedBarcode = query; // Keeping variable name but storing query for highlighting
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Product product) async {
    final existing = await _db.getProductByBarcode(product.barcodeNo);
    if (existing != null) return false;
    await _db.insertProduct(product);
    await loadAllProducts();
    return true;
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await loadAllProducts();
  }

  Future<void> deleteProduct(String barcode) async {
    await _db.deleteProduct(barcode);
    await loadAllProducts();
  }

  void sortBy(String mode) {
    _sortMode = mode;
    _applyFilters();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _history = await _db.getHistory();
    notifyListeners();
  }

  Future<void> addToHistory(String term) async {
    if (term.isEmpty) return;
    await _db.insertHistory(term);
    await loadHistory();
  }

  Future<void> clearHistoryList() async {
    await _db.clearHistory();
    await loadHistory();
  }

  Future<void> clearSearch() async {
    _lastSearchedBarcode = null;
    await loadAllProducts();
  }

  Future<void> seedDatabase() async {
    final seeds = [
      Product(barcodeNo: "111", productName: "Apple", category: "Food", unitPrice: 10.0, taxRate: 8, price: 10.8, stockInfo: 100),
      Product(barcodeNo: "222", productName: "Banana", category: "Food", unitPrice: 15.0, taxRate: 8, price: 16.2, stockInfo: 50),
      Product(barcodeNo: "333", productName: "Cherry", category: "Food", unitPrice: 20.0, taxRate: 8, price: 21.6, stockInfo: 0),
      Product(barcodeNo: "444", productName: "Laptop", category: "Electronics", unitPrice: 15000.0, taxRate: 18, price: 17700.0, stockInfo: 5),
      Product(barcodeNo: "555", productName: "Mouse", category: "Electronics", unitPrice: 250.0, taxRate: 18, price: 295.0, stockInfo: 20),
      Product(barcodeNo: "666", productName: "T-Shirt", category: "Clothes", unitPrice: 100.0, taxRate: 10, price: 110.0, stockInfo: 200),
      Product(barcodeNo: "777", productName: "Jeans", category: "Clothes", unitPrice: 300.0, taxRate: 10, price: 330.0, stockInfo: 15),
      Product(barcodeNo: "888", productName: "Book", category: "Other", unitPrice: 50.0, taxRate: 1, price: 50.5, stockInfo: 10),
      Product(barcodeNo: "999", productName: "Pen", category: "Other", unitPrice: 5.0, taxRate: 18, price: 5.9, stockInfo: 500),
      Product(barcodeNo: "123", productName: "Headphones", category: "Electronics", unitPrice: 1000.0, taxRate: 18, price: 1180.0, stockInfo: null),
    ];
    
    for (var p in seeds) {
      // Check directly against DB to avoid recursion loop via addProduct
      final exists = await _db.getProductByBarcode(p.barcodeNo);
      if (exists == null) {
        await _db.insertProduct(p);
      }
    }
  }
}