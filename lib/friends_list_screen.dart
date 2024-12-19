import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'friend_events_screen.dart'; // Import the new screen
import 'firestore_service.dart';
import 'profile.dart';

class FriendsListScreen extends StatefulWidget {
  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch friends from firestore
      final friends = await _firestoreService.getFriendsList();

      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friends: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading friends: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addFriend() async {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Friend'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Friend Email',
              hintText: 'Enter friend\'s email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    // Check if the user exists in Firestore first
                    bool userExists = await _firestoreService.checkUserExists(email);
                    if (!userExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User with this email not found.')),
                      );
                      return; // Exit if the user doesn't exist
                    }
                    // Use FirestoreService to add friend, this will throw error if the friend is already added
                    await FirestoreService().addFriend(email);
                    await _loadFriends(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Friend added successfully!')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(
        'Friends',
        style: TextStyle(fontWeight: FontWeight.bold),
    ),
    flexibleSpace: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),
    ),
    actions: [
    IconButton(
    icon: Icon(Icons.account_circle),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
    },
    ),
    IconButton(
    icon: Icon(Icons.search),
    onPressed: () {
    showSearch(
    context: context,
    delegate: FriendSearchDelegate(_friends),
    );
    },
    ),
    ],
    ),
    body: _isLoading
    ? Center(child: CircularProgressIndicator())
        : _friends.isEmpty
    ? _buildEmptyState()
        : ListView.builder(
    itemCount: _friends.length,
    padding: const EdgeInsets.all(16.0),
    itemBuilder: (context, index) {
    final friend = _friends[index];
    return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: ListTile(
    contentPadding: EdgeInsets.all(16),
      leading: CircleAvatar(
        radius: 28,
        child: Icon(Icons.person, size: 28),
      ),
      title: Text(
        friend['username'] ?? 'Unknown Friend',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(
        friend['email'] ?? 'No Email' ,
        style: TextStyle(color: Colors.grey[600]),
      ),
      onTap: () {
        print("Friend email: ${friend['email']}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendEventsScreen(
              friendEmail: friend['email'],
            ),
          ),
        );
      },
    ),
    );
    },
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFriend,
        backgroundColor: Color(0xFF6A1B9A),
        child: Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No friends added yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the "+" button to add friends.',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> friends;

  FriendSearchDelegate(this.friends);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = friends
        .where((friend) =>
    friend['username'].toLowerCase().contains(query.toLowerCase()) ||
        friend['email'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final friend = results[index];
        return ListTile(
          title: Text(friend['username'] ?? 'Unknown'),
          subtitle: Text(
            friend['email'] ?? '',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Text(
            '',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}