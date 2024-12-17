import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'firestore_service.dart'; // Import FirestoreService


class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic>? event;

  const AddEventScreen({Key? key, this.event}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore Service
  String? _eventName;
  String? _eventCategory;
  DateTime? _eventDate;
  String? _eventStatus;
  String? _eventLocation;
  String? _eventDescription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _eventName = widget.event!['name'];
      _eventCategory = widget.event!['category'];
      _eventStatus = widget.event!['status'];
      _eventLocation = widget.event!['location'];
      _eventDescription = widget.event!['description'];

      final date = widget.event!['date'];
      if (date != null) {
        if (date is String) {
          _eventDate = DateTime.tryParse(date);
        } else if (date is DateTime) {
          _eventDate = date;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
        backgroundColor: Color(0xFF6A1B9A),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _eventName,
                decoration: InputDecoration(labelText: 'Event Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _eventName = value;
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _eventCategory,
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                items: ['Birthday', 'Wedding', 'Engagement', 'Graduation']
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _eventCategory = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ListTile(
                title: Text(_eventDate == null
                    ? 'Select Date'
                    : _eventDate!.toLocal().toString().split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _eventStatus,
                decoration: InputDecoration(labelText: 'Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
                items: ['Upcoming', 'Current', 'Past']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _eventStatus = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: _eventLocation,
                decoration: InputDecoration(labelText: 'Location'),
                onSaved: (value) {
                  _eventLocation = value;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: _eventDescription,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) {
                  _eventDescription = value;
                },
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.event == null ? 'Add Event' : 'Update Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (selectedDate != null) {
      setState(() {
        _eventDate = selectedDate;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = await _databaseHelper.getCurrentUserId();

      final eventData = {
        '_id': widget.event?['_id'],
        'name': _eventName ?? '',
        'category': _eventCategory ?? '',
        'date': _eventDate?.toIso8601String() ?? '',
        'status': _eventStatus ?? '',
        'location': _eventLocation ?? '',
        'description': _eventDescription ?? '',
        'user_id': currentUserId,
      };

      print('AddEventScreen _submitForm eventData before saving: $eventData');


      if (widget.event == null) {
        print('AddEventScreen _submitForm calling insertEvent: $eventData');
        //await _firestoreService.insertEvent(eventData);
        _showSuccessMessage('Event added successfully');
      } else {
        print('AddEventScreen _submitForm calling updateEvent: $eventData');
        await _firestoreService.updateEvent(eventData);
        _showSuccessMessage('Event updated successfully');
      }
      Navigator.pop(context, eventData);
    } catch (e) {
      _showErrorMessage('Failed to ${widget.event == null ? 'add' : 'update'} event: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

}