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
  String get sortMode => _sortMode;

  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    _allProducts = await _db.getAllProducts();
    _lastSearchedBarcode = null;
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    Iterable<Product> list = _allProducts;

    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory);
    }

    final temp = list.toList();
    _applySortOnList(temp);
    _products = temp;
  }

  void _applySortOnList(List<Product> list) {
    switch (_sortMode) {
      case 'name_asc':
        list.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'name_desc':
        list.sort((a, b) => b.productName.compareTo(a.productName));
        break;
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'none':
      default:
        break;
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _lastSearchedBarcode = null;
    _applyFilters();
    notifyListeners();
  }

  Future<void> searchByBarcode(String barcode) async {
    _isLoading = true;
    notifyListeners();

    final product = await _db.getProductByBarcode(barcode);
    _lastSearchedBarcode = barcode;

    if (product == null) {
      _products = [];
    } else {
      _products = [product];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearSearch() async {
    _lastSearchedBarcode = null;
    await loadAllProducts();
  }

  Future<bool> addProduct(Product product) async {
    final existing = await _db.getProductByBarcode(product.barcodeNo);
    if (existing != null) return false;

    await _db.insertProduct(product);
    _allProducts = await _db.getAllProducts();
    _lastSearchedBarcode = null;
    _applyFilters();
    notifyListeners();
    return true;
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    _allProducts = await _db.getAllProducts();
    _lastSearchedBarcode = null;
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteProduct(String barcode) async {
    await _db.deleteProduct(barcode);
    _allProducts = await _db.getAllProducts();
    _lastSearchedBarcode = null;
    _applyFilters();
    notifyListeners();
  }

  void sortBy(String mode) {
    _sortMode = mode;

    if (_lastSearchedBarcode != null) {
      _applySortOnList(_products);
    } else {
      _applyFilters();
    }
    notifyListeners();
  }
}
