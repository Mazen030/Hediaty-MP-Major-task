import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern to ensure only one instance of DatabaseHelper exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database settings
  static final String _databaseName = "app_database.db";
  static final int _databaseVersion = 1;

  // Table and column names
  static final String tableUsers = 'users';
  static final String columnId = '_id';
  static final String columnUsername = 'username';
  static final String columnEmail = 'email';
  static final String columnPassword = 'password';

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create the users table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT NOT NULL,
        $columnEmail TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

  // Insert a new user into the database
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert(tableUsers, user);
  }

  // Check if a user exists by email
  Future<bool> checkUserExists(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableUsers,
      where: '$columnEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Retrieve all users (for debugging purposes)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    Database db = await database;
    return await db.query(tableUsers);
  }

  // Delete all users (for testing purposes)
  Future<void> deleteAllUsers() async {
    Database db = await database;
    await db.delete(tableUsers);
  }

  Future<bool> authenticateUser(String username, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableUsers,
      where: '$columnUsername = ? AND $columnPassword = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }
}
