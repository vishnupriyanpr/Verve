import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressProvider with ChangeNotifier {
  // bool breakfastCompleted = false;
  // bool lunchCompleted = false;
  // bool dinnerCompleted = false;
  // bool snackCompleted = false;
  // bool warmUpCompleted = false;
  // bool mainWorkoutCompleted = false;
  // bool coolDownCompleted = false;

  final Map<String, String> taskMapping = {
    'Warm-Up': 'warmUpCompleted',
    'Main Workout': 'mainWorkoutCompleted',
    'Cool-Down': 'coolDownCompleted',
  };

  double _totalCalories = 0; // Example initial value
  double _totalCaloriesBurnt = 0.0;
  double _totalWarmUpCalories = 0;
  double _totalMainWorkoutCalories = 0;
  double _totalCoolDownCalories = 0;

  double get totalCalories => _totalCalories;
  double get totalCaloriesBurnt => _totalCaloriesBurnt;
  double get totalWarmUpCalories => _totalCaloriesBurnt;
  double get totalMainWorkoutCalories => _totalMainWorkoutCalories;
  double get totalCoolDownCalories => _totalCoolDownCalories;

  // Method to update calories
  void updateCalories(
      {required double totalCalories,
      required double totalCaloriesBurnt,
      required double totalWarmUpCalories,
      required double totalMainWorkoutCalories,
      required double totalCoolDownCalories}) {
    _totalCalories = totalCalories;
    _totalCaloriesBurnt = totalCaloriesBurnt;
    _totalWarmUpCalories = totalWarmUpCalories;
    _totalMainWorkoutCalories = totalMainWorkoutCalories;
    _totalCoolDownCalories = totalCoolDownCalories;

    notifyListeners(); // Ensure widgets listening to this provider are updated
  }

  bool _breakfastCompleted = false;
  bool _lunchCompleted = false;
  bool _dinnerCompleted = false;
  bool _snackCompleted = false;
  bool _warmUpCompleted = false;
  bool _mainWorkoutCompleted = false;
  bool _coolDownCompleted = false;

  int _streakCount = 0;
  int get streakCount => _streakCount;

  // Overall progress fraction: 0.0 = none, 1.0 = all
  double get progress {
    int completedTasks = 0;
    if (breakfastCompleted) completedTasks++;
    if (lunchCompleted) completedTasks++;
    if (dinnerCompleted) completedTasks++;
    if (snackCompleted) completedTasks++;
    if (warmUpCompleted) completedTasks++;
    if (mainWorkoutCompleted) completedTasks++;
    if (coolDownCompleted) completedTasks++;
    return completedTasks / 7;
  }

  // Getters for UI access
  bool get breakfastCompleted => _breakfastCompleted;
  bool get lunchCompleted => _lunchCompleted;
  bool get dinnerCompleted => _dinnerCompleted;
  bool get snackCompleted => _snackCompleted;
  bool get warmUpCompleted => _warmUpCompleted;
  bool get mainWorkoutCompleted => _mainWorkoutCompleted;
  bool get coolDownCompleted => _coolDownCompleted;

  // (Optional getters) — unchanged
  int get mealsCompleted {
    int count = 0;
    if (breakfastCompleted) count++;
    if (lunchCompleted) count++;
    if (dinnerCompleted) count++;
    if (snackCompleted) count++;
    return count;
  }

  int get goalsMet {
    int count = 0;
    if (breakfastCompleted) count++;
    if (lunchCompleted) count++;
    if (dinnerCompleted) count++;
    if (snackCompleted) count++;
    if (warmUpCompleted) count++;
    if (mainWorkoutCompleted) count++;
    if (coolDownCompleted) count++;
    return count;
  }

// Method to congratulate the user
  void _congratulateUser() {
    var context;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Congratulations!"),
          content: const Text(
            "You have completed all the exercises for this section and burned all the calories! 🎉",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Toggling a task updates local state, updates streak, then tries to save once
  // Toggle task completion and sync progress
  void toggleTask(String task, bool value) {
    switch (task) {
      case 'Breakfast':
        _breakfastCompleted = value;

        break;
      case 'Lunch':
        _lunchCompleted = value;
        break;
      case 'Dinner':
        _dinnerCompleted = value;
        break;
      case 'Snack':
        _snackCompleted = value;
        break;
      case 'warmUp':
        _warmUpCompleted = value;

        if (_warmUpCompleted) {
          if (_totalCalories == 0) {
            print("Congrats!");
          } else {
            _totalCalories = (_totalCalories - _totalWarmUpCalories)
                .clamp(0, double.infinity);
            _totalCaloriesBurnt += _totalWarmUpCalories;
          }
        } else {
          // Deduct section calories from total available calories
          _totalCalories =
              (_totalCalories + _totalWarmUpCalories).clamp(0, double.infinity);
          _totalCaloriesBurnt -= _totalWarmUpCalories;
        }

        break;
      case 'mainWorkout':
        _mainWorkoutCompleted = value;

        if (_mainWorkoutCompleted) {
          if (_totalCalories == 0) {
            print("Congrats!");
          } else {
            _totalCalories = (_totalCalories - _totalMainWorkoutCalories)
                .clamp(0, double.infinity);
            _totalCaloriesBurnt += _totalMainWorkoutCalories;
          }
        } else {
          // Deduct section calories from total available calories
          _totalCalories = (_totalCalories + _totalMainWorkoutCalories)
              .clamp(0, double.infinity);
          _totalCaloriesBurnt -= _totalMainWorkoutCalories;
        }
        break;
      case 'coolDown':
        _coolDownCompleted = value;

        if (_coolDownCompleted) {
          if (_totalCalories == 0) {
            print("Congrats!");
          } else {
            _totalCalories = (_totalCalories - _totalCoolDownCalories)
                .clamp(0, double.infinity);
            _totalCaloriesBurnt += _totalCoolDownCalories;
          }
        } else {
          // Deduct section calories from total available calories
          _totalCalories = (_totalCalories + _totalCoolDownCalories)
              .clamp(0, double.infinity);
          _totalCaloriesBurnt -= _totalCoolDownCalories;
        }
        break;
    }

    _updateStreak();
    notifyListeners();

    saveDailyProgress();
    checkAndResetProgress();
  }

  // New method: Get task value
  bool getTaskValue(String task) {
    switch (task) {
      case 'Breakfast':
        return _breakfastCompleted;
      case 'Lunch':
        return _lunchCompleted;
      case 'Dinner':
        return _dinnerCompleted;
      case 'Snack':
        return _snackCompleted;
      case 'warmUp':
        return _warmUpCompleted;
      case 'mainWorkout':
        return _mainWorkoutCompleted;
      case 'coolDown':
        return _coolDownCompleted;
      default:
        return false; // Fallback for unknown tasks
    }
  }

  // If user completes all tasks => increment streak, else reset
  void _updateStreak() {
    if (progress == 1.0) {
      _streakCount++;
    } else {
      _streakCount = 0;
    }
  }

  // Load user progress from Firebase
  Future<void> loadUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        _breakfastCompleted = data['tasks'][0]['completed'] ?? false;
        _lunchCompleted = data['tasks'][1]['completed'] ?? false;
        _dinnerCompleted = data['tasks'][2]['completed'] ?? false;
        _snackCompleted = data['tasks'][3]['completed'] ?? false;
        _warmUpCompleted = data['tasks'][4]['completed'] ?? false;
        _mainWorkoutCompleted = data['tasks'][5]['completed'] ?? false;
        _coolDownCompleted = data['tasks'][6]['completed'] ?? false;
        _totalCalories = data['totalCalories'] ?? 0;
        _totalCaloriesBurnt = data['totalCaloriesBurnt'] ?? 0;
        _totalWarmUpCalories = data['totalWarmUpCalories'] ?? 0;
        _totalMainWorkoutCalories = data['totalMainWorkoutCalories'] ?? 0;
        _totalCoolDownCalories = data['totalCoolDownCalories'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print("Error loading user progress: $e");
    }
  }

  Future<void> saveDailyProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';

      final data = {
        'date': formattedDate,
        'progress': progress * 100,
        'streak': _streakCount,
        'completedTasks': _getCompletedTaskCount(),
        'totalCalories': _totalCalories,
        'totalCaloriesBurnt': _totalCaloriesBurnt,
        'totalWarmUpCalories': _totalWarmUpCalories,
        'totalMainWorkoutCalories': _totalMainWorkoutCalories,
        'totalCoolDownCalories': _totalCoolDownCalories,
        'tasks': [
          {'title': 'Breakfast', 'completed': breakfastCompleted},
          {'title': 'Lunch', 'completed': lunchCompleted},
          {'title': 'Dinner', 'completed': dinnerCompleted},
          {'title': 'Snack', 'completed': snackCompleted},
          {'title': 'warmUp', 'completed': warmUpCompleted},
          {'title': 'mainWorkout', 'completed': mainWorkoutCompleted},
          {'title': 'coolDown', 'completed': coolDownCompleted},
        ],
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('history')
          .doc(formattedDate)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print("Error saving daily progress: $e");
    }
  }

  void checkAndResetProgress() {
    if (warmUpCompleted && mainWorkoutCompleted && coolDownCompleted) {
      //  resetDailyProgress();  // Reset all progress to false
      notifyListeners();
    }
  }

  // Reset progress at the start of a new day
  void resetDailyProgress() {
    _breakfastCompleted = false;
    _lunchCompleted = false;
    _dinnerCompleted = false;
    _snackCompleted = false;
    _warmUpCompleted = false;
    _mainWorkoutCompleted = false;
    _coolDownCompleted = false;
    _totalCalories = 0; // Example initial value
    _totalCaloriesBurnt = 0.0;
    _totalWarmUpCalories = 0;
    _totalMainWorkoutCalories = 0;
    _totalCoolDownCalories = 0;

    notifyListeners();
  }

  // Helper method to count completed tasks
  int _getCompletedTaskCount() {
    return [
      _breakfastCompleted,
      _lunchCompleted,
      _dinnerCompleted,
      _snackCompleted,
      _warmUpCompleted,
      _mainWorkoutCompleted,
      _coolDownCompleted
    ].where((done) => done).length;
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
