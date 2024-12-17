import 'package:flutter/material.dart';
import 'gift_list_screen.dart';
import 'add_event_screen.dart';
import 'database_helper.dart';
import 'firestore_service.dart'; // Import FirestoreService


class EventListScreen extends StatefulWidget {
  final bool isUserEvents;

  EventListScreen({this.isUserEvents = true});

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore Service
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _sortBy = 'Name';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = widget.isUserEvents
          ? await _databaseHelper.getUserEvents()
          : await _databaseHelper.getFriendsEvents();

      setState(() {
        _events = events;
        _sortEvents();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isUserEvents ? 'My Events' : "Friend's Events",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF6A1B9A),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortEvents();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'Category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'Status', child: Text('Sort by Status')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? Center(child: Text('No events available'))
          : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            elevation: 5,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.event,
                color: _getStatusColor(event['status']),
                size: 32,
              ),
              title: Text(
                event['name'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${event['category']} - ${event['status']} - ${event['date'].toString().split(' ')[0]}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              trailing: widget.isUserEvents
                  ? PopupMenuButton<String>(
                onSelected: (value) => _handleEventAction(value, index),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiftListScreen(
                      friendName: event['name'],
                      isFriendGiftList: !widget.isUserEvents,
                      eventId: event['_id'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.isUserEvents
          ? FloatingActionButton.extended(
        backgroundColor: Color(0xFF6A1B9A),
        onPressed: _addEvent,
        icon: Icon(Icons.add),
        label: Text('Add Event'),
      )
          : null,
    );
  }

  void _addEvent() async {
    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEventScreen()),
    );

    if (newEvent != null) {
      final requiredFields = ['name', 'category', 'date', 'status'];
      for (var field in requiredFields) {
        if (!newEvent.containsKey(field) || newEvent[field] == null) {
          print('Missing required field: $field');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Missing required field: $field')),
          );
          return;
        }
      }
      if (newEvent['date'] is DateTime) {
        newEvent['date'] = (newEvent['date'] as DateTime).toIso8601String();
      }
      final eventToInsert = {
        'name': newEvent['name'],
        'category': newEvent['category'],
        'date': newEvent['date'],
        'status': newEvent['status'],
        'user_id': _databaseHelper.currentUserId,
        'location': newEvent['location'] ?? '',
        'description': newEvent['description'] ?? '',
      };
      print('Attempting to insert event: $eventToInsert');

      try {
        await _firestoreService.insertEvent(eventToInsert); // Use the Firestore service
        _loadEvents();
      } catch (e) {
        print('Error inserting event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add event: ${e.toString()}')),
        );
      }
    }
  }



  void _editEvent(Map<String, dynamic> event) async {
    final updatedEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(event: event),
      ),
    );

    if (updatedEvent != null) {
      try{
        await _firestoreService.updateEvent(updatedEvent);
        _loadEvents();
      } catch (e){
        print('Error updating event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event: ${e.toString()}')),
        );
      }

    }
  }




  void _deleteEvent(int index) async {
    try{
      await _firestoreService.deleteEvent(_events[index]['_id']); // Delete event from Firestore
      _loadEvents();
    } catch(e){
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
      );
    }
  }

  void _handleEventAction(String action, int index) {
    final event = _events[index];

    if (action == 'edit') {
      _editEvent(event);
    } else if (action == 'delete') {
      _deleteEvent(index);
    }
  }

  void _sortEvents() {
    if (_sortBy == 'Name') {
      _events.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortBy == 'Category') {
      _events.sort((a, b) => a['category'].compareTo(b['category']));
    } else if (_sortBy == 'Status') {
      _events.sort((a, b) => a['status'].compareTo(b['status']));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.green;
      case 'Current':
        return Colors.blue;
      case 'Past':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}