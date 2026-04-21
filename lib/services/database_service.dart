import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../screens/reports_screen.dart';
import 'shop_service.dart';

class DatabaseService implements ShopService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static const _databaseName = 'shop_manager.db';
  static const _databaseVersion = 1;
  static const productTable = 'products';
  static const saleTable = 'sales';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> get databasePath async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _databaseName);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> initialize() async {
    _database = await _initDatabase();
  }

  @override
  Future<void> initDB() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $productTable(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        buyingPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        lowStockThreshold INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $saleTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT NOT NULL,
        date INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(productId) REFERENCES $productTable(id)
      )
    ''');
  }

  @override
  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query(productTable,
        where: 'isDeleted = 0', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<List<Sale>> getSales() async {
    final db = await database;
    final rows = await db.query(saleTable, orderBy: 'date ASC');
    return rows.map(Sale.fromMap).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    final db = await database;
    await db.insert(productTable, product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(productTable, product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  @override
  Future<void> recordSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      final productRows = await txn
          .query(productTable, where: 'id = ?', whereArgs: [sale.productId]);
      if (productRows.isEmpty) {
        throw Exception('Product not found');
      }

      final product = Product.fromMap(productRows.first);
      if (sale.quantity > product.quantity) {
        throw Exception('Not enough stock');
      }

      await txn.insert(saleTable, sale.toMap());
      await txn.update(
        productTable,
        {'quantity': product.quantity - sale.quantity},
        where: 'id = ?',
        whereArgs: [product.id],
      );
    });
  }

  @override
  Future<void> seedProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert(productTable, product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final db = await database;
    await db.update(productTable, {'isDeleted': 1},
        where: 'id = ?', whereArgs: [productId]);
  }

  @override
  Future<List<ReportItem>> getReports(int days) async {
    final db = await database;
    final sales = await db.query(saleTable, orderBy: 'date ASC');
    final products = await db.query(productTable);

    final productMap = <String, Map<String, dynamic>>{};
    for (final p in products) {
      productMap[p['id'] as String] = p;
    }

    final now = DateTime.now();
    return List.generate(days, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - index));
      final daySales = sales.where((sale) {
        final saleDate =
            DateTime.fromMillisecondsSinceEpoch(sale['date'] as int);
        return saleDate.year == day.year &&
            saleDate.month == day.month &&
            saleDate.day == day.day;
      });

      double totalSales = 0;
      double totalProfit = 0;
      for (final sale in daySales) {
        final productData = productMap[sale['productId'] as String];
        if (productData != null) {
          final quantity = sale['quantity'] as int;
          final sellingPrice = productData['sellingPrice'] as double;
          final buyingPrice = productData['buyingPrice'] as double;
          totalSales += quantity * sellingPrice;
          totalProfit += quantity * (sellingPrice - buyingPrice);
        }
      }

      return ReportItem(date: day, sales: totalSales, profit: totalProfit);
    });
  }
}
