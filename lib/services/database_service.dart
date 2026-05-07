import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('subs_track.db');
    } catch (_) {
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'subs_track.db');
        await deleteDatabase(path);
        _database = await _initDB('subs_track.db');
      } catch (_) {}
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        category TEXT NOT NULL,
        priceInTL REAL NOT NULL,
        isUsdBased INTEGER NOT NULL DEFAULT 0,
        usdAmount REAL NOT NULL DEFAULT 0.0,
        renewalDay INTEGER NOT NULL,
        notifyDaysBefore INTEGER NOT NULL DEFAULT 2,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE rates (
        code TEXT PRIMARY KEY,
        rate REAL NOT NULL
      )
    ''');

    await db.insert('rates', {'code': 'TRY', 'rate': 1.0});
    await db.insert('rates', {'code': 'USD', 'rate': 32.5});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS subscriptions');
      await db.execute('DROP TABLE IF EXISTS rates');
      await _createDB(db, newVersion);
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

  // --- Extra Requested Analytics Methods ---
  Future<double> getTotalMonthly() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(priceInTL) as total FROM subscriptions WHERE isActive = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalYearly() async {
    final monthly = await getTotalMonthly();
    return monthly * 12.0;
  }

  Future<List<Subscription>> getSubscriptionsByDay(int day) async {
    final db = await instance.database;
    final result = await db.query('subscriptions', where: 'renewalDay = ?', whereArgs: [day]);
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<List<Subscription>> getUpcomingRenewals(int days) async {
    final all = await getAllSubscriptions();
    final now = DateTime.now();
    return all.where((sub) {
      final renewal = sub.nextRenewalDate;
      final diff = renewal.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff >= 0 && diff <= days;
    }).toList();
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
