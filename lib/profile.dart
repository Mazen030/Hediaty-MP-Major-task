import 'package:flutter/material.dart';
import 'event_listpage.dart';
import 'My Pledged Gifts Page.dart';

class ProfileScreen extends StatelessWidget {
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
                        "Name: User's Name",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Email: user@example.com",
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
                // Navigate to the event list page for the user's events
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
