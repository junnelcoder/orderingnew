import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../pages/config.dart';

class HomeNavBar extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;

  const HomeNavBar({
    required this.isDarkMode,
    required this.toggleDarkMode,
  });

  @override
  _HomeNavBarState createState() => _HomeNavBarState();
}

class _HomeNavBarState extends State<HomeNavBar> {
  Future<int> fetchOpenCartItemsCount() async {
    var ipAddress = AppConfig.serverIPAddress;
    var url = Uri.parse('http://$ipAddress:8080/api/get-open-cart-items-count');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final int count = data['count'] as int;
      return count;
    } else {
      throw Exception('Failed to fetch open cart items count');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: fetchOpenCartItemsCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int openCartItemsCount = snapshot.data!;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            height: 80,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.black : Colors.white, // Toggle background color based on dark mode
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Dark mode switch
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        widget.toggleDarkMode();
                      },
                      iconSize: 30, // Reduce icon size for dark mode toggle
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(),
                      alignment: Alignment.centerRight,
                      icon: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Dark mode toggle icon
                          Icon(
                            widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          // Circle container representing the dark mode toggle
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isDarkMode ? Colors.black : Colors.white,
                            ),
                            child: Icon(
                              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Invisible icon for centering
                Icon(Icons.add, color: Colors.transparent, size: 120),
                // Icon Button assignment_add
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "cartPage");
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.white : Colors.black, // Change color based on dark mode
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.assignment_add,
                          color: widget.isDarkMode ? Colors.black : Colors.white, // Change icon color based on dark mode
                          size: 30,
                        ),
                      ),
                      if (openCartItemsCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              openCartItemsCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}