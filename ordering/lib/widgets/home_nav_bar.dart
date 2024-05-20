import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ordering/pages/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

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
  int?
      _openCartItemsCount; // Define _openCartItemsCount as a class-level variable
  List<String>? _cachedCartItems;
  String selectedService = 'Dine In';

  @override
  void initState() {
    super.initState();
    _canInteractWithSwitch = true;
    _loadSwitchValueFromStorage();
    _refreshOnLoad();
    _startPollingForChanges(Duration(milliseconds: 1));
    loadSelectedService();
    setState(() {
      selectedService = 'Dine In';
    });
  }

  void _refreshOnLoad() async {
    _openCartItemsCount = await fetchOpenCartItemsCount();
    _loadSwitchValueFromStorage();
    setState(() {});
  }

  void _startPollingForChanges(Duration interval) {
    Timer.periodic(interval, (timer) async {
      bool hasChanges = await _checkForChanges();
      if (hasChanges) {
        _refreshOnLoad(); // Refresh the count if changes detected
      }
    });
  }

  Future<void> saveSelectedService(String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedService', service);
  }

  Future<void> loadSelectedService() async {
    final prefs = await SharedPreferences.getInstance();
    String? service = prefs.getString('selectedService');
    if (service != null) {
      setState(() {
        selectedService = service;
      });
    }
  }

  Future<bool> _checkForChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? currentCartItems = prefs.getStringList('cartItems');
    if (_listEquals(currentCartItems, _cachedCartItems)) {
      return false; // No changes detected
    } else {
      _cachedCartItems = currentCartItems; // Update cached cart items
      return true; // Changes detected
    }
  }

  bool _listEquals(List<String>? list1, List<String>? list2) {
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
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

  Future<void> removeTablesFromShared(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedTables');
    await prefs.remove('selectedTables2');

    List<int> retrievedIndexes = table.split(',').map(int.parse).toList();
    List<int> temp = [retrievedIndexes[0]];
    int action = 0;
    int change = 0;
    String? ipAddress = prefs.getString('ipAddress');
    var apiUrl =
        Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/occupy');
    var requestBody = jsonEncode({
      'selectedIndex': temp,
      'action': action,
      'previousIndex': table,
      'changeSelected': change,
    });
    var response = await http.post(
      apiUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: requestBody,
    );
    if (response.statusCode == 200) {
    } else {
      print('Failed to occupy tables. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> _saveSwitchValueToStorage(bool newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('switchValue', newValue ? 'FNB' : 'QS');
    String? temp = prefs.getString('selectedTables2');
    removeTablesFromShared(temp!);
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
            SizedBox(
              width: 110, // Set your desired width here
              child: FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Select Service'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedService = 'Dine In';
                                });
                                saveSelectedService('Dine In');
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                leading: Icon(Icons.restaurant_menu),
                                title: Text('Dine In'),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedService = 'Take Out';
                                });
                                saveSelectedService('Take Out');
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                leading: Icon(Icons.takeout_dining),
                                title: Text('Take Out'),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedService = 'Pick Up';
                                });
                                saveSelectedService('Pick Up');
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                leading: Icon(Icons.store_mall_directory),
                                title: Text('Pick Up'),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedService = 'Delivery';
                                });
                                saveSelectedService('Delivery');
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                leading: Icon(Icons.delivery_dining),
                                title: Text('Delivery'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                label: Text(selectedService),
                icon: Icon(Icons.room_service),
                backgroundColor: widget.isDarkMode
                    ? Colors.grey.withOpacity(0.85)
                    : Colors.blue.withOpacity(0.85),
                foregroundColor: Colors.white,
                elevation: 10.0,
              ),
            ),

            // Padding added here to move the cartPage button to the left
            Padding(
              padding: EdgeInsets.only(right: 50.0),
              child: GestureDetector(
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
            ),

            // Existing code for switch button and label
            Container(
              margin: EdgeInsets.only(top: 15),
              child: Column(
                children: [
                  Semantics(
                    key: Key('someFunctionalitySwitch'),
                    child: IgnorePointer(
                      ignoring: false,
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
        ));
  }
}
