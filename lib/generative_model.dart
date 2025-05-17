// TODO Implement this library.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class Nutrition extends StatefulWidget {
  const Nutrition({super.key});

  @override
  State<Nutrition> createState() => _NutritionState();
}

class _NutritionState extends State<Nutrition> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, dynamic> userData = {
    'name': 'N/A',
    'email': 'N/A',
    'healthCondition': 'N/A',
    'foodPreferences': 'N/A',
    'allergies': 'N/A',
    'height': 'N/A',
    'weight': 'N/A',
    'goal': 'N/A',
  };

  List<Map<String, dynamic>> _mealsAndRecipes = [];
  List<String> _nutritionTips = [];

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userData = {
            'name': user.displayName ?? 'N/A',
            'email': user.email ?? 'N/A',
            'healthCondition': data?['healthCondition'] ?? 'N/A',
            'foodPreferences': data?['foodPreferences'] ?? 'N/A',
            'allergies': data?['allergies'] ?? 'N/A',
            'height': (data?['height'] ?? 'N/A').toString(),
            'weight': (data?['weight'] ?? 'N/A').toString(),
            'goal': data?['goal'] ?? 'N/A',
          };
        });
      }
    }
  }

  Future<void> _generateNutritionPlan() async {
    setState(() {
      _isLoading = true;
    });

    final gemini = Gemini.instance;
    final prompt = _buildPrompt();

    try {
      final response = await gemini.text(prompt);

      if (response?.output != null) {
        _printFullResponse(response!.output!);

        // Clean up and parse the JSON response

        String cleanedResponse = response.output!
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '');
        final Map<String, dynamic> data = jsonDecode(cleanedResponse);
        setState(() {
          // Process mealsAndRecipes
          if (data.containsKey('mealsAndRecipes')) {
            final List<dynamic> mealsAndRecipes = data['mealsAndRecipes'];

            _mealsAndRecipes = mealsAndRecipes
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else {
            throw Exception('Invalid data format: "mealsAndRecipes" missing.');
          }

          // Process nutritionTips
          if (data.containsKey('nutritionTips')) {
            _nutritionTips = List<String>.from(data['nutritionTips']);
          } else {
            throw Exception('Invalid data format: "nutritionTips" missing.');
          }
        });
      } else {
        throw Exception('No output from Gemini.');
      }
    } catch (e) {
      print('Error generating workout plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _printFullResponse(String response) {
    const chunkSize = 800;
    for (var i = 0; i < response.length; i += chunkSize) {
      print(response.substring(i,
          i + chunkSize > response.length ? response.length : i + chunkSize));
    }
  }

  String _buildPrompt() {
    return """
  Create a detailed and structured nutrition plan tailored for an individual based on the following details:
  - **Age**: ${userData['age']}
  - **Allergies**: ${userData['allergies']}
  - **Height**: ${userData['height']}
  - **Weight**: ${userData['weight']}
  - **Goal**: ${userData['goal']}
  - **Food Preferences**: ${userData['foodPreferences']}
  
  The nutrition plan should include:
  1. **Main Meals**:
     - Each meal should include a name, a brief description, and key ingredients. 
     - Format meals as a list of strings, where each string represents a meal with its name, description, and recipe details.

  2. **Nutrition Tips**:
     - Provide a list of actionable and practical nutrition tips.
     - Each tip should be concise and focused on promoting healthy eating habits and achieving the specified goal.
  
  **Output Format**:
  Return the response as a JSON object with the following keys:
  - **mealsAndRecipes**: An array of objects where each object has a key `"meal"` containing an array of strings for each meal.
  - **nutritionTips**: An array of strings with each string representing a nutrition tip.
  
  **Example Output**:
  ```json
  {
    "mealsAndRecipes": [
      {
        "meal": [
          "Saturday",
          "Breakfast: Oatmeal with berries and a sprinkle of nuts (1/2 cup rolled oats, 1/2 cup mixed berries, 1 tablespoon chopped nuts).",
          "Lunch: Large salad with grilled chicken, mixed greens, and a light vinaigrette dressing.",
          "Dinner: Baked salmon with steamed broccoli and quinoa."
        ]
      },
      {
        "meal": [
          "Sunday",
          "Breakfast: Greek yogurt with berries and chia seeds.",
          "Lunch: Turkey sandwich with whole-grain bread and vegetables.",
          "Dinner: Grilled chicken stir-fry with mixed vegetables and brown rice."
        ]
      }
    ],
    "nutritionTips": [
      "Focus on whole, unprocessed foods.",
      "Control portion sizes.",
      "Choose lean protein sources.",
      "Incorporate fiber-rich foods.",
      "Spread carbohydrate intake throughout the day."
    ]
    """;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) {
      _generateNutritionPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Plan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meals and Recipes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._mealsAndRecipes.map((meal) {
                    final mealDetails = meal['meal'] as List<dynamic>;
                    final day =
                        mealDetails.isNotEmpty ? mealDetails.first : 'Day';
                    final meals = mealDetails.skip(1).toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...meals.map((detail) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text('- $detail'),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text(
                    'Nutrition Tips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._nutritionTips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('- $tip'),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}