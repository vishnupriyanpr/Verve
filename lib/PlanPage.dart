import 'package:flutter/material.dart';

class PlanPage extends StatelessWidget {
  final String timestamp;
  final List<String> warmUp;
  final List<String> mainWorkout;
  final List<String> coolDown;
  final List<String> additionalNotes;

  PlanPage({
    required this.timestamp,
    required this.warmUp,
    required this.mainWorkout,
    required this.coolDown,
    required this.additionalNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Plan - $timestamp'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExerciseDetail('Warm-Up:', warmUp),
            _buildExerciseDetail('Main Workout:', mainWorkout),
            _buildExerciseDetail('Cool-Down:', coolDown),
            _buildExerciseDetail('Additional Notes:', additionalNotes),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(String title, List<String> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        ...activities.map<Widget>((activity) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('- $activity', style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        const SizedBox(height: 10),
      ],
    );
  }
}
