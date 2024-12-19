import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'event_listpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'My Pledged Gifts Page.dart';
import 'firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();
  String _username = "Loading...";
  String _email = "Loading...";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
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

        await _firestoreService.syncFirebaseUser(currentUser);

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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF6A1B9A), // Header background color
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top:40.0),
                    child: Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Profile Picture
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Name: $_username",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                "Email: $_email",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              // List of Created Events
              _buildListItem(
                  icon: Icons.event,
                  title: "My Created Events",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EventListScreen(isUserEvents: true)),
                    );
                  }
              ),

              // Link to Pledged Gifts
              _buildListItem(
                  icon: Icons.card_giftcard,
                  title: "My Pledged Gifts",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MyPledgedGiftsScreen()),
                    );
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildListItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return  Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, color: Color(0xFF6A1B9A)),
              SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}