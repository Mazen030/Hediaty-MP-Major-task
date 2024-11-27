import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date

class MyPledgedGiftsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> pledgedGifts = [
    {'gift': 'Smartphone', 'friend': 'John', 'dueDate': DateTime(2024, 12, 25), 'status': 'pending'},
    {'gift': 'Book', 'friend': 'Emma', 'dueDate': DateTime(2024, 11, 30), 'status': 'fulfilled'},
    // Add more pledged gifts as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Pledged Gifts"),
        backgroundColor: Color(0xFF6A1B9A),
      ),
      body: pledgedGifts.isNotEmpty
          ? ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(
                gift['gift'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pledged to: ${gift['friend']}'),
                  Text('Due Date: ${DateFormat.yMMMMd().format(gift['dueDate'])}'),
                ],
              ),
              trailing: gift['status'] == 'pending'
                  ? ElevatedButton(
                onPressed: () {
                  // Handle modify pledge functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Modify pledge functionality coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: Text(
                  'Modify',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : Icon(Icons.check_circle, color: Colors.green, size: 30.0),
            ),
          );
        },
      )
          : Center(
        child: Text(
          "No pledged gifts yet!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
