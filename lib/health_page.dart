import 'package:flutter/material.dart';
import 'generalinfo_page.dart';
import 'user_info.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class HealthPage extends StatefulWidget {
  final String userId;
  final UserInfo userInfo;

  const HealthPage({
    Key? key,
    required this.userId,
    required this.userInfo,
  }) : super(key: key);

  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
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

  String? _selectedGoal;
  List<String> selectedDiseases = [];

  void _goToNextPage() {
    if (selectedDiseases.isNotEmpty && _selectedGoal != null) {
      widget.userInfo.disease = selectedDiseases.join(", "); // Store selected diseases as a string
      widget.userInfo.goal = _selectedGoal;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GeneralInfoPage(userId: widget.userId, userInfo: widget.userInfo),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your disease(s) and goal')),
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
                      fontFamily: 'Rowdies',
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
              child: Tooltip(
                message: "Go Back",
                child: IconButton(
                  icon: const Icon(
                      Icons.arrow_back, color: Colors.white54, size: 26),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
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
                        child: Form(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Health Information',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 22,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Provide us with your health information to live a healthy and happy life!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              MultiSelectDialogField(
                                title: Text('Select Your Disease(s)'),
                                items: _diseases
                                    .map((disease) =>
                                        MultiSelectItem(disease, disease))
                                    .toList(),
                                initialValue: selectedDiseases,
                                onConfirm: (values) {
                                  setState(() {
                                    selectedDiseases = values.cast<String>();
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Your Goal',
                                  border: OutlineInputBorder(),
                                ),
                                items: _goals.map((goal) {
                                  return DropdownMenuItem<String>(
                                    value: goal,
                                    child: Text(goal),
                                  );
                                }).toList(),
                                value: _selectedGoal,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGoal = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _goToNextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF286181),
                                    elevation: 10,
                                    shadowColor: Colors.black.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
