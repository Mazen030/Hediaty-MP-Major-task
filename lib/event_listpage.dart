import 'package:flutter/material.dart';
import 'gift_list_screen.dart'; // For navigating to the Gift List page
import 'add_event_screen.dart'; // For adding and editing events

class EventListScreen extends StatefulWidget {
  final bool isUserEvents; // Flag to check if events belong to the user

  EventListScreen({this.isUserEvents = true});

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Map<String, dynamic>> _events = [
    {
      'name': 'John\'s Birthday',
      'category': 'Birthday',
      'date': DateTime(2024, 12, 1),
      'status': 'Upcoming',
    },
    {
      'name': 'Sarah & Tom\'s Wedding',
      'category': 'Wedding',
      'date': DateTime(2024, 10, 30),
      'status': 'Past',
    },
  ];

  String _sortBy = 'Name';

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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${event['category']} - ${event['status']} - ${event['date'].toLocal().toString().split(' ')[0]}',
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
                        : null, // Hide actions for friend's events
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListScreen(
                            friendName: event['name'],
                            isFriendGiftList: !widget.isUserEvents,
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
      floatingActionButton: widget.isUserEvents
          ? FloatingActionButton.extended(
        backgroundColor: Color(0xFF6A1B9A),
        onPressed: _addEvent,
        icon: Icon(Icons.add),
        label: Text('Add Event'),
      )
          : null, // Hide Add button for friend's events
    );
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

  void _addEvent() async {
    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEventScreen()),
    );
    if (newEvent != null) {
      setState(() {
        _events.add(newEvent);
        _sortEvents(); // Sort after adding
      });
    }
  }

  void _editEvent(int index) async {
    final updatedEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(event: _events[index]),
      ),
    );
    if (updatedEvent != null) {
      setState(() {
        _events[index] = updatedEvent;
        _sortEvents(); // Sort after editing
      });
    }
  }

  void _deleteEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event deleted!')),
    );
  }

  void _handleEventAction(String action, int index) {
    if (action == 'edit') {
      _editEvent(index);
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
}
