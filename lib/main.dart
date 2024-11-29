import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  await dbHelper.debugDatabase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hedieaty',
      theme: ThemeData(
        primaryColor: Color(0xFF6A1B9A), // Purple theme
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomeScreen(), // Start with the HomeScreen
    );
  }
}
