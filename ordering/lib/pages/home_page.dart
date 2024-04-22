import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/select_table.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/item_widget.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<String> categories = [];
  late TextEditingController _searchController;
  bool isDarkMode = false;
  bool _isSwitchOn = false; // Initial state ng switch button
  String selectedService = 'Dine In';
  String alreadySelectedTable = "";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    fetchCategories();
    checkSwitchValue();
    loadSelectedService();
    selectedFromShared();

    setState(() {
      selectedService = 'Dine In';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _clearSharedPreferences();
    }
  }

  void _clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    String? uname = prefs.getString('username');
    await prefs.clear();
    if (ipAddress != null && uname != null) {
      await prefs.setString('ipAddress', ipAddress);
      await prefs.setString('username', uname);
    }
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _toggleSwitch(bool newValue) {
    setState(() {
      _isSwitchOn = newValue;
      saveSwitchValueToShared(newValue);
    });
  }

  Future<void> selectedFromShared() async {
    final prefs = await SharedPreferences.getInstance();
    String? temp = prefs.getString('selectedTables');
    alreadySelectedTable = temp ?? '';
  }

  Future<void> fetchCategories() async {
    var ipAddress = AppConfig.serverIPAddress;

    try {
      // Simulan ang pagkuha ng mga kategorya mula sa server
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final response = await http
          .get(
            Uri.parse('http://$ipAddress:8080/api/categories'),
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        categories =
            data.where((category) => category != null).cast<String>().toList();
        prefs.setStringList('categories', categories);
        setState(() {
          categories = data
              .where((category) => category != null)
              .cast<String>()
              .toList();
        });
      } else {
        // Kung may error sa pagkuha ng mga kategorya, i-handle ito dito
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      // Kung offline o may error sa pagkuha ng mga kategorya, i-handle ito dito
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedCategories = prefs.getStringList('categories');
      if (storedCategories != null) {
        setState(() {
          categories = storedCategories
              .cast<dynamic>()
              .where((category) => category != null)
              .cast<String>()
              .toList();
        });
      } else {
        // Kung walang kategorya, i-handle ito dito
        throw Exception('Failed to fetch categories');
      }
    }
  }

  Future<void> saveSwitchValueToShared(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('switchValue', newValue ? 'FNB' : 'QS');
  }

  Future<void> checkSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    String? switchValue = prefs.getString('switchValue');
    if (switchValue != null && switchValue == 'FNB') {
      setState(() {
        _isSwitchOn = true;
      });
    }
  }

  Future<void> saveSelectedService(String service) async {
    print(service);
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

  @override
  Widget build(BuildContext context) {
    selectedFromShared();
    List<String> filteredCategories =
        categories.where((category) => category != 'ALL').toList();
    String labelText = alreadySelectedTable.isNotEmpty
        ? '$alreadySelectedTable'
        : 'Select Table';
    return DefaultTabController(
      length: filteredCategories.length,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            color: Colors.black,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Search...",
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {}); // Trigger rebuild
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  indicator: BoxDecoration(),
                  labelStyle: TextStyle(fontSize: 15),
                  labelPadding: EdgeInsets.symmetric(horizontal: 20),
                  tabs: filteredCategories
                      .map<Tab>((category) => Tab(text: category))
                      .toList(),
                ),
                Flexible(
                  flex: 1,
                  child: TabBarView(
                    children: filteredCategories
                        .map<Widget>((category) => ItemWidget(
                              category: category,
                              searchQuery: _searchController.text,
                              isDarkMode: isDarkMode,
                              toggleDarkMode: _toggleDarkMode,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: HomeNavBar(
          isDarkMode: isDarkMode,
          isSwitchOn: _isSwitchOn,
          toggleDarkMode: _toggleDarkMode,
          onSwitchChanged: _toggleSwitch,
        ),

        floatingActionButton: Align(
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedOpacity(
                opacity: _isSwitchOn ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelectTablePage()),
                    );
                  },
                  label: Text(labelText),
                  icon: Icon(Icons.table_chart),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 4.0,
                ),
              ),
              SizedBox(height: 10),
              FloatingActionButton.extended(
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 4.0,
              ),
            ],
          ),
        ),

        // Kung hindi naka-QS, huwag ipakita ang floating button
      ),
    );
  }
}
