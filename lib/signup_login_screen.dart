import 'package:flutter/material.dart';
import 'signup_form.dart';
import 'login_form.dart';

class SignUpLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Welcome',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Color(0xFF6A1B9A),
            indicatorWeight: 4,
            labelColor: Color(0xFF6A1B9A),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Sign Up'),
              Tab(text: 'Log In'),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: 16), // Add some spacing
            Image.asset('assets/img.png', width: 150, height: 150),
            Text(
              'Hediaty',
              style: TextStyle(
                fontFamily: 'DancingScript',
                fontSize: 40,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SignUpForm(), // Sign-up form
                  LoginForm(), // Log-in form
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}