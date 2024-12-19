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
  static final int _databaseVersion = 4; // Increment version

  // Table Names
  static final String tableUsers = 'users';
  static final String tableEvents = 'events';
  static final String tableGifts = 'gifts';
  static final String tableFriends = 'friends';
  static final String tablePledgedGifts = 'pledged_gifts'; // Added pledged_gifts table

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


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // If upgrading to version 4, add the new user_email column and modify due_date column
      await db.execute('''
      ALTER TABLE $tablePledgedGifts ADD COLUMN user_email TEXT;
    ''');
      await db.execute('''
      ALTER TABLE $tablePledgedGifts ALTER COLUMN due_date TEXT;
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
        onUpgrade: _onUpgrade, //added onUpgrade
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
    await db.execute('CREATE TABLE $tableUsers (_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, preferences TEXT)');

    await db.execute('CREATE TABLE $tableEvents (_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT, date TEXT NOT NULL, location TEXT, description TEXT, status TEXT, user_id INTEGER, firestoreId TEXT, FOREIGN KEY (user_id) REFERENCES $tableUsers (_id))');

    await db.execute('CREATE TABLE $tableGifts (_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, category TEXT, price REAL, status TEXT NOT NULL, event_id INTEGER, pledged INTEGER DEFAULT 0, firestoreId TEXT, FOREIGN KEY (event_id) REFERENCES $tableEvents (_id))'); // Added firestoreId here

    await db.execute('CREATE TABLE $tableFriends (user_id INTEGER, friend_id INTEGER, PRIMARY KEY (user_id, friend_id), FOREIGN KEY (user_id) REFERENCES $tableUsers (_id), FOREIGN KEY (friend_id) REFERENCES $tableUsers (_id))');


    await db.execute('''
    CREATE TABLE $tablePledgedGifts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gift_id TEXT,
      gift_name TEXT,
      friend_name TEXT,
      due_date TEXT,
      gift_status TEXT,
      user_email TEXT
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




  // ========================= Event Methods =========================

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


  Future<int> insertEvent(Map<String, dynamic> event, String firestoreId) async {
    final db = await database;
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('No user is currently logged in.');
    }
    event['user_id'] = currentUserId;
    event['firestoreId'] = firestoreId; // Store the Firestore ID

    final id = await db.insert(tableEvents, event);

    return id;
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
  //modified method to get the firestore id and use it for deletion
  Future<String?> deleteEvent(int id) async { // Return the firestoreId
    final db = await database;
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
    // Get the firestore id of the event
    final eventToDelete = await db.query(
      tableEvents,
      columns: ['firestoreId'],
      where: '_id = ?',
      whereArgs: [id],
    );
    // Extract the firestoreId from the query
    final firestoreId = eventToDelete.isNotEmpty ? eventToDelete.first['firestoreId'] as String? : null;

    if (firestoreId == null){
      throw Exception ("Firestore ID not found for the event.");
    }

    //Delete the event
    await db.delete(
      tableEvents,
      where: '_id = ?',
      whereArgs: [id],
    );
    return firestoreId; // Return the firestoreId
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

    // Check if the gift exists before updating
    final gift = await db.query(
      tableGifts,
      where: '_id = ?',
      whereArgs: [giftId],
    );

    if (gift.isEmpty) {
      print('Gift with ID $giftId not found in database');
      throw Exception('Gift not found');
    }

    return await db.update(
      tableGifts,
      {'pledged': 1}, // Mark gift as pledged
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
  // Inside DatabaseHelper class

  Future<List<Map<String, dynamic>>> getPledgedGifts() async {
    final db = await database;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (currentUserEmail == null) {
      throw Exception("No user is currently logged in.");
    }

    return await db.query(
        tablePledgedGifts,
        where: 'user_email = ? AND gift_status = ?',
        whereArgs: [currentUserEmail, 'pending'],
        orderBy: 'due_date ASC'
    );
  }



// Update gift status to fulfilled
  Future<void> updatePledgedGiftStatus(String giftId, String newStatus) async {  // Changed parameter type to String
    final db = await database;
    await db.update(
        tablePledgedGifts,
        {'gift_status': newStatus},
        where: 'gift_id = ?',
        whereArgs: [giftId]
    );
  }


  Future<void> removePledgedGift(String giftId) async {  // Changed parameter type to String
    final db = await database;
    await db.delete(
        tablePledgedGifts,
        where: 'gift_id = ?',
        whereArgs: [giftId]
    );
  }
  Future<void> createPledgedGift({
    required String giftId,
    required String giftName,
    required String friendName,
    required DateTime dueDate,
    required String giftStatus,
  }) async {
    final db = await database;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (currentUserEmail == null) {
      throw Exception("No user is currently logged in.");
    }

    await db.insert(tablePledgedGifts, {
      'gift_id': giftId,
      'gift_name': giftName,
      'friend_name': friendName,
      'due_date': dueDate.toIso8601String(),
      'gift_status': giftStatus,
      'user_email': currentUserEmail,
    },
        conflictAlgorithm: ConflictAlgorithm.replace
    );
  }


  // ========================= Friends Methods =========================



  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final db = await database;
    final currentUserId = await getCurrentUserId();
    print('📋 Retrieving friends for User ID: $currentUserId');

    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    final friends = await db.rawQuery('''
    SELECT f.friend_id,
           u.username AS name,
           u.email,
           COUNT(e._id) AS upcomingEvents
    FROM friends f
    LEFT JOIN users u ON f.friend_id = u._id
    LEFT JOIN events e ON e.user_id = f.friend_id AND e.date >= ?
    WHERE f.user_id = ?
    GROUP BY f.friend_id, u.username, u.email
    ''', [DateTime.now().toIso8601String(), currentUserId]);

    print('👥 Friends found: $friends');
    return friends;
  }


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
    print('🔍 Attempting to add friend with email: $friendEmail');

    final db = await database;
    final currentUserId = await getCurrentUserId();
    print('🔑 Current User ID: $currentUserId');

    if(currentUserId == null){
      throw Exception("No user is logged in.");
    }

    // Fetch the friend's user ID using their email
    final result = await db.query(
      tableUsers,
      columns: ['_id'],
      where: 'email = ?',
      whereArgs: [friendEmail],
    );

    print('👥 Friend query result: $result');

    if (result.isNotEmpty) {
      int friendId = (result.first['_id'] ?? 0) as int;
      print('🆔 Friend ID found: $friendId');

      if(currentUserId == friendId){
        throw Exception("You can not add yourself as a friend!");
      }

      // Check existing friendship
      final existingFriendship = await db.query(
        tableFriends,
        where: '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
        whereArgs: [currentUserId, friendId, friendId, currentUserId],
      );

      print('🤝 Existing friendship check: $existingFriendship');

      if (existingFriendship.isNotEmpty) {
        throw Exception("Friendship already exists.");
      }

      Map<String, dynamic> friend1 = {
        'user_id': currentUserId,
        'friend_id': friendId,
      };
      print('Friend 1 data to insert: $friend1'); //Debug

      Map<String, dynamic> friend2 = {
        'user_id': friendId,
        'friend_id': currentUserId,
      };
      print('Friend 2 data to insert: $friend2'); //Debug

      print('📝 Friendship details to insert:');
      print('Friend 1: $friend1');
      print('Friend 2: $friend2');

      await insertFriend(friend1);
      await insertFriend(friend2);

      return 1;
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