import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeNavBar extends StatefulWidget {
  final bool isDarkMode;
  final bool isSwitchOn;
  final VoidCallback toggleDarkMode;
  final ValueChanged<bool> onSwitchChanged;

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
  late bool _someFunctionalitySwitchValue;
  late bool _canInteractWithSwitch;

  @override
  void initState() {
    super.initState();
    _canInteractWithSwitch = true;
    _loadSwitchValueFromStorage();
  }

  Future<void> _loadSwitchValueFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItems = prefs.getStringList('cartItems');
    if (cartItems != null && cartItems.isNotEmpty) {
      setState(() {
        _canInteractWithSwitch = false;
      });
    }

    String? switchValue = prefs.getString('switchValue');
    if (switchValue == null) {
      setState(() {
        _someFunctionalitySwitchValue = false;
      });
      _saveSwitchValueToStorage(false);
    } else {
      setState(() {
        _someFunctionalitySwitchValue = switchValue == 'FNB';
      });
    }
  }

  Future<void> _saveSwitchValueToStorage(bool newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('switchValue', newValue ? 'FNB' : 'QS');
  }

  Future<int> fetchOpenCartItemsCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItems = prefs.getStringList('cartItems');
    if (cartItems != null) {
      int openCartItemsCount = 0;
      for (String cartItem in cartItems) {
        Map<String, dynamic> item = json.decode(cartItem);
        if (item['category'] != 'notes') {
          openCartItemsCount++;
        }
      }
      return openCartItemsCount;
    } else {
      return 0;
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
            height: 90,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            widget.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            child: Icon(
                              widget.isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "cartPage");
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black,
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
                          color:
                              widget.isDarkMode ? Colors.black : Colors.white,
                          size: 40,
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
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 15),
                  child: Column(
                    children: [
                      Semantics(
                        key: Key('someFunctionalitySwitch'),
                        child: IgnorePointer(
                          ignoring: !_canInteractWithSwitch,
                          child: Switch(
                            value: _someFunctionalitySwitchValue,
                            onChanged: _canInteractWithSwitch
                                ? (value) {
                                    setState(() {
                                      _someFunctionalitySwitchValue = value;
                                      _saveSwitchValueToStorage(value);
                                      widget.onSwitchChanged(value);
                                    });
                                  }
                                : null,
                            activeTrackColor: Colors.black,
                            activeColor: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        _someFunctionalitySwitchValue ? 'FNB' : 'QS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }
      },
    );
  }
}
