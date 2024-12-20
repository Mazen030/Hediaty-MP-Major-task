import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import the generated file
import 'home_screen.dart';
import 'login_form.dart';

void main({bool testing = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the app (only when not testing)
  if (!testing) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(MyApp(testing: testing));
}

class MyApp extends StatelessWidget {
  final bool testing;

  const MyApp({Key? key, this.testing = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: testing ? LoginForm() : HomeScreen(),
    );
  }
}





