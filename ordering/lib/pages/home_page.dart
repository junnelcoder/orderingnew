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
    ? FloatingActionButton.extended(
        onPressed: () {
          // Navigate to select_table.dart when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectTablePage()),
          );
        },
        label: Text('Select a Table'), // Palitan ang label ng button
        icon: Icon(Icons.table_chart), // Palitan ang icon ng "Select Table"
        backgroundColor: Colors.grey, // Palitan ang kulay ng background
        foregroundColor: Colors.white, // Palitan ang kulay ng text at icon
        elevation: 4.0, // Palitan ang taas ng elevasyon para sa shadow effect
      )
    : null, // Kung hindi naka-QS, huwag ipakita ang floating button


      ),
    );
  }
}