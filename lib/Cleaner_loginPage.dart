import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Cleaner/Cleaners Dashboard/CleanersDashboard.dart';
import 'Services/Color.dart';
import 'Services/resuableTextField.dart';
import 'Services/user_auth_service.dart';
import 'SignUpScreeen.dart';

class CleanersLoginPage extends StatefulWidget {
  const CleanersLoginPage({super.key});

  @override
  State<CleanersLoginPage> createState() => _CleanersLoginPageState();
}

class _CleanersLoginPageState extends State<CleanersLoginPage> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  bool _isLoading = false;

  // Key for saving the email
  final String _emailPrefsKey = 'cleaner_saved_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  /// Loads the saved email from SharedPreferences
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedEmail = prefs.getString(_emailPrefsKey) ?? '';
    if (savedEmail.isNotEmpty) {
      _emailTextController.text = savedEmail;
    }
  }

  /// Saves the email to SharedPreferences
  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailPrefsKey, email);
  }

  Future<void> _login() async {
    final String email = _emailTextController.text.trim();
    final String password = _passwordTextController.text;

    if (email.isEmpty || password.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both email and password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserAuthService.login(email, password, 'cleaner');

      // Save email after successful login so it persists next time
      await _saveEmail(email);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CleanersDashboard()),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleaners Login Page"),
        backgroundColor: const Color(0xFFFFFF),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width, // Make it take the full screen height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF440099),
              Color(0xFF440099),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.2,
              20,
              0,
            ),
            child: Column(
              children: <Widget>[
                logoWidget("assets/images/housekeeping.png"),
                const SizedBox(height: 30),
                // Username/email field
                resuableTextField(
                  "Enter Username",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 20),
                // Password field - obscure text
                resuableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(height: 30),
                signInSignUPButton(context, true, _login, isLoading: _isLoading),
                signUpOption(context),
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
          "Don't have an account?",
          style: TextStyle(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
