import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'progress_provider.dart';

// If you have a separate HistoryPage for the plan history
import 'nutritionHistoryPage.dart';

final Map<String, Map<String, List<Map<String, dynamic>>>> localMeals = {
  'Diabetes': {
    'Breakfast': [
      {
        "name": "Foul Medames",
        "calories": 150,
        "protein": 10,
        "carbs": 20,
        "fat": 5,
        "ingredients": [
          "Fava beans: 1 cup",
          "Olive oil: 1 tbsp",
          "Lemon juice: 1 tbsp",
          "Garlic: 1 clove",
          "Whole-grain pita bread: 1 slice"
        ],
        "description":
            "Fava beans with olive oil, lemon juice, and garlic, served with whole-grain pita bread.",
        "preparation":
            "1. Cook fava beans. 2. Mix with olive oil, lemon juice, and garlic. 3. Serve with pita bread."
      },
      // Add more breakfast items...
    ],
    'Lunch': [
      {
        "name": "Grilled Hammour with Quinoa Salad",
        "calories": 400,
        "protein": 30,
        "carbs": 50,
        "fat": 15,
        "ingredients": [
          "Hammour: 1 fillet",
          "Quinoa: 1 cup",
          "Parsley: 1/4 cup",
          "Pomegranate: 1/4 cup"
        ],
        "description":
            "Grilled local fish with a side of quinoa, parsley, and pomegranate.",
        "preparation":
            "1. Grill the hammour. 2. Cook quinoa. 3. Mix quinoa with parsley and pomegranate. 4. Serve with grilled hammour."
      },
      // Add more lunch items...
    ],
    'Dinner': [
      {
        "name": "Vegetable Gratin",
        "calories": 300,
        "protein": 20,
        "carbs": 40,
        "fat": 10,
        "ingredients": [
          "Zucchini: 1",
          "Eggplant: 1",
          "Tomato: 1",
          "Low-fat cheese: 1/4 cup"
        ],
        "description":
            "A mix of zucchini, eggplant, and tomato baked with a sprinkle of low-fat cheese.",
        "preparation":
            "1. Slice vegetables. 2. Layer in a baking dish. 3. Sprinkle with cheese. 4. Bake at 350°F for 30 minutes."
      },
      // Add more dinner items...
    ],
    'Snack': [
      {
        "name": "Stuffed Grape Leaves (Wara Enab)",
        "calories": 100,
        "protein": 5,
        "carbs": 15,
        "fat": 3,
        "ingredients": [
          "Grape leaves: 10",
          "Quinoa: 1/2 cup",
          "Tomatoes: 1/4 cup",
          "Herbs: 1 tbsp"
        ],
        "description": "Grape leaves filled with quinoa, tomatoes, and herbs.",
        "preparation":
            "1. Prepare grape leaves. 2. Mix quinoa, tomatoes, and herbs. 3. Stuff grape leaves. 4. Steam for 10 minutes."
      },
      // Add more snack items...
    ]
  },
  'High Cholesterol': {
    'Breakfast': [
      {
        "name": "Whole-wheat bread with low-fat labneh and mint",
        "calories": 200,
        "protein": 12,
        "carbs": 25,
        "fat": 7,
        "ingredients": [
          "Whole-wheat bread: 1 slice",
          "Low-fat labneh: 2 tbsp",
          "Mint leaves: 5"
        ],
        "description":
            "A light and satisfying breakfast with creamy labneh, mint leaves, and wholesome whole-wheat bread.",
        "preparation": "1. Spread labneh on bread. 2. Top with mint leaves."
      },
      // Add more breakfast items...
    ],
    // Add more meal types...
  },
  'Hypertension': {
    'Breakfast': [
      {
        "name": "Whole-wheat bread with olive oil and tomato slices",
        "calories": 150,
        "protein": 10,
        "carbs": 20,
        "fat": 5,
        "ingredients": [
          "Whole-wheat bread: 1 slice",
          "Olive oil: 1 tbsp",
          "Tomato: 1 slice"
        ],
        "description":
            "A light and wholesome start with whole-wheat bread drizzled with olive oil and fresh tomato slices.",
        "preparation": "1. Drizzle olive oil on bread. 2. Add tomato slices."
      },
      // Add more breakfast items...
    ],
    // Add more meal types...
  }
};

class Nutrition extends StatefulWidget {
  const Nutrition({Key? key}) : super(key: key);

  @override
  State<Nutrition> createState() => _NutritionState();
}

class _NutritionState extends State<Nutrition> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isFavorited = false;

  /// User data fetched from Firestore,
  /// used ONLY for AI prompt (not shown in the interface)
  Map<String, dynamic> userData = {
    'name': 'N/A',
    'email': 'N/A',
    'disease': 'N/A',
    'foodPreference': 'N/A',
    'allergies': 'N/A',
    'height': 'N/A',
    'weight': 'N/A',
    'goal': 'N/A',
  };

  // Meals for a single day
// Updated meals for a single day
  Map<String, List<Map<String, dynamic>>> _meals = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snack': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) async {
      final planExists = await _fetchExistingPlan();
      if (!planExists) {
        _generateNutritionPlan();
      }
    });
  }

  /// Fetch user info from Firestore (not displayed, only used for prompt)
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            // Also fetch name/email from Firebase Auth user
            userData['name'] = user.displayName ?? 'N/A';
            userData['email'] = user.email ?? 'N/A';

            userData['disease'] = data['disease'] ?? 'N/A';
            userData['foodPreference'] = data['foodPreference'] ?? 'N/A';
            userData['allergies'] = data['allergies'] ?? 'N/A';
            userData['height'] = (data['height'] ?? 'N/A').toString();
            userData['weight'] = (data['weight'] ?? 'N/A').toString();
            userData['gender'] = data['gender'] ?? 'N/A';
            userData['age'] = data['age'] ?? 'N/A';
            userData['goal'] = data['goal'] ?? 'N/A';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  /// Check if a plan already exists
  Future<bool> _fetchExistingPlan() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('nutritionPlans')
          .doc(user.uid)
          .collection('dailyMeals')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          _meals['Breakfast'] =
              List<Map<String, dynamic>>.from(doc['Breakfast'] ?? []);
          _meals['Lunch'] = List<Map<String, dynamic>>.from(doc['Lunch'] ?? []);
          _meals['Dinner'] =
              List<Map<String, dynamic>>.from(doc['Dinner'] ?? []);
          _meals['Snack'] = List<Map<String, dynamic>>.from(doc['Snack'] ?? []);
        });
        return true;
      }
    }
    return false;
  }

  /// Generate a new plan or regenerate a specific meal via Gemini (AI), automatically saved
  /// Generate a new plan or regenerate a specific meal via Gemini (AI), automatically saved
  Future<void> _generateNutritionPlan(
      {String? mealType, String? feedback}) async {
    setState(() {
      _isLoading = true;
      _isFavorited = false;
    });

// Access the ProgressProvider directly
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    final gemini = Gemini.instance;

    // Fetch favorite plans to include in the prompt
    final favoritePlans = await _fetchFavoritePlans();
    final previousPlans = await _fetchUserPlans();
    final feedbacks = await _fetchFeedback();

    final prompt = mealType != null
        ? _buildPromptForMeal(
            mealType,
            feedback: feedback,
            feedbacks: feedbacks,
            favoritePlans: favoritePlans,
          )
        : _buildPrompt(
            feedback: feedback,
            feedbacks: feedbacks,
            favoritePlans: favoritePlans,
            previousPlans: previousPlans);

    try {
      final response = await gemini.text(prompt);
      if (response?.output != null) {
        final cleanedResponse = response!.output!
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanedResponse);

        setState(() {
          if (mealType != null) {
            _meals[mealType] =
                List<Map<String, dynamic>>.from(data[mealType] ?? []);
            progressProvider.toggleTask(mealType, false);
          } else {
            _meals = {
              'Breakfast':
                  List<Map<String, dynamic>>.from(data['Breakfast'] ?? []),
              'Lunch': List<Map<String, dynamic>>.from(data['Lunch'] ?? []),
              'Dinner': List<Map<String, dynamic>>.from(data['Dinner'] ?? []),
              'Snack': List<Map<String, dynamic>>.from(data['Snack'] ?? []),
            };
            progressProvider.toggleTask('Breakfast', false);
            progressProvider.toggleTask('Lunch', false);
            progressProvider.toggleTask('Dinner', false);
          }
        });

        await _saveMealsToFirestore();
      } else {
        throw Exception('No output received from Gemini.');
      }
    } catch (e) {
      print('Error generating nutrition plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>?> _fetchUserPlans() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('dailyMeals')
            .orderBy('timestamp', descending: true)
            .limit(7)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Initialize an empty map to store all meal types
          final Map<String, List<Map<String, dynamic>>> allPlans = {
            'Breakfast': [],
            'Lunch': [],
            'Dinner': [],
            'Snack': [],
          };

          // Iterate through each document and aggregate the data
          for (var doc in querySnapshot.docs) {
            final data = doc.data();

            allPlans['Breakfast']?.addAll(
                List<Map<String, dynamic>>.from(data['Breakfast'] ?? []));
            allPlans['Lunch']
                ?.addAll(List<Map<String, dynamic>>.from(data['Lunch'] ?? []));
            allPlans['Dinner']
                ?.addAll(List<Map<String, dynamic>>.from(data['Dinner'] ?? []));
            allPlans['Snack']
                ?.addAll(List<Map<String, dynamic>>.from(data['Snack'] ?? []));
          }
          print('Document w data: $allPlans');
          return allPlans;
        }
      } catch (e) {
        print('Error fetching preveous plans: $e');
      }
    }
    return null; // No favorite plans found
  }

  Future<Map<String, List<Map<String, dynamic>>>?> _fetchFavoritePlans() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('favoritesNutritionPlans')
            .orderBy('timestamp', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Initialize an empty map to store all meal types
          final Map<String, List<Map<String, dynamic>>> allPlans = {
            'Breakfast': [],
            'Lunch': [],
            'Dinner': [],
            'Snack': [],
          };

          // Iterate through each document and aggregate the data
          for (var doc in querySnapshot.docs) {
            final data = doc.data();

            allPlans['Breakfast']?.addAll(
                List<Map<String, dynamic>>.from(data['Breakfast'] ?? []));
            allPlans['Lunch']
                ?.addAll(List<Map<String, dynamic>>.from(data['Lunch'] ?? []));
            allPlans['Dinner']
                ?.addAll(List<Map<String, dynamic>>.from(data['Dinner'] ?? []));
            allPlans['Snack']
                ?.addAll(List<Map<String, dynamic>>.from(data['Snack'] ?? []));
          }
          print('Document data: $allPlans');
          return allPlans;
        }
      } catch (e) {
        print('Error fetching favorite plans: $e');
      }
    }
    return null; // No favorite plans found
  }

  Future<void> _storeFeedback(String mealType, String feedback) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('nutritionFeedback')
            .add({
          'mealType': mealType,
          'feedback': feedback,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Feedback saved successfully!');
      } catch (e) {
        print('Error saving feedback: $e');
      }
    } else {
      print('User not logged in!');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFeedback() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Query the Firestore collection for feedback
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('nutritionFeedback')
            .orderBy('timestamp', descending: true)
            .get();

        // Convert the documents into a list of maps
        List<Map<String, dynamic>> feedbackList = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id, // Document ID
            'mealType': doc['mealType'], // Meal type
            'feedback': doc['feedback'], // Feedback content
            'timestamp': (doc['timestamp'] as Timestamp).toDate(), // DateTime
          };
        }).toList();

        print('Feedback fetched successfully!');
        return feedbackList;
      } catch (e) {
        print('Error fetching feedback: $e');
        return [];
      }
    } else {
      print('User not logged in!');
      return [];
    }
  }

  Future<String?> _showFeedbackDialog(
    BuildContext context,
    String mealType,
  ) async {
    TextEditingController feedbackController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Feedback for $mealType'),
          content: TextField(
            controller: feedbackController,
            decoration: const InputDecoration(
              labelText: 'Why are you regenerating this?',
              hintText: 'Provide your feedback (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                final feedback = feedbackController.text;
                Navigator.of(context).pop(feedback); // Submit feedback
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    ).then((feedback) {
      if (feedback != null && feedback.isNotEmpty) {
        _storeFeedback(mealType, feedback); // Save feedback to Firestore
      }
      return feedback;
    });
  }

  final String imagePaths = '''
images/cinnamon_toast.png,
images/coleslaw.jpg,
images/smoothie.jpg,
images/yogurt.jpg,
images/smoothie1.jpg,
images/yogurtWithCinnamon.jpg,
images/labneh.jpg,
images/Chicken-Kabsa.jpg,
images/LentilSoup.jpg,
images/AppleWithAlmondButter.jpg,
images/oatmeal.jpg,
images/fishWithBbrownRice.jpg,
images/VegetableSoup.jpg,
images/porridge.jpeg,
images/Gareesh.jpeg,
images/snackk.jpg,
images/Breakfastt.jpeg,
images/roastedSalmonWithVegetables.jpeg,
images/checkenAndVegetabls.jpg,
images/nutsAndSeeds.webp,
images/chickenSaladAndWholeWheatPita.webp,
images/YogurtAndBluberry.jpeg,
images/yogurt.jpg,
images/vegetabls.jpeg,
images/potatos.jpeg,
images/EggplanFattehWithYogurt.jpg,
images/Margoug.jpg,
images/Goursan.png,
images/LabanOrMilk with Dates.jpg,
images/TabboulehSalad.jpg,
images/Foul.jpg,
images/labneh with olive oil and za'atar.webp,
images/Grilled liver.jpg,
images/Pumpkin soup with vegetables and chicken.jpg,
images/ Hummus with tahini.jpg,
images/Cottage-Cheese-with-Tomatoes-and-Pepitas.jpg,
images/Chicken Saliq .jpg,
images/Yogurt cucumber salad.jpg,
images/Boiled eggs with whole-grain bread and cucumber.jpeg,
images/Machkhool.jpg,
images/Oat soup.png,
images/Mathloutha.jpeg,
images/Fattoush salad.jpg,
images/Grilled fish.jpg,
images/Oats with low-fat milk and a sprinkle of cinnamon..jpg,
images/scrambled-eggs.jpg,
images/Rice.jpg,
images/pasta.webp,
images/Lunch.png,
images/Dinner.jpg,
images/roasted chickpeas.jpg
images/AlmondStuffDates.png.webp
''';

  /// Build the prompt for generating the entire plan

  /// Build the prompt for generating the entire plan
  String _buildPrompt({
    String? feedback,
    List<Map<String, dynamic>>? feedbacks,
    Map<String, List<Map<String, dynamic>>>? favoritePlans,
    Map<String, List<Map<String, dynamic>>>?
        previousPlans, // Added parameter for previous plans
  }) {
    // Extract user data with null checks and default values
    final disease = userData['disease'] ?? 'Not specified';
    final allergies = userData['allergies'] ?? 'None';
    final preference = userData['foodPreference'] ?? 'No specific preference';
    final goal = userData['goal'] ?? 'General wellness';
    final age = userData['age'];
    final gender = userData['gender'];
    final height = userData['height'];
    final weight = userData['weight'];

    // Safely incorporate favorite plans into the prompt
    final favoriteBreakfast =
        favoritePlans?['Breakfast']?.join(', ') ?? 'No data';
    final favoriteLunch = favoritePlans?['Lunch']?.join(', ') ?? 'No data';
    final favoriteDinner = favoritePlans?['Dinner']?.join(', ') ?? 'No data';
    final favoriteSnack = favoritePlans?['Snack']?.join(', ') ?? 'No data';

    // Safely incorporate previous plans into the prompt to ensure diversity
    final previousBreakfast =
        previousPlans?['Breakfast']?.join(', ') ?? 'No data';
    final previousLunch = previousPlans?['Lunch']?.join(', ') ?? 'No data';
    final previousDinner = previousPlans?['Dinner']?.join(', ') ?? 'No data';
    final previousSnack = previousPlans?['Snack']?.join(', ') ?? 'No data';

    // Include the meal plans for reference
    const mealPlansReference = """
Here are some meal plans for different conditions:

**High Cholesterol Meal Plan**  
Breakfast: Whole-wheat bread with low-fat labneh, Qursan bread with low-fat cottage cheese, Dates with low-fat laban,  Boiled eggs with whole-grain toast and tomato slices, Adas (Lentil Stew)..  
Lunch: Margoug with vegetables, Chicken Kabsa, Jareesh with chicken, Grilled salmon with quinoa and steamed broccoli, Vegetable Machkhool with barley rice, Chicken Saliq (made with low-fat broth and rice cooked with minimal butter),Pumpkin soup with vegetables and boiled chicken.  
Dinner: Lentil soup, Eggplant Fatteh, Tabbouleh salad, Foul Medames with olive oil and whole-grain bread, Grilled chicken with yogurt cucumber salad.  
Snack: Hummus with carrot sticks or cucumber slices, Roasted Chickpeas, Stuffed Grape Leaves (Wara Enab),Hummus with Carrot Sticks, Date and Nut Energy Balls, Arabic Coffee with 1-2 Dates.  

**Hypertension Meal Plan**  
Breakfast: Foul Medames, Whole-wheat bread with olive oil, Traditional Saudi Aseeda, Boiled eggs with whole-grain bread, Barley bread with olive oil and zaatar, Scrambled eggs with spinach.  
Lunch: Grilled fish with brown rice, Margoug with vegetables, Chicken Kabsa, Vegetable Saloona with bulgur, Mathloutha with skinless chicken.  
Dinner: Oat soup, Hummus with olive oil, Eggplant Fatteh, Vegetable soup with lentils, Spinach and feta-stuffed chicken breast.  
Snack: A small handful of unsalted almonds with fresh pomegranate seeds,Date and Nut Smoothie, Cucumber and Labneh Dip, Olives and Almonds, Apple Slices with Almond Butter, Laban with 1-2 Dates and Tahini Dip.  

**Diabetes Meal Plan**  
Breakfast: Zaatar and Olive Labneh Wrap, Vegetable Shakshuka, Hard-Boiled Egg, Low-carb pancakes with tahini, Spinach and mushroom omelette, Mqalqal (Spiced Meat).  
Lunch: Grilled Hammour with Quinoa Salad, Chicken Kabsa, Vegetable Saloona, Stuffed bell peppers, Shrimp and zucchini stir-fry, Okra Stew with Lean Beef.  
Dinner: Vegetable Gratin, Chicken and Spinach Curry, Grilled Lamb Chops, Mutabbal with fresh vegetables, Eggplant and lentil moussaka.  
Snack: Greek yogurt with a sprinkle of chia seeds and fresh berries, Tahini and Celery Sticksو Grilled Halloumi Salad, Pomegranate Seeds, Zaatar Crackers with Olive Oil, Berries with Chia Seeds.  
""";
    // Construct the prompt with proper formatting and clarity
    return """
    Create a personalized daily nutrition plan for a user based on:
    - Disease/condition: $disease
    - Allergies: $allergies
    - Food preference: $preference
    - Goal: $goal
    - Height: $height
    - Weight: $weight
    - Gender: $gender
    - Age: $age

    User Preferences:
    - Favorite Breakfast Items: $favoriteBreakfast
    - Favorite Lunch Items: $favoriteLunch
    - Favorite Dinner Items: $favoriteDinner
    - Favorite Snack Items: $favoriteSnack

    Previous Meal Plans:
    - Previous Breakfast Items: $previousBreakfast
    - Previous Lunch Items: $previousLunch
    - Previous Dinner Items: $previousDinner
    - Previous Snack Items: $previousSnack

    Feedback: ${feedback ?? 'No specific feedback'}

    Requirements:
    1. Ensure meal diversity. Avoid repeating the same Ingredients or recipes across meals. Exclude any items that were part of the previous meals.
    Ensure breakfast is diffrent meal and integredians from $previousBreakfast,
    Ensure Lunch is diffrent meal and integredians from $previousLunch
    Ensure Dinner is diffrent meal and integredians from $previousDinner
    Ensure Snack is diffrent meal and integredians from $previousSnack.
    2. Tailor meals to the user's $disease/condition and dietary requirements.
    3. Each meal (Breakfast, Lunch, Dinner, Snack) must include:
       - **Ingredients:** List of required ingredients with quantities.
       - **Description:** Brief description of the meal.
       - **Preparation Instructions:** Step-by-step method to prepare the meal.
       - **Nutritional Info:** Include calories, protein, carbs, and fat content.
      -**image:** Include image path only the folowing paths $imagePaths are available

    
    4. Ensure the meals are culturally appropriate (e.g., Saudi meals).
    5. Maintain balanced total daily calories to align with the user's $goal.
    6. no addtinalnotes please
    7. take meals ideas from $localMeals
    8. take ideas from images
    9.  6. Aim for 1 unique options for each meal type, drawing from the meal plans provided $mealPlansReference.
    10. Take into Account User $feedbacks especially $feedback

    Return the result as JSON in this format:
    {
      "Breakfast": [
        {
          "name": "Food Item 1",
          "calories": 150,
          "protein": 10,
          "carbs": 20,
          "fat": 5,
          "ingredients": [
            "Ingredient 1: Quantity",
            "Ingredient 2: Quantity"
          ],
          "description": "Brief description of the meal",
          "preparation": "Step-by-step preparation method"
          "image": 'images/Breakfast.jpg'
        },
        {
          "name": "Food Item 2",
          "calories": 200,
          "protein": 12,
          "carbs": 25,
          "fat": 7,
          "ingredients": [
            "Ingredient 1: Quantity",
            "Ingredient 2: Quantity"
          ],
          "description": "Brief description of the meal",
          "preparation": "Step-by-step preparation method"
          "image": 'images/Breakfast.jpg'
        }
      ],
      "Lunch": [
        {
          "name": "Food Item 1",
          "calories": 400,
          "protein": 30,
          "carbs": 50,
          "fat": 15,
          "ingredients": [
            "Ingredient 1: Quantity",
            "Ingredient 2: Quantity"
          ],
          "description": "Brief description of the meal",
          "preparation": "Step-by-step preparation method"
          "image": 'images/Lunch.jpg'
        }
      ],
      "Dinner": [
        {
          "name": "Food Item 1",
          "calories": 300,
          "protein": 20,
          "carbs": 40,
          "fat": 10,
          "ingredients": [
            "Ingredient 1: Quantity",
            "Ingredient 2: Quantity"
          ],
          "description": "Brief description of the meal",
          "preparation": "Step-by-step preparation method"
          "image": 'images/Dinner.png'
        }
      ],
      "Snack": [
        {
          "name": "Food Item 1",
          "calories": 100,
          "protein": 5,
          "carbs": 15,
          "fat": 3,
          "ingredients": [
            "Ingredient 1: Quantity",
            "Ingredient 2: Quantity"
          ],
          "description": "Brief description of the meal",
          "preparation": "Step-by-step preparation method"
          "image": 'images/Snack.jpg'
          
        }
      ]
    }
  """;
  }

  /// Build the prompt for regenerating a specific meal
  // Build the prompt for regenerating a specific meal
  String _buildPromptForMeal(
    String mealType, {
          String? feedback,
    List<Map<String, dynamic>>? feedbacks,
    Map<String, List<Map<String, dynamic>>>? favoritePlans,
    Map<String, List<Map<String, dynamic>>>?
        previousPlans, // Added parameter for previous plans
  }) {
    // Extract user data with null checks and default values
    final disease = userData['disease'] ?? 'Not specified';
    final allergies = userData['allergies'] ?? 'None';
    final preference = userData['foodPreference'] ?? 'No specific preference';
    final goal = userData['goal'] ?? 'General wellness';

    // Include favorite and previous plan details for the specified mealType
    final favoriteMealItems = favoritePlans?[mealType]?.join(', ') ?? 'No data';
    final previousMealItems = previousPlans?[mealType]?.join(', ') ?? 'No data';

    // Include the meal plans for reference
    const mealPlansReference = """
Here are some meal plans for different conditions:

**High Cholesterol Meal Plan**  
Breakfast: Whole-wheat bread with low-fat labneh, Qursan bread with low-fat cottage cheese, Dates with low-fat laban,  Boiled eggs with whole-grain toast and tomato slices, Adas (Lentil Stew)..  
Lunch: Margoug with vegetables, Chicken Kabsa, Jareesh with chicken, Grilled salmon with quinoa and steamed broccoli, Vegetable Machkhool with barley rice, Chicken Saliq (made with low-fat broth and rice cooked with minimal butter),Pumpkin soup with vegetables and boiled chicken.  
Dinner: Lentil soup, Eggplant Fatteh, Tabbouleh salad, Foul Medames with olive oil and whole-grain bread, Grilled chicken with yogurt cucumber salad.  
Snack: Hummus with carrot sticks or cucumber slices, Roasted Chickpeas, Stuffed Grape Leaves (Wara Enab),Hummus with Carrot Sticks, Date and Nut Energy Balls, Arabic Coffee with 1-2 Dates.  

**Hypertension Meal Plan**  
Breakfast: Foul Medames, Whole-wheat bread with olive oil, Traditional Saudi Aseeda, Boiled eggs with whole-grain bread, Barley bread with olive oil and zaatar, Scrambled eggs with spinach.  
Lunch: Grilled fish with brown rice, Margoug with vegetables, Chicken Kabsa, Vegetable Saloona with bulgur, Mathloutha with skinless chicken.  
Dinner: Oat soup, Hummus with olive oil, Eggplant Fatteh, Vegetable soup with lentils, Spinach and feta-stuffed chicken breast.  
Snack: A small handful of unsalted almonds with fresh pomegranate seeds,Date and Nut Smoothie, Cucumber and Labneh Dip, Olives and Almonds, Apple Slices with Almond Butter, Laban with 1-2 Dates and Tahini Dip.  

**Diabetes Meal Plan**  
Breakfast: Zaatar and Olive Labneh Wrap, Vegetable Shakshuka, Hard-Boiled Egg, Low-carb pancakes with tahini, Spinach and mushroom omelette, Mqalqal (Spiced Meat).  
Lunch: Grilled Hammour with Quinoa Salad, Chicken Kabsa, Vegetable Saloona, Stuffed bell peppers, Shrimp and zucchini stir-fry, Okra Stew with Lean Beef.  
Dinner: Vegetable Gratin, Chicken and Spinach Curry, Grilled Lamb Chops, Mutabbal with fresh vegetables, Eggplant and lentil moussaka.  
Snack: Greek yogurt with a sprinkle of chia seeds and fresh berries, Tahini and Celery Sticksو Grilled Halloumi Salad, Pomegranate Seeds, Zaatar Crackers with Olive Oil, Berries with Chia Seeds.  
""";

    // Construct the prompt with proper formatting and clarity
    return """
  Create a personalized plan for $mealType based on:
  - Disease/condition: $disease
  - Allergies: $allergies
  - Food preference: $preference
  - Goal: $goal

  User Preferences:
  - Favorite $mealType Items: $favoriteMealItems

  Previous $mealType Items:
  - $previousMealItems

  Feedback: ${feedback ?? 'No specific feedback'}

  Requirements:
  1. Ensure meal diversity. Avoid repeating the same ingredients or recipes as previous meals. Exclude any items that were part of the previous $mealType.
  2. Tailor the meal to the user's disease/condition and dietary requirements.
  3. Include the following details for $mealType:
    - **Ingredients:** List of required ingredients with quantities.
       - **Description:** Brief description of the meal.
       - **Preparation Instructions:** Step-by-step method to prepare the meal.
       - **Nutritional Info:** Include calories, protein, carbs, and fat content.
       -**image:** Include image path only the folowing paths $imagePaths are available

    4. Ensure the meals are culturally appropriate (e.g., Saudi meals).
    5. Maintain balanced total daily calories to align with the user's $goal.
    6. no addtinalnotes please
    7. take meals ideas from $localMeals
    8. take ideas from images
    9. Aim for 1 unique options for each meal type, drawing from the meal plans provided $mealPlansReference.
    10. Take into Account User $feedbacks especially $feedback

  Return the result as JSON in this format:
  {
    "$mealType": [
      {
        "name": "Food Item 1",
        "calories": 150,
        "protein": 10,
        "carbs": 20,
        "fat": 5,
        "ingredients": [
          "Ingredient 1: Quantity",
          "Ingredient 2: Quantity"
        ],
        "description": "Brief description of the meal",
        "preparation": "Step-by-step preparation method"
      },
  }
  """;
  }

  /// Save plan to Firestore
  Future<void> _saveMealsToFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('dailyMeals');
        final docId = DateTime.now().toIso8601String();
        await docRef.doc(docId).set({
          'Breakfast': _meals['Breakfast'],
          'Lunch': _meals['Lunch'],
          'Dinner': _meals['Dinner'],
          'Snack': _meals['Snack'],
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('Meals successfully saved to Firestore!');
      } catch (e) {
        print('Error saving meals to Firestore: $e');
      }
    }
  }

  /// Placeholder: open History page
  void _viewHistory() {
    final user = _auth.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoryPage(userId: user.uid),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No user logged in. Cannot view history.')),
      );
    }
  }

  /// Placeholder for other features

  void _exportPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export/Share Feature Coming Soon!')),
    );
  }

  Future<void> _checkIfFavorited() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final dailyMealsRef = _firestore
          .collection('nutritionPlans')
          .doc(user.uid)
          .collection('dailyMeals');
      final querySnapshot = await dailyMealsRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final planId = querySnapshot.docs.first.id;
        final docRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('favoritesNutritionPlans')
            .doc(planId);

        final docSnapshot = await docRef.get();

        setState(() {
          _isFavorited = docSnapshot.exists;
        });
      } else {
        setState(() {
          _isFavorited = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final dailyMealsRef = _firestore
          .collection('nutritionPlans')
          .doc(user.uid)
          .collection('dailyMeals');
      final querySnapshot = await dailyMealsRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final planId = querySnapshot.docs.first.id;
        final docRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('favoritesNutritionPlans')
            .doc(planId);

        if (_isFavorited) {
          await docRef.delete();
          print('Removed from favorites');
        } else {
          await docRef.set({
            'Breakfast': _meals['Breakfast'],
            'Lunch': _meals['Lunch'],
            'Dinner': _meals['Dinner'],
            'Snack': _meals['Snack'],
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Added to favorites');
        }

        setState(() {
          _isFavorited = !_isFavorited;
        });
      }
    }
  }

  Future<void> _addToFavorites() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final dailyMealsRef = _firestore
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('dailyMeals');
        final querySnapshot = await dailyMealsRef
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final planId = querySnapshot.docs.first.id;

          final favoriteRef = _firestore
              .collection('nutritionPlans')
              .doc(user.uid)
              .collection('favoritesNutritionPlans')
              .doc(planId);

          final docSnapshot = await favoriteRef.get();

          if (docSnapshot.exists) {
            print('This nutrition plan is already in favorites!');
            return;
          }

          // Ensure meals are structured correctly (as a List of Maps)
          await favoriteRef.set({
            'Breakfast': _meals[
                'Breakfast'], // If _meals['Breakfast'] is a map, ensure it's handled properly
            'Lunch': _meals['Lunch'],
            'Dinner': _meals['Dinner'],
            'Snack': _meals['Snack'],
            'timestamp': FieldValue.serverTimestamp(),
          });

          print('Nutrition plan added to favorites!');
        }
      } catch (e) {
        print('Error adding nutrition plan to favorites: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // HEADER
          Container(
            height: 270, // Adjusted height for progress display
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
                      color: const Color(0xFF360980).withOpacity(0.5),
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
                  top: MediaQuery.of(context).padding.top +
                      60, // Adjust the top alignment
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fastfood,
                        size: 50,
                        color: Colors.white,
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Nutrition Plans',
                        style: TextStyle(
                          fontFamily: "Raleway",
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Display Progress
                    ],
                  ),
                ),
              ],
            ),
          ),
          // MAIN CONTENT
          Padding(
            padding: const EdgeInsets.only(top: 300), // Adjusted padding
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? Center(
                        key: ValueKey('loadingCenter'),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Image.asset(
                            'images/Nutrtion.gif', // Path to your GIF
                            width: 500, // Adjusted size to make the GIF bigger
                            height: 500, // Adjusted size to make the GIF bigger
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ProgressBarChart(
                              progress:
                                  (progressProvider.mealsCompleted * 0.25)),
                          Text(
                            'Nutrition Progress: ${(progressProvider.mealsCompleted.ceil() * 25).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 80, 82, 94),
                            ),
                          ),
                          _buildMealContent(),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealContent() {
    return Column(
      key: const ValueKey('mealContent'),
      children: [
        // Meal Cards
        _buildMealExpansionTile('Breakfast', _meals['Breakfast'] ?? []),
        _buildMealExpansionTile('Lunch', _meals['Lunch'] ?? []),
        _buildMealExpansionTile('Dinner', _meals['Dinner'] ?? []),
        _buildMealExpansionTile('Snack', _meals['Snack'] ?? []),
        const SizedBox(height: 20),

        // ACTION BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final feedback =
                          await _showFeedbackDialog(context, 'Nutrition Plan');
                      await _generateNutritionPlan(feedback: feedback);
                    },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Regenerate Plan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF286181),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // SECONDARY ACTIONS
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _viewHistory,
                  icon: const Icon(Icons.history, color: Colors.orange),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.grey,
                  ),
                  label: Text(
                    _isFavorited ? 'Remove from Favorites' : 'Add to Favorites',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _exportPlan,
                icon: const Icon(Icons.ios_share, color: Colors.blue),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Create a Card for each meal
  Widget _buildMealExpansionTile(
      String mealTitle, List<Map<String, dynamic>> items) {
    final mealIcon = mealTitle == 'Breakfast'
        ? Icons.breakfast_dining
        : mealTitle == 'Lunch'
            ? Icons.lunch_dining
            : mealTitle == 'Dinner'
                ? Icons.dinner_dining
                : Icons.fastfood;

    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final isCompleted = mealTitle == 'Breakfast'
            ? progressProvider.breakfastCompleted
            : mealTitle == 'Lunch'
                ? progressProvider.lunchCompleted
                : mealTitle == 'Dinner'
                    ? progressProvider.dinnerCompleted
                    : mealTitle == 'Snack'
                        ? progressProvider.snackCompleted
                        : false;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            leading: Icon(mealIcon, color: Color(0xFF0D47A1),),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mealTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 88, 79),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        if (value != null) {
                          progressProvider.toggleTask(mealTitle, value);
                        }
                      },
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              // Show the feedback dialog for the specified meal
                              final feedback =
                                  await _showFeedbackDialog(context, mealTitle);
                              // Regenerate only the specific meal with optional feedback
                              await _generateNutritionPlan(
                                  mealType: mealTitle, feedback: feedback);
                            },
                      icon: _isLoading
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.refresh, color: (Color(0xFF286181)),),
                      tooltip: _isLoading
                          ? 'Please wait...'
                          : 'Regenerate $mealTitle',
                    ),
                  ],
                ),
              ],
            ),
            subtitle: items.isEmpty
                ? const Text(
                    'No items available.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                : Text(
                    '${items.length} item${items.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
            children: items.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No items for this meal. Add some to get started!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  ]
                : items.map((item) {
                    final name = item['name'] ?? 'Unnamed item';
                    final calories = item['calories']?.toString() ?? 'Unknown';
                    final protein = item['protein']?.toString() ?? 'N/A';
                    final carbs = item['carbs']?.toString() ?? 'N/A';
                    final fat = item['fat']?.toString() ?? 'N/A';
                    final ingredients =
                        (item['ingredients'] as List<dynamic>?)?.join(', ') ??
                            'No ingredients provided';
                    final preparation =
                        item['preparation'] ?? 'Preparation details missing';
                    final imagee = item['image'] ?? 'images/Dinner.jpg';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 13, 55, 16)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              imagee, // Path to your GIF
                              width:
                                  150, // Adjusted size to make the GIF bigger
                              height:
                                  150, // Adjusted size to make the GIF bigger
                            ),
                          ),
                          // Nutritional Info Section
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            'Nutritional Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                                color: Color(0xFF0D47A1),
                            ),
                          ),
                          const Divider(thickness: 1),
                          // Nutritional Pie Chart Section
                          NutritionalPieChart(
                            calories: double.tryParse(calories) ?? 0,
                            protein: double.tryParse(protein) ?? 0,
                            carbs: double.tryParse(carbs) ?? 0,
                            fat: double.tryParse(fat) ?? 0,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  'Calories: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 70, 122, 116),
                                  ),
                                ),
                                Text(calories),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  'Protein: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 157, 152, 82),
                                  ),
                                ),
                                Text('$protein g'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  'Carbs: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 180, 113, 151),
                                  ),
                                ),
                                Text('$carbs g'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  'Fat: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 119, 138, 162),
                                  ),
                                ),
                                Text('$fat g'),
                              ],
                            ),
                          ),

                          // Ingredients Section
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            'Ingredients',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal,
                            ),
                          ),
                          const Divider(thickness: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: _buildPlanItems(ingredients
                                .split(', ')), // Split ingredients by commas
                          ),

                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            'Preparation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Divider(thickness: 1),

                          // The expanded section with a more interesting design
                          ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 16),
                            leading: Icon(
                              Icons.fastfood,
                                color: Color(0xFF0D47A1),
                            ),
                            title: Text(
                              'Tap to explore Preparation Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            childrenPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: _buildPlanItems(preparation.split('. ')),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPlanItems(List<String> items) {
    return Column(
      children: List.generate(items.length, (index) {
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightBlue,
                  ),
                ),
                if (index < items.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: Colors.lightBlue,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                items[index],
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// WaveClipper for the wavy header
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

// Custom widget for displaying nutritional data as a bar chart

class NutritionalPieChart extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionalPieChart({
    Key? key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          height: 150, // Smaller height for a smaller chart
          width: 150, // Width also adjusted to make it circular and compact
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius:
                  20, // Smaller center space radius for a compact look
              sections: [
                // PieChartSectionData(
                //   value: calories,
                //   color: const Color.fromARGB(255, 133, 106, 160),
                //   title: '${calories.toStringAsFixed(0)} kcal',
                //   titleStyle: TextStyle(color: Colors.white, fontSize: 10),
                // ),
                PieChartSectionData(
                  value: protein,
                  color: const Color.fromARGB(255, 157, 152, 82),
                  title: '${protein.toStringAsFixed(0)} g',
                  titleStyle: TextStyle(color: Colors.white, fontSize: 10),
                ),
                PieChartSectionData(
                  value: carbs,
                  color: const Color.fromARGB(255, 180, 113, 151),
                  title: '${carbs.toStringAsFixed(0)} g',
                  titleStyle: TextStyle(color: Colors.white, fontSize: 10),
                ),
                PieChartSectionData(
                  value: fat,
                  color: const Color.fromARGB(255, 119, 138, 162),
                  title: '${fat.toStringAsFixed(0)} g',
                  titleStyle: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressBarChart extends StatefulWidget {
  final double progress; // Progress value between 0 and 1

  ProgressBarChart({required this.progress});

  @override
  _ProgressBarChartState createState() => _ProgressBarChartState();
}

class _ProgressBarChartState extends State<ProgressBarChart> {
  @override
  Widget build(BuildContext context) {
    // Round the progress to the nearest multiple of 33%
    int progressPercentage = ((widget.progress * 4).ceil() * 25).clamp(0, 100);

    return Column(
      children: [
        // Progress Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 30, // Set the height for the BarChart (a thin progress bar)
            width: double.infinity, // Ensure the bar stretches horizontally
            decoration: BoxDecoration(
              color: Colors.grey[300], // Background color (remaining progress)
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.progress, // The width of the progress bar
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 77, 149, 216), // Color for progress
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CaloriesPieChart extends StatelessWidget {
  final double suggestedCalories;
  final double actualCalories;

  CaloriesPieChart({
    required this.suggestedCalories,
    required this.actualCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Explicit size constraints
      height: 150, // Explicit size constraints
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: actualCalories,
                  color: Colors.green,
                  title: '${actualCalories.toStringAsFixed(0)} cal',
                  radius: 40,
                  titleStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: suggestedCalories,
                  color: Colors.grey,
                  title: '${suggestedCalories.toStringAsFixed(0)} cal',
                  radius: 40,
                  titleStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
