import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/home_nav_bar.dart';
import '../widgets/item_widget.dart';
import 'config.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    var ipAddress =
        AppConfig.serverIPAddress; // Get the IP address from AppConfig
    final response =
        await http.get(Uri.parse('http://$ipAddress:8080/categories'));

    print('haha:${AppConfig.serverIPAddress}');
    if (response.statusCode == 200) {
      setState(() {
        final List<dynamic> data = json.decode(response.body);
        categories =
            data.where((category) => category != null).cast<String>().toList();
      });
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length + 1, // Add 1 for the 'ALL' option
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
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
                                decoration: InputDecoration(
                                  hintText: "What would you like to haves?",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          // Icon(Icons.filter_list),
                        ],
                      ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 15),
                //   child: Text(
                //     "Have a nice day!",
                //     style: TextStyle(
                //       color: Colors.black,
                //       fontSize: 32,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                // SizedBox(height: 5),
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 15),
                //   child: Text(
                //     "Keep Smiling",
                //     style: TextStyle(
                //       color: Colors.grey,
                //       fontSize: 22,
                //     ),
                //   ),
                // ),
                SizedBox(height: 5),
                TabBar(
                  isScrollable: true,
                  indicator: BoxDecoration(),
                  labelStyle: TextStyle(fontSize: 15),
                  labelPadding: EdgeInsets.symmetric(horizontal: 20),
                  tabs: [
                    Tab(text: 'ALL'), // Add the 'ALL' option
                    ...categories
                        .map<Tab>((category) => Tab(text: category))
                        .toList(),
                  ],
                ),
                Flexible(
                  flex: 1,
                  child: TabBarView(
                    children: [
                      ItemWidget(category: 'ALL'), // Add 'ALL' category tab
                      ...categories
                          .map<Widget>(
                              (category) => ItemWidget(category: category))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: HomeNavBar(),
      ),
    );
  }
}
