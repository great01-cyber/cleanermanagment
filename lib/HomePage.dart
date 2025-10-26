import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Cleaner_loginPage.dart';
import 'Supervisor_Login_Page.dart';
import 'Admin/admin_login_screen.dart';

// Main home page with login options for different user types
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFF), Color(0xFF440099), Color(0xFF440099)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 350,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/uos.png"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cleaners Management App',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 50),
            /*Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/products 1.png"),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/cleaning 1.png"),
                    ),
                  ),
                ),
              ],
            ),*/
            const SizedBox(height: 80),
            // Login buttons for supervisors and cleaners
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to supervisor login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupervisorLoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF440099),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white, width: 2)
                    ),
                  ),
                  child: const Text(
                    'Supervisor Login',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to cleaner login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CleanersLoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF440099),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white, width: 2)

                    ),
                  ),
                  child: const Text(
                    "Cleaners Login",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 70,),
            const SizedBox(height: 20),
            // Admin panel button - now requires login
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to admin login screen (requires authentication)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF440099),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 2)
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
