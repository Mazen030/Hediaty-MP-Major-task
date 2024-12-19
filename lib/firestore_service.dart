import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'database_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  String get _currentUserId => _auth.currentUser!.uid;


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
      'user_id': _currentUserId, // This should be the Firebase Auth UID
    };
  }
  Future<String?> _getFirestoreEventId(int localEventId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
        DatabaseHelper.tableEvents,
        columns: ['firestoreId'],
        where: '_id = ?',
        whereArgs: [localEventId]
    );

    return result.isNotEmpty ? result.first['firestoreId'] as String? : null;
  }

  Map<String, dynamic> _giftToFirestore(Gift localGift, String? firestoreEventId) {
    return {
      'name': localGift.name,
      'description': localGift.description,
      'category': localGift.category,
      'price': localGift.price,
      'status': localGift.status,
      'event_id': firestoreEventId, // Use Firestore event ID instead of local ID
      'user_id': _currentUserId,  // Add the user ID for querying
      'pledged': localGift.pledged,
    };
  }

  // ------------------ User Methods ------------------
  // Method to sync local data with Firebase when a user logs in
  Future<void> syncFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        // First, sync to local database
        await _dbHelper.syncFirebaseUserToLocalDatabase(firebaseUser);

        // Check if user already exists in Firestore
        final usersQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .get();

        if (usersQuery.docs.isEmpty) {
          // If user doesn't exist in Firestore, add them
          final userDocRef = await _firestore.collection('users').add({
            'username': firebaseUser.displayName ?? firebaseUser.email?.split('@').first,
            'email': firebaseUser.email,
            'uid': firebaseUser.uid,  // Store the Firebase Auth UID
            'createdAt': FieldValue.serverTimestamp(),
          });

          print("Created user ${firebaseUser.email} in Firestore with ID: ${userDocRef.id}");
        } else {
          // Update existing user to ensure uid is stored
          final docId = usersQuery.docs.first.id;
          await _firestore.collection('users').doc(docId).update({
            'uid': firebaseUser.uid,  // Ensure the uid is stored/updated
          });
          print("Updated user ${firebaseUser.email} with uid");
        }
      } catch (e) {
        print('Error syncing user: $e');
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try{
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data();
      }
      else {
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
      throw Exception('Failed to fetch user data. Please try again');
    }
  }


  Future<bool> checkUserExists(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return snapshot.docs.isNotEmpty; // Return true if a document with the email is found
    } catch (e) {
      print('Error checking user existence: $e');
      throw Exception('Failed to check user existence. Please try again');
    }
  }



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
      // Get the Firestore event ID for this gift's event
      final db = await _dbHelper.database;
      final eventResult = await db.query(
          DatabaseHelper.tableEvents,
          columns: ['firestoreId'],
          where: '_id = ?',
          whereArgs: [gift['event_id']]
      );

      final firestoreEventId = eventResult.isNotEmpty ? eventResult.first['firestoreId'] as String? : null;

      // Create Firestore document with the Firestore event ID
      final firestoreDocRef = await _firestore
          .collection('gifts')
          .add(_giftToFirestore(Gift.fromMap(gift), firestoreEventId));

      final firestoreId = firestoreDocRef.id;

      // Insert locally and store the Firestore ID
      await _dbHelper.insertGift({...gift, 'firestoreId': firestoreId});

      print('Inserted gift with Firestore ID: $firestoreId for event: $firestoreEventId');
    } catch (e) {
      print('Error inserting gift to Firestore: $e');
    }
  }

  Future<void> updateGift(Map<String, dynamic> gift) async {
    try {
      final db = await _dbHelper.database;

      final giftResult = await db.query(
          DatabaseHelper.tableGifts,
          where: '_id = ?',
          whereArgs: [gift['_id']]
      );

      if (giftResult.isEmpty) {
        print('No gift found with local ID: ${gift['_id']}');
        return;
      }

      // Get the firestore id from the local db
      final firestoreId = (await db.query(
          DatabaseHelper.tableGifts,
          columns: ['firestoreId'],
          where: '_id = ?',
          whereArgs: [gift['_id']]
      )).first['firestoreId'] as String?;

      if(firestoreId == null){
        print("No firestore ID found for local gift ID ${gift['_id']}");
        return;
      }

      // Get the Firestore event ID for this gift's event
      final eventResult = await db.query(
          DatabaseHelper.tableEvents,
          columns: ['firestoreId'],
          where: '_id = ?',
          whereArgs: [gift['event_id']]
      );

      final firestoreEventId = eventResult.isNotEmpty ? eventResult.first['firestoreId'] as String? : null;

      await _dbHelper.updateGift(gift); // Update locally first

      // Update in Firestore using the Firestore-specific document ID
      await _firestore
          .collection('gifts')
          .doc(firestoreId)
          .update(_giftToFirestore(Gift.fromMap(gift), firestoreEventId));
      print('Updated gift ${gift['_id']} in Firestore');

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
  Future<List<Map<String, dynamic>>> getAllPledgesForGift({
    required String friendEmail,
    required String giftName,
    String? eventId,
  }) async {
    try {
      // First get the friend's user document
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isEmpty) {
        print('Friend not found with email $friendEmail');
        return [];
      }

      // Build base query to search across all users' pledges
      var allPledgesQuery = _firestore
          .collectionGroup('pledges')
          .where('giftName', isEqualTo: giftName)
          .where('giftOwnerEmail', isEqualTo: friendEmail);

      // Add event filter if eventId is provided
      if (eventId != null) {
        allPledgesQuery = allPledgesQuery.where('eventId', isEqualTo: eventId);
      }

      final querySnapshot = await allPledgesQuery.get();

      return querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      print('Error getting all pledges for gift: $e');
      return [];
    }
  }


  Future<DocumentReference> createPledge({
    required Map<String, dynamic> pledgeData,
    required String friendEmail,
    required String currentUserEmail,
  }) async {
    try {
      // Check for existing pledges first
      final existingPledges = await getAllPledgesForGift(
        friendEmail: friendEmail,
        giftName: pledgeData['giftName'],
        eventId: pledgeData['eventId'],
      );

      if (existingPledges.isNotEmpty) {
        throw Exception('This gift has already been pledged');
      }

      // Get the current user's document
      final currentUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .get();

      if (currentUserQuery.docs.isEmpty) {
        throw Exception('Current user not found with email $currentUserEmail');
      }

      final currentUserId = currentUserQuery.docs.first.id;

      // Add additional metadata to pledgeData
      final enrichedPledgeData = {
        ...pledgeData,
        'giftOwnerEmail': friendEmail,
        'pledgedByEmail': currentUserEmail,
        'pledgeDate': FieldValue.serverTimestamp(),
      };

      // Create the pledge under the current user's pledges collection
      final pledgeRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pledges')
          .add(enrichedPledgeData);

      return pledgeRef;
    } catch (e) {
      print('Error creating pledge: $e');
      rethrow;
    }
  }

  Future<void> updatePledge({
    required Map<String, dynamic> pledgeData,
    required String friendEmail,
    required String pledgeId
  }) async {
    try{
      // Get user from firestore using friend email.
      final friendDoc =  await _firestore.collection('users').where('email', isEqualTo: friendEmail).get();

      if (friendDoc.docs.isEmpty) {
        throw Exception("No friend found with email $friendEmail");
      }
      final friendId = friendDoc.docs.first.id;

      await _firestore.collection('users')
          .doc(friendId)
          .collection('pledges')
          .doc(pledgeId)
          .update(pledgeData);
      print('Updated pledge with ID: ${pledgeId} in Firestore for friend: ${friendEmail}');
    }catch(e){
      print('Error updating pledge: $e');
      throw Exception('Error updating pledge: $e');
    }
  }

  Future<void> removePledge({
    required String pledgeId,
    required String currentUserEmail, // Update parameter
  }) async {
    try {
      // Get current user's document
      final currentUserDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .get();

      if (currentUserDoc.docs.isEmpty) {
        throw Exception('Current user not found with email $currentUserEmail');
      }

      final currentUserId = currentUserDoc.docs.first.id;

      // Delete the pledge from the current user's pledges collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pledges')
          .doc(pledgeId)
          .delete();
    } catch (e) {
      print('Error removing pledge: $e');
      rethrow;
    }
  }


// ------------------ Friend Methods ------------------
  // ------------------ Friend Gift Methods ------------------

  Future<List<Map<String, dynamic>>> getFriendGifts(String friendEmail, String eventFirestoreId) async {
    try {
      // Get friend's user document to get their Firebase Auth UID
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isEmpty) {
        print('No user found with email $friendEmail in Firestore');
        return [];
      }

      final friendUid = friendQuery.docs.first.get('uid');

      print('Querying gifts for event: $eventFirestoreId and user: $friendUid');

      // Query gifts using the Firestore event ID
      final giftsSnapshot = await _firestore
          .collection('gifts')
          .where('event_id', isEqualTo: eventFirestoreId)
          .where('user_id', isEqualTo: friendUid)
          .get();

      print('Found ${giftsSnapshot.docs.length} gifts');

      return giftsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'price': data['price'] ?? 0.0,
          'status': data['status'] ?? 'active',
          'pledged': data['pledged'] ?? 0,
          'event_id': data['event_id'] ?? '',
        };
      }).toList();

    } catch (e) {
      print('Error fetching gifts for friend $friendEmail: $e');
      return [];
    }
  }


  Future<void> addFriend(String friendEmail) async {
    try {
      // First, find the friend's Firestore document
      final friendSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendSnapshot.docs.isEmpty) {
        throw Exception('Friend with email $friendEmail not found');
      }

      // Get the friend's Firestore document ID
      final friendId = friendSnapshot.docs.first.id;
      final currentUserEmail = _auth.currentUser?.email;

      if (currentUserEmail == null) {
        throw Exception('No user is currently logged in.');
      }

      // Get current user's document
      final currentUserSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .get();

      if (currentUserSnapshot.docs.isEmpty) {
        throw Exception('Current user not found in Firestore');
      }

      final currentUserId = currentUserSnapshot.docs.first.id;

      // Check if the friendship already exists
      final existingFriendship = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('user_friends')
          .where('friendId', isEqualTo: friendId)
          .get();

      if (existingFriendship.docs.isNotEmpty) {
        throw Exception('$friendEmail is already in your friends list');
      }

      // Add friend to Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('user_friends')
          .add({
        'email': friendEmail,
        'friendId': friendId,
        'added_at': FieldValue.serverTimestamp()
      });

      print('Added friend $friendEmail to Firestore');

    } catch (e) {
      print('Error adding friend $friendEmail to Firestore: $e');
      rethrow;
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


  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final currentUserEmail = _auth.currentUser?.email;
      if (currentUserEmail == null) {
        throw Exception('No user is currently logged in.');
      }

      // Find the current user's Firestore document
      final currentUserSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .get();

      if (currentUserSnapshot.docs.isEmpty) {
        throw Exception('Current user not found in Firestore');
      }

      final currentUserId = currentUserSnapshot.docs.first.id;

      // Fetch friends of the current user
      QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('user_friends')
          .get();

      // List of friend data
      List<Map<String, dynamic>> friends = [];

      for (var doc in friendsSnapshot.docs) {
        // Get friend's ID from the friends collection
        final friendId = doc.data()['friendId'];
        final friendEmail = doc.data()['email'];

        // Fetch full friend details from users collection
        final friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          final friendData = friendDoc.data()!;
          friendData['email'] = friendEmail;
          friendData['friendId'] = friendId;
          friends.add(friendData);
        }
      }

      return friends;
    } catch(e) {
      print('Error getting friends list: $e');
      throw Exception('Error getting friends list: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPledgedGifts() async {
    try {
      final currentUserEmail = _auth.currentUser?.email;
      if(currentUserEmail == null) {
        throw Exception('No user is currently logged in.');
      }

      final currentUser = await _dbHelper.getUserByEmail(currentUserEmail);
      if (currentUser == null) {
        throw Exception('Current user not found in local database');
      }
      final db = await _dbHelper.database;


      QuerySnapshot<Map<String, dynamic>> pledgedGiftsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('user_friends')
          .get();
      List<Map<String, dynamic>> pledgedGifts = [];
      for(var friendDoc in pledgedGiftsSnapshot.docs){
        QuerySnapshot<Map<String, dynamic>> pledgedGiftsForFriend = await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('user_friends')
            .doc(friendDoc.id)
            .collection('user_pledged_gifts')
            .get();

        for (var doc in pledgedGiftsForFriend.docs) {
          final data = doc.data();
          final localGift = await db.query(
            'gifts',
            where: 'name = ?',
            whereArgs: [data['giftName']],
          );
          final giftId = localGift.isNotEmpty ? localGift.first['id'] as int : null;


          if (data.containsKey('giftName') && giftId != null) {
            pledgedGifts.add({
              'id': doc.id,
              'giftName': data['giftName'] as String,
              'pledgeDate': data['pledgeDate'] as String,
              'friendName': friendDoc.id,
              'giftId': giftId,
            });

          }
        }
      }
      return pledgedGifts;

    } catch (e) {
      print('Error fetching pledged gifts: $e');
      throw Exception('Error fetching pledged gifts: $e');
    }
  }

  Future<void> updatePledgeStatus({
    required String pledgeId,
    required String newStatus,
    required String friendEmail
  }) async {
    try {
      // Get user from firestore using friend email.
      final friendDoc =  await _firestore.collection('users').where('email', isEqualTo: friendEmail).get();
      if (friendDoc.docs.isEmpty) {
        throw Exception("No friend found with email $friendEmail");
      }
      final friendId = friendDoc.docs.first.id;

      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('pledges')
          .doc(pledgeId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating pledge status: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPledge({
    required String friendEmail,
    required String giftName,
    required String currentUserEmail, // Add current user's email
    String? eventId,
  }) async {
    try {
      // Get current user's document (the one who made the pledge)
      final currentUserDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUserEmail)
          .get();

      if (currentUserDoc.docs.isEmpty) {
        print("Current user not found with email $currentUserEmail");
        return [];
      }

      final currentUserId = currentUserDoc.docs.first.id;

      // Query the pledges under the current user's document
      var query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pledges')
          .where('giftName', isEqualTo: giftName)
          .where('giftOwnerEmail', isEqualTo: friendEmail);

      if (eventId != null) {
        query = query.where('eventId', isEqualTo: eventId);
      }

      final querySnapshot = await query.get();

      final pledges = querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();

      return pledges;
    } catch (e) {
      print('Error fetching pledge: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getFriendEvents(String friendEmail) async {
    try {
      print('Fetching events for friend: $friendEmail');

      // Get friend's user document to get their Firebase Auth UID
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user document found for email: $friendEmail');
        return [];
      }

      // Get the Firebase Auth UID from the user document
      // This assumes you store the Firebase Auth UID in the user document
      final userData = userQuery.docs.first.data();
      final authUid = userData['uid']; // Make sure you store this when creating user documents

      if (authUid == null) {
        print('No Firebase Auth UID found for user');
        return [];
      }

      print('Found friend Auth UID: $authUid');

      // Query events using the Firebase Auth UID
      final eventsQuery = await _firestore
          .collection('events')
          .where('user_id', isEqualTo: authUid)
          .get();

      print('Found ${eventsQuery.docs.length} events for Auth UID: $authUid');

      return eventsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Event',
          'category': data['category'] ?? '',
          'date': data['date'] ?? '',
          'description': data['description'] ?? '',
          'location': data['location'] ?? '',
          'status': data['status'] ?? '',
          'user_id': data['user_id'] ?? '',
        };
      }).toList();

    } catch (e) {
      print('Error in getFriendEvents: $e');
      return [];
    }
  }
  // Future<void> updateGiftPledgeStatus(String giftId, int pledgeStatus) async {
  //   try {
  //     final giftsCollection = FirebaseFirestore.instance.collection('gifts');
  //     await giftsCollection.doc(giftId).update({'pledged': pledgeStatus});
  //   } catch (e) {
  //     print('Error updating pledge status: $e');
  //     throw e;
  //   }
  // }
  Future<void> _syncPledgeStatusToLocal(String firestoreGiftId, int pledgeStatus) async {
    try {
      final db = await _dbHelper.database;

      // Query the local gift using the Firestore ID
      final localGifts = await db.query(
        DatabaseHelper.tableGifts,
        columns: ['_id'],
        where: 'firestoreId = ?',
        whereArgs: [firestoreGiftId],
      );

      if (localGifts.isEmpty) {
        print('No local gift found with Firestore ID: $firestoreGiftId');
        return;
      }

      // Update the local gift's pledge status
      final localGiftId = localGifts.first['_id'] as int;
      await db.update(
        DatabaseHelper.tableGifts,
        {'pledged': pledgeStatus},
        where: '_id = ?',
        whereArgs: [localGiftId],
      );

      print('Successfully synced pledge status to local database for gift ID: $localGiftId');
    } catch (e) {
      print('Error syncing pledge status to local database: $e');
      throw Exception('Failed to sync pledge status to local database: $e');
    }
  }
  // Future<void> updateGiftPledgeStatus(String giftId, int pledgeStatus) async {
  //   try {
  //     // First get the gift document from Firestore to find the owner
  //     final giftDoc = await _firestore.collection('gifts').doc(giftId).get();
  //
  //     if (!giftDoc.exists) {
  //       throw Exception('Gift not found in Firestore');
  //     }
  //
  //     final giftData = giftDoc.data();
  //     final ownerId = giftData?['user_id']; // This is the Firebase Auth UID of the gift owner
  //
  //     if (ownerId == null) {
  //       throw Exception('Gift owner not found');
  //     }
  //
  //     // Get the owner's email from users collection
  //     final ownerDoc = await _firestore
  //         .collection('users')
  //         .where('uid', isEqualTo: ownerId)
  //         .get();
  //
  //     if (ownerDoc.docs.isEmpty) {
  //       throw Exception('Gift owner user document not found');
  //     }
  //
  //     final ownerEmail = ownerDoc.docs.first.data()['email'];
  //
  //     // Update Firestore
  //     await _firestore
  //         .collection('gifts')
  //         .doc(giftId)
  //         .update({'pledged': pledgeStatus});
  //
  //     // Check if the current user is the gift owner
  //     if (_auth.currentUser?.email == ownerEmail) {
  //       // If yes, update local database
  //       await _syncPledgeStatusToLocal(giftId, pledgeStatus);
  //       print('Updated local database for gift owner');
  //     } else {
  //       print('Skipping local database update as current user is not the gift owner');
  //     }
  //
  //     print('Successfully updated pledge status in Firestore');
  //   } catch (e) {
  //     print('Error updating pledge status: $e');
  //     throw e;
  //   }
  // }
  Future<void> updateGiftPledgeStatus(String giftId, int pledgeStatus) async {
    try {
      // First get the gift document from Firestore to find the owner
      final giftDoc = await _firestore.collection('gifts').doc(giftId).get();

      if (!giftDoc.exists) {
        throw Exception('Gift not found in Firestore');
      }

      final giftData = giftDoc.data();
      final ownerId = giftData?['user_id']; // This is the Firebase Auth UID of the gift owner

      if (ownerId == null) {
        throw Exception('Gift owner not found');
      }

      // Get the owner's email from users collection
      final ownerDoc = await _firestore
          .collection('users')
          .where('uid', isEqualTo: ownerId)
          .get();

      if (ownerDoc.docs.isEmpty) {
        throw Exception('Gift owner user document not found');
      }

      // Update Firestore - this will be synced to owner's local DB when they next open the app
      await _firestore
          .collection('gifts')
          .doc(giftId)
          .update({'pledged': pledgeStatus});

      print('Successfully updated pledge status in Firestore for gift: $giftId');
      print('Changes will sync to gift owner\'s device when they next open the app');

    } catch (e) {
      print('Error updating pledge status: $e');
      throw e;
    }
  }



}