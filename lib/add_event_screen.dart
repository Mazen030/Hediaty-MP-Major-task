import 'package:flutter/material.dart';
import 'database_helper.dart';
class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic>? event;

  AddEventScreen({this.event});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _eventName;
  String? _eventCategory;
  DateTime? _eventDate;
  String? _eventStatus;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _eventName = widget.event!['name'];
      _eventCategory = widget.event!['category'];
      _eventStatus = widget.event!['status'];

      // Safely handle both String and DateTime formats for the date
      final date = widget.event!['date'];
      if (date != null) {
        if (date is String) {
          _eventDate = DateTime.parse(date);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                items: ['Birthday', 'Wedding', 'Engagement', 'Graduation']
                    .map((category) => DropdownMenuItem(
                  child: Text(category),
                  value: category,
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
                items: ['Upcoming', 'Current', 'Past']
                    .map((status) => DropdownMenuItem(
                  child: Text(status),
                  value: status,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _eventStatus = value;
                  });
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
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (selectedDate != null) {
      setState(() {
        _eventDate = selectedDate;
      });
    }
  }

  // void _submitForm() {
  //   if (_formKey.currentState!.validate()) {
  //     _formKey.currentState!.save();
  //
  //     // Ensure all required fields are included
  //     Navigator.pop(context, {
  //       'name': _eventName,
  //       'category': _eventCategory,
  //       'date': _eventDate?.toIso8601String(),
  //       'status': _eventStatus,
  //       'location': '', // Optional
  //       'description': '', // Optional
  //       'user_id': DatabaseHelper().currentUserId,
  //     });
  //   }
  // }
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create the updated event map
      final updatedEvent = {
        '_id': widget.event?['_id'], // Ensure the ID is preserved for updates
        'name': _eventName ?? '',    // Updated event name
        'category': _eventCategory ?? '', // Updated category
        'date': _eventDate?.toIso8601String() ?? '', // Updated date
        'status': _eventStatus ?? '', // Updated status
        'location': widget.event?['location'] ?? '', // Keep existing location
        'description': widget.event?['description'] ?? '', // Keep existing description
        'user_id': DatabaseHelper().currentUserId, // User ID
      };

      // Return the updated event to the previous screen
      Navigator.pop(context, updatedEvent);
    }
  }




}
