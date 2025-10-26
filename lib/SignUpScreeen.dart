import 'package:cleanerapplication/HomePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Services/Color.dart';
import 'Services/resuableTextField.dart';
import 'Supervisor/Supervisor Dashboard/Supervisor Dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up Page"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context)
            .size
            .width, // Make it take the full screen height
        decoration: BoxDecoration(
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
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                Container(
                  height: 200,
                  width: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage('assets/images/uos.png'), // replace with your asset path, // optional
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                resuableTextField("Enter Username", Icons.person_outline, false,
                    _emailTextController),
                SizedBox(
                  height: 20,
                ),
                resuableTextField("Enter Email Id", Icons.lock_outline, false,
                    _passwordTextController),
                SizedBox(
                  height: 30,
                ),
                resuableTextField("Enter Password", Icons.lock_outline, false,
                    _passwordTextController),
                SizedBox(
                  height: 30,
                ),
                signInSignUPButton(context, true, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SupervisorDashboard()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
