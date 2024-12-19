import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'gift_list_screen.dart';
import 'database_helper.dart';

class FriendEventsScreen extends StatefulWidget {
  final String friendEmail;

  const FriendEventsScreen({
    Key? key,
    required this.friendEmail,
  }) : super(key: key);

  @override
  _FriendEventsScreenState createState() => _FriendEventsScreenState();
}

class _FriendEventsScreenState extends State<FriendEventsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadFriendEvents();
  }

  Future<List<Map<String, dynamic>>> _loadFriendEvents() async {
    try {
      return await _firestoreService.getFriendEvents(widget.friendEmail);
    } catch (e) {
      print('Error loading friend events: $e'); // Debug print
      throw Exception('Failed to load events: $e');
    }
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          event['name'] ?? 'No Title',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              event['description'] ?? 'No Description',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (event['date'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Date: ${_formatDate(event['date'])}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _navigateToGiftList(event['id']),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    // Handle Timestamp or other date formats as needed
    return date.toString();
  }

  void _navigateToGiftList(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiftListScreen(
          friendName: widget.friendEmail,
          isFriendGiftList: true,
          eventFirestoreId: eventId,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.friendEmail}\'s Events',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _eventsFuture = _loadFriendEvents();
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _eventsFuture = _loadFriendEvents();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No events available for ${widget.friendEmail}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            );
          },
        ),
      ),
    );
  }
}