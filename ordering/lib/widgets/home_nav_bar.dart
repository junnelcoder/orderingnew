import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  int? _openCartItemsCount;

  @override
  void initState() {
    super.initState();
    _canInteractWithSwitch = true;
    _loadSwitchValueFromStorage();
    _refreshOnLoad();
  }

  void _refreshOnLoad() async {
    // Fetch open cart items count and assign it to _openCartItemsCount
    _openCartItemsCount = await fetchOpenCartItemsCount();
  }

  void _updateOpenCartItemsCount(int count) {
    setState(() {
      _openCartItemsCount = count;
    });
  }

  void _setSomeFunctionalitySwitchValue(bool value, BuildContext context) {
    if (!_canInteractWithSwitch) {
      // If switch interaction is disabled, show toast message
      Fluttertoast.showToast(
        msg: 'Finish transaction first before switching',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else {
      setState(() {
        _someFunctionalitySwitchValue = value;
        _saveSwitchValueToStorage(value);
        widget.onSwitchChanged(value);
      });
    }
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      height: 90,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Color(0xFF222222) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.grey.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: widget.isDarkMode ? 10 : 25,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Existing code for dark mode toggle button
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
                      widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    SizedBox(width: 8), // Add some space between the icons
                    Visibility(
                      visible: widget
                          .isDarkMode, // Only show the second icon when in dark mode
                      child: Icon(
                        Icons.light_mode,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Existing code for cart button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "cartPage");
            },
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.grey : Colors.black,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDarkMode
                            ? Colors.grey.withOpacity(0)
                            : Colors.black.withOpacity(0.4),
                        spreadRadius: 1,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.assignment_add,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                if (_openCartItemsCount != null && _openCartItemsCount! > 0)
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
                        _openCartItemsCount.toString(),
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
          // Existing code for switch button and label
          Container(
            margin: EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Semantics(
                  key: Key('someFunctionalitySwitch'),
                  child: IgnorePointer(
                    ignoring:
                        false, // Always allow interaction with the Switch widget
                    child: Switch(
                      value: _someFunctionalitySwitchValue,
                      onChanged: (value) {
                        _setSomeFunctionalitySwitchValue(value, context);
                      },
                      activeTrackColor:
                          widget.isDarkMode ? Colors.grey : Colors.black,
                      activeColor: Colors.white,
                    ),
                  ),
                ),
                Text(
                  _someFunctionalitySwitchValue ? 'FNB' : 'QS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
