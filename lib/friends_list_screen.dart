import 'package:flutter/material.dart';
import 'gift_list_screen.dart';
import 'create_event_list_screen.dart';
import 'event_listpage.dart';
import 'profile.dart';


class FriendsListScreen extends StatefulWidget {
  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    setState(() {
      _friends = [
        {'name': 'John Doe', 'profilePicture': '', 'upcomingEvents': 2},
        {'name': 'Jane Smith', 'profilePicture': '', 'upcomingEvents': 0},
      ];
      _isLoading = false;
    });
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
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventListScreen()),
                );
              },
              icon: Icon(Icons.event, color: Colors.white),
              label: Text(
                'Create Your Own Event/List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                      backgroundImage: friend['profilePicture'] != ''
                          ? AssetImage(friend['profilePicture'])
                          : null,
                      child: friend['profilePicture'] == '' ? Icon(Icons.person, size: 28) : null,
                    ),
                    title: Text(
                      friend['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      friend['upcomingEvents'] > 0
                          ? 'Upcoming Events: ${friend['upcomingEvents']}'
                          : 'No Upcoming Events',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: friend['upcomingEvents'] > 0
                        ? CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(
                        '${friend['upcomingEvents']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListScreen(
                            friendName: friend['name'],
                            isFriendGiftList: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

  void _addFriend() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add Friend functionality coming soon!')),
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
        friend['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final friend = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend['profilePicture'] != ''
                ? AssetImage(friend['profilePicture'])
                : null,
            child: friend['profilePicture'] == '' ? Icon(Icons.person) : null,
          ),
          title: Text(friend['name']),
          subtitle: Text(friend['upcomingEvents'] > 0
              ? 'Upcoming Events: ${friend['upcomingEvents']}'
              : 'No Upcoming Events'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GiftListScreen(friendName: friend['name']),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
