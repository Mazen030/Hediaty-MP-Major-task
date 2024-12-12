// import 'package:flutter/material.dart';
// import 'database_helper.dart'; // Import the DatabaseHelper
//
// class SignUpForm extends StatefulWidget {
//   @override
//   _SignUpFormState createState() => _SignUpFormState();
// }
//
// class _SignUpFormState extends State<SignUpForm> {
//   final _formKey = GlobalKey<FormState>();
//   final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance of DatabaseHelper
//
//   String _username = '';
//   String _email = '';
//   String _password = '';
//
//   Future<void> _signUp() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//
//       try {
//         // Check if the email already exists
//         bool userExists = await _dbHelper.checkUserExists(_email);
//         if (userExists) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Email already exists!')),
//           );
//           return;
//         }
//
//         // Save the new user in the database
//         Map<String, dynamic> newUser = {
//           'username': _username,
//           'email': _email,
//           'password': _password, // Hash the password in production
//         };
//
//         await _dbHelper.insertUser(newUser);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Account created successfully!')),
//         );
//
//         // Navigate to the login or home screen
//         Navigator.pop(context); // Close the sign-up screen
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: Text('Sign Up'),
//       //   backgroundColor: Color(0xFF6A1B9A), // Purple
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.all(13.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Username Field
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Username',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onSaved: (value) => _username = value!,
//                 validator: (value) =>
//                 value!.isEmpty ? 'Please enter a username' : null,
//               ),
//               SizedBox(height: 16),
//
//               // Email Field
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 onSaved: (value) => _email = value!,
//                 validator: (value) => value!.isEmpty || !value.contains('@')
//                     ? 'Enter a valid email'
//                     : null,
//               ),
//               SizedBox(height: 16),
//
//               // Password Field
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 obscureText: true,
//                 onSaved: (value) => _password = value!,
//                 validator: (value) => value!.length < 6
//                     ? 'Password must be at least 6 characters'
//                     : null,
//               ),
//               SizedBox(height: 24),
//
//               // Sign-Up Button
//               ElevatedButton(
//                 onPressed: _signUp,
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: Size(double.infinity, 50),
//                   backgroundColor: Color(0xFF6A1B9A), // Purple
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   'Sign Up',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // OR Divider
//               Row(
//                 children: [
//                   Expanded(child: Divider(color: Colors.grey)),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Text('OR'),
//                   ),
//                   Expanded(child: Divider(color: Colors.grey)),
//                 ],
//               ),
//               SizedBox(height: 16),
//
//               // Social Login Buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _socialButton(Icons.apple, 'Apple', Colors.black, () {
//                     // Handle Apple sign-in
//                   }),
//                   _socialButton(Icons.facebook, 'Facebook', Colors.blue, () {
//                     // Handle Facebook sign-in
//                   }),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _socialButton(
//       IconData icon, String label, Color color, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         foregroundColor: color,
//         backgroundColor: Colors.white,
//         side: BorderSide(color: color),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       icon: Icon(icon, color: color),
//       label: Text(label, style: TextStyle(color: color)),
//     );
//   }
// }
//
//
//
















import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // Future<void> _signup() async {
  //   try {
  //     await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Signup successful!')),
  //     );
  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }

  Future<void> _signup() async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Prepare user data for local database
      Map<String, dynamic> newUser = {
        'username': _usernameController.text.trim(), // Assuming you have a username controller
        'email': _emailController.text.trim(),
        'password': '', // Firebase handles authentication, so no local password storage
        'preferences': '' // Optional: add any initial preferences
      };

      // Insert user into local database
      await _dbHelper.insertUser(newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup successful!')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // More specific error handling for Firebase Authentication
      String errorMessage = 'Signup failed';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for this email.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    } catch (e) {
      // Catch any other unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

