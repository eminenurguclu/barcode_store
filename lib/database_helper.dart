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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Creating table based on Database Model
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
  }

  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert(
      'ProductTable',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'ProductTable',
      columns: null,
      where: 'BarcodeNo = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('ProductTable');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'ProductTable',
      product.toMap(),
      where: 'BarcodeNo = ?',
      whereArgs: [product.barcodeNo],
    );
  }

  Future<int> deleteProduct(String barcode) async {
    final db = await instance.database;
    return await db.delete(
      'ProductTable',
      where: 'BarcodeNo = ?',
      whereArgs: [barcode],
    );
  }
}