import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_page.dart';
import 'user_info.dart';

class GeneralInfoPage extends StatefulWidget {
  final String userId;
  final UserInfo userInfo;

  const GeneralInfoPage({
    super.key,
    required this.userId,
    required this.userInfo,
  });

  @override
  _GeneralInfoPageState createState() => _GeneralInfoPageState();
}

class _GeneralInfoPageState extends State<GeneralInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // These final values go to Firestore
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedHeight;
  String? _selectedWeight;

  // Predefined lists
  final List<String> ageList =
  List.generate(86, (index) => (15 + index).toString());   // 15..100
  final List<String> heightList =
  List.generate(81, (index) => (120 + index).toString()); // 120..200
  final List<String> weightList =
  List.generate(151, (index) => (30 + index).toString()); // 30..180

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Use existing userInfo or defaults
    _selectedAge = widget.userInfo.age ?? '18';
    _selectedHeight = widget.userInfo.height ?? '150';
    _selectedWeight = widget.userInfo.weight ?? '50';
    _selectedGender = widget.userInfo.gender;
  }

  /// Shows a bottom sheet with a CupertinoPicker.
  ///   - [title] used at the top of the bottom sheet
  ///   - [items] is the list of strings to pick from
  ///   - [initialValue] is the currently selected item
  ///   - [onDone] callback with the new selection
  void _showNumberPicker({
    required String title,
    required List<String> items,
    required String initialValue,
    required ValueChanged<String> onDone,
  }) {
    final initialIndex = items.indexOf(initialValue);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // We'll store a temporary selection so user can scroll freely
        String tempSelected = initialValue;

        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // spacer
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Done button
                  TextButton(
                    onPressed: () {
                      // Return the chosen value
                      onDone(tempSelected);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                  FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (index) {
                    tempSelected = items[index];
                  },
                  children: items.map((value) {
                    return Center(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToNextPage() async {
    if (_isSubmitting) return; // Prevent double presses
    _isSubmitting = true;

    // Check the form + gender
    if (_formKey.currentState!.validate() && _selectedGender != null) {
      // Save to userInfo
      widget.userInfo
        ..age = _selectedAge
        ..height = _selectedHeight
        ..weight = _selectedWeight
        ..gender = _selectedGender;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set(
          widget.userInfo.toMap(),
          SetOptions(merge: true),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodPage(
              userId: widget.userId,
              userInfo: widget.userInfo,
            ),
          ),
        ).then((_) => _isSubmitting = false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
        _isSubmitting = false;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select your gender'),
        ),
      );
      _isSubmitting = false;
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
                      Color(0xFF05ABC4),// Softer green
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

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white54,
                  size: 26,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Main Content
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
                          key: _formKey,
                          child: Column(
                            children: [
                              const Text(
                                'Personal Information',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 22,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Age Row
                              _buildSelectableRow(
                                label: 'Age',
                                value: _selectedAge ?? '',
                                onTap: () => _showNumberPicker(
                                  title: 'Select Age',
                                  items: ageList,
                                  initialValue: _selectedAge ?? '18',
                                  onDone: (newVal) {
                                    setState(() {
                                      _selectedAge = newVal;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Gender Dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ],
                                value: _selectedGender,
                                onChanged: (value) {
                                  setState(() => _selectedGender = value);
                                },
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Select gender';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Height Row
                              _buildSelectableRow(
                                label: 'Height (cm)',
                                value: _selectedHeight ?? '',
                                onTap: () => _showNumberPicker(
                                  title: 'Select Height',
                                  items: heightList,
                                  initialValue: _selectedHeight ?? '150',
                                  onDone: (newVal) {
                                    setState(() {
                                      _selectedHeight = newVal;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Weight Row
                              _buildSelectableRow(
                                label: 'Weight (kg)',
                                value: _selectedWeight ?? '',
                                onTap: () => _showNumberPicker(
                                  title: 'Select Weight',
                                  items: weightList,
                                  initialValue: _selectedWeight ?? '50',
                                  onDone: (newVal) {
                                    setState(() {
                                      _selectedWeight = newVal;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

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
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(color: Colors.white, fontSize: 18),
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

  /// Reusable widget that shows label + chosen value,
  /// and triggers the bottom sheet picker on tap.
  Widget _buildSelectableRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value.isEmpty ? 'Tap to select' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for the Header's Curved Design
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
