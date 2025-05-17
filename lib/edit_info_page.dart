import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class EditInfoPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditInfoPage({Key? key, required this.userId, required this.userData})
      : super(key: key);

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late String goal;
  late String disease;
  late String foodPreference;
  late String allergies;
  late double height;
  late double weight;

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
    List<String> selectedDiseases = [];

  @override
  void initState() {
    super.initState();
    goal = widget.userData['goal'] ?? 'Maintain Weight';
  disease = widget.userData['disease'] ?? 'N/A';
    foodPreference = widget.userData['foodPreference'] ?? 'N/A';
    allergies = widget.userData['allergies'] ?? 'N/A';
    height = double.tryParse(widget.userData['height'] ?? '0.0') ?? 0.0;
    weight = double.tryParse(widget.userData['weight'] ?? '0.0') ?? 0.0;
    
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      try {
        await _firestore.collection('users').doc(widget.userId).update({
          'goal': goal,
          'disease': disease,
          'foodPreference': foodPreference,
          'allergies': allergies,  // may be empty
          'height': height,
          'weight': weight,
        });
        Navigator.pop(context); // Navigate back after saving changes
      } catch (e) {
        // Handle errors (e.g., connection issues, Firebase errors)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background and wave effect
          Container(
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
                // Wave background
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
                      color: const Color(0xFF360980).withOpacity(0.5),
                    ),
                  ),
                ),
                // Avatar and Header Text
                Positioned(
                  top: MediaQuery.of(context).padding.top + 30,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: const [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Edit Information',
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
                // Back and Save Buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: SafeArea(
                    child: IconButton(
                      icon:
                      const Icon(Icons.save, color: Colors.white, size: 28),
                      onPressed: _saveChanges,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form content
          Padding(
            padding: const EdgeInsets.only(top: 250), // Below the header
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildDropdownField(
                        label: 'Goal',
                        value: goal,
                        options: ['Lose Weight', 'Maintain Weight', 'Gain Weight'],
                        onChanged: (value) => setState(() => goal = value!),
                      ),
                              const SizedBox(height: 20),
      _buildDropdownField(
        label: 'Select Diseases',
        value: disease, // Display the comma-separated string from selectedDiseases
        options: _diseases, // The list of diseases
        onChanged: (value) {
          setState(() {
            // You can update the selectedDiseases list here if needed
            selectedDiseases = value != null ? value.split(', ') : [];
            disease = value ?? '';
          });
        },
      ),
      MultiSelectDialogField(
        title: Text('Select Your Disease(s)'),
        items: _diseases
            .map((disease) => MultiSelectItem(disease, disease))
            .toList(),
        initialValue: selectedDiseases,
        onConfirm: (values) {
          setState(() {
            selectedDiseases = values.cast<String>();
            disease = selectedDiseases.join(', ');
          });
        },
      ),
                      const SizedBox(height: 10),
                      _buildDropdownField(
                        label: 'Food Preferences',
                        value: foodPreference,
                        options: [
                          'N/A',
                          'Vegetarian',
                          'Gluten-Free',
                          'No Preferences'
                        ],
                        onChanged: (value) =>
                            setState(() => foodPreference = value!),
                      ),
                      const SizedBox(height: 10),
                      // Allergies is now optional
                      _buildTextField(
                        label: 'Allergies',
                        initialValue: allergies,
                        onSaved: (value) => allergies = value!,
                        isOptional: true,  // <--- pass "true" here
                      ),
                      const SizedBox(height: 10),
                      _buildNumericField(
                        label: 'Height (cm)',
                        initialValue: height.toString(),
                        onSaved: (value) => height = double.parse(value!),
                      ),
                      const SizedBox(height: 10),
                      _buildNumericField(
                        label: 'Weight (kg)',
                        initialValue: weight.toString(),
                        onSaved: (value) => weight = double.parse(value!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    // Ensure value is in the options list, else default to the first option
    if (!options.contains(value)) {
      value = options[0];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: onChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a valid option';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required void Function(String?) onSaved,
    bool isOptional = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: initialValue,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onSaved: onSaved,
                validator: (value) {
                  // If this field is optional, skip the "cannot be empty" check.
                  if (!isOptional && (value == null || value.isEmpty)) {
                    return 'This field cannot be empty';
                  }
                  return null; // Passes validation
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if the user input is within valid ranges for Height or Weight.
  Widget _buildNumericField({
    required String label,
    required String initialValue,
    required void Function(String?) onSaved,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: initialValue,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onSaved: onSaved,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }

                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }

                  // Range checks for Height or Weight
                  if (label == 'Height (cm)') {
                    if (number < 120 || number > 200) {
                      return 'Out of range';
                    }
                  } else if (label == 'Weight (kg)') {
                    if (number < 30 || number > 180) {
                      return 'Out of range';
                    }
                  }

                  return null; // Passes validation
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 20,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height - 40,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
