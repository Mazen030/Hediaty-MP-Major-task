import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_gift_screen.dart';
import 'firestore_service.dart'; // Import FirestoreService

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
  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore Service

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
    if (widget.isFriendGiftList) {
      if (widget.friendName == null) {
        print("Friend name is null");
        return;
      }

      // Fetch gifts from firestore using friend's email
      final friend = await _databaseHelper.getUserByEmail(widget.friendName);
      if(friend != null){
        final gifts = await _firestoreService.getFriendGifts(friend['email'] as String);
        if (mounted) {
          setState(() {
            _gifts = gifts;
            _sortGifts();
          });
        }
      }
      else{
        print("Friend not found in local database");
      }
    }
    // If it's not a friend's gift list, load gifts from the local database
    else if (widget.eventId != null) {
      final gifts = await _databaseHelper.getGiftsForEvent(widget.eventId!);
      if (mounted) {
        setState(() {
          _gifts = gifts;
          _sortGifts();
        });
      }
    }
  }


  Future<Map<String, dynamic>?> _getGiftByFirestoreId(String firestoreId) async {
    final db = await _databaseHelper.database;
    final gifts = await db.query(
        DatabaseHelper.tableGifts,
        where: 'firestoreId = ?',
        whereArgs: [firestoreId]
    );

    if (gifts.isEmpty) {
      print('No gift found with Firestore ID: $firestoreId');
      return null;
    }

    return gifts.first; // Return the first (and should be only) gift found
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isFriendGiftList) // Conditionally show the pledge button
                          _buildPledgeButton(gift, index)
                        else
                          Row( // Show edit and delete if not a friend's list
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
    return TextButton(
      onPressed: () => _togglePledgeGift(index),
      style: TextButton.styleFrom(
        backgroundColor: (gift['pledged'] == 1) ? Colors.white : Color(0xFF6A1B9A),
      ),
      child: Text(
        (gift['pledged'] == 1) ? 'Pledged' : 'Pledge',
        style: TextStyle(
          color: (gift['pledged'] == 1) ? Colors.green : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
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
      await _firestoreService.deleteGift(gift['_id']);
      _loadGifts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gift: $e')),
      );
    }
  }

  // void _togglePledgeGift(int index) async {
  //   final gift = _gifts[index];
  //   final isPledged = gift['pledged'] == 1 || gift['pledged'] == '1';
  //
  //   try {
  //     final firestoreId = gift['_id']?.toString();
  //     if (firestoreId == null || firestoreId.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update pledge: Invalid gift ID')),
  //       );
  //       return;
  //     }
  //
  //     final localGift = await _getGiftByFirestoreId(firestoreId);
  //     if(localGift == null){
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update pledge: Invalid local gift ID')),
  //       );
  //       return;
  //     }
  //     final giftId = localGift['_id'] as int;
  //     await _databaseHelper.pledgeGift(giftId);
  //
  //     // Update Firestore with new pledge status
  //     await _firestoreService.updateGift(
  //         {...gift, 'pledged': isPledged ? 0 : 1}
  //     );
  //
  //     _loadGifts();
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           isPledged
  //               ? 'You have unpledged "${gift['name']}"'
  //               : 'You pledged to give "${gift['name']}"',
  //         ),
  //       ),
  //     );
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to update pledge: $e')),
  //     );
  //   }
  // }

  void _togglePledgeGift(int index) async {
    final gift = _gifts[index];
    final isPledged = gift['pledged'] == 1 || gift['pledged'] == '1';

    try {
      final firestoreId = gift['_id']?.toString();
      if (firestoreId == null || firestoreId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pledge: Invalid gift ID')),
        );
        return;
      }

      final localGift = await _getGiftByFirestoreId(firestoreId);
      if(localGift == null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pledge: Gift not found in local database')),
        );
        return;
      }

      final giftId = localGift['_id'] as int;

      if (!isPledged) {
        // Create a pledged gift record
        await _databaseHelper.createPledgedGift(
            giftId: giftId,
            giftName: gift['name'],
            friendName: widget.friendName, // Use the friend's name from the current screen
            dueDate: DateTime.now().add(Duration(days: 30)), // Example: due in 30 days
            giftStatus: 'pending'
        );
      } else {
        // If already pledged, remove the pledged gift record
        await _databaseHelper.unpledgeGift(giftId);
      }

      // Update the gift's pledged status
      await _databaseHelper.pledgeGift(giftId);

      // Update Firestore with new pledge status
      await _firestoreService.updateGift(
          {...gift, 'pledged': isPledged ? 0 : 1}
      );

      _loadGifts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPledged
                ? 'You have unpledged "${gift['name']}"'
                : 'You pledged to give "${gift['name']}"',
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pledge: $e')),
      );
    }
  }

  void _sortGifts() {
    // Create a mutable copy of the list before sorting
    List<Map<String, dynamic>> sortableGifts = List.from(_gifts);

    if (_sortBy == 'Name') {
      sortableGifts.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortBy == 'Category') {
      sortableGifts.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
    } else if (_sortBy == 'Pledged') {
      sortableGifts.sort((a, b) => (b['pledged'] ?? 0).compareTo(a['pledged'] ?? 0));
    }

    // Update the original _gifts list with the sorted list
    _gifts = sortableGifts;
  }
}