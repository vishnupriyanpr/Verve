import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'exercise_history.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'progress_provider.dart';
import 'dart:async'; // For Timer

class Exercise extends StatefulWidget {
  const Exercise({super.key});

  @override
  State<Exercise> createState() => _ExerciseState();
}

class _ExerciseState extends State<Exercise> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isFavorited = false; // Track whether the plan is in favorites
  bool _isWorkoutCompleted = false;

  // Basic user data from Firestore
  Map<String, dynamic> userData = {
    'name': 'N/A',
    'email': 'N/A',
    'age': 'N/A',
    'disease': 'N/A',
    'foodPreference': 'N/A',
    'allergies': 'N/A',
    'height': 'N/A',
    'weight': 'N/A',
    'goal': 'N/A',
  };

  // The plan data
  List<Map<String, dynamic>> _mainWorkout = [];

  List<Map<String, dynamic>> _warmUp = [];
  List<Map<String, dynamic>> _coolDown = [];
  List<Map<String, dynamic>> _additionalNotes = [];

  // Track completion status of each exercise
  List<bool> _completedExercises = [];

  double _progress = 0.0; // Progress of completed exercises
  double _totalCaloriesBurnt = 0.0; // Track total calories burnt
  double _totalCalories = 0;
  double _totalWarmUpCalories = 0;
  double _totalMainWorkoutCalories = 0;
  double _totalCoolDownCalories = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Fetch user data from Firestore and initialize plan
  Future<void> _initializeData() async {
    await _fetchUserData();
    final planExists = await _fetchExistingExercisePlan();
    if (!planExists) {
      await _generateExercisePlan();
    }
    await _checkIfFavorited();
    // Initialize the _completedExercises list based on _mainWorkout length
    _completedExercises = List.generate(_mainWorkout.length, (index) => false);
    setState(() {});
  }

  // Calculate progress as percentage of completed exercises
  double get progress => _mainWorkout.isEmpty
      ? 0.0
      : _completedExercises.where((completed) => completed).length /
          _mainWorkout.length;



  // Fetch existing exercise plan
  Future<bool> _fetchExistingExercisePlan() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('exercisePlans')
          .doc(user.uid)
          .collection('dailyWorkouts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          _warmUp = List<Map<String, dynamic>>.from(doc['warmUp'] ?? []);
          _mainWorkout =
              List<Map<String, dynamic>>.from(doc['mainWorkout'] ?? []);
          _coolDown = List<Map<String, dynamic>>.from(doc['coolDown'] ?? []);
          _additionalNotes =
              List<Map<String, dynamic>>.from(doc['additionalNotes'] ?? []);
          // Fetch and convert totalCalories to double
          _totalCalories = (doc['totalCalories'] ?? 0).toDouble();
          _totalCaloriesBurnt = (doc['totalCaloriesBurnt'] ?? 0).toDouble();
          _totalWarmUpCalories = (doc['totalWarmUpCalories'] ?? 0).toDouble();
          _totalMainWorkoutCalories =
              (doc['totalMainWorkoutCalories'] ?? 0).toDouble();
          _totalCoolDownCalories =
              (doc['totalCoolDownCalories'] ?? 0).toDouble();
        });
        print('Existing exercise plan loaded.');
        return true;
      }
    }
    return false;
  }

  // Call this method when the workout is marked as completed to save data
  // void _markWorkoutAsCompleted() {
  //   setState(() {
  //     _isWorkoutCompleted = true;
  //     _updateCaloriesBurnt(); // Ensure calories are updated when workout is completed
  //   });
  // }
  /// Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userData = {
            'name': user.displayName ?? 'N/A',
            'email': user.email ?? 'N/A',
            'age': data?['age'] ?? 'N/A',
            'disease': data?['disease'] ?? 'N/A',
            'foodPreference': data?['foodPreference'] ?? 'N/A',
            'allergies': data?['allergies'] ?? 'N/A',
            'height': (data?['height'] ?? 'N/A').toString(),
            'weight': (data?['weight'] ?? 'N/A').toString(),
            'goal': data?['goal'] ?? 'N/A',
            'gender': data?['gender'] ?? 'N/A',
          };
        });
      }
    }
  }

  /// Generate a new exercise plan via AI
  /// Generate a new exercise plan via AI
  Future<void> _generateExercisePlan({
    String? exerciseType,
    String? feedback,
  }) async {
    setState(() {
      _isLoading = true;
      _progress = 0.0; // Reset the progress when starting the task
      _isFavorited = false;
      _totalCaloriesBurnt = 0; // Initialize total calories to 0
    });

// Access the ProgressProvider directly
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    final gemini = Gemini.instance;

    // Fetch favorite exercises to include in the prompt
    final favoriteExercises = await _fetchFavoritePlans();
    final userExercises = await _fetchUserPlans();
    final feedbacks = await _fetchExerciseFeedback();

    final prompt = exerciseType != null
        ? _buildPromptForExercise(
            exerciseType,
            feedback: feedback,
            feedbacks: feedbacks,
            favoriteExercises: favoriteExercises,
            progressProvider: progressProvider,
          )
        : _buildPrompt(
            feedback: feedback,
            feedbacks: feedbacks,
            favoriteExercises: favoriteExercises,
            userExercises: userExercises,
          );

    try {
      final response = await gemini.text(prompt);
      print(response);
      if (response?.output != null) {
        final cleanedResponse = response!.output!
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanedResponse);

        // Extract total calories from the response

        // Update state with total calories and other data
        setState(() {
          _totalCaloriesBurnt = 0;
          _totalCalories = (data['totalCalories'] ?? 0).toDouble();

          _totalWarmUpCalories = (data['totalWarmUpCalories'] ?? 0).toDouble();
          _totalMainWorkoutCalories =
              (data['totalMainWorkoutCalories'] ?? 0).toDouble();
          _totalCoolDownCalories =
              (data['totalCoolDownCalories'] ?? 0).toDouble();

          // Update based on exercise type
          if (exerciseType == 'warmUp' || exerciseType == null) {
            progressProvider.toggleTask('warmUp', false);
            _totalWarmUpCalories =
                (data['totalWarmUpCalories'] ?? _totalWarmUpCalories)
                    .toDouble();
            _warmUp = List<Map<String, dynamic>>.from(
              (data['warmUp'] ?? []).map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  throw Exception('Warm-up item is not a Map.');
                }
              }),
            );
          }

          if (exerciseType == 'mainWorkout' || exerciseType == null) {
            progressProvider.toggleTask('mainWorkout', false);
            _mainWorkout = List<Map<String, dynamic>>.from(
              (data['mainWorkout'] ?? []).map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  throw Exception('Main workout item is not a Map.');
                }
              }),
            );
          }

          if (exerciseType == 'coolDown' || exerciseType == null) {
            progressProvider.toggleTask('coolDown', false);
            _coolDown = List<Map<String, dynamic>>.from(
              (data['coolDown'] ?? []).map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  throw Exception('Cool-down item is not a Map.');
                }
              }),
            );
          }

          if (exerciseType == 'additionalNotes' || exerciseType == null) {
            _additionalNotes =
                List<Map<String, dynamic>>.from(data['additionalNotes'] ?? []);
          }
          progressProvider.updateCalories(
            totalCalories: _totalCalories,
            totalCaloriesBurnt: _totalCaloriesBurnt,
            totalWarmUpCalories: _totalWarmUpCalories,
            totalMainWorkoutCalories: _totalMainWorkoutCalories,
            totalCoolDownCalories: _totalCoolDownCalories,
          );
          // Simulate process completion
          _progress = 1.0;
        });

        // Save exercises to Firestore or any other relevant storage
        await _saveExercisesToFirestore();
      } else {
        throw Exception('No output received from Gemini.');
      }
    } catch (e) {
      print('Error generating exercise plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, List<String>>?> _fetchUserPlans() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection(
                'exercisePlans') // Changed to 'exercisePlans' collection
            .doc(user.uid)
            .collection(
                'dailyWorkouts') // Changed to 'favoritesExercisePlans' collection
            .orderBy('timestamp', descending: true)
            .limit(7)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final Map<String, List<String>> allPlans = {
            'Warm-Up': [],
            'MainWorkout': [],
            'Cool-Down': [],
          };

          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            allPlans['Warm-Up']!
                .addAll(List<String>.from(data['Warm-Up'] ?? []));
            allPlans['MainWorkout']!
                .addAll(List<String>.from(data['MainWorkout'] ?? []));
            allPlans['Cool-Down']!
                .addAll(List<String>.from(data['Cool-Down'] ?? []));
          }

          // Ensure no duplicate values are added
          allPlans['Warm-Up'] = allPlans['Warm-Up']!.toSet().toList();
          allPlans['MainWorkout'] = allPlans['MainWorkout']!.toSet().toList();
          allPlans['Cool-Down'] = allPlans['Cool-Down']!.toSet().toList();

          return allPlans;
        }
      } catch (e) {
        print('Error fetching favorite exercise plans: $e');
      }
    }
    return null; // No favorite exercise plans found
  }

  Future<Map<String, List<String>>?> _fetchFavoritePlans() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection(
                'exercisePlans') // Changed to 'exercisePlans' collection
            .doc(user.uid)
            .collection(
                'favoritesExercisePlans') // Changed to 'favoritesExercisePlans' collection
            .orderBy('timestamp', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final Map<String, List<String>> allPlans = {
            'Warm-Up': [],
            'MainWorkout': [],
            'Cool-Down': [],
          };

          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            allPlans['Warm-Up']!
                .addAll(List<String>.from(data['Warm-Up'] ?? []));
            allPlans['MainWorkout']!
                .addAll(List<String>.from(data['MainWorkout'] ?? []));
            allPlans['Cool-Down']!
                .addAll(List<String>.from(data['Cool-Down'] ?? []));
          }

          // Ensure no duplicate values are added
          allPlans['Warm-Up'] = allPlans['Warm-Up']!.toSet().toList();
          allPlans['MainWorkout'] = allPlans['MainWorkout']!.toSet().toList();
          allPlans['Cool-Down'] = allPlans['Cool-Down']!.toSet().toList();

          return allPlans;
        }
      } catch (e) {
        print('Error fetching favorite exercise plans: $e');
      }
    }
    return null; // No favorite exercise plans found
  }

  Future<void> _storeExerciseFeedback(String planType, String feedback) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('exerciseFeedback')
            .add({
          'planType': planType, // Type of exercise plan
          'feedback': feedback, // Feedback content
          'timestamp': FieldValue.serverTimestamp(), // Timestamp
        });
        print('Exercise feedback saved successfully!');
      } catch (e) {
        print('Error saving exercise feedback: $e');
      }
    } else {
      print('User not logged in!');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExerciseFeedback() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('exerciseFeedback')
            .orderBy('timestamp', descending: true)
            .get();

        List<Map<String, dynamic>> feedbackList = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id, // Document ID
            'planType': doc['planType'], // Exercise plan type
            'feedback': doc['feedback'], // Feedback content
            'timestamp': (doc['timestamp'] as Timestamp).toDate(), // DateTime
          };
        }).toList();

        print('Exercise feedback fetched successfully!');
        return feedbackList;
      } catch (e) {
        print('Error fetching exercise feedback: $e');
        return [];
      }
    } else {
      print('User not logged in!');
      return [];
    }
  }

  Future<String?> _showFeedbackDialog(
      BuildContext context, String planType) async {
    final TextEditingController feedbackController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Feedback for $planType Plan'),
          content: TextField(
            controller: feedbackController,
            decoration: const InputDecoration(
              labelText: 'Reason for regenerating',
              hintText: 'Provide your feedback (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel action
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
        _storeExerciseFeedback(
            planType, feedback); // Save feedback to Firestore
      }
      return feedback;
    });
  }

  /// Build AI prompt for generating a workout plan
  String _buildPrompt({
        String? feedback,
    List<Map<String, dynamic>>? feedbacks,
    Map<String, List<String>>? favoriteExercises,
    Map<String, List<String>>? userExercises,
  }) {
    final age = userData['age'];
    final disease = userData['disease'];
    final preference = userData['foodPreference'];
    final allergies = userData['allergies'];
    final height = userData['height'];
    final weight = userData['weight'];
    final goal = userData['goal'];
    final gender = userData['gender'];

    final favoriteWarmUp =
        favoriteExercises?['warmUp']?.join(', ') ?? 'No preferences';
    final favoriteMainWorkout =
        favoriteExercises?['mainWorkout']?.join(', ') ?? 'No preferences';
    final favoriteCoolDown =
        favoriteExercises?['coolDown']?.join(', ') ?? 'No preferences';

    final previousPlansDetails =
        userExercises != null && userExercises.isNotEmpty
            ? '''
- Warm-Up: ${userExercises['warmUp']?.join(', ') ?? 'None'}
- Main Workout: ${userExercises['mainWorkout']?.join(', ') ?? 'None'}
- Cool-Down: ${userExercises['coolDown']?.join(', ') ?? 'None'}
'''
            : 'No previous plans available.';

    return """
Generate a personalized workout plan for a user with the following details:
- **Age**: $age
- **Height**: $height
- **Weight**: $weight
- **Goal**: $goal
- **Food Preferences**: $preference
- **Allergies**: $allergies
- **Chronic Disease**: $disease
- **Gender**: $gender

### User Inputs
- **Feedback**: ${feedback ?? 'None provided'}
- **Favorite Exercises**:
  - Warm-Up: $favoriteWarmUp
  - Main Workout: $favoriteMainWorkout
  - Cool-Down: $favoriteCoolDown
- **Previous Plans**:
$previousPlansDetails

### Instructions
1. **No Additional Text**: Only return valid JSON. Do not include explanations, comments, or additional text outside the JSON object.
2. **No Repetition**: Ensure exercises are distinct from the previous plan.
3. **Customization**: Align exercises with user preferences, goals, and health conditions.
4. **Balance**: Include diverse types of exercises (e.g., strength, cardio, flexibility).
5. **Disease-Specific Adjustments**: Tailor exercises to the user's chronic disease.
6. **gender** suitable exercises
7. Take into Account User $feedbacks especially $feedback
### JSON Output Format
The output must be a valid JSON object with the following structure:
- **totalCalories**: Total estimated calories burned. you should calculate from all the exercises! and it should be summed accurttly
- **totalWarmUpCalories**: Total warmUp estimated calories burned. you should calculate from all the exercises of warmUp! and it should be summed accurttly
- **totalMainWorkoutCalories**: Total mainWorkout estimated calories burned. you should calculate from all the exercises of mainWorkout! and it should be summed accurttly
- **totalCoolDownCalories**: Total coolDown estimated calories burned. you should calculate from all the exercises of coolDown! and it should be summed accurttly
- **warmUp**: Array of exercises with sets, repetitions, descriptions, calories burned, and a `completed` status.
- **mainWorkout**: Array of objects with:
  - **exercise**: Name of the exercise.
  - **description**: Brief explanation.
  - **sets**: Number of sets.
  - **repetitions**: Repetitions or duration (in quotes).
  - **calories_burned**: Estimated calories burned.
- **coolDown**: Array of exercises with sets, repetitions, descriptions, calories burned, and a `completed` status.

### Example Output
{
  "totalCalories": 300,
  "totalWarmUpCalories": 18
  "totalMainWorkoutCalories": 40
  "totalCoolDownCalories": 5

  "warmUp": [
    {
      "exercise": "Jumping Jacks",
      "sets": 2,
      "repetitions": "30 seconds",
      "description": "Full-body warm-up to increase heart rate.",
      "calories_burned": 10,

    },
    {
      "exercise": "High Knees",
      "sets": 2,
      "repetitions": "30 seconds",
      "description": "Activates legs and core for a warm-up.",
      "calories_burned": 8,

    }

  ],
  "mainWorkout": [
    {
      "exercise": "Bodyweight Squats",
      "description": "Builds lower body strength.",
      "sets": 3,
      "repetitions": "10",
      "calories_burned": 40,

    }

  ],
  "coolDown": [
    {
      "exercise": "Hamstring Stretch",
      "sets": 1,
      "repetitions": "30 seconds per leg",
      "description": "Stretches the hamstrings to reduce tightness.",
      "calories_burned": 5,

    }

  ]
}

""";
  }

  /// Build AI prompt for regenerating a specific workout plan section (e.g., Main Workout)
  String _buildPromptForExercise(String exerciseType,
      {    String? feedback,
        List<Map<String, dynamic>>? feedbacks,
      Map<String, List<String>>? favoriteExercises,
      Map<String, List<String>>? userExercises,
      ProgressProvider? progressProvider}) {
    final age = userData['age'];
    final disease = userData['disease'];
    final preference = userData['foodPreference'];
    final allergies = userData['allergies'];
    final height = userData['height'];
    final weight = userData['weight'];
    final goal = userData['goal'];

    // Handling favorite exercises for the specified section
    String favoriteExercisesForSection =
        'No favorite exercises available for $exerciseType.';
    if (favoriteExercises != null &&
        favoriteExercises.containsKey(exerciseType)) {
      favoriteExercisesForSection =
          favoriteExercises[exerciseType]?.join(', ') ??
              'No favorite exercises available for $exerciseType.';
    }

    final previousPlansDetails =
        userExercises != null && userExercises.isNotEmpty
            ? '''
- $exerciseType: ${userExercises[exerciseType]?.join(', ') ?? 'None'}
'''
            : 'No previous plans available for $exerciseType.';

    return """
Regenerate the $exerciseType plan for an individual with:
- Age: $age
- Height: $height
- Weight: $weight
- Goal: $goal
- Food Preference: $preference
- Allergies: $allergies
- Chronic Disease or Condition: $disease

User Feedback: ${feedback ?? 'No specific feedback provided'}

Favorite Exercises for $exerciseType:
- $favoriteExercisesForSection

Previous Plans:
$previousPlansDetails

The plan should include:
 **$exerciseType**: 
1. Keep the plan simple
2. Ensure exercises are distinct from the previous plan.
3. Tailor the exercises to the user's preferences, goals, and health conditions.
4. Make adjustments for chronic diseases as necessary.

**Output Format**:
Return the response as a JSON object with the following structure:
- **$exerciseType**: An array of objects where each object contains:
  - **exercise**: Name of the exercise.
  - **description**: A brief explanation of the exercise.
  - **sets**: Number of sets.
  - **repetitions**: Number of repetitions or duration. Ensure it's between quotation marks.
  - **calories_burned**: Estimated calories burned.
  you should take the $_totalCalories and subtract it from the previous $exerciseType calories and then add it to the current $exerciseType calories
  and you shouldn't change the other exercises calories!
    10. Take into Account User $feedbacks especially $feedback
**Example Output**:
{
  "totalCalories": 300,
  "totalWarmUpCalories": 18
  "totalMainWorkoutCalories": 40
  "totalCoolDownCalories": 5

  "$exerciseType": [
    {
      "exercise": "Bodyweight Squats",
      "description": "Builds lower body strength and endurance.",
      "sets": 2,
      "repetitions": "10-12",
      "calories_burned": 30
    },
    {
      "exercise": "Push-Ups",
      "description": "Improves upper body strength.",
      "sets": 2,
      "repetitions": "8-10",
      "calories_burned": 20
    }
  ]
}
""";
  }

  /// Save to Firestore
  Future<void> _saveExercisesToFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('dailyWorkouts');

        final docId = DateTime.now().toIso8601String();
        await docRef.doc(docId).set({
          'totalCaloriesBurnt': _totalCaloriesBurnt,
          'totalCalories': _totalCalories,
          'totalWarmUpCalories': _totalWarmUpCalories,
          'totalMainWorkoutCalories': _totalMainWorkoutCalories,
          'totalCoolDownCalories': _totalCoolDownCalories,
          'warmUp': _warmUp,
          'mainWorkout': _mainWorkout,
          'coolDown': _coolDown,
          'additionalNotes': _additionalNotes,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Exercise plan saved to Firestore!');
      } catch (e) {
        print('Error saving exercise plan: $e');
      }
    }
  }

  /// Check if the latest plan is favorited
  Future<void> _checkIfFavorited() async {
    final user = _auth.currentUser;
    if (user != null) {
      final dailyWorkoutsRef = _firestore
          .collection('exercisePlans')
          .doc(user.uid)
          .collection('dailyWorkouts');

      final querySnapshot = await dailyWorkoutsRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final planId = querySnapshot.docs.first.id;
        final docRef = _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('favoritesExercisePlans')
            .doc(planId);

        final docSnapshot = await docRef.get();
        setState(() {
          _isFavorited = docSnapshot.exists;
        });
      } else {
        setState(() => _isFavorited = false);
      }
    }
  }

  /// Toggle the favorite state
  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      final dailyWorkoutsRef = _firestore
          .collection('exercisePlans')
          .doc(user.uid)
          .collection('dailyWorkouts');

      final querySnapshot = await dailyWorkoutsRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final planId = querySnapshot.docs.first.id;
        final docRef = _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('favoritesExercisePlans')
            .doc(planId);

        if (_isFavorited) {
          // Remove from favorites
          await docRef.delete();
          print('Removed from favorites');
        } else {
          // Add to favorites
          await docRef.set({
            'warmUp': _warmUp,
            'mainWorkout': _mainWorkout,
            'coolDown': _coolDown,
            'additionalNotes': _additionalNotes,
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

// Method to handle individual exercise completion (or unchecking it)
// Method to update calories in Firestore

// Method to update calories in Firestore
  Future<void> _updateCaloriesInFirestore(
      double totalCalories, double totalCaloriesBurnt, bool isCompleted) async {
    try {
      final user = _auth.currentUser;

      // Reference to the Firestore collection
      final querySnapshot = await _firestore
          .collection('exercisePlans')
          .doc(user?.uid)
          .collection('dailyWorkouts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document reference from the snapshot
        final docRef = querySnapshot.docs.first.reference;

        // Update the calories values using the document reference
        await docRef.update({
          'totalCalories': totalCalories,
          'totalCaloriesBurnt': totalCaloriesBurnt,
          'completed': isCompleted,
        });
      }

    } catch (e) {
      print("Error updating calories in Firestore: $e, no document found");
    }
  }

// Update calories based on exercise completion
  void _updateExerciseCalories(List<Map<String, dynamic>> exercises,
      Map<String, dynamic> exercise, bool isCompleted) async {
    double exerciseCalories = (exercise["calories_burned"] ?? 0.0).toDouble();

    setState(() {
      if (isCompleted) {
        // Add calories to total burnt calories and deduct from total available calories
        _totalCaloriesBurnt += exerciseCalories;
        _totalCalories -= exerciseCalories;
      } else {
        // Subtract calories from total burnt calories and add back to total available calories
        _totalCaloriesBurnt -= exerciseCalories;
        _totalCalories += exerciseCalories;
      }


    });

    // Update Firestore after the change
    try {
      final user = _auth.currentUser;
      final querySnapshot = await _firestore
          .collection('exercisePlans')
          .doc(user?.uid)
          .collection('dailyWorkouts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        // Update Firestore document with the exercise's completed status
        await docRef.update({
          'exerciseName': exercise["name"],
          'calories_burned': exercise["calories_burned"],
          'completed': isCompleted,
        });
      }
    } catch (e) {
      print("Error updating Firestore for exercise: $e");
    }
  }

// Method to update exercise completion (CheckboxListTile)
  Widget _buildExerciseTile(
      List<Map<String, dynamic>> exercises, Map<String, dynamic> exercise) {
    return CheckboxListTile(
      title: const Text('Complete Exercise'),
      value: exercise["completed"] ?? false,
      onChanged: (bool? value) {
        setState(() {
          exercise["completed"] = value ?? false;
          // Update calories based on exercise completion status
          _updateExerciseCalories(exercises, exercise, value ?? false);
        });
      },
      checkColor: Colors.white, // Color of the checkmark
      activeColor: Colors.teal, // Color when checked
    );
  }

  double sectionCals(String title) {
    switch (title) {
      case 'warmUp':
        return _totalWarmUpCalories;
      case 'mainWorkout':
        return _totalMainWorkoutCalories;
      case 'coolDown':
        return _totalCoolDownCalories;
      default:
        return 0; // Return the original title if no match is found
    }
  }

// Method to mark section as completed
  void _markSectionAsCompleted(String title,
      List<Map<String, dynamic>> exercises, ProgressProvider progressProvider) {
    double sectionCalories = sectionCals(title);
    print(sectionCalories);
    setState(() {
      if (progressProvider.totalCalories == 0) {
        _congratulateUser();
      } else {
        // Deduct section calories from total available calories
        _totalCalories =
            (_totalCalories - sectionCalories).clamp(0, double.infinity);
        _totalCaloriesBurnt += sectionCalories;
        if (progressProvider.totalCalories == 0) {
          _congratulateUser();
        }
      }
      // Check if all calories are burned
    });

    // Update Firestore with the section completion status
    _updateCaloriesInFirestore(_totalCalories, _totalCaloriesBurnt, true);
  }

// Method to congratulate the user
  void _congratulateUser() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Congratulations!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('images/congrats.gif'), // Add the GIF animation here
              const SizedBox(height: 10),
              const Text(
                "You have completed all the exercises for today and burned all the calories! 🎉",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    // Close the dialog automatically after a few seconds
    Timer(const Duration(seconds: 10), () {
      // Navigator.of(context).pop();
    });
  }

// Unmark section as completed
  void _unmarkSectionAsCompleted(String title,
      List<Map<String, dynamic>> exercises, ProgressProvider progressProvider) {
    double sectionCalories = sectionCals(title);
    print(sectionCalories);
    setState(() {
      if (progressProvider.totalCalories == 0) {
        _congratulateUser();
      } else {
        // Deduct section calories from total available calories
        _totalCalories =
            (_totalCalories + sectionCalories).clamp(0, double.infinity);
        _totalCaloriesBurnt -= sectionCalories;
        if (progressProvider.totalCalories == 0) {
          _congratulateUser();
        }
        // No additional manual adjustment of _totalCalories or _totalCaloriesBurnt is needed here
        // since _updateExerciseCalories already handles it.
      }
    });

    // Update Firestore with the section's uncompleted status
    _updateCaloriesInFirestore(_totalCalories, _totalCaloriesBurnt, false);
  }

  Widget _buildSectionExpansionTile({
    required String title,
    required List<Map<String, dynamic>> exercises,
  }) {
    String formatTitle(String title) {
      switch (title) {
        case 'warmUp':
          return 'Warm-Up';
        case 'mainWorkout':
          return 'Main Workout';
        case 'coolDown':
          return 'Cool-Down';
        default:
          return title; // Return the original title if no match is found
      }
    }

    // Check if all exercises are completed
    bool _isSectionCompleted =
        exercises.every((exercise) => exercise["completed"] == true);

    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        // Update the section's completion status based on progressProvider
        bool _isSectionChecked = title == 'warmUp'
            ? progressProvider.warmUpCompleted
            : title == 'mainWorkout'
                ? progressProvider.mainWorkoutCompleted
                : title == 'coolDown'
                    ? progressProvider.coolDownCompleted
                    : false;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.fitness_center, color: Color(0xFF1F0051)),
            title: Text(
              formatTitle(title),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 46, 7, 112),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_drop_down, color: Color(0xFF1F0051)),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final feedback =
                              await _showFeedbackDialog(context, title);
                          await _generateExercisePlan(
                              exerciseType: title, feedback: feedback);
                        },
                  icon: const Icon(Icons.refresh, color: Color(0xFF286181)),
                  tooltip: 'Regenerate $title',
                ),
              ],
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ...exercises.isEmpty
                  ? [const Text("No exercises available.")]
                  : exercises.map((exercise) {
                      return ExpansionTile(
                        leading: const Icon(Icons.fitness_center,
                            color: Color(0xFF1F0051)),
                        title: Text(
                          exercise["exercise"] ?? "Unknown Exercise",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Sets: ${exercise["sets"]} | Reps: ${exercise["repetitions"]} | Calories Burned: ${exercise["calories_burned"] ?? "N/A"}",
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              exercise["description"] ??
                                  "No description available.",
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              const SizedBox(height: 16),
              // Add a checkbox for completing the entire section
              CheckboxListTile(
                title: const Text('Complete Section'),
                value: _isSectionChecked,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      progressProvider.toggleTask(title, true);
                      _markSectionAsCompleted(
                          title, exercises, progressProvider);
                    } else {
                      progressProvider.toggleTask(title, false);
                      _unmarkSectionAsCompleted(
                          title, exercises, progressProvider);
                    }
                  });
                },
                checkColor: Colors.white, // Color of the checkmark
                activeColor: Colors.teal, // Color when checked
              ),
            ],
          ),
        );
      },
    );
  }


// Method to mark the entire workout as complete
  void _markWorkoutAsCompleted() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch the most recent workout document
        final querySnapshot = await _firestore
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('dailyWorkouts')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;

          // Calculate total calories burnt for the workout
          final newTotalCaloriesBurnt =
              _mainWorkout.fold<double>(0, (sum, workout) {
            return sum + (workout["calories_burned"] ?? 0);
          });

          // Ensure calories do not exceed available total
          final updatedTotalCalories = _totalCalories - newTotalCaloriesBurnt;

          setState(() {
            _isWorkoutCompleted = true;

            // Update state safely
            _totalCaloriesBurnt = newTotalCaloriesBurnt;
            _totalCalories =
                updatedTotalCalories >= 0 ? updatedTotalCalories : 0;
            if (_totalCalories == 0) {
              // Display congratulatory dialog to the user
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Congratulations!'),
                    content: Text(
                        'You have completed your exercise plan for today.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } // Clamp to 0
            else {}
          });

          // Update Firestore with the new totals
          await doc.reference.update({
            'totalCaloriesBurnt': _totalCaloriesBurnt,
            'totalCalories': _totalCalories,
          });

          print(
              'Workout marked as completed and calories updated in Firestore.');
        } else {
          print('No recent workout found to mark as completed.');
        }
      } catch (e) {
        print('Error marking workout as completed: $e');
      }
    } else {
      print('No user is logged in.');
    }
  }


// Method to update completion status of an exercise
  void _updateCompletionStatus(int index, bool value) {
    setState(() {
      _completedExercises[index] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          // Header with gradient and waves
          Container(
            height: 270,
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
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          "Exercise Plans",
                          style: TextStyle(
                            fontFamily: "Raleway",
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.only(top: 300),
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
                            'images/RunningPerson.gif', // Path to your GIF
                            width: 500, // Adjusted size to make the GIF bigger
                            height: 500, // Adjusted size to make the GIF bigger
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Total Calories Burnt: ${progressProvider.totalCaloriesBurnt}",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 200, // Set width for the pie chart
                            height: 200, // Set height for the pie chart
                            child: _buildProgressSection(),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 0),
                            child: Column(
                              children: [
                                _buildSectionExpansionTile(
                                    title: "warmUp", exercises: _warmUp),
                                _buildSectionExpansionTile(
                                    title: "mainWorkout",
                                    exercises: _mainWorkout),
                                _buildSectionExpansionTile(
                                    title: "coolDown", exercises: _coolDown),
                                const SizedBox(height: 28),
                                Center(
                                  child: Column(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                // Show the feedback dialog when regenerating the entire plan
                                                final feedback =
                                                    await _showFeedbackDialog(
                                                        context,
                                                        'Exercise Plan');
                                                // Regenerate the entire nutrition plan with optional feedback
                                                await _generateExercisePlan(
                                                    feedback: feedback);
                                              },
                                        icon: const Icon(Icons.refresh,
                                            color: Colors.white),
                                        label: const Text("Regenerate Plan"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF286181),
                                          foregroundColor: Colors.white,
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Secondary Buttons Group
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ExerciseHistory()),
                                              );
                                            },
                                            icon: const Icon(Icons.history,
                                                color: Colors.orange),
                                            label: const Text("History"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.orange,
                                              side: const BorderSide(
                                                  color: Colors.orange),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: _toggleFavorite,
                                            icon: Icon(
                                              _isFavorited
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: _isFavorited
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              _isFavorited
                                                  ? "Remove from Favorites"
                                                  : "Add to Favorites",
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.purple,
                                              side: const BorderSide(
                                                  color: Colors.purple),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 13,
                                                      vertical: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Export Button in a New Row
                                      OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.ios_share,
                                            color: Colors.blue),
                                        label: const Text("Export"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: const BorderSide(
                                              color: Colors.blue),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          // If _isLoading is true, show a loading indicator over everything
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressProvider = Provider.of<ProgressProvider>(context);
    // Example data from exercise plan
    // Suggested calories could be based on the user's goal or some other logic
    double suggestedCalories = progressProvider.totalCalories;
    // = userData['goal'] == 'Weight Loss' ? 2200 : 2500; // Example suggested calories based on user goal
    double actualCalories = progressProvider
        .totalCaloriesBurnt; // Use the dynamic calories burnt from workout

    return SizedBox(
      width: 200, // Set width for the PieChart
      height: 200,
      child: CaloriesPieChart(
        suggestedCalories: suggestedCalories,
        actualCalories: actualCalories,
      ),
    );
  }
}

/// WaveClipper for the header waves
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

class CalorieChartWidget extends StatelessWidget {
  final List<int> caloriesBurned;
  final List<String> labels;

  const CalorieChartWidget({
    Key? key,
    required this.caloriesBurned,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Calories Burned Over the Week",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                                index < labels.length ? labels[index] : ''),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(
      caloriesBurned.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0, // Add this line to set the starting point of the bar
            toY: caloriesBurned[index]
                .toDouble(), // Specify the height of the bar
            gradient: LinearGradient(
              // Use gradient instead of colors
              colors: [
                Colors.teal,
                Colors.red,
                Colors.green
              ], // Two colors for the gradient
            ),
            width: 16,
          ),
        ],
      ),
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
