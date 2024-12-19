import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_gift_screen.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'My Pledged Gifts Page.dart'; // Import the pledged gift screen

class GiftListScreen extends StatefulWidget {
  final String friendName;
  final bool isFriendGiftList;
  final int? eventId;
  final String? eventFirestoreId;

  GiftListScreen({
    required this.friendName,
    this.isFriendGiftList = false,
    this.eventId,
    this.eventFirestoreId,
  });

  @override
  _GiftListScreenState createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  List<Map<String, dynamic>> _gifts = [];
  String _sortBy = 'Name';
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserEmail => _auth.currentUser?.email ?? '';

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
    if (_currentUserEmail.isEmpty) {
      print('No user is currently logged in');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isFriendGiftList) {
        if (widget.eventFirestoreId == null) {
          print("Event ID is null");
          return;
        }

        final gifts = await _firestoreService.getFriendGifts(
          widget.friendName,
          widget.eventFirestoreId!,
        );

        // For each gift, check if the current user has pledged it
        for (var gift in gifts) {
          final pledgeData = await _firestoreService.getPledge(
            friendEmail: widget.friendName,
            giftName: gift['name'],
            currentUserEmail: _currentUserEmail,
            eventId: widget.eventFirestoreId,
          );
          gift['pledged'] = pledgeData.isNotEmpty ? 1 : 0;
        }

        if (mounted) {
          setState(() {
            _gifts = gifts;
            _sortGifts();
            _isLoading = false;
          });
        }
      } else if (widget.eventId != null) {
        final gifts = await _databaseHelper.getGiftsForEvent(widget.eventId!);
        if (mounted) {
          setState(() {
            _gifts = gifts;
            _sortGifts();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading gifts: $e');
      setState(() {
        _isLoading = false;
      });
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
          if (widget.isFriendGiftList)
            IconButton(
                onPressed: () => _viewPledgedGifts(),
                icon: Icon(Icons.card_giftcard)),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                        if (widget.isFriendGiftList)
                          _buildPledgeButton(gift, index)
                        else
                          Row(
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
    bool isPledged = gift['pledged'] == 1;
    return TextButton(
      onPressed: () => _togglePledgeGift(gift, index),
      style: TextButton.styleFrom(
        backgroundColor: isPledged ? Colors.white : Color(0xFF6A1B9A),
      ),
      child: Text(
        isPledged ? 'Pledged' : 'Pledge',
        style: TextStyle(
          color: isPledged ? Colors.green : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _togglePledgeGift(Map<String, dynamic> gift, int index) async {
    if (_currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to pledge gifts')),
      );
      return;
    }

    final isPledged = gift['pledged'] == 1;

    try {
      final firestoreId = gift['id']; // Firestore document ID
      if (firestoreId == null || firestoreId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pledge: Invalid gift ID')),
        );
        return;
      }

      if (!isPledged) {
        // Check if anyone has already pledged this gift
        final existingPledges = await _firestoreService.getAllPledgesForGift(
          friendEmail: widget.friendName,
          giftName: gift['name'],
          eventId: widget.eventFirestoreId,
        );

        if (existingPledges.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This gift has already been pledged by someone')),
          );
          return;
        }
        // Get current date time
        DateTime now = DateTime.now();
        // Create a new pledge
        await _firestoreService.createPledge(
          pledgeData: {
            'giftName': gift['name'],
            'pledged': 1,
            'pledgeDate': now.toString(),
            'status': 'pending',
            'eventId': widget.eventFirestoreId,
            'giftId': firestoreId,
            'category': gift['category'],
          },
          friendEmail: widget.friendName,
          currentUserEmail: _currentUserEmail,
        );
        await _databaseHelper.createPledgedGift(
          giftId: firestoreId,
          giftName: gift['name'],
          friendName: widget.friendName,
          dueDate: now,
          giftStatus: 'pending',
        );



        // Update the pledge status in the gifts collection
        await _firestoreService.updateGiftPledgeStatus(firestoreId, 1);
      } else {
        // Get and remove existing pledge
        final pledgeData = await _firestoreService.getPledge(
          friendEmail: widget.friendName,
          giftName: gift['name'],
          currentUserEmail: _currentUserEmail,
          eventId: widget.eventFirestoreId,
        );

        if (pledgeData.isNotEmpty) {
          await _firestoreService.removePledge(
            pledgeId: pledgeData.first['id'],
            currentUserEmail: _currentUserEmail,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unpledge: pledge not found.')),
          );
          return;
        }

        await _databaseHelper.removePledgedGift(firestoreId);
        // Update the pledge status in the gifts collection
        await _firestoreService.updateGiftPledgeStatus(firestoreId, 0);
      }

      // Update gift's pledged status locally
      setState(() {
        _gifts[index]['pledged'] = isPledged ? 0 : 1;
      });

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
      print('Error toggling pledge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pledge: $e')),
      );
    }
  }
  void _viewPledgedGifts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyPledgedGiftsScreen(),
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
      await _loadGifts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gift: $e')),
      );
    }
  }

  void _sortGifts() {
    List<Map<String, dynamic>> sortableGifts = List.from(_gifts);

    if (_sortBy == 'Name') {
      sortableGifts.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortBy == 'Category') {
      sortableGifts.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
    } else if (_sortBy == 'Pledged') {
      sortableGifts.sort((a, b) => (b['pledged'] ?? 0).compareTo(a['pledged'] ?? 0));
    }

    _gifts = sortableGifts;
  }
}