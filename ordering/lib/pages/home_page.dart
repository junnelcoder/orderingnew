import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> fetchCategories() async {
    var ipAddress = AppConfig.serverIPAddress;
    
try {
  final response = await http.get(
    Uri.parse('http://$ipAddress:8080/api/categories'),
  ).timeout(Duration(seconds: 5)); 
   if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
        categories =
            data.where((category) => category != null).cast<String>().toList();
             SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('categories', categories);
      setState(() {
        final List<dynamic> data = json.decode(response.body);
        categories =
            data.where((category) => category != null).cast<String>().toList();
      });
    } else {
      throw Exception('Failed to fetch categories');
    }
}catch(e){
      print("offline");
  SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedCategories = prefs.getStringList('categories');
if (storedCategories != null) {
      setState(() {
        final List<dynamic> data = storedCategories.cast<dynamic>(); // Casting storedCategories to List<dynamic>
        categories = data.where((category) => category != null).cast<String>().toList();
      });
    } else {
      throw Exception('Failed to fetch categories');
    }
}
   
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length + 1,
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
                  tabs: [
                    Tab(text: 'ALL'),
                    ...categories
                        .map<Tab>((category) => Tab(text: category))
                        .toList(),
                  ],
                ),
                Flexible(
                  flex: 1,
                  child: TabBarView(
                    children: [
                      ItemWidget(
                          category: 'ALL',
                        searchQuery: _searchController.text,
                        isDarkMode: isDarkMode,
                        toggleDarkMode: _toggleDarkMode,
                      ),
                      ...categories
                          .map<Widget>((category) => ItemWidget(
                                category: category,
                                searchQuery: _searchController.text,
                                isDarkMode: isDarkMode,
                                toggleDarkMode: _toggleDarkMode,
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: HomeNavBar(
          isDarkMode: isDarkMode,
          toggleDarkMode: _toggleDarkMode,
        ),
      ),
    );
  }
}
