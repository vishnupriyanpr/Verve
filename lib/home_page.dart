import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'user_profile_page.dart';
import 'setting_page.dart';
import 'Exercise.dart';
import 'nutrition.dart';
import 'dart:async';
import 'Track_page.dart';
import 'package:provider/provider.dart';
import 'progress_provider.dart';
import 'MyNotesPage.dart';
import 'contactUsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  late DateTime _currentTime;
  List<String> _userGoals = [];

  String _searchQuery = '';
  List<String> _customGoals = [];

  bool _isMealExpanded = false;
  bool _isExerciseExpanded = false;

  bool _breakfastCompleted = false;
  bool _lunchCompleted = false;
  bool _dinnerCompleted = false;

  bool _morningExerciseCompleted = false;
  bool _afternoonExerciseCompleted = false;
  bool _eveningExerciseCompleted = false;

  int streakCount = 0; // Tracks consecutive days of goal completion
  bool allGoalsCompletedToday = false;

  List<Map<String, dynamic>> _currentMealPlan = []; // Changed to a list
  List<Map<String, dynamic>> _currentExercisePlan = [];
  bool _isLoadingMeal = true;
  bool _isLoadingExercise = true;

  int get _totalTasks => 6; // 3 meals + 3 exercises

  int get _completedTasks {
    int count = 0;
    if (_breakfastCompleted) count++;
    if (_lunchCompleted) count++;
    if (_dinnerCompleted) count++;
    if (_morningExerciseCompleted) count++;
    if (_afternoonExerciseCompleted) count++;
    if (_eveningExerciseCompleted) count++;
    return count;
  }

  double get _progress =>
      _completedTasks / 6; // Total 6 tasks (3 meals + 3 exercises)

  @override
  void initState() {
    super.initState();
    _fetchGoals();
    _currentTime = DateTime.now();
    _fetchMealPlan();

    _fetchExercisePlan();

    // Update the plans every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
      _fetchMealPlan();
      _fetchExercisePlan();
    });
  }

  Future<void> _fetchGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _userGoals = List<String>.from(data['goals'] ?? []);
          });
        }
      } catch (e) {
        print('Error fetching goals: $e');
      }
    }
  }

  Future<void> _fetchMealPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('nutritionPlans')
            .doc(user.uid)
            .collection('dailyMeals')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final hour = DateTime.now().hour;

          setState(() {
            if (hour >= 6 && hour < 11) {
              _currentMealPlan =
                  List<Map<String, dynamic>>.from(data['Breakfast'] ?? []);
            } else if (hour >= 11 && hour < 17) {
              _currentMealPlan =
                  List<Map<String, dynamic>>.from(data['Lunch'] ?? []);
            } else if (hour >= 18 && hour < 23) {
              _currentMealPlan =
                  List<Map<String, dynamic>>.from(data['Dinner'] ?? []);
            } else {
              _currentMealPlan =
                  List<Map<String, dynamic>>.from(data['Snack'] ?? []);
            }
          });
        } else {
          setState(() {
            _currentMealPlan = [];
          });
        }
      } catch (e) {
        print('Error fetching meal plan: $e');
        setState(() {
          _currentMealPlan = [];
        });
      }
    }
  }

List<String> _exercisePhases = ['warmUp', 'mainWorkout', 'coolDown','Relax'];
  int _currentPhaseIndex = 0;
  // Function to determine the current phase
void updateCurrentPhase(ProgressProvider progressProvider) {
  // Determine which phase is false
  if (!progressProvider.warmUpCompleted) {
    _currentPhaseIndex = 0; // warmUp
  } else if (!progressProvider.mainWorkoutCompleted) {
    _currentPhaseIndex = 1; // mainWorkout
  } else if (!progressProvider.coolDownCompleted) {
    _currentPhaseIndex = 2; // coolDown
  } else {
    _currentPhaseIndex = 2; // Relax
  }
}

  Future<void> _fetchExercisePlan() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('exercisePlans')
            .doc(user.uid)
            .collection('dailyWorkouts')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          if (_currentPhaseIndex !=3){
          final doc = querySnapshot.docs.first.data();
          setState(() {
  _currentExercisePlan = List<Map<String, dynamic>>.from(
   doc[_exercisePhases[_currentPhaseIndex]]  ?? []);
              });}
        } else {
          setState(() {
            _currentExercisePlan = [
              {
                'exercise': 'No exercise plan available.',
                'sets': '',
                'repetitions': ''
              }
            ];
          });
        }
      } catch (e) {
        
        print('Error fetching exercise plan: $e');
        setState(() {
          _currentExercisePlan = [
            {
              'exercise': 'Error fetching exercise plan.',
              'sets': '',
              'repetitions': ''
            }
          ];
        });
      }
    }
  }

  void _nextExercisePhase() {
    if (_currentPhaseIndex < _exercisePhases.length - 1) {
      setState(() {
        _currentPhaseIndex++;
      });
      _fetchExercisePlan(); // Fetch next phase's data
    } else if (_currentPhaseIndex == 3) {
      _currentExercisePlan = [
        {
          "exercise": "Relax",
          "sets": "N/A",
          "repetitions": "N/A",
          "calories_burned": "0"
        }
      ];
      print("All phases completed");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateStreaks() {
    if (_progress == 1.0 && !allGoalsCompletedToday) {
      setState(() {
        streakCount++;
        allGoalsCompletedToday = true;
      });
    } else if (_progress < 1.0 && allGoalsCompletedToday) {
      setState(() {
        allGoalsCompletedToday = false;
      });
    }
  }

  void _showAddGoalDialog() {
    final TextEditingController goalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Goal!"),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: goalController,
            decoration: const InputDecoration(
              hintText: "Enter your goal",
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (goalController.text.isNotEmpty) {
                _addGoal(goalController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addGoal(String goal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userGoals.add(goal);
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'goals': _userGoals}, SetOptions(merge: true));
      } catch (e) {
        print('Error saving goal: $e');
      }
    }
  }

  String getCurrentMeal() {
    final hour = _currentTime.hour;
    if (hour >= 6 && hour < 10) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 15) {
      return 'Lunch';
    } else if (hour >= 16 && hour < 20) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  // String getCurrentExercise() {
  //   final hour = _currentTime.hour;
  //   if (hour >= 6 && hour < 10) {
  //     return 'Morning Exercise';
  //   } else if (hour >= 11 && hour < 15) {
  //     return 'Midday Exercise';
  //   } else if (hour >= 16 && hour < 23) {
  //     return 'Evening Exercise';
  //   } else {
  //     return 'Relaxation Exercise';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
        final progressProvider = Provider.of<ProgressProvider>(context);
          updateCurrentPhase(progressProvider);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildHeader(context, user),
                Padding(
                  padding: const EdgeInsets.only(top: 250),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: _searchQuery.isNotEmpty
                                ? _getFilteredItems()
                                : [
                                    _buildProgressSummaryTile(context),
                                    _buildWaterReminder(),
                                    _buildMealExpansionTile(
                                        _getMealTitle(), _currentMealPlan),
                                    const SizedBox(height: 20),

                                    _buildSectionExpansionTile(_exercisePhases[
                                        _currentPhaseIndex]), // Here
                                    const SizedBox(height: 80),
                                    // _buildProgressSection(),
                                    // const SizedBox(height: 20),
                                    _buildUserGoalsSection(),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFC3C3B7),
        foregroundColor: Colors.black,
        heroTag: null,
        tooltip: 'Add Goal',
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  String _getMealTitle() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'Lunch';
    } else if (hour >= 19 && hour < 23) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  // List<String> _exercisePhases = ['Warm-Up Exercise', 'Main Workout', 'Cool Down'];
  // int _currentPhaseIndex = 0;

  String _getExerciseTitle() {
    return _exercisePhases[_currentPhaseIndex];
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
        final bool isCompleted = mealTitle == 'Breakfast'
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ExpansionTile(
            leading: Icon(mealIcon, color:Color(0xFF0D47A1)),
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
                Checkbox(
                  value: progressProvider.getTaskValue(mealTitle),
                  onChanged: (bool? value) {
                    if (value != null) {
                      progressProvider.toggleTask(mealTitle, value);
                      _nextExercisePhase();
                    }
                  },
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
                                                    Image.asset(
                            imagee, // Path to your GIF
                            width: 250, // Adjusted size to make the GIF bigger
                            height: 250, // Adjusted size to make the GIF bigger
                          ),
                          // Nutritional Info Section
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            'Nutritional Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blueAccent,
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
                            child: _buildPlanItems(ingredients.split(', ')),
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

                          ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 16),
                            leading: Icon(
                              Icons.fastfood,
                              color:Color(0x4AADC3FF),
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

  Widget _buildUserGoalsSection({List<String>? filteredGoals}) {
    final goalsToDisplay = filteredGoals ?? _userGoals;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Goals",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Raleway",
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          if (goalsToDisplay.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No goals found.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...goalsToDisplay.map((goal) {
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    goal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _editGoal(goal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteGoal(goal),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _confirmDeleteGoal(String goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Goal"),
        content: Text("Are you sure you want to delete the goal \"$goal\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _userGoals.remove(goal);
              });

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({'goals': _userGoals}, SetOptions(merge: true));
                } catch (e) {
                  print('Error deleting goal: $e');
                }
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _editGoal(String goal) {
    TextEditingController _goalController = TextEditingController(text: goal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Goal"),
          content: TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: "Goal"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final index = _userGoals.indexOf(goal);
                if (index != -1) {
                  setState(() {
                    _userGoals[index] = _goalController.text.trim();
                  });

                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({'goals': _userGoals}, SetOptions(merge: true));
                    } catch (e) {
                      print('Error updating goal: $e');
                    }
                  }
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  final TextEditingController _searchController = TextEditingController();

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController, // Attach the controller to the TextField
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase(); // Update the search query
          });
        },
        decoration: InputDecoration(
          hintText: 'Search goals, meals, or exercises...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1),),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = ''; // Clear the search query
                      _searchController
                          .clear(); // Clear the text in the TextField
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  List<Widget> _getFilteredItems() {
    final List<Widget> items = [];

    if (_userGoals.isNotEmpty &&
        (_searchQuery.isEmpty ||
            _userGoals
                .any((goal) => goal.toLowerCase().contains(_searchQuery)))) {
      items.add(
        _buildUserGoalsSection(
          filteredGoals: _userGoals
              .where((goal) => goal.toLowerCase().contains(_searchQuery))
              .toList(),
        ),
      );
    }

    if (_searchQuery.isEmpty || _currentMealPlan.contains(_searchQuery)) {
      items.add(_buildMealExpansionTile(_getMealTitle(), _currentMealPlan));
    }

    if (_searchQuery.isEmpty || _currentExercisePlan.contains(_searchQuery)) {
      items.add(_buildSectionExpansionTile(_getExerciseTitle()));
    }

    if (items.isEmpty && _searchQuery.isNotEmpty) {
      items.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No results found for "$_searchQuery".',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildWaterReminder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.local_drink, color: Colors.blue, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Stay hydrated! Remember to drink 8 glasses of water today.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummaryTile(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading:
                const Icon(Icons.track_changes, color: Color(0xFF0D47A1), size: 40),
            title: const Text(
              "Track Your Progress",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Raleway",
                  color: Colors.black87),
            ),
            subtitle: Text(
              "${(progressProvider.progress * 100).toInt()}% Completed Today!\nCheck your streaks and achievements.",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward, color: Color(0xFF0D47A1)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrackPage()),
              );
            },
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
                      color: Color(0xFF0D47A1),
                  ),
                ),
                if (index < items.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: Color(0xFF0D47A1),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                items[index],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionExpansionTile(String title) {
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

    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final bool isCompleted = title == 'Warm-Up'
            ? progressProvider.warmUpCompleted
            : title == 'Main Workout'
                ? progressProvider.mainWorkoutCompleted
                : progressProvider.coolDownCompleted;
                      updateCurrentPhase( progressProvider);

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ExpansionTile(
            leading: const Icon(
              Icons.fitness_center,
              color: Color(0xFF0D47A1), // Change this to any dark blue you like
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTitle(title),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 88, 79),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: progressProvider.getTaskValue(title),
                      onChanged: (bool? value) {
                        if (value != null) {
                          progressProvider.toggleTask(title, value);
                          _nextExercisePhase();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _currentExercisePlan.isEmpty
                ? [const Text("No exercises available.")]
                : _currentExercisePlan.map((exercise) {
                    return ListTile(
                      leading:
                          const Icon(Icons.directions_run, color: Colors.blueAccent),
                      title: Text(
                        exercise["exercise"] ?? "Unknown Exercise",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Sets: ${exercise["sets"] ?? 'N/A'} | Reps: ${exercise["repetitions"] ?? 'N/A'}",
                      ),
                      trailing: Text(
                        "Calories: ${exercise["calories_burned"] ?? 'N/A'} kcal",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF3FFFFFE),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomIcon(
            icon: Icons.restaurant_menu,
            label: 'Nutrition Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Nutrition()),
              );
            },
          ),
          _buildBottomIcon(
            icon: Icons.fitness_center,
            label: 'Exercise Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Exercise()),
              );
            },
          ),
          /*
        _buildBottomIcon(
          icon: Icons.track_changes, // Icon for tracking
          label: 'Track',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TrackPage()), // Navigate to Track Page
            );
          },
        ),
        */
        ],
      ),
    );
  }
}

Widget _buildHeader(BuildContext context, User? user) {
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
                height: 100, color: const Color(0xFF1F0051).withOpacity(0.3)),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
                height: 80, color: const Color(0xFF360980).withOpacity(0.5)),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(user!.photoURL!,
                            fit: BoxFit.cover, width: 60, height: 60),
                      )
                    : const Icon(Icons.person, size: 30, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w300),
                  ),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 90),
            child: const Text(
              'VERVE',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: SafeArea(
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white, size: 32),
              color: const Color(0xFFF5F5DC),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              itemBuilder: (BuildContext context) {
                return [
                  _buildMenuItem(
                      icon: Icons.person, text: 'Profile', color: Colors.teal),
                  _buildMenuItem(
                      icon: Icons.mail, text: 'Contact Us', color: Colors.blue),
                  _buildMenuItem(
                      icon: Icons.notes,
                      text: 'My Notes',
                      color: Colors.deepPurple),
                  _buildMenuItem(
                      icon: Icons.settings,
                      text: 'Settings',
                      color: Colors.grey),
                  _buildMenuItem(
                      icon: Icons.logout, text: 'Log Out', color: Colors.red),
                ];
              },
              onSelected: (value) {
                switch (value) {
                  case 'Profile':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserProfilePage()),
                    );
                    break;
                  case 'Contact Us':
                    _showContactDialog(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactUsPage()),
                    );
                    break;
                  case 'Settings':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                    break;
                  case 'My Notes':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyNotesPage()),
                    );
                    break;
                  case 'Log Out':
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                    break;
                }
              },
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBottomIcon({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Icon(icon, color: Colors.blueAccent, size: 30),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    ),
  );
}

PopupMenuItem<String> _buildMenuItem(
    {required IconData icon, required String text, required Color color}) {
  return PopupMenuItem<String>(
    value: text,
    child: Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

void _showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Contact Us'),
        content: const Text(
            'For inquiries, please email us at verveapp1215@gmail.com.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      );
    },
  );
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        3 * size.width / 4, size.height - 40, size.width, size.height - 20);
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
          height: 180, // Smaller height for a smaller chart
          width: 180, // Width also adjusted to make it circular and compact
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius:
                  25, // Smaller center space radius for a compact look
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
