import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Import shared_preferences
import 'package:shared_preferences/shared_preferences.dart'; // <-- ADDED

import 'Services/Color.dart';
import 'Services/resuableTextField.dart';
import 'Services/user_auth_service.dart';
import 'SignUpScreeen.dart';
import 'Supervisor/Supervisor Dashboard/Supervisor Dashboard.dart';

class SupervisorLoginPage extends StatefulWidget {
  const SupervisorLoginPage({super.key});

  @override
  State<SupervisorLoginPage> createState() => _SupervisorLoginPageState();
}

class _SupervisorLoginPageState extends State<SupervisorLoginPage> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool _isLoading = false;

  // Define a key for saving the email
  final String _emailPrefsKey = 'supervisor_saved_email'; // <-- ADDED

  @override
  void initState() { // <-- ADDED THIS WHOLE METHOD
    super.initState();
    _loadSavedEmail(); // Load the email when the page opens
  }

  /// Loads the saved email from SharedPreferences
  Future<void> _loadSavedEmail() async { // <-- ADDED
    final prefs = await SharedPreferences.getInstance();
    final String savedEmail = prefs.getString(_emailPrefsKey) ?? '';
    _emailTextController.text = savedEmail;
  }

  /// Saves the email to SharedPreferences
  Future<void> _saveEmail(String email) async { // <-- ADDED
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailPrefsKey, email);
  }

  Future<void> _login() async {
    final String email = _emailTextController.text.trim(); // <-- ADDED
    final String password = _passwordTextController.text; // <-- ADDED

    if (email.isEmpty || password.isEmpty) { // <-- Use new variables
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- Save the email ---
    await _saveEmail(email); // <-- ADDED
    // ----------------------

    setState(() {
      _isLoading = true;
    });

    try {
      await UserAuthService.login(
        email, // <-- Use new variable
        password, // <-- Use new variable
        'supervisor',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SupervisorDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() { // <-- ADDED (Good practice to dispose controllers)
    _passwordTextController.dispose();
    _emailTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Supervisor Login Page"),
        backgroundColor: Color(0xFFFFFFF),
      ),
      body: Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width, // Make it take the full screen height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFF), Color(0xFF440099), Color(0xFF440099)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery
                .of(context)
                .size
                .height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget("assets/images/supervisor.png"),
                SizedBox(
                  height: 30,
                ),
                resuableTextField("Enter Username", Icons.person_outline, false,
                    _emailTextController),
                SizedBox(
                  height: 20,
                ),
                resuableTextField("Enter Password", Icons.lock_outline, false,
                    _passwordTextController),
                SizedBox(
                  height: 30,
                ),
                signInSignUPButton(context, true, _login, isLoading: _isLoading),
                signUpOption(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
            "Don't have an account?", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context, // Use the passed context
              MaterialPageRoute(builder: (context) => SignUpScreen()),
            );
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}

// You will need to make sure logoWidget is defined, e.g.:
Image logoWidget(String assetName) {
  return Image.asset(
    assetName,
    width: 240,
    height: 240,
  );
}