import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        location TEXT,
        description TEXT
      )
    ''');
    }
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      print('Database path: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
        onOpen: (db) {
          print('Database opened successfully');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    print('Configuring database');
    await db.execute('PRAGMA foreign_keys = ON');
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
    category TEXT,
    date TEXT NOT NULL,
    location TEXT,
    description TEXT,
    status TEXT,
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

  // Future<int?> getCurrentUserId() async {
  //   return await SessionManager().getCurrentUserId();
  // }

  Future<int?> getCurrentUserId() async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // First, try to find the local user ID based on Firebase UID
        final db = await database;
        final result = await db.query(
          tableUsers,
          columns: ['_id'],
          where: 'email = ?',
          whereArgs: [firebaseUser.email],
        );

        if (result.isNotEmpty) {
          // Return the local database user ID
          return result.first['_id'] as int?;
        }

        // If no local user found, you might want to handle this case
        print('No local user found for Firebase user: ${firebaseUser.email}');
        return null;
      }

      // No authenticated user found
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query(tableUsers);
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;

    // Check if user already exists by email
    final existingUser = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [user['email']],
    );

    if (existingUser.isNotEmpty) {
      // User already exists, update if needed
      return await db.update(
          tableUsers,
          user,
          where: 'email = ?',
          whereArgs: [user['email']]
      );
    }

    // Insert new user
    return await db.insert(tableUsers, user);
  }

  Future<bool> checkUserExists(String email) async {
    final db = await database;
    var result = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    //Add a method to get user details by email (useful for Firebase integration)
    final db = await database;
    var result = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // Future<bool> authenticateUser(String username, String password) async {
  //   final db = await database;
  //   final result = await db.rawQuery(
  //     'SELECT * FROM $tableUsers WHERE username = ? AND password = ?',
  //     [username, password],
  //   );
  //
  //   if (result.isNotEmpty) {
  //     int userId = result.first['_id'] as int;
  //     await SessionManager().setCurrentUserId(userId);
  //     return true;
  //   }
  //   return false;
  // }




  // ========================= Event Methods =========================
  // Future<List<Map<String, dynamic>>> getUserEvents() async {
  //   final db = await database;
  //   final currentUserId = await getCurrentUserId();
  //   if (currentUserId == null) {
  //     throw Exception('No user is currently logged in.');
  //   }
  //
  //   final events = await db.query(
  //     tableEvents,
  //     where: 'user_id = ?',
  //     whereArgs: [currentUserId],
  //   );
  //
  //   return events.map((event) {
  //     return {
  //       ...event,
  //       'date': DateTime.tryParse(event['date'] as String) ?? event['date'], // Parse string back to DateTime
  //     };
  //   }).toList();
  // }
  Future<List<Map<String, dynamic>>> getUserEvents() async {
    final db = await database;
    final currentUserId = await getCurrentUserId();

    if (currentUserId == null) {
      print('No user logged in. Cannot retrieve events.');
      return []; // Return empty list if no user is logged in
    }

    final events = await db.query(
      tableEvents,
      where: 'user_id = ?',
      whereArgs: [currentUserId],
    );

    return events.map((event) {
      return {
        ...event,
        'date': DateTime.tryParse(event['date'] as String) ?? event['date'],
      };
    }).toList();
  }


  Future<List<Map<String, dynamic>>> getFriendsEvents() async {
    final db = await database;
    return await db.query(tableEvents, where: 'user_id != ?', whereArgs: [currentUserId]);
  }


  // Future<int> insertEvent(Map<String, dynamic> event) async {
  //   event['user_id'] = currentUserId;
  //
  //   final db = await database;
  //   int id = await db.insert(tableEvents, event);
  //   print('Inserted event with ID: $id'); // Add logging
  //   return id;
  // }
  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('No user is currently logged in.');
    }
    event['user_id'] = currentUserId;
    return await db.insert(tableEvents, event);
  }


  Future<int> updateEvent(Map<String, dynamic> event) async {
    print("Updating event: $event");

    if (event['_id'] == null) {
      throw ArgumentError("Event must have a valid '_id'. Received: ${event['_id']}");
    }

    final db = await database;
    //final currentUserId = await SessionManager().getCurrentUserId();
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    // Ensure the event belongs to the logged-in user
    final result = await db.query(
      tableEvents,
      where: '_id = ? AND user_id = ?',
      whereArgs: [event['_id'], currentUserId],
    );

    if (result.isEmpty) {
      throw Exception("Event does not belong to the current user.");
    }

    return await db.update(
      tableEvents,
      event,
      where: '_id = ?',
      whereArgs: [event['_id']],
    );
  }
  Future<int> deleteEvent(int id) async {
    final db = await database;
    //final currentUserId = await SessionManager().getCurrentUserId();
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    // Ensure the event belongs to the logged-in user
    final result = await db.query(
      tableEvents,
      where: '_id = ? AND user_id = ?',
      whereArgs: [id, currentUserId],
    );

    if (result.isEmpty) {
      throw Exception("Event does not belong to the current user.");
    }

    return await db.delete(
      tableEvents,
      where: '_id = ?',
      whereArgs: [id],
    );
  }



  // ========================= Gift Methods =========================
  Future<List<Map<String, dynamic>>> getGiftsForEvent(int eventId) async {
    final db = await database;
    print('Querying gifts for event ID: $eventId');

    final gifts = await db.query(
        tableGifts,
        where: 'event_id = ?',
        whereArgs: [eventId]
    );

    print('Gifts found: ${gifts.length}');
    print('Gifts details: $gifts');

    return gifts;
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
  // Add this method to the existing DatabaseHelper class
  Future<int> deleteGift(int giftId) async {
    final db = await database;
    return await db.delete(
        tableGifts,
        where: '_id = ?',
        whereArgs: [giftId]
    );
  }

  // ========================= Friends Methods =========================

  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final db = await database;
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    return await db.rawQuery('''
    SELECT f.friend_id, 
           u.username AS name, 
           u.email, 
           COUNT(e._id) AS upcomingEvents
    FROM friends f
    LEFT JOIN users u ON f.friend_id = u._id
    LEFT JOIN events e ON e.user_id = f.friend_id AND e.date > ?
    WHERE f.user_id = ?
    GROUP BY f.friend_id, u.username, u.email
    ''', [DateTime.now().toIso8601String(), currentUserId]);
  }

  // Future<List<Map<String, dynamic>>> getFriendsList() async {
  //   final db = await database;
  //   return await db.rawQuery('''
  //   SELECT f.friend_id, u.username AS name, u.email,
  //          COUNT(e._id) as upcomingEvents
  //   FROM friends f
  //   LEFT JOIN users u ON f.friend_id = u._id
  //   LEFT JOIN events e ON e.user_id = f.friend_id AND e.date > ?
  //   WHERE f.user_id = ?
  //   GROUP BY f.friend_id
  // ''', [DateTime.now().toIso8601String(), currentUserId]);
  // }



  Future<int> insertFriend(Map<String, dynamic> friend) async {
    if (friend == null || friend['friend_id'] == null) {
      throw Exception('Invalid friend data');
    }

    //final currentUserId = await SessionManager().getCurrentUserId();
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    friend['user_id'] = currentUserId;

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
    //final currentUserId = await SessionManager().getCurrentUserId();
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    return await db.delete(
      tableFriends,
      where: 'friend_id = ? AND user_id = ?',
      whereArgs: [friendId, currentUserId],
    );
  }

  Future<int> addFriend(String friendEmail) async {
    if (friendEmail == null || friendEmail.isEmpty) {
      throw Exception('Friend email cannot be null or empty');
    }

    final db = await database;
    //final currentUserId = await SessionManager().getCurrentUserId();
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

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

    try {
      final db = await database; // This ensures database is initialized

      print('Database Path: ${await getDatabasesPath()}');

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table';"
      );
      print('Tables in database: $tables');

      if (tables.isEmpty) {
        print('NO TABLES FOUND IN DATABASE');
        return;
      }

      for (var table in tables) {
        final tableName = table['name'];
        print('Examining table: $tableName');

        final columns = await db.rawQuery('PRAGMA table_info($tableName);');
        print('Columns in $tableName: $columns');
      }
    } catch (e) {
      print('Error in debugDatabase: $e');
    }
  }

  Future<bool> doesTableExist(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> syncFirebaseUserToLocalDatabase(User firebaseUser) async {
    final db = await database;

    // Check if user already exists
    final existingUser = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [firebaseUser.email],
    );

    if (existingUser.isEmpty) {
      // Insert new user
      await db.insert(tableUsers, {
        'username': firebaseUser.displayName ?? firebaseUser.email?.split('@').first,
        'email': firebaseUser.email,
        'password': '', // Firebase handles authentication, so no local password
      });
    }
  }

}


