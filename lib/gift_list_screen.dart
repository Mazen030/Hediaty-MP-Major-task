import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_gift_screen.dart';

class GiftListScreen extends StatefulWidget {
  final String friendName;
  final bool isFriendGiftList;
  final int? eventId;

  GiftListScreen({
    required this.friendName,
    this.isFriendGiftList = false,
    this.eventId,
  });

  @override
  _GiftListScreenState createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  List<Map<String, dynamic>> _gifts = [];
  String _sortBy = 'Name';
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    if (widget.eventId != null) {
      final gifts = await _databaseHelper.getGiftsForEvent(widget.eventId!);

      if (mounted) {
        setState(() {
          _gifts = gifts;
          _sortGifts();
        });
      }
    }
  }

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
            child: _gifts.isEmpty
                ? Center(child: Text('No gifts added yet'))
                : ListView.builder(
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return Card(
                  color: (gift['pledged'] == 1) ? Colors.green[50] : null,
                  child: ListTile(
                    title: Text(gift['name'] ?? ''),
                    subtitle: Text('Category: ${gift['category'] ?? 'N/A'}'),
                    trailing: widget.isFriendGiftList
                        ? _buildPledgeButton(gift, index)
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editGift(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteGift(index),
                        ),
                      ],
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
    return (gift['pledged'] == 1)
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
    if (widget.eventId == null) {
      print('Warning: No event ID set when adding gift');
      return;
    }

    final newGift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGiftScreen(
          eventId: widget.eventId,
        ),
      ),
    );

    if (newGift != null) {
      print('New gift added: $newGift');
      await _loadGifts();
    }
  }

  void _editGift(int index) async {
    final currentGift = _gifts[index];

    final updatedGift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGiftScreen(gift: currentGift),
      ),
    );

    if (updatedGift != null) {
      await _loadGifts();
    }
  }

  void _deleteGift(int index) async {
    final gift = _gifts[index];

    try {
      final result = await _databaseHelper.deleteGift(gift['_id']);

      if (result > 0) {
        await _loadGifts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gift: $e')),
      );
    }
  }

  void _pledgeGift(int index) async {
    final gift = _gifts[index];

    final result = await _databaseHelper.pledgeGift(gift['_id']);

    if (result > 0) {
      await _loadGifts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You pledged to give "${gift['name']}"')),
      );
    }
  }

  void _sortGifts() {
    if (_sortBy == 'Name') {
      _gifts.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortBy == 'Category') {
      _gifts.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
    } else if (_sortBy == 'Pledged') {
      _gifts.sort((a, b) => (b['pledged'] ?? 0).compareTo(a['pledged'] ?? 0));
    }
  }
}