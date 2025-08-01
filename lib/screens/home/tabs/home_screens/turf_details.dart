import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:turf_client/models/turf.dart';
import 'package:turf_client/screens/home/tabs/home_screens/comfirmation.dart';

class TurfDetailsPage extends StatefulWidget {
  final Turf turf;

  const TurfDetailsPage({Key? key, required this.turf}) : super(key: key);

  @override
  State<TurfDetailsPage> createState() => _TurfDetailsPageState();
}

class _TurfDetailsPageState extends State<TurfDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedDateIndex = 0;
  int _selectedSlotIndex = -1;
  bool _isLoading = false;
  List<DateTime> _availableDates = [];
  List<String> _availableSlots = [];
  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchBookedSlots();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _availableDates =
        List.generate(7, (index) => now.add(Duration(days: index)));
    _availableSlots = _generateTimeSlots();
  }

  List<String> _generateTimeSlots() {
    return [
      '6:00 AM - 8:00 AM',
      '8:00 AM - 10:00 AM',
      '10:00 AM - 12:00 PM',
      '12:00 PM - 2:00 PM',
      '2:00 PM - 4:00 PM',
      '4:00 PM - 6:00 PM',
      '6:00 PM - 8:00 PM',
      '8:00 PM - 10:00 PM',
    ];
  }

  Future<void> _fetchBookedSlots() async {
    try {
      final selectedDate = _availableDates[_selectedDateIndex];
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final snapshot = await _firestore
          .collection('bookings')
          .where('turfId', isEqualTo: widget.turf.id)
          .where('date', isEqualTo: formattedDate)
          .get();

      setState(() {
        _bookedSlots = snapshot.docs
            .map((doc) => doc.data()['timeSlot'] as String)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: ${e.toString()}')),
      );
    }
  }

  Future<void> _bookTurf() async {
    if (_selectedSlotIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    // Check if user profile is complete
    final userDoc = await _firestore.collection('clients').doc(user.uid).get();
    if (!userDoc.exists ||
        userDoc.data()?['name'] == null ||
        userDoc.data()?['phoneNumber'] == null) {
      _showProfileCompletionDialog(user);
      return;
    }

    final selectedDate = _availableDates[_selectedDateIndex];
    final selectedSlot = _availableSlots[_selectedSlotIndex];
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Parse time slot
    final timeParts = selectedSlot.split(' - ');
    final startTime = DateFormat('h:mm a').parse(timeParts[0]);
    final endTime = DateFormat('h:mm a').parse(timeParts[1]);

    // Combine with selected date
    final bookingStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final bookingEnd = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    // Navigate to confirmation screen and wait for result
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmation(
          turf: widget.turf,
          bookingDate: selectedDate,
          timeSlot: selectedSlot,
          startTime: bookingStart,
          endTime: bookingEnd,
          price: widget.turf.price,
        ),
      ),
    );

    if (confirmed == true) {
      await _createBooking(
        formattedDate,
        selectedSlot,
        bookingStart,
        bookingEnd,
        user,
      );
    }
  }

  Future<void> _showProfileCompletionDialog(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Incomplete'),
        content: const Text('Please complete your profile before booking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Navigate to profile screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    }
  }

  Future<void> _createBooking(
    String formattedDate,
    String selectedSlot,
    DateTime bookingStart,
    DateTime bookingEnd,
    User user,
  ) async {
    setState(() => _isLoading = true);

    try {
      // Fetch user data from Firestore
      final userDoc =
          await _firestore.collection('clients').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found in Firestore.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'User';
      final userPhone = userData['phoneNumber'] ?? 'N/A';

      // Create a unique booking ID
      final bookingId = _firestore.collection('bookings').doc().id;

      final bookingData = {
        'bookingId': bookingId,
        'turfId': widget.turf.id,
        'turfName': widget.turf.name,
        'userId': user.uid,
        'userName': userName,
        'userPhone': userPhone,
        'date': formattedDate,
        'timeSlot': selectedSlot,
        'startTime': Timestamp.fromDate(bookingStart),
        'endTime': Timestamp.fromDate(bookingEnd),
        'amount': widget.turf.price,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': widget.turf.ownerId,
        'status': 'confirmed',
        'paymentMethod': 'Cash',
      };

      // Create booking document
      await _firestore.collection('bookings').doc(bookingId).set(bookingData);

      // Update user's bookings with the booking ID
      await _firestore.collection('clients').doc(user.uid).update({
        'bookings': FieldValue.arrayUnion([bookingId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to owner's bookings
      await _firestore.collection('owners').doc(widget.turf.ownerId).update({
        'bookings': FieldValue.arrayUnion([bookingId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );

      await _fetchBookedSlots();
      setState(() => _selectedSlotIndex = -1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            _buildTurfInformationSection(),
            const Divider(),
            _buildSelectDateSection(),
            const SizedBox(height: 16),
            _buildSelectSlotSection(),
            const SizedBox(height: 16),
            _buildAmenitiesSection(),
            const SizedBox(height: 16),
            _buildBookButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: widget.turf.imageUrl.startsWith('http')
                  ? NetworkImage(widget.turf.imageUrl) as ImageProvider
                  : AssetImage(widget.turf.imageUrl),
              fit: BoxFit.cover,
            ),
            color: Colors.green.shade200,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurfInformationSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.turf.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            widget.turf.location,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(widget.turf.rating.toString()),
              const SizedBox(width: 16),
              Text(
                '₹${widget.turf.price}/hour',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSelectDateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Date",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        _selectedSlotIndex = -1;
                      });
                      _fetchBookedSlots();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: _selectedDateIndex == index
                                ? Colors.green.shade600
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade600),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "${date.day}\n${DateFormat('EEE').format(date)}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedDateIndex == index
                                  ? Colors.white
                                  : Colors.green.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildSelectSlotSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Slot",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 2.5,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final isBooked = _bookedSlots.contains(_availableSlots[index]);
              return ElevatedButton(
                onPressed: isBooked
                    ? null
                    : () {
                        setState(() {
                          _selectedSlotIndex = index;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedSlotIndex == index
                      ? Colors.green.shade600
                      : isBooked
                          ? Colors.grey.shade300
                          : Colors.white,
                  side: BorderSide(
                    color:
                        isBooked ? Colors.grey.shade400 : Colors.green.shade600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _availableSlots[index],
                  style: TextStyle(
                    color: _selectedSlotIndex == index
                        ? Colors.white
                        : isBooked
                            ? Colors.grey.shade600
                            : Colors.green.shade600,
                  ),
                ),
              );
            },
          ),
          if (_bookedSlots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '* Grey slots are already booked',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amenities",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24.0,
            runSpacing: 14.0,
            children: widget.turf.amenities.map((amenity) {
              return _AmenityIcon(
                label: amenity,
                icon: _getAmenityIcon(amenity),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookTurf,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(double.infinity, 50),
          elevation: 5,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Book Now",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'Parking':
        return Icons.local_parking;
      case 'Restrooms':
        return Icons.wc;
      case 'Cafeteria':
        return Icons.fastfood;
      case 'Changing Rooms':
        return Icons.meeting_room;
      case 'Floodlights':
        return Icons.lightbulb;
      case 'Water':
        return Icons.water_drop;
      default:
        return Icons.help_outline;
    }
  }
}

class _AmenityIcon extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AmenityIcon({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
