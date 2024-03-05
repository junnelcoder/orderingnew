import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Set the initial route to the login screen
      initialRoute: "loginScreenState",
      routes: {
        // Define the routes for each screen
        "loginScreenState": (context) => LoginScreen(),
        "/": (context) => HomePage(),
        "cartPage": (context) => CartPage(),
      },
    );
  }
}
