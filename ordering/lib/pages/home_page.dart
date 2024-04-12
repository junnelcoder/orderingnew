import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/select_table.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/item_widget.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> categories = [];
  late TextEditingController _searchController;
  bool isDarkMode = false;
  bool _isSwitchOn = false; // Initial state ng switch button
  String _selectedService = 'Select Service'; // Track the selected service
  List<String> _serviceOptions = [
    'Dine In',
    'Take Out',
    'Pick Up'
  ]; // Service options

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _toggleSwitch(bool newValue) {
    setState(() {
      _isSwitchOn = newValue;
    });
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

  @override
  Widget build(BuildContext context) {
    // Alisin ang "ALL" na kategorya mula sa listahan ng kategorya
    List<String> filteredCategories =
        categories.where((category) => category != 'ALL').toList();

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
        floatingActionButton: _isSwitchOn
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FloatingActionButton.extended(
                          heroTag: null, // Remove transition effect
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SelectTablePage()),
                            );
                          },
                          label: Text('Select a Table'),
                          icon: Icon(Icons.table_chart),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 4.0,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8), // Add some space here
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.black,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: DropdownButton<String>(
                          value: _selectedService,
                          icon:
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                          iconSize: 24,
                          elevation: 16,
                          style: TextStyle(color: Colors.white),
                          underline: Container(
                            height: 0,
                            color: Colors.transparent,
                          ),
                          dropdownColor: Colors.black,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedService = newValue!;
                            });
                          },
                          items: _serviceOptions
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
