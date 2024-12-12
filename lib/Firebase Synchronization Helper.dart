import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'database_helper.dart';
import 'package:flutter/material.dart';

class FirebaseSyncHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // User Synchronization
  Future<void> syncUserToFirebase() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get local user data
    final localUser = await _databaseHelper.getUserByEmail(currentUser.email!);
    if (localUser == null) return;

    // Sync to Firebase Realtime Database
    await _database.ref('users/${currentUser.uid}').set({
      'username': localUser['username'],
      'email': localUser['email'],
      'preferences': localUser['preferences'] ?? {},
    });
  }

  // Events Synchronization
  Future<void> syncEventsToFirebase() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get local events for current user
    final localEvents = await _databaseHelper.getUserEvents();

    // Create a reference to the user's events in Firebase
    final eventsRef = _database.ref('events/${currentUser.uid}');

    // Sync each event
    for (var event in localEvents) {
      await eventsRef.child(event['_id'].toString()).set({
        'name': event['name'],
        'category': event['category'],
        'date': event['date'].toString(),
        'location': event['location'],
        'description': event['description'],
        'status': event['status'],
      });
    }
  }

  // Gifts Synchronization
  Future<void> syncGiftsToFirebase(int eventId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get gifts for specific event
    final localGifts = await _databaseHelper.getGiftsForEvent(eventId);

    // Create a reference to the event's gifts in Firebase
    final giftsRef = _database.ref('gifts/${currentUser.uid}/$eventId');

    // Sync each gift
    for (var gift in localGifts) {
      await giftsRef.child(gift['_id'].toString()).set({
        'name': gift['name'],
        'description': gift['description'],
        'category': gift['category'],
        'price': gift['price'],
        'status': gift['status'],
        'pledged': gift['pledged'] ?? 0,
      });
    }
  }

  // Real-time Gift Status Listener
  StreamSubscription? listenToGiftStatusChanges(int eventId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final giftsRef = _database.ref('gifts/${currentUser.uid}/$eventId}');

    return giftsRef.onChildChanged.listen((event) async {
      // Get the updated gift data
      final giftData = event.snapshot.value as Map<dynamic, dynamic>;
      final giftId = int.parse(event.snapshot.key!);

      // Update local database
      await _databaseHelper.updateGift({
        '_id': giftId,
        'status': giftData['status'],
        'pledged': giftData['pledged'],
      });

      // Optionally, trigger UI update
      print('Gift $giftId status updated to ${giftData['status']}');
    });
  }

  // Get Gift Status Color
  Color getGiftStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.blue;
      case 'pledged':
        return Colors.green;
      case 'purchased':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Pull Firebase Data to Local Database
  Future<void> pullFirebaseDataToLocal() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Pull events
    final eventsRef = _database.ref('events/${currentUser.uid}');
    final eventsSnapshot = await eventsRef.get();

    if (eventsSnapshot.exists) {
      final eventsData = eventsSnapshot.value as Map<dynamic, dynamic>;

      for (var eventEntry in eventsData.entries) {
        await _databaseHelper.insertEvent({
          'name': eventEntry.value['name'],
          'category': eventEntry.value['category'],
          'date': eventEntry.value['date'],
          'location': eventEntry.value['location'],
          'description': eventEntry.value['description'],
          'status': eventEntry.value['status'],
        });
      }
    }

    // Similar logic can be added for gifts and other data
  }
}