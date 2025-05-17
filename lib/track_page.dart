import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'progress_provider.dart';
import 'track_history.dart';
import 'dart:async';  // For Timer

class TrackPage extends StatefulWidget {
  const TrackPage({Key? key}) : super(key: key);

  @override
  _TrackPageState createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  late ProgressProvider _progressProvider;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        Provider.of<ProgressProvider>(context, listen: false).resetDailyProgress();
      }
    });
  }


  @override
  void dispose() {
    _progressProvider.saveDailyProgress();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<ProgressProvider>(context, listen: false).loadUserProgress();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildDailySummary(context),
                  const SizedBox(height: 20),
                  _buildTaskList(context),
                  const SizedBox(height: 20),
                  _buildCircularProgress(context),
                  const SizedBox(height: 20),
                  _buildStreakAchievements(context),
                  const SizedBox(height: 20),
                  _buildViewHistoryButton(context),
                  const SizedBox(height: 20),
                  _buildResetButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          // Wave pattern at bottom
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
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Title + avatar
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.track_changes, size: 50, color:Color(0xFF1F0051)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Progress Tracker',
                  style: TextStyle(
                    fontFamily: "Raleway",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildDailySummary(BuildContext context) {
  return Consumer<ProgressProvider>(
    builder: (context, provider, child) {
      final completedCount = [
        provider.breakfastCompleted,
        provider.lunchCompleted,
        provider.dinnerCompleted,
        provider.snackCompleted,
        provider.warmUpCompleted,
        provider.mainWorkoutCompleted,
        provider.coolDownCompleted,
      ].where((task) => task).length;

      final totalTasks = 7;

      final percent = (completedCount / totalTasks) * 100;
      final allCompleted = completedCount == totalTasks;

      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: Text(
                  '$completedCount/$totalTasks',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: const Text(
                'Today\'s Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:Color(0xFF1F0051)),
              ),
              subtitle: Text('${percent.toStringAsFixed(1)}% completed'),
            ),
            if (allCompleted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Congratulations! You completed all your tasks!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'images/congrats.gif',
                      height: 150,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}




  Widget _buildTaskList(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, child) {
        // Group tasks into Meals vs. Exercises
        final mealTasks = [
          {'title': 'Breakfast', 'status': provider.breakfastCompleted},
          {'title': 'Lunch', 'status': provider.lunchCompleted},
          {'title': 'Dinner', 'status': provider.dinnerCompleted},
          {'title': 'Snack', 'status': provider.snackCompleted},
        ];

        final exerciseTasks = [
          {'title': 'warmUp', 'status': provider.warmUpCompleted},
          {'title': 'mainWorkout', 'status': provider.mainWorkoutCompleted},
          {'title': 'coolDown', 'status': provider.coolDownCompleted},
        ];




        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Task List',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:Color(0xFF1F0051)),
                ),
                const SizedBox(height: 10),
                _buildTaskSection(mealTasks, provider, 'Meals'),
                const SizedBox(height: 16),
                _buildTaskSection(exerciseTasks, provider, 'Exercise'),
              ],
            ),
          ),
        );
      },
    );
  }




  Widget _buildTaskSection(
      List<Map<String, dynamic>> tasks,
      ProgressProvider provider,
      String heading,
      ) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.map((task) {
          final bool isCompleted = task['status'] as bool;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.grey, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                formatTitle(task['title']),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.black : Colors.grey.shade600,
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? Colors.green : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Switch(
                value: isCompleted,
                onChanged: (value) {
                  provider.toggleTask(task['title'] as String, value);

                  // Quick feedback via snack bar
                  final snackBar = SnackBar(
                    content: Text(
                      value
                          ? '${task['title']} completed!'
                          : '${task['title']} marked as pending.',
                    ),
                    duration: const Duration(seconds: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, child) {
        final progress = provider.progress;

        // Determine color based on progress level
        Color progressColor;
        if (progress <= 1 / 3) {
          progressColor = const Color.fromARGB(255, 186, 53, 44);
        } else if (progress <= 2 / 3) {
          progressColor = const Color.fromARGB(255, 176, 148, 70);
        } else {
          progressColor = const Color.fromARGB(255, 99, 162, 101);
        }

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color:Color(0xFF1F0051)),
                ),
                const SizedBox(height: 10),
                SfCircularChart(
                  series: <CircularSeries>[
                    DoughnutSeries<_ProgressData, String>(
                      dataSource: [
                        _ProgressData('Completed', progress * 100),
                        _ProgressData('Pending', (1 - progress) * 100),
                      ],
                      xValueMapper: (_ProgressData data, _) => data.task,
                      yValueMapper: (_ProgressData data, _) => data.completion,
                      animationDuration: 1200, // animate
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                        labelPosition: ChartDataLabelPosition.outside,
                      ),
                      pointColorMapper: (_ProgressData data, _) =>
                      data.task == 'Completed' ? progressColor : Colors.grey.shade300,
                      innerRadius: '70%',
                      radius: '90%',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildStreakAchievements(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, child) {
        final streak = provider.streakCount;
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streaks & Achievements',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:Color(0xFF1F0051)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 50,
                  ),
                  title: Text(
                    'Streak: $streak days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: streak > 0 ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                  subtitle: Text(
                    streak > 0 ? 'Keep up the great work!' : 'Start your streak today!',
                    style: TextStyle(
                      fontSize: 14,
                      color: streak > 0 ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (streak > 0)
                  LinearProgressIndicator(
                    value: streak / 30, // assume 30-day streak goal
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                const SizedBox(height: 10),
                if (streak == 0)
                  Text(
                    'Tip: Try setting small achievable goals to start your streak.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewHistoryButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TrackHistoryPage()),
          );
        },
        icon: const Icon(Icons.history, color: Colors.teal),
        label: const Text("View History"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.teal,
          side: const BorderSide(color: Colors.teal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          final provider = Provider.of<ProgressProvider>(context, listen: false);
          provider.resetDailyProgress();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress reset for today!')),
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Today'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _ProgressData {
  _ProgressData(this.task, this.completion);
  final String task;
  final double completion;
}

// WaveClipper for the header decoration
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 4, size.height,
      size.width / 2, size.height - 20,
    );
    path.quadraticBezierTo(
      3 * size.width / 4, size.height - 40,
      size.width, size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
