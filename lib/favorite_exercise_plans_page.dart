import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritePlansPage extends StatefulWidget {
  final String userId;

  // Custom constructor to pass data
  const FavoritePlansPage({super.key, required this.userId});

  @override
  _FavoritePlansPageState createState() => _FavoritePlansPageState();
}

class _FavoritePlansPageState extends State<FavoritePlansPage> {
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
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('favoritesExercisePlans');

        final querySnapshot = await favoritePlansRef.get();
        setState(() {
          _favoritePlans = querySnapshot.docs;
        });
      } catch (e) {
        print('Error loading favorite plans: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Remove a plan from favorites
  Future<void> _deleteEntirePlan(String planId) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final favoritePlansRef = _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('favoritesExercisePlans');

        await favoritePlansRef.doc(planId).delete();

        setState(() {
          _favoritePlans.removeWhere((plan) => plan.id == planId);
        });

        print('Plan $planId deleted successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted successfully.')),
        );
      } catch (e) {
        print('Error deleting plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting plan.')),
        );
      }
    }
  }

  Widget _buildFavoritePlanCard(DocumentSnapshot plan) {
    final timestamp = (plan['timestamp'] as Timestamp).toDate().toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              title: Text(
                'Exercise Plan - $timestamp',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              children: [
                _buildExerciseDetail('Warm-Up:', plan['warmUp']),
                _buildExerciseDetail('Main Workout:', plan['mainWorkout']),
                _buildExerciseDetail('Cool-Down:', plan['coolDown']),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteEntirePlan(plan.id),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(String title, dynamic activities) {
    if (activities is List) {
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
          ...activities.map<Widget>((activity) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('- $activity', style: const TextStyle(fontSize: 14)),
            );
          }),
          const SizedBox(height: 10),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          Container(
            height: 250,
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white,size: 28),
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
                          Icons.fitness_center,
                          size: 50,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Favorite Exercise Plans',
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
                  // Loading Indicator
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  // No Data Message
                  if (_favoritePlans.isEmpty && !_isLoading)
                    const Center(child: Text('No favorite plans yet.')),
                  // Favorite Plans List
                  if (!_isLoading && _favoritePlans.isNotEmpty)
                    ..._favoritePlans.map((plan) {
                      return _buildFavoritePlanCard(plan);
                    }),
                ],
              ),
            ),
          ),
        ],
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
