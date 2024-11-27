import 'package:flutter/material.dart';
import 'database_helper.dart';  // Import DatabaseHelper
import 'friends_list_screen.dart'; // Import FriendsListScreen

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance of DatabaseHelper
  String _username = '';
  String _password = '';

  Future<void> _logIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if the username and password are correct
      bool loginSuccess = await _dbHelper.authenticateUser(_username, _password);

      if (loginSuccess) {
        // Navigate to Friends List Screen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FriendsListScreen()),
        );

        // Show a welcome message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, $_username!')),
        );
      } else {
        // Show an error message if login fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid username or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Username Field
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSaved: (value) => _username = value!,
              validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
            ),
            SizedBox(height: 16),

            // Password Field
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
              onSaved: (value) => _password = value!,
              validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
            ),
            SizedBox(height: 16),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle forgot password
                },
                child: Text('Forgot Password?'),
              ),
            ),

            // Log-In Button
            ElevatedButton(
              onPressed: () => _logIn(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF6A1B9A), // Purple
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Log In',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
