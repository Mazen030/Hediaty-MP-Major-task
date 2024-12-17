import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart'; // Import your DatabaseHelper


// PledgedGift Model
class PledgedGift {
  final int giftId;
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
      giftId: map['gift_id'],
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
      final List<Map<String, dynamic>> fetchedGifts = await dbHelper.getPledgedGifts();
      setState(() {
        _pledgedGifts = fetchedGifts
            .map((map) => PledgedGift.fromMap(map))
            .toList();
        _sortGifts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pledged gifts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Pledged Gifts"),
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
          ))
          : ListView.builder(
        itemCount: _pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = _pledgedGifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(
                gift.giftName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pledged to: ${gift.friendName}'),
                  Text(
                      'Due Date: ${DateFormat.yMMMMd().format(gift.dueDate)}'),
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
                child: Text(
                  'Modify',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : Icon(Icons.check_circle,
                  color: Colors.green, size: 30.0),
            ),
          );
        },
      ),
    );
  }

  void _showModifyOptions(BuildContext context, PledgedGift gift) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.check),
                title: Text('Mark as Fulfilled'),
                onTap: () async {
                  await dbHelper.fulfillGift(gift.giftId);
                  Navigator.pop(context);
                  _loadPledgedGifts();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Cancel Pledge'),
                onTap: () async {
                  await dbHelper.unpledgeGift(gift.giftId);
                  Navigator.pop(context);
                  _loadPledgedGifts();
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