import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeNavBar extends StatefulWidget {
  final bool isDarkMode;
  final bool isSwitchOn; // State ng switch button
  final VoidCallback toggleDarkMode;
  final ValueChanged<bool> onSwitchChanged; // Callback function para sa pagbabago ng switch button

  const HomeNavBar({
    required this.isDarkMode,
    required this.isSwitchOn,
    required this.toggleDarkMode,
    required this.onSwitchChanged,
  });

  @override
  _HomeNavBarState createState() => _HomeNavBarState();
}

class _HomeNavBarState extends State<HomeNavBar> {
  bool _someFunctionalitySwitchValue = false; // Define switch value

  Future<int> fetchOpenCartItemsCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? cartItems = prefs.getStringList('cartItems');

      if (cartItems != null) {
        // Count items except the ones with category 'notes'
        int openCartItemsCount = 0;
        for (String cartItem in cartItems) {
          Map<String, dynamic> item = json.decode(cartItem);
          if (item['category'] != 'notes') {
            openCartItemsCount++;
          }
        }
        return openCartItemsCount;
      } else {
        // If no cart items found, return count as 0
        return 0;
      }
    } catch (e) {
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
              color: widget.isDarkMode ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items at the start and end of the row
              children: [
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        widget.toggleDarkMode();
                      },
                      iconSize: 30,
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(),
                      alignment: Alignment.centerRight,
                      icon: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Icon(
                            widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
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
                // Icon(Icons.add, color: Colors.transparent, size: 120),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "cartPage");
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
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
                          color: widget.isDarkMode ? Colors.black : Colors.white,
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
                // Switch button for some functionality
Column(
  children: [
    Switch(
      value: _someFunctionalitySwitchValue,
      onChanged: (value) {
        setState(() {
          _someFunctionalitySwitchValue = value;
          widget.onSwitchChanged(value); // Pasa ang bagong estado ng switch button
        });
        // perform action on switch value change
      },
      activeTrackColor: Colors.grey, // Kulay ng track kapag naka-on
      activeColor: Colors.white, // Kulay ng button kapag naka-on
    ),
    Text(
      _someFunctionalitySwitchValue ? 'QS' : 'FNB', // Teksto ng switch button base sa estado
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.isDarkMode ? Colors.white : Colors.black,
      ),
    ),
  ],
),



              ],
            ),
          );
        }
      },
    );
  }
}
