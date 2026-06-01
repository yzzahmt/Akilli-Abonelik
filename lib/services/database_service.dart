import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';
import '../models/investment_model.dart';
import '../models/cash_account_model.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('subs_track.db');
    } catch (e) {
      // İlk açılış başarısız olduysa bozuk DB'yi sil ve tekrar dene
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'subs_track.db');
        await deleteDatabase(path);
        _database = await _initDB('subs_track.db');
      } catch (e2) {
        // Her ikisi de başarısız olduysa yeni bir DB oluştur
        try {
          _database = await openDatabase(
            ':memory:',
            version: 7,
            onCreate: _createDB,
          );
        } catch (_) {}
      }
    }
    if (_database == null) {
      throw Exception('Veritabanı açılamadı. Lütfen uygulamayı yeniden başlatın.');
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, 
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
        createdAt TEXT NOT NULL,
        billingCycle TEXT NOT NULL DEFAULT 'Aylık',
        cycleDays INTEGER NOT NULL DEFAULT 30,
        currency TEXT NOT NULL DEFAULT 'TRY',
        originalPrice REAL NOT NULL DEFAULT 0.0
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

    // SubsTrack yeni özellik — Yatırım tablosu (Bölüm 7)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        buy_price REAL NOT NULL,
        buy_date TEXT NOT NULL,
        currency TEXT DEFAULT 'TRY',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // SubsTrack yeni özellik — is_favorite kolonu (Bölüm 5)
    try {
      await db.execute('ALTER TABLE subscriptions ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    } catch (_) {} // Zaten varsa hata vermez

    // SubsTrack yeni özellik — Aktivite Logları (Bölüm 9)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'TRY'
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // v3'ten önceyse tüm şemayı baştan oluştur
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS subscriptions');
      await db.execute('DROP TABLE IF EXISTS rates');
      await db.execute('DROP TABLE IF EXISTS investments');
      await db.execute('DROP TABLE IF EXISTS activity_logs');
      await db.execute('DROP TABLE IF EXISTS cash_accounts');
      await _createDB(db, newVersion);
      return; // _createDB zaten her şeyi oluşturdu, aşağıdaki adımları atla
    }
    // v4 yükseltme — Yatırım tablosu
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity REAL NOT NULL,
          buy_price REAL NOT NULL,
          buy_date TEXT NOT NULL,
          currency TEXT DEFAULT 'TRY',
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute('ALTER TABLE subscriptions ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    // v5 yükseltme — Fatura döngüsü & çoklu para birimi
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE subscriptions ADD COLUMN billingCycle TEXT NOT NULL DEFAULT 'Aylık'");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE subscriptions ADD COLUMN cycleDays INTEGER NOT NULL DEFAULT 30');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE subscriptions ADD COLUMN currency TEXT NOT NULL DEFAULT 'TRY'");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE subscriptions ADD COLUMN originalPrice REAL NOT NULL DEFAULT 0.0');
      } catch (_) {}
    }
    // v6 yükseltme — Aktivite logları
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          description TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
    // v7 yükseltme — Nakit hesaplar
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cash_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT DEFAULT 'TRY'
        )
      ''');
    }
  }

  // --- Cash Account Methods ---

  Future<int> insertCashAccount(CashAccount account) async {
    final db = await instance.database;
    return await db.insert('cash_accounts', account.toMap());
  }

  Future<List<CashAccount>> getAllCashAccounts() async {
    final db = await instance.database;
    final result = await db.query('cash_accounts', orderBy: 'id DESC');
    return result.map((json) => CashAccount.fromMap(json)).toList();
  }

  Future<int> updateCashAccount(CashAccount account) async {
    final db = await instance.database;
    return await db.update(
      'cash_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteCashAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // SubsTrack yeni özellik — Yatırım CRUD (Bölüm 7)
  Future<int> insertInvestment(Investment inv) async {
    final db = await instance.database;
    return await db.insert('investments', inv.toMap());
  }

  Future<List<Investment>> getAllInvestments() async {
    final db = await instance.database;
    final result = await db.query('investments', orderBy: 'created_at DESC');
    return result.map((json) => Investment.fromMap(json)).toList();
  }

  Future<int> updateInvestment(Investment inv) async {
    final db = await instance.database;
    return await db.update(
      'investments',
      inv.toMap(),
      where: 'id = ?',
      whereArgs: [inv.id],
    );
  }

  Future<int> deleteInvestment(int id) async {
    final db = await instance.database;
    return await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  // SubsTrack yeni özellik — Favori toggle (Bölüm 5)
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    await db.update(
      'subscriptions',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Activity Logs CRUD (Bölüm 9) ---
  Future<void> insertActivityLog(String actionType, String description) async {
    final db = await instance.database;
    await db.insert('activity_logs', {
      'action_type': actionType,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentActivityLogs({int limit = 50}) async {
    final db = await instance.database;
    return await db.query(
      'activity_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // SubsTrack yeni özellik — Tüm verileri JSON'a çevir (Bölüm 11)
  Future<Map<String, dynamic>> exportAllData() async {
    final subs = await getAllSubscriptions();
    final invs = await getAllInvestments();
    return {
      'version': 4,
      'exportDate': DateTime.now().toIso8601String(),
      'subscriptions': subs.map((s) => s.toMap()).toList(),
      'investments': invs.map((i) => i.toMap()).toList(),
    };
  }

  // SubsTrack yeni özellik — JSON'dan veri yükle (Bölüm 11)
  Future<void> importData(Map<String, dynamic> data) async {
    final db = await instance.database;
    final batch = db.batch();

    // Subscriptions ekle (merge — mevcut verileri silme)
    final subsData = data['subscriptions'] as List<dynamic>? ?? [];
    for (var subMap in subsData) {
      final map = Map<String, dynamic>.from(subMap);
      map.remove('id'); // Otomatik ID al
      batch.insert('subscriptions', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Investments ekle
    final invData = data['investments'] as List<dynamic>? ?? [];
    for (var invMap in invData) {
      final map = Map<String, dynamic>.from(invMap);
      map.remove('id');
      batch.insert('investments', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }
}
