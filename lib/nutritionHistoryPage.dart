import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'favorite_nutrition_plans_page.dart';

class HistoryPage extends StatelessWidget {
  final String userId;

  const HistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plansStream = FirebaseFirestore.instance
        .collection('nutritionPlans')
        .doc(userId)
        .collection('dailyMeals')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          _buildHeader(context),
          // Main Content
          Padding(
            padding: const EdgeInsets.only(top: 240),
            child: StreamBuilder<QuerySnapshot>(
              stream: plansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>?;

                    final breakfast = List<Map<String, dynamic>>.from(data?['Breakfast'] ?? []);
                    final lunch = List<Map<String, dynamic>>.from(data?['Lunch'] ?? []);
                    final dinner = List<Map<String, dynamic>>.from(data?['Dinner'] ?? []);
                    final snack = List<Map<String, dynamic>>.from(data?['Snack'] ?? []);

                    final timestamp = data?['timestamp'] as Timestamp?;
                    final dateTime = timestamp?.toDate() ?? DateTime.now();
                    final formattedDate =
                        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                    final formattedTime =
                        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          'Plan: $formattedDate at $formattedTime',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: "Raleway",
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: _buildPlanSummary(breakfast, lunch, dinner, snack),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          _buildMealTile('Breakfast', breakfast, Icons.breakfast_dining),
                          _buildMealTile('Lunch', lunch, Icons.lunch_dining),
                          _buildMealTile('Dinner', dinner, Icons.dinner_dining),
                          _buildMealTile('Snack', snack, Icons.fastfood),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 280,
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
            top: MediaQuery.of(context).padding.top + 0,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.fastfood_outlined,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Nutrition Plans History',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Raleway",
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Review your past meal plans',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoriteNutritionPlansPage(userId: userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary(
      List<Map<String, dynamic>> breakfast,
      List<Map<String, dynamic>> lunch,
      List<Map<String, dynamic>> dinner,
      List<Map<String, dynamic>> snack,
      ) {
    final totalCalories = [
      ...breakfast,
      ...lunch,
      ...dinner,
      ...snack,
    ].fold<double>(0, (sum, item) => sum + (item['calories'] ?? 0));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        'Total Calories: ${totalCalories.toStringAsFixed(0)} kcal',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildMealTile(String mealTitle, List<Map<String, dynamic>> items, IconData icon) {
    if (items.isEmpty) {
      return ListTile(
        leading: Icon(icon, color: Color(0xFF1F0051)),
        title: Text('$mealTitle: No items'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon, color: Color(0xFF1F0051)),
          title: Text('$mealTitle (${items.length} items)'),
        ),
        ...items.map((item) {
          final ingredients = item['ingredients'];
          final preparation = item['preparation'];

          // Handle ingredients and preparation as either List or String
          final ingredientDetails = ingredients is List
              ? ingredients.join(', ')
              : (ingredients ?? 'No ingredients provided');

          final preparationDetails = preparation is List
              ? preparation.join('. ')
              : (preparation ?? 'No preparation details provided');

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Name
                  Text(
                    item['name'] ?? 'Unnamed Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nutritional Info
                  Text('Calories: ${item['calories'] ?? 0} kcal'),
                  Text('Protein: ${item['protein'] ?? 0} g'),
                  Text('Carbs: ${item['carbs'] ?? 0} g'),
                  Text('Fat: ${item['fat'] ?? 0} g'),
                  const Divider(thickness: 1, height: 20),
                  // Ingredients Section
                  ExpansionTile(
                    leading: const Icon(Icons.list, color: Color(0xFF1F0051)),
                    title: const Text(
                      'Ingredients',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          ingredientDetails,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  // Preparation Section
                  ExpansionTile(
                    leading: const Icon(Icons.receipt, color: Color(0xFF1F0051)),
                    title: const Text(
                      'Preparation',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          preparationDetails,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const Divider(thickness: 1, height: 20),
      ],
    );
  }


  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No past plans found.\nStart creating plans now!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
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
