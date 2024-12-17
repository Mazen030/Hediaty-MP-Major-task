import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import your existing DatabaseHelper
import 'firestore_service.dart';

class FirebaseGiftSync {
  final DatabaseHelper _localDb = DatabaseHelper();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirestoreService _firestoreService = FirestoreService();

  // Gift status constants
  static const String STATUS_AVAILABLE = 'available';
  static const String STATUS_PLEDGED = 'pledged';
  static const String STATUS_PURCHASED = 'purchased';

  // Color mapping for gift status
  static Map<String, Color> statusColors = {
    STATUS_AVAILABLE: Colors.blue.shade100,
    STATUS_PLEDGED: Colors.green.shade100,
    STATUS_PURCHASED: Colors.red.shade100,
  };



  // Sync a single event's gifts to Firebase
  Future<void> syncEventGiftsToFirebase(int eventId) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Get gifts from local database
      List<Map<String, dynamic>> gifts = await _localDb.getGiftsForEvent(eventId);

      // Create a reference to this event's gifts in Firebase
      DatabaseReference eventGiftsRef = _database.ref('events/$eventId/gifts');

      // Sync each gift
      for (var gift in gifts) {
        await eventGiftsRef.child(gift['_id'].toString()).set({
          'name': gift['name'],
          'description': gift['description'],
          'category': gift['category'],
          'price': gift['price'],
          'status': gift['status'] ?? STATUS_AVAILABLE,
          'pledged': gift['pledged'] ?? 0,
        });
      }
    } catch (e) {
      print('Error syncing gifts to Firebase: $e');
    }
  }

  // Listen for real-time updates to gifts for an event
  Stream<List<Map<String, dynamic>>> listenToEventGifts(int eventId) {
    DatabaseReference eventGiftsRef = _database.ref('events/$eventId/gifts');

    return eventGiftsRef.onValue.map((event) {
      if (event.snapshot.value == null) return [];

      Map<dynamic, dynamic> giftsMap = event.snapshot.value as Map<dynamic, dynamic>;
      return giftsMap.entries.map((entry) {
        return {
          '_id': int.tryParse(entry.key.toString()) ?? 0,
          'name': entry.value['name'],
          'description': entry.value['description'],
          'category': entry.value['category'],
          'price': entry.value['price'],
          'status': entry.value['status'] ?? STATUS_AVAILABLE,
          'pledged': entry.value['pledged'] ?? 0,
        };
      }).toList();
    });
  }

  // Update gift status in both local and Firebase databases
  Future<void> updateGiftStatus(int eventId, int giftId, String newStatus) async {
    try {
      // Update local database
      await _localDb.updateGift({
        '_id': giftId,
        'status': newStatus,
      });

      // Update Firebase
      DatabaseReference giftRef = _database.ref('events/$eventId/gifts/$giftId');
      await giftRef.update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating gift status: $e');
    }
  }

  // Pledge a gift (mark as pledged)
  Future<void> pledgeGift(int eventId, int giftId) async {
    try {
      // Update local database
      await _localDb.pledgeGift(giftId);

      // Update Firebase
      DatabaseReference giftRef = _database.ref('events/$eventId/gifts/$giftId');
      await giftRef.update({
        'status': STATUS_PLEDGED,
        'pledged': 1,
      });
    } catch (e) {
      print('Error pledging gift: $e');
    }
  }

  // Utility method to get color based on gift status
  Color getGiftStatusColor(String status) {
    return statusColors[status] ?? Colors.grey.shade100;
  }

  // Initial sync of all gifts when a user logs in
  Future<void> initialGiftsSync() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null){
      await _firestoreService.syncFirebaseUser(firebaseUser);
    }


    //await _firestoreService.migrateDataToFirestore();
    print("Initial Gifts Sync Finished");

  }
}