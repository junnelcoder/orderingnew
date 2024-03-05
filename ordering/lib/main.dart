import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/ip_screen.dart';
import 'pages/login_screen.dart'; // Import the login screen
import 'pages/cart_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Set the initial route to the ipScreen after login
      initialRoute: "ipScreenState",
      routes: {
        // Define the routes for each screen
        "loginScreenState": (context) => LoginScreen(),
        "ipScreenState": (context) => IpScreen(),
        "/": (context) => HomePage(),
        "cartPage": (context) => CartPage(),
      },
    );
  }
}
