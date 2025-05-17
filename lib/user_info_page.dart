import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class UserInfoPage extends StatefulWidget {
  final String userId;

  const UserInfoPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _diseases = [
    'Diabetes',
    'Hypertension',
    'High Cholesterol',
    'Arthritis',
    'Back pain',
    'Osteoporosis',
    'Asthma',
    'Obesity',
    'Sleep Disorder',
    'Normal'
  ];

  final List<String> _goals = ['Lose Weight', 'Maintain Weight', 'Gain Weight'];
  final List<String> _foodPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'No Preferences'
  ];

  String? _selectedDisease;
  String? _selectedGoal;
  String? _selectedPreference;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submitUserInfo() async {
    if (_formKey.currentState!.validate() &&
        _selectedDisease != null &&
        _selectedGoal != null &&
        _selectedPreference != null) {
      try {
        await _firestore.collection('users').doc(widget.userId).set({
          'age': int.tryParse(_ageController.text.trim()),
          'height': double.tryParse(_heightController.text.trim()),
          'weight': double.tryParse(_weightController.text.trim()),
          'disease': _selectedDisease,
          'goal': _selectedGoal,
          'foodPreference': _selectedPreference,
          'allergies': _allergyController.text.trim(),
        });

        // Navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF05ABC4), Color(0xFF286181)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1F0051), Color(0xFF05ABC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'User Information',
                        style: TextStyle(
                          fontFamily: 'WtfHorselandDemo',
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your age' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _heightController,
                      decoration:
                          const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your height' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _weightController,
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your weight' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Disease'),
                      items: _diseases
                          .map((disease) => DropdownMenuItem<String>(
                                value: disease,
                                child: Text(disease),
                              ))
                          .toList(),
                      value: _selectedDisease,
                      onChanged: (value) {
                        setState(() {
                          _selectedDisease = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a disease' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Goal'),
                      items: _goals
                          .map((goal) => DropdownMenuItem<String>(
                                value: goal,
                                child: Text(goal),
                              ))
                          .toList(),
                      value: _selectedGoal,
                      onChanged: (value) {
                        setState(() {
                          _selectedGoal = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a goal' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Food Preference'),
                      items: _foodPreferences
                          .map((preference) => DropdownMenuItem<String>(
                                value: preference,
                                child: Text(preference),
                              ))
                          .toList(),
                      value: _selectedPreference,
                      onChanged: (value) {
                        setState(() {
                          _selectedPreference = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a preference' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _allergyController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies (Optional)',
                        hintText: 'Write if any',
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF05ABC4), // Turquoise color
                          elevation: 10, // Shadow effect
                          shadowColor:
                              Colors.black.withOpacity(0.7), // Shadow color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Submet',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
