import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackHistoryPage extends StatefulWidget {
  const TrackHistoryPage({Key? key}) : super(key: key);

  @override
  _TrackHistoryPageState createState() => _TrackHistoryPageState();
}

class _TrackHistoryPageState extends State<TrackHistoryPage> {
  late TextEditingController _searchController;

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];

  // For the summary panel
  double _averageProgress = 0.0;
  double _maxProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      final historyList = querySnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _history = historyList.cast<Map<String, dynamic>>();
        _filteredHistory = _history;
      });

      _calculateSummaryStats();
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  void _calculateSummaryStats() {
    if (_history.isEmpty) {
      _averageProgress = 0.0;
      _maxProgress = 0.0;
      return;
    }

    double total = 0.0;
    double maxVal = 0.0;
    for (var record in _history) {
      final progress = (record['progress'] ?? 0).toDouble();
      total += progress;
      if (progress > maxVal) maxVal = progress;
    }

    _averageProgress = total / _history.length;
    _maxProgress = maxVal;
  }

  void _filterHistory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((record) {
          final date = (record['date'] ?? '').toString().toLowerCase();
          final progress = record['progress'].toString();

          // Flatten tasks to a single string
          final tasks = (record['tasks'] as List<dynamic>? ?? []);
          final taskTitles = tasks
              .map((t) => (t['title'] ?? '').toString().toLowerCase())
              .join(' ');

          return date.contains(query.toLowerCase())
              || progress.contains(query)
              || taskTitles.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  /// Deletes the Firestore doc for [dateStr], then removes it from local lists.
  Future<void> _deleteRecord(String dateStr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('history')
          .doc(dateStr)
          .delete();

      setState(() {
        _history.removeWhere((record) => record['date'] == dateStr);
        _filteredHistory.removeWhere((record) => record['date'] == dateStr);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record for $dateStr deleted.')),
      );
    } catch (e) {
      print('Error deleting record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete record.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: Column(
              children: [
                _buildSearchBar(),
                _buildSummaryPanel(),
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? const Center(child: Text('No history available.'))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final record = _filteredHistory[index];
                      return _buildHistoryCard(record);
                    },
                  ),
                ),
              ],
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
                color: const Color(0xFF1F0051).withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.history,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Track History',
                  style: TextStyle(
                    fontFamily: 'Raleway',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Search History',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: _filterHistory,
      ),
    );
  }

  /// Simple row showing total days, avg progress, max progress
  Widget _buildSummaryPanel() {
    if (_history.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem('Total Days', '${_history.length}'),
              _buildSummaryItem(
                  'Avg Progress', '${_averageProgress.toStringAsFixed(1)}%'),
              _buildSummaryItem(
                  'Max Progress', '${_maxProgress.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final dateStr = record['date'] ?? 'Unknown Date';
    final rawProgress = record['progress'] ?? 0;
    final double progressVal =
    rawProgress is int ? rawProgress.toDouble() : rawProgress;
    final tasks = (record['tasks'] as List<dynamic>? ?? []);
    final progressPercent = (progressVal / 100).clamp(0.0, 1.0);
    final completedTasks = tasks.where((t) => t['completed'] == true).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 6),
            Text(
              '${progressVal.toStringAsFixed(1)}% Completed '
                  '($completedTasks of ${tasks.length} tasks)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        children: [
          const Divider(),
          // Display tasks as chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: tasks.map((task) {
                final bool isCompleted = task['completed'] ?? false;
                final taskTitle = task['title'] ?? 'Task';
                return Chip(
                  label: Text(taskTitle),
                  avatar: Icon(
                    isCompleted ? Icons.check : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  backgroundColor:
                  isCompleted ? Colors.green[100] : Colors.grey[200],
                );
              }).toList(),
            ),
          ),
          // Delete button row
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete this day',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Entry'),
                        content: Text('Are you sure you want to delete $dateStr?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      _deleteRecord(dateStr);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
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
