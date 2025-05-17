import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  void _deleteAccount(BuildContext context) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          Container(
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
                // Wavy Background
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
                // App Title
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Content Section
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Delete Account
                  _buildSettingItem(
                    context,
                    icon: Icons.delete,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    color: Colors.red,
                    onTap: () => _deleteAccount(context),
                  ),
                  const SizedBox(height: 20),
                  // Language Selection
                  _buildSettingItem(
                    context,
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'Change app language',
                    color: Colors.blue,
                    onTap: () {
                      // Add language change functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language settings coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Placeholder for More Settings
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    color: Colors.orange,
                    onTap: () {
                      // Add notification settings functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Custom Clipper for Wave Background
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 * size.width / 4, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
