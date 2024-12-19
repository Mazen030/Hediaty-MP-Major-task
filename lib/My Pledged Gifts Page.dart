import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// PledgedGift Model
class PledgedGift {
  final String giftId;
  final String giftName;
  final String friendName;
  final DateTime dueDate;
  final String giftStatus;

  PledgedGift({
    required this.giftId,
    required this.giftName,
    required this.friendName,
    required this.dueDate,
    required this.giftStatus,
  });

  factory PledgedGift.fromMap(Map<String, dynamic> map) {
    return PledgedGift(
      giftId: map['gift_id'].toString(),
      giftName: map['gift_name'],
      friendName: map['friend_name'],
      dueDate: DateTime.parse(map['due_date']),
      giftStatus: map['gift_status'],
    );
  }
}

class MyPledgedGiftsScreen extends StatefulWidget {
  @override
  _MyPledgedGiftsScreenState createState() => _MyPledgedGiftsScreenState();
}

class _MyPledgedGiftsScreenState extends State<MyPledgedGiftsScreen> {
  final dbHelper = DatabaseHelper();
  final firestoreService = FirestoreService();
  List<PledgedGift> _pledgedGifts = [];
  bool _isLoading = true;
  String _sortBy = 'Name';

  @override
  void initState() {
    super.initState();
    _loadPledgedGifts();
  }

  Future<void> _loadPledgedGifts() async {
    setState(() => _isLoading = true);
    try {
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentUserEmail == null) {
        throw Exception("No user is logged in");
      }
      final List<Map<String, dynamic>> localGifts = await dbHelper.getPledgedGifts();
      setState(() {
        _pledgedGifts = localGifts.map((map) => PledgedGift.fromMap(map)).toList();
        _sortGifts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pledged gifts: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pledged gifts: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "My Pledged Gifts",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortGifts();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'DueDate', child: Text('Sort by Due Date')),
              PopupMenuItem(value: 'Status', child: Text('Sort by Status')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pledgedGifts.isEmpty
          ? Center(
        child: Text(
          "No pledged gifts yet!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = _pledgedGifts[index];
          return _buildGiftCard(gift, index);
        },
      ),
    );
  }


  Widget _buildGiftCard(PledgedGift gift, int index) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeIn,
        ),
      ),
      child: Card(
        elevation: 4.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Text(
              gift.giftName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Color(0xFF4A148C),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pledged to: ${gift.friendName}', style: TextStyle(color: Colors.grey[600],)),
                SizedBox(height: 4.0),
                Text(
                  'Due Date: ${DateFormat.yMMMMd().format(gift.dueDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: gift.giftStatus == 'pending'
                ? ElevatedButton(
              onPressed: () {
                _showModifyOptions(context, gift);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('Modify', style: TextStyle(color: Colors.white),),
            )
                : Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 30.0,
            )
        ),
      ),
    );
  }


  void _showModifyOptions(BuildContext context, PledgedGift gift) {
    showGeneralDialog(
      context: context,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.check, color: Colors.green),
                title: Text('Mark as Fulfilled'),
                onTap: () async {
                  try {
                    await dbHelper.updatePledgedGiftStatus(gift.giftId, 'fulfilled');
                    // Implement Firebase Update logic here
                    Navigator.pop(context);
                    _loadPledgedGifts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update gift: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Cancel Pledge'),
                onTap: () async {
                  try {
                    // Get user email for the friend
                    final friend = await dbHelper.getUserByEmail(gift.friendName);
                    if (friend == null) {
                      throw Exception('Friend not found');
                    }

                    // Remove pledge from Firestore
                    final pledgeData = await firestoreService.getPledge(
                      friendEmail: gift.friendName,
                      giftName: gift.giftName,
                      currentUserEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                      eventId: '',
                    );
                    if(pledgeData.isNotEmpty){
                      await firestoreService.removePledge(
                        pledgeId: pledgeData.first['id'],
                        currentUserEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                      );
                    }

                    await dbHelper.removePledgedGift(gift.giftId);
                    Navigator.pop(context);
                    _loadPledgedGifts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to cancel pledge: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortGifts() {
    if (_sortBy == 'Name') {
      _pledgedGifts.sort((a, b) => a.giftName.compareTo(b.giftName));
    } else if (_sortBy == 'DueDate') {
      _pledgedGifts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortBy == 'Status') {
      _pledgedGifts.sort((a, b) => a.giftStatus.compareTo(b.giftStatus));
    }
  }
}