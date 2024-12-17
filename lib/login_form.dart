import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_form.dart';
import 'package:flutter/material.dart';
import 'friends_list_screen.dart';
import 'Firebase Gift Sync and Management.dart'; // Import FirebaseGiftSync

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FirebaseGiftSync _giftSync = FirebaseGiftSync();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _logIn(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print("Login successful, UID: ${user.uid}");
        await _giftSync.initialGiftsSync();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FriendsListScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, ${user.email}!')),
        );
      } else{
        _showErrorDialog('Login failed: User is null.');
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showErrorDialog('Login failed: An unexpected error occurred.');
      print('Login failed: An unexpected error occurred: $e');
    }finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage = 'Login failed: An unexpected error occurred.';
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'Login failed: User not found.';
        break;
      case 'wrong-password':
        errorMessage = 'Login failed: Invalid email or password.';
        break;
      case 'invalid-email':
        errorMessage = 'Login failed: Invalid email format.';
        break;
      case 'user-disabled':
        errorMessage = 'Login failed: User disabled.';
        break;
      case 'too-many-requests':
        errorMessage = 'Login failed: Too many requests. Please try again later.';
        break;
      default:
        print('Firebase Authentication Error Code: ${e.code}');
        break;
    }
    _showErrorDialog(errorMessage);
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isLoading)
              CircularProgressIndicator(),
            if (!_isLoading) ...[
              _buildEmailField(),
              SizedBox(height: 16),
              _buildPasswordField(),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _logIn(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).primaryColor,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onSaved: (value) => _email = value!.trim(),
      validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      obscureText: true,
      onSaved: (value) => _password = value!,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters long';
        return null;
      },
    );
  }
}