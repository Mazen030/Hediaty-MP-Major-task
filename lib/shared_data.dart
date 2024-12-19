import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'firestore_service.dart';
class SharedData extends ChangeNotifier {
  DatabaseHelper? databaseHelper;
  FirestoreService? firestoreService;

  SharedData({this.databaseHelper, this.firestoreService});

  void update(DatabaseHelper db, FirestoreService fs){
    databaseHelper = db;
    firestoreService = fs;
    notifyListeners();
  }
}