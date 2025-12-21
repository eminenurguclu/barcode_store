import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('store.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Versiyon 2 olarak kalsın, onUpgrade çalışması için
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS SearchHistory (Term TEXT PRIMARY KEY, Timestamp INTEGER)');
    }
  }

  Future _createDB(Database db, int version) async {
    // Sadece birer kez tablo oluştur
    await db.execute('''
    CREATE TABLE ProductTable (
      BarcodeNo TEXT PRIMARY KEY,
      ProductName TEXT NOT NULL,
      Category TEXT NOT NULL,
      UnitPrice REAL NOT NULL,
      TaxRate INTEGER NOT NULL,
      Price REAL NOT NULL,
      Stockinfo INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE SearchHistory (
      Term TEXT PRIMARY KEY,
      Timestamp INTEGER
    )
    ''');
  }

  // --- CRUD Metotları (Sınıfın İçinde Kalmalı) ---
  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert('ProductTable', product.toMap());
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query('ProductTable', where: 'BarcodeNo = ?', whereArgs: [barcode]);
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'ProductTable',
      where: 'ProductName LIKE ? OR BarcodeNo LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('ProductTable');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update('ProductTable', product.toMap(), where: 'BarcodeNo = ?', whereArgs: [product.barcodeNo]);
  }

  Future<int> deleteProduct(String barcode) async {
    final db = await instance.database;
    return await db.delete('ProductTable', where: 'BarcodeNo = ?', whereArgs: [barcode]);
  }

  Future<void> insertHistory(String term) async {
    final db = await instance.database;
    await db.insert('SearchHistory', {'Term': term, 'Timestamp': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getHistory() async {
    final db = await instance.database;
    final maps = await db.query('SearchHistory', orderBy: 'Timestamp DESC', limit: 10);
    return maps.map((e) => e['Term'] as String).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('SearchHistory');
  }
} // Sınıf burada bitiyor.