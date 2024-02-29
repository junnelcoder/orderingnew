import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:ordering/pages/single_item_page.dart';

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
      routes: {
        "/": (context) => HomePage(),
        // "singleItemPage": (context) => SingleItemPage(),
        "cartPage": (context) => CartPage(),
      },
    );
  }
}
