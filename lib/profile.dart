import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'event_listpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'My Pledged Gifts Page.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _username = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Get the current Firebase user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user details from local database using email
        final userDetails = await _databaseHelper.getUserByEmail(currentUser.email!);

        if (userDetails != null) {
          setState(() {
            _username = userDetails['username'] ?? currentUser.displayName ?? "User";
            _email = currentUser.email ?? "No email";
          });
        } else {
          setState(() {
            _username = currentUser.displayName ?? "User";
            _email = currentUser.email ?? "No email";
          });
        }
      } else {
        setState(() {
          _username = "No User";
          _email = "Not Logged In";
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _username = "Error";
        _email = "Error fetching email";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Color(0xFF6A1B9A),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Placeholder Profile Picture
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF6A1B9A),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  // User Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Name: $_username",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Email: $_email",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(thickness: 1.0),
            // List of Created Events
            ListTile(
              leading: Icon(Icons.event, color: Color(0xFF6A1B9A)),
              title: Text(
                "My Created Events",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                //Navigate to the event list page for the user's events
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventListScreen(isUserEvents: true)),
                );
              },
            ),
            Divider(thickness: 1.0),
            // Link to Pledged Gifts
            ListTile(
              leading: Icon(Icons.card_giftcard, color: Color(0xFF6A1B9A)),
              title: Text(
                "My Pledged Gifts",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                // Navigate to the pledged gifts page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPledgedGiftsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}