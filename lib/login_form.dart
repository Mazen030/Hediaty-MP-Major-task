// import 'package:flutter/material.dart';
// import 'database_helper.dart';
// import 'friends_list_screen.dart';
//
// class LoginForm extends StatefulWidget {
//   @override
//   _LoginFormState createState() => _LoginFormState();
// }
//
// class _LoginFormState extends State<LoginForm> {
//   final _formKey = GlobalKey<FormState>();
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   String _username = '';
//   String _password = '';
//   bool _isLoading = false;
//
//   Future<void> _logIn(BuildContext context) async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//
//       setState(() {
//         _isLoading = true;
//       });
//
//       bool loginSuccess = await _dbHelper.authenticateUser(_username, _password);
//
//       setState(() {
//         _isLoading = false;
//       });
//
//       if (loginSuccess) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => FriendsListScreen()),
//         );
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Welcome back, $_username!')),
//         );
//       } else {
//         _showErrorDialog('Invalid username or password');
//       }
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Error'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             if (_isLoading)
//               CircularProgressIndicator(),
//             if (!_isLoading) ...[
//               _buildUsernameField(),
//               SizedBox(height: 16),
//               _buildPasswordField(),
//               SizedBox(height: 16),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {
//                     // Handle forgot password
//                   },
//                   child: Text('Forgot Password?'),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () => _logIn(context),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: Size(double.infinity, 50),
//                   backgroundColor: Theme.of(context).primaryColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   'Log In',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUsernameField() {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: 'Username',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       onSaved: (value) => _username = value!.trim().toLowerCase(),
//       validator: (value) => value == null || value.isEmpty ? 'Please enter your username' : null,
//     );
//   }
//
//   Widget _buildPasswordField() {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: 'Password',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       obscureText: true,
//       onSaved: (value) => _password = value!,
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Please enter your password';
//         if (value.length < 6) return 'Password must be at least 6 characters long';
//         return null;
//       },
//     );
//   }
// }
//
//
//









import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_form.dart';
import 'package:flutter/material.dart';
import 'friends_list_screen.dart';
import 'Firebase Gift Sync and Management.dart';

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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Sign in with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Check if user is successfully authenticated
        User? user = userCredential.user;
        if (user != null) {
          print("Login successful, UID: ${user.uid}");
/////////////////////////////////////////
          await _giftSync.initialGiftsSync();
          // Navigate to FriendsListScreen if login is successful
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FriendsListScreen()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${user.email}!')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message if login fails
        _showErrorDialog('Login failed: ${e.toString()}');
      }
    }
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
