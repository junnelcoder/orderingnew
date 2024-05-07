import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/home_page.dart';
// import 'package:ordering/pages/ip_screen.dart';
// import 'dart:async';
import 'config.dart';
import 'ip_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

final TextEditingController _passwordController = TextEditingController();
String? _selectedUsername;

void saveUsernameToSharedPreferences(String username) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
}

class _LoginPageState extends State<LoginScreen> {
  bool _isObscured = true;
  List<String> users = [];
  List<String> passwords = []; // Declare passwords here
  DateTime? currentBackPressTime;
  @override
  void initState() {
    super.initState();
    fetchUsers();
    currentBackPressTime = null;
  }

  void navigateToIpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IpScreen(),
      ),
    );
  }

  void fetchUsers() async {
    try {
      var ipAddress = AppConfig.serverIPAddress.trim();
      print('IP Address: $ipAddress'); // Debug statement

      // if (ipAddress == null) {
      //   print('Server IP address is null'); // Debug statement
      //   return;
      // }

      final response = await http
          .get(Uri.parse('http://$ipAddress:8080/api/getUsers'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        for (var userData in responseData) {
          users.add(userData['username']);
          passwords.add(userData['password']);
        }
        for (int i = 0; i < passwords.length; i++) {
          String password = passwords[i];
          String encryptedPassword = '';
          for (int x = 0; x < password.length; x++) {
            var n = password.codeUnitAt(x) - (x + 1);
            encryptedPassword += String.fromCharCode(n);
          }
          passwords[i] = encryptedPassword;
        }

        setState(() {
          // Update your UI if necessary
        });
      } else {
        print('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IpScreen(),
        ),
      );
      print('Error fetching users: $e');
      Fluttertoast.showToast(
        msg: "Error fetching users",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;


  return WillPopScope(
      onWillPop: () async {
        // If currentBackPressTime is null or elapsed time is more than 2 seconds, exit the app
        if (currentBackPressTime == null ||
            DateTime.now().difference(currentBackPressTime!) >
                Duration(seconds: 2)) {
          // Update currentBackPressTime
          currentBackPressTime = DateTime.now();
          // Show toast message
          Fluttertoast.showToast(
            msg: "Press back again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return false;
        } else {
          // If back button is pressed again within 2 seconds, exit the app
          return true;
        }
      },
    child : Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[600]!,
                Colors.grey[300]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: screenHeight * 0.1),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GlowingText(
                      text: "Welcome Back",
                      glowColor: Colors.black,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.05,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MaanJoy',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    GlowingText(
                      text: "Sign in to continue",
                      glowColor: Colors.black,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.025,
                        fontFamily: 'MaanJoy',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.1),
                      topRight: Radius.circular(screenWidth * 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: screenWidth * 0.02,
                        blurRadius: screenWidth * 0.04,
                        offset: Offset(0, screenWidth * 0.03),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: screenHeight * 0.1),
                        DropdownButtonFormField<String>(
                          value: _selectedUsername,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUsername = newValue!;
                            });
                          },
                          items: users
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(value),
                                ),
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: "Select Username",
                            prefixIcon: Icon(Icons.person, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.05),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          style: TextStyle(fontFamily: 'MaanJoy'),
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.05),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              String username = _selectedUsername!;
                              String password = _passwordController.text;
                              int arrSize = users.length;
                              for (int i = 0; i < arrSize; i++) {
                                if (username.trim() == users[i].trim()) {
                                  if (password.trim() == passwords[i].trim()) {
                                    saveUsernameToSharedPreferences(username);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(),
                                      ),
                                    );
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Incorrect password",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.05),
                              ),
                            ),
                            child: GlowingText(
                              text: "Sign in",
                              glowColor: Colors.black,
                              style: TextStyle(
                                fontSize: screenHeight * 0.025,
                                color: Colors.white,
                                fontFamily: 'MaanJoy',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),);
  }
}

class GlowingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color glowColor;

  const GlowingText({
    Key? key,
    required this.text,
    required this.style,
    required this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.copyWith(shadows: [
        Shadow(
          blurRadius: 10.0,
          color: glowColor,
          offset: const Offset(0, 0),
        ),
        Shadow(
          blurRadius: 10.0,
          color: glowColor,
          offset: const Offset(0, 0),
        ),
      ]),
    );
  }
}
