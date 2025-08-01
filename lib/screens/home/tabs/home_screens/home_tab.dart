import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turf_client/constants/assets.dart';
import 'package:turf_client/models/turf.dart';
import 'package:turf_client/screens/home/tabs/home_screens/subscription_scree.dart';
import 'package:turf_client/screens/home/tabs/home_screens/turf_details.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedSport = "All";
  int _currentPage = 0;
  List<Turf> turfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
  }

  Future<void> _fetchTurfs() async {
    try {
      final snapshot = await _firestore.collection('turfs').get();
      final List<Turf> fetchedTurfs = snapshot.docs.map((doc) {
        final data = doc.data();
        return Turf(
          id: doc.id,
          name: data['name'] ?? 'No Name',
          description: data['description'] ?? 'No Description',
          location: data['location'] ?? 'No Location',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          sports: List<String>.from(data['sports'] ?? []),
          imageUrl: data['imageUrl'] ?? Assets.turfImage,
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          amenities: List<String>.from(data['amenities'] ?? []),
          phoneNumber: data['phoneNumber'] ?? 'No Phone',
          ownerId: data['ownerId'] ?? 'No Owner',
        );
      }).toList();

      setState(() {
        turfs = fetchedTurfs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching turfs: ${e.toString()}')),
      );
    }
  }

  void _selectSport(String sport) {
    setState(() {
      _selectedSport = sport;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location and Search Bar
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    "Nashik",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search turf",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Great Offers Section
              Text(
                "Great Offers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                height: 150,
                child: PageView.builder(
                  itemCount: asd.length,
                  controller: PageController(viewportFraction: 0.9),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(asd[index]),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.green[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(asd.length, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? Colors.green
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 24),

              // Subscription Plan Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SubscriptionScreen()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[800]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PREMIUM MEMBERSHIP",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Play at any turf for a year",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Just ₹4999/-",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Venues Section
              Text(
                "Venues around you",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip("All"),
                    _buildChip("Cricket"),
                    _buildChip("Football"),
                    _buildChip("Badminton"),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Venues List
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : turfs.isEmpty
                      ? Center(child: Text("No turfs available"))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _getFilteredTurfs().length,
                          itemBuilder: (context, index) {
                            final turf = _getFilteredTurfs()[index];
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              TurfDetailsPage(turf: turf)),
                                    );
                                  },
                                  child: _buildVenueCard(turf),
                                ),
                                SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedSport == label,
        onSelected: (bool selected) {
          _selectSport(label);
        },
        selectedColor: Colors.green,
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildVenueCard(Turf turf) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: turf.imageUrl.startsWith('http')
                  ? Image.network(turf.imageUrl, fit: BoxFit.cover)
                  : Image.asset(turf.imageUrl, fit: BoxFit.cover),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turf.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(turf.rating.toString()),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(turf.location),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: turf.sports.map((sport) {
                      return Text(_getSportEmoji(sport));
                    }).toList(),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "₹${turf.price}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSportEmoji(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return '🏏';
      case 'football':
        return '⚽';
      case 'badminton':
        return '🏸';
      default:
        return sport;
    }
  }

  List<Turf> _getFilteredTurfs() {
    if (_selectedSport == "All") {
      return turfs;
    } else {
      return turfs
          .where((turf) => turf.sports.contains(_selectedSport))
          .toList();
    }
  }
}
