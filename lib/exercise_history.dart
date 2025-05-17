import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'favorite_exercise_plans_page.dart';

class ExerciseHistory extends StatefulWidget {
  const ExerciseHistory({super.key});

  @override
  State<ExerciseHistory> createState() => _ExerciseHistoryState();
}

class _ExerciseHistoryState extends State<ExerciseHistory> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _exercisePlans = [];

  Future<void> _fetchExerciseHistory() async {
    setState(() {
      _isLoading = true;
    });

    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('dailyWorkouts')
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          _exercisePlans = querySnapshot.docs.map((doc) {
            return {
              'timestamp': doc['timestamp'],
              'warmUp': doc['warmUp'] ?? [],
              'mainWorkout': doc['mainWorkout'] ?? [],
              'coolDown': doc['coolDown'] ?? [],
              'additionalNotes': doc['additionalNotes'] ?? [],
            };
          }).toList();
        });
      } catch (e) {
        print('Error fetching exercise history: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchExerciseHistory();
  }

  String _formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          _buildHeader(context),
          // Main Content
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_exercisePlans.isEmpty && !_isLoading)
                    _buildEmptyState(),
                  if (!_isLoading && _exercisePlans.isNotEmpty)
                    ..._exercisePlans.map((exercisePlan) {
                      final timestamp = _formatDate(exercisePlan['timestamp']);
                      return _buildExerciseCard(exercisePlan, timestamp);
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            color: Color(0xFF1F0051),
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'No exercise history found.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Start logging your workouts to track your progress!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercisePlan, String timestamp) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Title with Timestamp
            ExpansionTile(
              leading: const Icon(Icons.fitness_center, color:Color(0xFF1F0051)),
              title: Text(
                'Exercise Plan\n($timestamp)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Raleway",
                  color: Colors.black87,
                ),
              ),
              children: [
                // All exercises and notes inside the ExpansionTile
                _buildExerciseSection(
                  'Warm-Up',
                  exercisePlan['warmUp'],
                  Icons.directions_run,
                  color: Color(0xFF1F0051),
                ),

                const Divider(),
                _buildExerciseSection('Main Workout', exercisePlan['mainWorkout'], Icons.fitness_center, color: Color(0xFF1F0051)),
                const Divider(),
                _buildExerciseSection('Cool-Down', exercisePlan['coolDown'], Icons.directions_walk, color: Color(0xFF1F0051)),
                const SizedBox(height: 8),
                _buildExerciseDetail('Additional Notes:', exercisePlan['additionalNotes']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Exercise Section with ExpansionTile
  Widget _buildExerciseSection(String title, dynamic activities, IconData icon, {required Color color}) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      children: activities.isEmpty
          ? [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('- No activities found', style: TextStyle(fontSize: 14)),
        )
      ]
          : activities.map<Widget>((activity) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              // Replaced checkmark with dots
              const Icon(Icons.circle, size: 8, color: Colors.grey), // Circle as a dot
              const SizedBox(width: 8),
              Expanded(child: Text('- $activity', style: const TextStyle(fontSize: 14))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Additional Notes Section with ExpansionTile
  Widget _buildExerciseDetail(String title, dynamic activities) {
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
        const SizedBox(height: 8),
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('- No details available', style: TextStyle(fontSize: 14)),
          )
        else
          ...activities.map<Widget>((activity) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.star_outline, color: Colors.yellow), // Star outline for notes
                  const SizedBox(width: 8),
                  Expanded(child: Text('- $activity', style: const TextStyle(fontSize: 14))),
                ],
              ),
            );
          }).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF05ABC4), Color(0xFF286181)],
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
                color: const Color(0xFF1F0051).withOpacity(0.3),
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
                color: const Color(0xFF1F0051).withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // Adjust for status bar height
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white, size: 28),
              onPressed: () {
                final userId = _auth.currentUser?.uid ?? '';
                if (userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritePlansPage(userId: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in first')),
                  );
                }
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.fitness_center,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Exercise History',
                  style: TextStyle(
                    fontFamily: "Raleway",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
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
