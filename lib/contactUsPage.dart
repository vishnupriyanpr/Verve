import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'verveapp1215@gmail.com',
        queryParameters: {
          'subject': _subjectController.text,
          'body': 'Name: ${_nameController.text}\n'
              'Email: ${_emailController.text}\n\n'
              'Message: ${_messageController.text}'
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showSnackBar('Could not open email app. Please try again.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormFields(),
                    const SizedBox(height: 20),
                    _buildSendMessageButton(),
                    const SizedBox(height: 20),
                    _buildContactLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              child: Container(height: 100, color: const Color(0xFF1F0051).withOpacity(0.3)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.contact_mail, size: 40, color: Colors.teal),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Contact Us',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400),
                    ),
                    Text(
                      'We\'re here to assist you!',
                      style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Your Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Your Email', Icons.email, email: true),
            const SizedBox(height: 16),
            _buildTextField(_subjectController, 'Subject', Icons.subject),
            const SizedBox(height: 16),
            _buildTextField(_messageController, 'Message', Icons.message, maxLines: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool email = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color:Color(0xFF286181)),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (email && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildSendMessageButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _sendEmail,
        icon: const Icon(Icons.send, size: 22, color:Color(0xFF1F0051)),
        label: const Text(
          'Send Message',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color:Color(0xFF1F0051),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF1F0051),
          side: const BorderSide(color:Color(0xFF1F0051), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }


  Widget _buildContactLink() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Or contact us directly at ',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: 'verveapp1215@gmail.com',
              style: const TextStyle(
                color: Color(0xFF1F0051)


                ,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri emailUri = Uri(scheme: 'mailto', path: 'ettizanapp@gmail.com');
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    _showSnackBar('Error opening email app.');
                  }
                },
            ),
          ],
        ),
      ),
    );
  }
}

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
