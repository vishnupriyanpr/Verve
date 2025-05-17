import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteNutritionPlansPage extends StatefulWidget {
  final String userId;

  // Custom constructor to pass data
  const FavoriteNutritionPlansPage({Key? key, required this.userId})
      : super(key: key);

  @override
  _FavoriteNutritionPlansPageState createState() =>
      _FavoriteNutritionPlansPageState();
}

class _FavoriteNutritionPlansPageState
    extends State<FavoriteNutritionPlansPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<DocumentSnapshot> _favoritePlans = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritePlans();
  }

  // Load favorite plans from Firestore
  Future<void> _loadFavoritePlans() async {
    setState(() {
      _isLoading = true;
    });

    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final favoritePlansRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('favoritesNutritionPlans');

        final querySnapshot = await favoritePlansRef.get();
        print('Loaded ${querySnapshot.docs.length} favorite plans.');
        setState(() {
          _favoritePlans = querySnapshot.docs;
        });
      } catch (e) {
        print('Error loading favorite plans: $e');
      }
    } else {
      print('No user logged in');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF76D7C4), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      height: 100,
                      color: const Color(0xFF008080).withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      height: 80,
                      color: const Color(0xFF008080).withOpacity(0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 30,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.fastfood_outlined,
                          size: 50,
                          color: Colors.teal,
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        'Favorite Nurtition Plans',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: "Raleway",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Section
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_favoritePlans.isEmpty && !_isLoading)
                    const Center(child: Text('No favorite plans yet.')),
                  if (!_isLoading && _favoritePlans.isNotEmpty)
                    ..._favoritePlans.map((plan) {
                      return _buildFavoritePlanCard(plan);
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritePlanCard(DocumentSnapshot plan) {
    final data = plan.data() as Map<String, dynamic>?;

    // Safely access fields with default values
    final timestamp = data != null && data.containsKey('timestamp')
        ? (data['timestamp'] as Timestamp).toDate().toString()
        : 'Unknown Date';
    final Breakfast = data != null &&
        data.containsKey('Breakfast') &&
        data['Breakfast'] is List
        ? data['Breakfast']
        : [];
    final Dinner =
    data != null && data.containsKey('Dinner') && data['Dinner'] is List
        ? data['Dinner']
        : [];
    final Snack =
    data != null && data.containsKey('Snack') && data['Snack'] is List
        ? data['Snack']
        : [];
    final Lunch =
    data != null && data.containsKey('Lunch') && data['Lunch'] is List
        ? data['Lunch']
        : [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ExpansionTile(
                title: Text(
                  'Nutrition Plan - $timestamp',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                children: [
                  _buildDetailSection('Breakfast:', Breakfast),
                  _buildDetailSection('Lunch:', Lunch),
                  _buildDetailSection('Snack:', Snack),
                  _buildDetailSection('Dinner:', Dinner),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFromFavorites(plan.id),
            ),
          ],
        ),
      ),
    );
  }

  // Remove a plan from favorites
  Future<void> _removeFromFavorites(String planId) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final planRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('favoritesNutritionPlans')
            .doc(planId);

        await planRef.delete();
        setState(() {
          _favoritePlans.removeWhere((plan) => plan.id == planId);
        });
        print('Plan removed from favorites');
      } catch (e) {
        print('Error removing plan from favorites: $e');
      }
    }
  }

  Widget _buildDetailSection(String title, dynamic details) {
    if (details == null || (details is List && details.isEmpty)) {
      return Text(
        '$title No details available.',
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      );
    }

    if (details is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ...details.map<Widget>((detail) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('- $detail', style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          const SizedBox(height: 10),
        ],
      );
    }

    // Fallback for non-list details
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$title $details',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
// Custom Clipper for Wave Background
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 * size.width / 4, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}