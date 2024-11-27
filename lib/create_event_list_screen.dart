import 'package:flutter/material.dart';

class CreateEventListScreen extends StatefulWidget {
  @override
  _CreateEventListScreenState createState() => _CreateEventListScreenState();
}

class _CreateEventListScreenState extends State<CreateEventListScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _eventName;
  String? _eventCategory;
  DateTime? _eventDate;
  String? _eventStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event/List'),
        backgroundColor: Color(0xFF6A1B9A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _eventName = value;
                },
              ),
              SizedBox(height: 16.0),

              // Event Category Field
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Event Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Birthday',
                  'Wedding',
                  'Engagement',
                  'Graduation',
                  'Holiday',
                ].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _eventCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Event Date Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Event Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _eventDate = selectedDate;
                    });
                  }
                },
                validator: (value) {
                  if (_eventDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: _eventDate != null
                      ? "${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}"
                      : '',
                ),
              ),
              SizedBox(height: 16.0),

              // Event Status Field
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Event Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Upcoming',
                  'Current',
                  'Past',
                ].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _eventStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                ),
                child: Text(
                  'Create Event/List',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();

      // Create a new event as a Map
      final newEvent = {
        'name': _eventName!,
        'category': _eventCategory!,
        'date': _eventDate!,
        'status': _eventStatus!,
      };

      // Pass the new event back to the EventListScreen
      Navigator.pop(context, newEvent);
    }
  }
}
