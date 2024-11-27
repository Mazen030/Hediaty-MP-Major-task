import 'package:flutter/material.dart';

class AddGiftScreen extends StatefulWidget {
  final Map<String, dynamic>? gift;

  AddGiftScreen({this.gift});

  @override
  _AddGiftScreenState createState() => _AddGiftScreenState();
}

class _AddGiftScreenState extends State<AddGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _giftName;
  String? _giftCategory;
  bool _pledged = false;

  @override
  void initState() {
    super.initState();
    // Initialize fields if editing an existing gift
    if (widget.gift != null) {
      _giftName = widget.gift!['name'];
      _giftCategory = widget.gift!['category'];
      _pledged = widget.gift!['pledged'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gift == null ? 'Add Gift' : 'Edit Gift'),
        backgroundColor: Color(0xFF6A1B9A),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gift Name Input
                TextFormField(
                  initialValue: _giftName,
                  decoration: InputDecoration(
                    labelText: 'Gift Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a gift name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _giftName = value;
                  },
                ),
                SizedBox(height: 16.0),
                // Gift Category Dropdown
                DropdownButtonFormField<String>(
                  value: _giftCategory,
                  decoration: InputDecoration(
                    labelText: 'Gift Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Electronics', 'Books', 'Clothing', 'Accessories', 'Other']
                      .map((category) => DropdownMenuItem(
                    child: Text(category),
                    value: category,
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _giftCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                // Pledged Checkbox
                CheckboxListTile(
                  title: Text('Pledged'),
                  value: _pledged,
                  onChanged: (value) {
                    setState(() {
                      _pledged = value!;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                // Add/Update Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    widget.gift == null ? 'Add Gift' : 'Update Gift',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    // Validate and save form data
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newGift = {
        'name': _giftName,
        'category': _giftCategory,
        'pledged': _pledged,
      };
      // Return the new/updated gift to the calling screen
      Navigator.pop(context, newGift);
    }
  }
}
