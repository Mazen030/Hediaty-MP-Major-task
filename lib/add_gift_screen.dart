import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'firestore_service.dart'; // Import FirestoreService

class AddGiftScreen extends StatefulWidget {
  final Map<String, dynamic>? gift;
  final int? eventId;

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
  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore Service
  final DatabaseHelper _databaseHelper = DatabaseHelper();



  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: _getInitialText(widget.gift, 'name'));
    _descriptionController = TextEditingController(text: _getInitialText(widget.gift, 'description'));
    _categoryController = TextEditingController(text: _getInitialText(widget.gift, 'category'));
    _priceController = TextEditingController(
        text: _getInitialPrice(widget.gift)
    );
  }

  String _getInitialText(Map<String, dynamic>? gift, String key) {
    return gift != null && gift[key] != null ? gift[key].toString() : '';
  }

  String _getInitialPrice(Map<String, dynamic>? gift) {
    if (gift != null && gift['price'] != null) {
      return gift['price'].toString();
    }
    return '';
  }

  @override
  void dispose() {
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

  bool _isEditMode() {
    return widget.gift != null && widget.gift!['_id'] != null;
  }

  void _saveGift() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      Map<String, dynamic> giftData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'status': 'active',
        'pledged': 0,
      };

      if (widget.eventId != null) {
        giftData['event_id'] = widget.eventId;
        print('Saving gift with event ID: ${widget.eventId}');
      } else {
        print('Warning: No event ID when saving gift');
      }


      try {
        if (!_isEditMode()) {
          await _firestoreService.insertGift(giftData);
          print('Gift inserted with eventId: ${widget.eventId}');
        } else {
          giftData['_id'] = widget.gift!['_id'];
          await _firestoreService.updateGift(giftData);
          print('Gift updated: $giftData');
        }

        Navigator.pop(context, giftData);
      } catch (e) {
        print('Error saving gift: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save gift: $e')),
        );
      }
    }
  }
}