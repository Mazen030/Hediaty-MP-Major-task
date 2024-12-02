import 'package:flutter/material.dart';
import 'database_helper.dart';  // Adjust import path

class AddGiftScreen extends StatefulWidget {
  final Map<String, dynamic>? gift;
  final int? eventId;  // Optional event ID when adding a gift

  const AddGiftScreen({Key? key, this.gift, this.eventId}) : super(key: key);

  @override
  _AddGiftScreenState createState() => _AddGiftScreenState();
}

class _AddGiftScreenState extends State<AddGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing gift data or empty strings
    _nameController = TextEditingController(text: _getInitialText(widget.gift, 'name'));
    _descriptionController = TextEditingController(text: _getInitialText(widget.gift, 'description'));
    _categoryController = TextEditingController(text: _getInitialText(widget.gift, 'category'));
    _priceController = TextEditingController(
        text: _getInitialPrice(widget.gift)
    );
  }

  // Helper method to safely get initial text
  String _getInitialText(Map<String, dynamic>? gift, String key) {
    return gift != null && gift[key] != null ? gift[key].toString() : '';
  }

  // Helper method to safely get initial price
  String _getInitialPrice(Map<String, dynamic>? gift) {
    if (gift != null && gift['price'] != null) {
      return gift['price'].toString();
    }
    return '';
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode() ? 'Edit Gift' : 'Add Gift'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Gift Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a gift name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                ),
                child: const Text('Save Gift'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to check if in edit mode
  bool _isEditMode() {
    return widget.gift != null && widget.gift!['_id'] != null;
  }

  void _saveGift() async {
    // Ensure form is valid before proceeding
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // Prepare gift data
      Map<String, dynamic> giftData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'status': 'active',  // Default status
        'pledged': 0,  // Not pledged by default
      };

      // If editing an existing gift, include the ID
      if (_isEditMode()) {
        giftData['_id'] = widget.gift!['_id'];
      }

      // If adding to a specific event, include event ID
      if (widget.eventId != null) {
        giftData['event_id'] = widget.eventId;
      }

      try {
        // Insert or update gift
        if (!_isEditMode()) {
          await _databaseHelper.insertGift(giftData);
        } else {
          await _databaseHelper.updateGift(giftData);
        }

        // Close the screen and return the gift data
        Navigator.pop(context, giftData);
      } catch (e) {
        // Show error if save fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save gift: $e')),
        );
      }
    }
  }
}