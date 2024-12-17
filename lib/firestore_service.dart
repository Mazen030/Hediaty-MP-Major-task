import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import with alias
import 'database_helper.dart'; // Import your local database helper
import 'package:uuid/uuid.dart';

// Classes used to store data locally
class LocalUser {
  int? id;
  String username;
  String email;
  String? password;
  String? preferences;

  LocalUser({this.id, required this.username, required this.email, this.password, this.preferences});

  //Convert from local map
  LocalUser.fromMap(Map<String, dynamic> map)
      : id = map['_id'],
        username = map['username'],
        email = map['email'],
        password = map['password'],
        preferences = map['preferences'];
}

class Event {
  int? id;
  String name;
  String? category;
  String date;
  String? location;
  String? description;
  String? status;
  int? user_id; // Keep as int for local and use as String when storing on Firebase
  String? firestoreId; // Adding firestore id for consistency

  Event(
      {this.id,
        required this.name,
        this.category,
        required this.date,
        this.location,
        this.description,
        this.status,
        this.user_id,
        this.firestoreId});
  //Convert from local map
  Event.fromMap(Map<String, dynamic> map)
      : id = map['_id'],
        name = map['name'],
        category = map['category'],
        date = map['date'],
        location = map['location'],
        description = map['description'],
        status = map['status'],
        user_id = map['user_id'],
        firestoreId = map['firestoreId'];
}
class Gift {
  int? id;
  String name;
  String? description;
  String? category;
  double? price;
  String status;
  int? event_id; // Keep as int for local and use as String when storing on Firebase
  int? pledged;

  Gift(
      {this.id,
        required this.name,
        this.description,
        this.category,
        this.price,
        required this.status,
        this.event_id,
        this.pledged});

  //Convert from local map
  Gift.fromMap(Map<String, dynamic> map)
      : id = map['_id'],
        name = map['name'],
        description = map['description'],
        category = map['category'],
        price = map['price'],
        status = map['status'],
        event_id = map['event_id'],
        pledged = map['pledged'] is String ? int.tryParse(map['pledged']) : map['pledged'];

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'event_id': event_id,
      'pledged': pledged,
    };
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ------------------ Data Conversion Functions ------------------

  Map<String, dynamic> _userToFirestore(LocalUser localUser) {
    return {
      'username': localUser.username,
      'email': localUser.email,
      'preferences': localUser.preferences,
    };
  }

  Map<String, dynamic> _eventToFirestore(Event localEvent) {
    return {
      'name': localEvent.name,
      'category': localEvent.category,
      'date': localEvent.date,
      'location': localEvent.location,
      'description': localEvent.description,
      'status': localEvent.status,
      'user_id': localEvent.user_id?.toString(), // Convert int user_id to String
    };
  }

  Map<String, dynamic> _giftToFirestore(Gift localGift) {
    return {
      'name': localGift.name,
      'description': localGift.description,
      'category': localGift.category,
      'price': localGift.price,
      'status': localGift.status,
      'event_id': localGift.event_id?.toString(), // Convert int event_id to String
      'pledged': localGift.pledged,
    };
  }

  // ------------------ User Methods ------------------
  // Method to sync local data with Firebase when a user logs in
  Future<void> syncFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        await _dbHelper.syncFirebaseUserToLocalDatabase(firebaseUser);
        print("Synchronized user ${firebaseUser.email}");
      } catch (e) {
        print('Error syncing user: $e');
      }
    }
  }
  // Future<void> syncFirebaseUser(firebase_auth.User? firebaseUser) async {
  //   if (firebaseUser != null) {
  //     try {
  //       final userRef = _firestore.collection('users').doc(firebaseUser.email);
  //       final doc = await userRef.get();
  //       if(!doc.exists){
  //         await userRef.set({});
  //       }
  //       await _dbHelper.syncFirebaseUserToLocalDatabase(firebaseUser);
  //       print("Synchronized user ${firebaseUser.email}");
  //     } catch (e) {
  //       print('Error syncing user: $e');
  //     }
  //   }
  // }


  // ------------------ Initial Migration ------------------
//removed migration method for future implementation
  Future<void> migrateDataToFirestore() async {
    try {
      final db = await _dbHelper.database;

      // Migrate Users
      final localUsers = await _dbHelper.getUsers();
      for (var userMap in localUsers) {
        final localUser = LocalUser.fromMap(userMap);
        final firestoreData = _userToFirestore(localUser);
        await _firestore.collection('users').doc(localUser.email).set(
            firestoreData);
        print("Uploaded user ${localUser.email}");
      }
    }
    catch (e) {
      print('Error migrating data to Firestore: $e');
    }
  }
  // ------------------ Event Methods ------------------

  Future<void> insertEvent(Map<String, dynamic> event) async {
    try {
      // Firestore insert
      final firestoreDocRef = await _firestore.collection('events').add(_eventToFirestore(Event.fromMap(event)));
      final firestoreId = firestoreDocRef.id;

      // Local database insert (using the method that takes firestoreId)
      await _dbHelper.insertEvent(event, firestoreId);

      print('Inserted event with Firestore ID: $firestoreId');

    } catch (e) {
      print('Error inserting event to Firestore: $e');
    }
  }
// Update the deleteEvent method
  Future<void> deleteEvent(int localId) async {
    try {
      final db = await _dbHelper.database;

      // First, fetch the Firestore document ID for this local event
      final eventResult = await db.query(
          DatabaseHelper.tableEvents,
          columns: ['firestoreId'],
          where: '_id = ?',
          whereArgs: [localId]
      );

      if (eventResult.isEmpty) {
        print('No event found with local ID: $localId');
        return;
      }

      final firestoreDocId = eventResult.first['firestoreId'] as String?;

      // Delete associated gifts first
      final gifts = await _dbHelper.getGiftsForEvent(localId);
      for(var gift in gifts){
        // Ensure gift deletion from both local database and Firestore
        await deleteGift(gift['_id']);
      }

      // Delete the event locally
      await _dbHelper.deleteEvent(localId);

      // Delete from Firestore using the Firestore-specific document ID
      if (firestoreDocId != null) {
        await _firestore.collection('events').doc(firestoreDocId).delete();
        print('Deleted event $localId from Firestore with firestore doc ID: $firestoreDocId');
      }
    } catch (e) {
      print('Error deleting event from Firestore: $e');
    }
  }
  //update method
  Future<void> updateEvent(Map<String, dynamic> event) async {
    try {
      final db = await _dbHelper.database;

      // First, fetch the Firestore document ID for this local event
      final eventResult = await db.query(
          DatabaseHelper.tableEvents,
          columns: ['_id', 'firestoreId'],
          where: '_id = ?',
          whereArgs: [event['_id']]
      );

      if (eventResult.isEmpty) {
        print('No event found with local ID: ${event['_id']}');
        return;
      }

      final firestoreDocId = eventResult.first['firestoreId'] as String?;
      await _dbHelper.updateEvent(event); // Update locally first

      // Update in Firestore using the Firestore-specific document ID
      if (firestoreDocId != null) {
        await _firestore
            .collection('events')
            .doc(firestoreDocId)
            .update(_eventToFirestore(Event.fromMap(event)));
        print('Updated event ${event['_id']} in Firestore');
      }
    } catch (e) {
      print('Error updating event in Firestore: $e');
    }
  }

// ------------------ Gift Methods ------------------
  Future<void> insertGift(Map<String, dynamic> gift) async {
    try {
      final firestoreDocRef = await _firestore.collection('gifts').add(_giftToFirestore(Gift.fromMap(gift)));
      final firestoreId = firestoreDocRef.id;
      // Insert locally and get local id

      await _dbHelper.insertGift({...gift, 'firestoreId': firestoreId});


      print('Inserted gift with Firestore ID: ${firestoreDocRef.id}');

    } catch (e) {
      print('Error inserting gift to Firestore: $e');
    }
  }


  Future<void> updateGift(Map<String, dynamic> gift) async {
    try {
      final db = await _dbHelper.database;

      final giftResult = await db.query(
          DatabaseHelper.tableGifts,
          columns: ['_id'],
          where: '_id = ?',
          whereArgs: [gift['_id']]
      );

      if (giftResult.isEmpty) {
        print('No gift found with local ID: ${gift['_id']}');
        return;
      }
      //get local gift id
      final giftId = giftResult.first['_id'] as int;

      final firestoreDocRef = await _firestore
          .collection('gifts')
          .where('event_id', isEqualTo: gift['event_id']?.toString() )
          .get();

      if (firestoreDocRef.docs.isEmpty) {
        print('No gift found in firestore with event ID: ${gift['event_id']}');
        return;
      }

      final firestoreDocId = firestoreDocRef.docs.first.id;


      await _dbHelper.updateGift(gift); // Update locally first

      // Update in Firestore using the Firestore-specific document ID
      if (firestoreDocId != null) {
        await _firestore
            .collection('gifts')
            .doc(firestoreDocId)
            .update(_giftToFirestore(Gift.fromMap(gift)));
        print('Updated gift ${gift['_id']} in Firestore');
      }


    } catch (e) {
      print('Error updating gift in Firestore: $e');
    }
  }


  Future<void> deleteGift(int id) async {
    try {
      final db = await _dbHelper.database;
      final giftResult = await db.query(
          DatabaseHelper.tableGifts,
          columns: ['_id', 'firestoreId'],
          where: '_id = ?',
          whereArgs: [id]
      );

      if(giftResult.isEmpty){
        print('No gift found locally with id $id');
        return;
      }

      final firestoreDocId = giftResult.first['firestoreId'] as String?;

      // Delete from local database first
      await _dbHelper.deleteGift(id);

      // Delete from Firestore if Firestore ID exists
      if (firestoreDocId != null) {
        await _firestore.collection('gifts').doc(firestoreDocId).delete();
        print('Deleted gift $id from Firestore');
      }
    } catch (e) {
      print('Error deleting gift from Firestore: $e');
    }
  }

  // ------------------ Pledge Methods ------------------
  Future<void> createPledge({
    required Map<String, dynamic> pledgeData,
    required String friendEmail
  }) async {
    try{
      final currentUser = await _dbHelper.getUserByEmail(
          _auth.currentUser?.email ?? ""
      );

      if(currentUser == null){
        throw Exception('Current user not found in local database');
      }

      final friend = await _dbHelper.getUserByEmail(friendEmail);

      if(friend == null){
        throw Exception("No friend found with email $friendEmail");
      }
      final pledgeId = Uuid().v4();
      await _firestore.collection('users')
          .doc(currentUser['email'])
          .collection('user_friends')
          .doc(friendEmail)
          .collection('user_pledged_gifts')
          .doc(pledgeId)
          .set(pledgeData);
      print('Created pledge with ID: $pledgeId in Firestore for friend: ${friendEmail}');


    }catch(e){
      print('Error creating pledge: $e');
      throw Exception('Error creating pledge: $e');
    }

  }

  Future<void> updatePledge({
    required Map<String, dynamic> pledgeData,
    required String friendEmail
  }) async {
    try{
      final currentUser = await _dbHelper.getUserByEmail(
          _auth.currentUser?.email ?? ""
      );

      if(currentUser == null){
        throw Exception('Current user not found in local database');
      }

      final friend = await _dbHelper.getUserByEmail(friendEmail);
      if(friend == null){
        throw Exception("No friend found with email $friendEmail");
      }
      await _firestore.collection('users')
          .doc(currentUser['email'])
          .collection('user_friends')
          .doc(friendEmail)
          .collection('user_pledged_gifts')
          .doc(pledgeData['id'])
          .update(pledgeData);
      print('Updated pledge with ID: ${pledgeData['id']} in Firestore for friend: ${friendEmail}');
    }catch(e){
      print('Error updating pledge: $e');
      throw Exception('Error updating pledge: $e');
    }
  }

  Future<void> removePledge({
    required String pledgeId,
    required String friendEmail
  }) async {
    try{
      final currentUser = await _dbHelper.getUserByEmail(
          _auth.currentUser?.email ?? ""
      );

      if(currentUser == null){
        throw Exception('Current user not found in local database');
      }

      final friend = await _dbHelper.getUserByEmail(friendEmail);
      if(friend == null){
        throw Exception("No friend found with email $friendEmail");
      }

      await _firestore.collection('users')
          .doc(currentUser['email'])
          .collection('user_friends')
          .doc(friendEmail)
          .collection('user_pledged_gifts')
          .doc(pledgeId).delete();
      print('Removed pledge with ID: $pledgeId in Firestore for friend: ${friendEmail}');

    }catch(e){
      print('Error removing pledge: $e');
      throw Exception('Error removing pledge: $e');
    }
  }





// ------------------ Friend Methods ------------------
  // ------------------ Friend Gift Methods ------------------
  // Future<List<Map<String, dynamic>>> getFriendGifts(String friendEmail) async {
  //   try {
  //     final friendUser = await _dbHelper.getUserByEmail(friendEmail);
  //     if (friendUser == null) {
  //       print("No friend found with email $friendEmail");
  //       return [];
  //     }
  //     final db = await _dbHelper.database;
  //     final friendEvents = await db.query(
  //         DatabaseHelper.tableEvents,
  //         where: 'user_id = ?',
  //         whereArgs: [friendUser['_id']]
  //     );
  //
  //
  //     if (friendEvents.isEmpty) {
  //       print('No events found for user ID: ${friendUser['_id']}');
  //       return [];
  //     }
  //
  //     List<String> eventIds = friendEvents.map((event) => event['_id'].toString()).toList();
  //
  //     final giftsQuery = await _firestore.collection('gifts')
  //         .where('event_id', whereIn: eventIds)
  //         .get();
  //
  //     final gifts = giftsQuery.docs.map((doc) {
  //       final data = doc.data();
  //       return {
  //         '_id': int.tryParse(doc.id) ?? -1,  // Firestore document ID
  //         ...data,
  //         'pledged': data['pledged'] is int
  //             ? data['pledged']
  //             : int.tryParse(data['pledged']?.toString() ?? '0') ?? 0,
  //         // Similar conversions for other fields if needed
  //       };
  //     }).toList();
  //     return gifts;
  //   } catch (e) {
  //     print('Error fetching gifts for friend: $e');
  //     return [];
  //   }
  // }

  Future<List<Map<String, dynamic>>> getFriendGifts(String friendEmail) async {
    try {
      final friendUser = await _dbHelper.getUserByEmail(friendEmail);
      if (friendUser == null) {
        print("No friend found with email $friendEmail");
        return [];
      }
      final db = await _dbHelper.database;
      final friendEvents = await db.query(
          DatabaseHelper.tableEvents,
          where: 'user_id = ?',
          whereArgs: [friendUser['_id']]
      );


      if (friendEvents.isEmpty) {
        print('No events found for user ID: ${friendUser['_id']}');
        return [];
      }

      List<String> eventIds = friendEvents.map((event) => event['_id'].toString()).toList();

      final giftsQuery = await _firestore.collection('gifts')
          .where('event_id', whereIn: eventIds)
          .get();

      final gifts = await Future.wait(giftsQuery.docs.map((doc) async {
        final data = doc.data();

        final localGift = await db.query(
            DatabaseHelper.tableGifts,
            where: 'firestoreId = ?',
            whereArgs: [doc.id]
        );

        final localGiftId = localGift.isNotEmpty ? localGift.first['_id'] : null;

        return {
          '_id': doc.id,  // Firestore document ID
          ...data,
          'localId': localGiftId,
          'pledged': data['pledged'] is int
              ? data['pledged']
              : int.tryParse(data['pledged']?.toString() ?? '0') ?? 0,
          // Similar conversions for other fields if needed
        };
      }).toList());
      return gifts;
    } catch (e) {
      print('Error fetching gifts for friend: $e');
      return [];
    }
  }


  Future<void> addFriend(String friendEmail) async {
    try{
      await _dbHelper.addFriend(friendEmail);
      final currentUserId = await _dbHelper.getCurrentUserId();
      if(currentUserId == null){
        throw Exception('No user is currently logged in.');
      }
      final currentUser = await _dbHelper.getUserByEmail(
          _auth.currentUser?.email ?? ""
      );
      if(currentUser != null) {
        await _firestore.collection('users')
            .doc(currentUser['email'])
            .collection('user_friends')
            .doc(friendEmail)
            .set({});

        print('Added friend ${friendEmail} to Firestore');
      }

    } catch(e){
      print('Error adding friend ${friendEmail} to Firestore: $e');
    }

  }

  Future<void> removeFriend(int friendId) async {
    try {
      final currentUserId = await _dbHelper.getCurrentUserId();
      if(currentUserId == null){
        throw Exception('No user is currently logged in.');
      }
      final currentUser = await _dbHelper.getUserByEmail(
          _auth.currentUser?.email ?? ""
      );

      final friend = await _dbHelper.getUserByEmail(
          (await _dbHelper.getUsers()).firstWhere((element) => (element as Map)['id'] == friendId)['email']
      );

      if (currentUser != null && friend!= null) {
        await _dbHelper.removeFriend(friendId); // Delete locally first
        await _firestore
            .collection('users')
            .doc(currentUser['email'])
            .collection('user_friends')
            .doc(friend['email']).delete();
        print('Removed friend ${friendId} from Firestore');
      }

    } catch (e) {
      print('Error removing friend ${friendId} from Firestore: $e');
    }
  }
}