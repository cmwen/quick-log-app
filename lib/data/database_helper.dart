import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _dbVersion = 2;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quicklog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        category TEXT NOT NULL,
        usageCount INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        createdAt INTEGER NOT NULL,
        note TEXT,
        tags TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        locationLabel TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        reviewStatus TEXT NOT NULL DEFAULT 'none',
        visitStartedAt INTEGER,
        visitEndedAt INTEGER,
        visitDurationMinutes INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_entries_createdAt ON entries(createdAt DESC)
    ''');

    // Seed default tags
    await _seedDefaultTags(db);
  }

  Future<void> _seedDefaultTags(Database db) async {
    final defaultTags = [
      // Activities
      LogTag(id: 'work', label: 'Work', category: TagCategory.activity),
      LogTag(id: 'exercise', label: 'Exercise', category: TagCategory.activity),
      LogTag(id: 'reading', label: 'Reading', category: TagCategory.activity),
      LogTag(id: 'coding', label: 'Coding', category: TagCategory.activity),
      LogTag(id: 'meeting', label: 'Meeting', category: TagCategory.activity),
      LogTag(id: 'shopping', label: 'Shopping', category: TagCategory.activity),

      // Moods
      LogTag(id: 'happy', label: 'Happy', category: TagCategory.mood),
      LogTag(id: 'focused', label: 'Focused', category: TagCategory.mood),
      LogTag(id: 'tired', label: 'Tired', category: TagCategory.mood),
      LogTag(id: 'stressed', label: 'Stressed', category: TagCategory.mood),

      // Locations
      LogTag(id: 'home', label: 'Home', category: TagCategory.location),
      LogTag(id: 'office', label: 'Office', category: TagCategory.location),
      LogTag(id: 'cafe', label: 'Café', category: TagCategory.location),
      LogTag(id: 'gym', label: 'Gym', category: TagCategory.location),

      // People
      LogTag(id: 'solo', label: 'Solo', category: TagCategory.people),
      LogTag(id: 'family', label: 'Family', category: TagCategory.people),
      LogTag(id: 'friends', label: 'Friends', category: TagCategory.people),
      LogTag(id: 'coworkers', label: 'Coworkers', category: TagCategory.people),
    ];

    for (var tag in defaultTags) {
      await db.insert('tags', tag.toMap());
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE entries ADD COLUMN source TEXT NOT NULL DEFAULT 'manual'",
      );
      await db.execute(
        "ALTER TABLE entries ADD COLUMN reviewStatus TEXT NOT NULL DEFAULT 'none'",
      );
      await db.execute('ALTER TABLE entries ADD COLUMN visitStartedAt INTEGER');
      await db.execute('ALTER TABLE entries ADD COLUMN visitEndedAt INTEGER');
      await db.execute(
        'ALTER TABLE entries ADD COLUMN visitDurationMinutes INTEGER',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_createdAt ON entries(createdAt DESC)',
      );
    }
  }

  // Tag Operations
  Future<List<LogTag>> getAllTags() async {
    final db = await database;
    final result = await db.query(
      'tags',
      orderBy: 'usageCount DESC, label ASC',
    );
    return result.map((map) => LogTag.fromMap(map)).toList();
  }

  Future<List<LogTag>> getRecentTags({int limit = 8}) async {
    final db = await database;
    final result = await db.query(
      'tags',
      orderBy: 'usageCount DESC',
      limit: limit,
    );
    return result.map((map) => LogTag.fromMap(map)).toList();
  }

  Future<void> insertTag(LogTag tag) async {
    final db = await database;
    await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTagUsage(String tagId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE tags SET usageCount = usageCount + 1 WHERE id = ?',
      [tagId],
    );
  }

  Future<void> deleteTag(String tagId) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
  }

  // Entry Operations
  Future<int> insertEntry(LogEntry entry) async {
    final db = await database;
    final id = await db.insert('entries', entry.toMap());

    // Update usage count for tags
    for (var tagId in entry.tags) {
      await updateTagUsage(tagId);
    }

    return id;
  }

  Future<List<LogEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query('entries', orderBy: 'createdAt DESC');
    return result.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<LogEntry?> getLatestAutoVisitEntry() async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'source = ?',
      whereArgs: [EntrySource.autoVisit.name],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return LogEntry.fromMap(result.first);
  }

  Future<List<LogEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'createdAt >= ? AND createdAt <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getEntriesByTag(String tagId) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'tags LIKE ?',
      whereArgs: ['%$tagId%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<void> updateEntry(LogEntry entry) async {
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
