import 'package:flutter/material.dart';
import 'add_gift_screen.dart';

class GiftListScreen extends StatefulWidget {
  final String friendName;
  final bool isFriendGiftList;

  GiftListScreen({
    required this.friendName,
    this.isFriendGiftList = false,
  });

  @override
  _GiftListScreenState createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  List<Map<String, dynamic>> _gifts = [
    {'name': 'Smartphone', 'category': 'Electronics', 'pledged': false},
    {'name': 'Book', 'category': 'Books', 'pledged': true},
    {'name': 'Watch', 'category': 'Accessories', 'pledged': false},
  ];

  String _sortBy = 'Name'; // Default sort criterion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friendName}'s Gift List"),
        backgroundColor: Color(0xFF6A1B9A),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortGifts();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'Category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'Pledged', child: Text('Sort by Pledged Status')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.isFriendGiftList)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _addGift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                ),
                child: Text(
                  'Add Gift',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return Card(
                  color: gift['pledged'] ? Colors.green[50] : null,
                  child: ListTile(
                    title: Text(gift['name']),
                    subtitle: Text('Category: ${gift['category']}'),
                    trailing: widget.isFriendGiftList
                        ? _buildPledgeButton(gift, index)
                        : IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editGift(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPledgeButton(Map<String, dynamic> gift, int index) {
    return gift['pledged']
        ? TextButton(
      onPressed: null,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
      ),
      child: Text(
        'Pledged',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    )
        : TextButton(
      onPressed: () => _pledgeGift(index),
      style: TextButton.styleFrom(
        backgroundColor: Color(0xFF6A1B9A),
      ),
      child: Text('Pledge'),
    );
  }

  void _addGift() async {
    final newGift = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGiftScreen()),
    );
    if (newGift != null) {
      setState(() {
        _gifts.add(newGift);
        _sortGifts(); // Sort after adding
      });
    }
  }

  void _editGift(int index) async {
    final updatedGift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGiftScreen(gift: _gifts[index]),
      ),
    );
    if (updatedGift != null) {
      setState(() {
        _gifts[index] = updatedGift;
        _sortGifts(); // Sort after editing
      });
    }
  }

  void _pledgeGift(int index) {
    setState(() {
      _gifts[index]['pledged'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You pledged to give "${_gifts[index]['name']}"')),
    );
  }

  void _sortGifts() {
    if (_sortBy == 'Name') {
      _gifts.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortBy == 'Category') {
      _gifts.sort((a, b) => a['category'].compareTo(b['category']));
    } else if (_sortBy == 'Pledged') {
      _gifts.sort((a, b) => b['pledged'].compareTo(a['pledged']));
    }
  }
}
