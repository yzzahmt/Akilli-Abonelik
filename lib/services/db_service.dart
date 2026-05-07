import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('subs_track.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        currency TEXT NOT NULL,
        billingCycle TEXT NOT NULL,
        firstRenewalDate TEXT NOT NULL,
        category TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        reminderDaysBefore INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rates (
        code TEXT PRIMARY KEY,
        rate REAL NOT NULL
      )
    ''');

    // Add default conversion rates
    await db.insert('rates', {'code': 'TRY', 'rate': 1.0});
    await db.insert('rates', {'code': 'USD', 'rate': 32.5});
    await db.insert('rates', {'code': 'EUR', 'rate': 35.2});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Basic upgrade handling if table doesn't exist
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rates (
          code TEXT PRIMARY KEY,
          rate REAL NOT NULL
        )
      ''');
    }
  }

  // --- Subscriptions CRUD ---
  Future<int> insertSubscription(Subscription sub) async {
    final db = await instance.database;
    return await db.insert('subscriptions', sub.toMap());
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await instance.database;
    final result = await db.query('subscriptions');
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<int> updateSubscription(Subscription sub) async {
    final db = await instance.database;
    return await db.update(
      'subscriptions',
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final db = await instance.database;
    return await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Rates CRUD ---
  Future<void> updateRates(Map<String, double> newRates) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var entry in newRates.entries) {
      batch.insert(
        'rates',
        {'code': entry.key, 'rate': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, double>> getRates() async {
    final db = await instance.database;
    final result = await db.query('rates');
    final Map<String, double> rates = {};
    for (var row in result) {
      rates[row['code'] as String] = row['rate'] as double;
    }
    return rates;
  }
}
