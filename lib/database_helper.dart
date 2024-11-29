import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static final String _databaseName = "app_database.db";
  static final int _databaseVersion = 1;

  // Table Names
  static final String tableUsers = 'users';
  static final String tableEvents = 'events';
  static final String tableGifts = 'gifts';
  static final String tableFriends = 'friends';

  // Column Names
  static final String columnUserEmail = 'email';
  static final String columnUserName = 'username';
  static final String columnUserPassword = 'password';

  // Currently Logged-In User (Mock)
  int currentUserId = 1; // Update this dynamically with actual user login

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        preferences TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableEvents (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT,
        description TEXT,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableGifts (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        price REAL,
        status TEXT NOT NULL,
        event_id INTEGER,
        pledged INTEGER DEFAULT 0,
        FOREIGN KEY (event_id) REFERENCES $tableEvents (_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFriends (
        user_id INTEGER,
        friend_id INTEGER,
        PRIMARY KEY (user_id, friend_id),
        FOREIGN KEY (user_id) REFERENCES $tableUsers (_id),
        FOREIGN KEY (friend_id) REFERENCES $tableUsers (_id)
      )
    ''');
  }

  Future<void> resetDatabase() async {
    // Temporary method to delete and recreate the database during development
    String path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path); // Deletes the existing database
  }

  // ========================= User Methods =========================
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query(tableUsers);
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(tableUsers, user);
  }

  Future<bool> checkUserExists(String email) async {
    final db = await database;
    var result = await db.query(
      tableUsers,
      where: '$columnUserEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<bool> authenticateUser(String username, String password) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM $tableUsers WHERE username = ? AND password = ?',
      [username, password],
    );
    return result.isNotEmpty;
  }

  // ========================= Event Methods =========================
  Future<List<Map<String, dynamic>>> getUserEvents() async {
    final db = await database;
    return await db.query(tableEvents, where: 'user_id = ?', whereArgs: [currentUserId]);
  }

  Future<List<Map<String, dynamic>>> getFriendsEvents() async {
    final db = await database;
    return await db.query(tableEvents, where: 'user_id != ?', whereArgs: [currentUserId]);
  }

  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert(tableEvents, event);
  }

  Future<int> updateEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.update(tableEvents, event, where: '_id = ?', whereArgs: [event['_id']]);
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete(tableEvents, where: '_id = ?', whereArgs: [id]);
  }

  // ========================= Gift Methods =========================
  Future<List<Map<String, dynamic>>> getGiftsForEvent(int eventId) async {
    final db = await database;
    return await db.query(tableGifts, where: 'event_id = ?', whereArgs: [eventId]);
  }

  Future<int> insertGift(Map<String, dynamic> gift) async {
    final db = await database;
    return await db.insert(tableGifts, gift);
  }

  Future<int> updateGift(Map<String, dynamic> gift) async {
    final db = await database;
    return await db.update(tableGifts, gift, where: '_id = ?', whereArgs: [gift['_id']]);
  }

  Future<int> pledgeGift(int giftId) async {
    final db = await database;
    return await db.update(
      tableGifts,
      {'pledged': 1},
      where: '_id = ?',
      whereArgs: [giftId],
    );
  }

  // ========================= Friends Methods =========================
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final db = await database;
    return await db.query(tableFriends, where: 'user_id = ?', whereArgs: [currentUserId]);
  }

  Future<int> insertFriend(Map<String, dynamic> friend) async {
    if (friend == null || friend['user_id'] == null || friend['friend_id'] == null) {
      throw Exception('Invalid friend data');
    }

    final db = await database;
    return await db.insert(tableFriends, friend);
  }

  Future<int> _getUserIdByName(String username) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      columns: ['_id'],
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first['_id'] as int : -1;
  }

  Future<int> removeFriend(int friendId) async {
    final db = await database;
    return await db.delete(tableFriends, where: 'friend_id = ?', whereArgs: [friendId]);
  }

  Future<int> addFriend(String friendEmail) async {
    if (friendEmail == null || friendEmail.isEmpty) {
      throw Exception('Friend email cannot be null or empty');
    }

    final db = await database;

    // Fetch the friend's user ID using their email
    final result = await db.query(
      tableUsers,
      columns: ['_id'],
      where: 'email = ?',
      whereArgs: [friendEmail],
    );

    if (result.isNotEmpty) {
      int friendId = (result.first['_id'] ?? 0) as int;

      // Create a map with the necessary details
      Map<String, dynamic> friend = {
        'user_id': currentUserId,
        'friend_id': friendId,
      };

      return await insertFriend(friend);
    } else {
      throw Exception('Friend with email $friendEmail not found');
    }
  }
  Future<void> debugDatabase() async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';"
    );
    print('Tables in database: $tables');

    for (var table in tables) {
      final tableName = table['name'];
      final columns = await db.rawQuery('PRAGMA table_info($tableName);');
      print('Columns in $tableName: $columns');
    }
  }
}