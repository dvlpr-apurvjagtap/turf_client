import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyGamesTab extends StatefulWidget {
  @override
  _MyGamesTabState createState() => _MyGamesTabState();
}

class _MyGamesTabState extends State<MyGamesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isUpcomingSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "My Games",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildToggleButtons(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('clients')
                  .doc(_auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                final bookings = List<String>.from(userData?['bookings'] ?? []);

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('No bookings found'),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('bookings')
                      .where('bookingId', whereIn: bookings)
                      // .orderBy('date')
                      // .orderBy('startTime')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookingsData = snapshot.data!.docs;
                    final now = DateTime.now();

                    // Filter bookings based on upcoming/past selection
                    final filteredBookings = bookingsData.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as String);
                      final startTime =
                          (data['startTime'] as Timestamp).toDate();

                      // Parse the date string to DateTime
                      final bookingDate = DateFormat('yyyy-MM-dd').parse(date);
                      final bookingDateTime = DateTime(
                        bookingDate.year,
                        bookingDate.month,
                        bookingDate.day,
                        startTime.hour,
                        startTime.minute,
                      );

                      return isUpcomingSelected
                          ? bookingDateTime.isAfter(now)
                          : bookingDateTime.isBefore(now);
                    }).toList();

                    if (filteredBookings.isEmpty) {
                      return Center(
                        child: Text(
                          isUpcomingSelected
                              ? 'No upcoming bookings'
                              : 'No past bookings',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index].data()
                            as Map<String, dynamic>;
                        final date = booking['date'] as String;
                        final startTime =
                            (booking['startTime'] as Timestamp).toDate();
                        final endTime =
                            (booking['endTime'] as Timestamp).toDate();
                        final turfName = booking['turfName'] ?? 'Unknown Turf';
                        final timeSlot = booking['timeSlot'] ?? 'Unknown Time';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUpcomingSelected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isUpcomingSelected
                                      ? Colors.green
                                      : Colors.grey.shade300),
                            ),
                            child: ListTile(
                              title: Text(
                                turfName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd, yyyy').format(startTime),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${booking['amount'] ?? '0'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isUpcomingSelected = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isUpcomingSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "Upcoming",
                style: TextStyle(
                  color: isUpcomingSelected ? Colors.white : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                isUpcomingSelected = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isUpcomingSelected ? Colors.transparent : Colors.green,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "Past",
                style: TextStyle(
                  color: isUpcomingSelected ? Colors.green : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
