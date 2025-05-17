import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'user_info.dart';

class FoodPage extends StatefulWidget {
  final String userId;
  final UserInfo userInfo;

  const FoodPage({Key? key, required this.userId, required this.userInfo}) : super(key: key);

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final List<String> _foodPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'No Preferences',
  ];
  final TextEditingController _allergyController = TextEditingController();
  String? _selectedFoodPreference;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmitting = false;

  Future<void> _submitUserInfo() async {
    if (_isSubmitting) return;

    if (_selectedFoodPreference != null) {
      setState(() => _isSubmitting = true);

      widget.userInfo.foodPreference = _selectedFoodPreference;
      widget.userInfo.allergies = _allergyController.text.trim();

      try {
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .set(widget.userInfo.toMap(), SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your food preference')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Header with Wave Design
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1F0051), // Teal
                      Color(0xFF05ABC4), // Softer green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'VERVE',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 26),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            // Page Content
            Column(
              children: [
                const SizedBox(height: 200),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Food Preferences',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 22,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Help us tailor your experience by providing your dietary information.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Your Food Preference',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                // filled: true,
                                // fillColor: Colors.grey[100],
                              ),
                              items: _foodPreferences.map((preference) {
                                return DropdownMenuItem<String>(
                                  value: preference,
                                  child: Text(preference),
                                );
                              }).toList(),
                              value: _selectedFoodPreference,
                              onChanged: (value) {
                                setState(() {
                                  _selectedFoodPreference = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _allergyController,
                              decoration: InputDecoration(
                                labelText: 'Food Allergies (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                // filled: true,
                                // fillColor: Colors.grey[100],
                              ),
                              maxLines: 3,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitUserInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSubmitting
                                    ? Colors.grey
                                    : const Color(0xFF286181),
                                elevation: 10,
                                shadowColor: Colors.black.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height, // Control point
      size.width, size.height - 50, // End at bottom-right
    );
    path.lineTo(size.width, 0); // Top-right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
