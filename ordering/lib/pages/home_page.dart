import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/select_table.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
import '../widgets/home_nav_bar.dart';
import '../widgets/item_widget.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<String> categories = [];
  late TextEditingController _searchController;
  late AnimationController _animationController;
  bool isDarkMode = false;
  bool _isSwitchOn = false;
  String selectedService = 'Dine In';
  String alreadySelectedTable = "";
  DateTime? currentBackPressTime;
  String loggedIn = "";
  bool showSubButtons = false;
  bool _subButtons = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addObserver(this);
    fetchCategories();
    checkSwitchValue();
    loadSelectedService();
    selectedFromShared();
    _storeCurrentPage('homePage');
    _fetchThemeMode();
    loadUser();
    setState(() {
      selectedService = 'Dine In';
    });
    currentBackPressTime = null;
    _subButtons = false;
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _fetchThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeMode = prefs.getString('isDarkMode');
    if (themeMode != null && themeMode == 'true') {
      setState(() {
        isDarkMode = true;
      });
    }
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    setState(() {
      loggedIn = username!;
    });
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

  void _clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    String? uname = prefs.getString('username');
    String? temp = prefs.getString('selectedTables2');
    String? switchValue = prefs.getString('switchValue');
    removeTablesFromShared(temp!);
    await prefs.clear();
    if (ipAddress != null && uname != null) {
      await prefs.setString('ipAddress', ipAddress);
      await prefs.setString('username', uname);
      await prefs.setString('switchValue', switchValue!);
    }
  }

  void _toggleDarkMode() async {
    isDarkMode = !isDarkMode;
    String theme = isDarkMode.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('isDarkMode', theme);
    String? temp = prefs.getString('isDarkMode');
    setState(() {
      temp;
    });
  }

  void _toggleSwitch(bool newValue) {
    setState(() {
      _isSwitchOn = newValue;
      _subButtons = false;
      saveSwitchValueToShared(newValue);
    });
  }

  Future<void> _storeCurrentPage(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentPage', pageName);
  }

  Future<void> selectedFromShared() async {
    final prefs = await SharedPreferences.getInstance();
    String? temp = prefs.getString('selectedTables');
    alreadySelectedTable = temp ?? '';
  }

  Future<void> fetchCategories() async {
    var ipAddress = AppConfig.serverIPAddress;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final response = await http
          .get(
            Uri.parse(
                'http://$ipAddress:${AppConfig.serverPort}/api/categories'),
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        categories =
            data.where((category) => category != null).cast<String>().toList();
        // Add 'All' category to the list
        categories.insert(0, 'ALL');
        prefs.setStringList('categories', categories);
        setState(() {
          categories = data
              .where((category) => category != null)
              .cast<String>()
              .toList();
          // Add 'All' category to the list
          categories.insert(0, 'ALL');
        });
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedCategories = prefs.getStringList('categories');
      if (storedCategories != null) {
        setState(() {
          categories = storedCategories
              .cast<dynamic>()
              .where((category) => category != null)
              .cast<String>()
              .toList();
          categories.insert(0, 'ALL');
        });
      } else {
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
    List<String> filteredCategories = categories.toList();

    String labelText = alreadySelectedTable.isNotEmpty
        ? '$alreadySelectedTable'
        : 'Select Table';

    // Check if categories are empty to show shimmer effect
    bool showShimmer = categories.isEmpty;

    // ignore: deprecated_member_use
    return WillPopScope(
        onWillPop: () async {
          if (currentBackPressTime == null ||
              DateTime.now().difference(currentBackPressTime!) >
                  Duration(seconds: 3)) {
            // If currentBackPressTime is null or elapsed time is more than 2 seconds,
            // update currentBackPressTime and show toast message
            currentBackPressTime = DateTime.now();
            Fluttertoast.showToast(
              msg: "Press back again to exit",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );

            return false; // Return false to prevent exiting the app
          } else {
            SystemNavigator.pop(); // Exit the app
            return false; // Return true to exit the app
          }
        },
        child: DefaultTabController(
            length: filteredCategories.length,
            child: Scaffold(
              backgroundColor:
                  isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.white,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              loggedIn,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.grey.withOpacity(0.4)
                                        : Colors.black.withOpacity(0.4),
                                    spreadRadius: 1,
                                    blurRadius: 8,
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
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: TextFormField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: "Search...",
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleDarkMode,
                            icon: Icon(
                              isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
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
                      unselectedLabelColor:
                          isDarkMode ? Colors.grey : Colors.grey,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                    ),
                    Flexible(
                      flex: 1,
                      child: showShimmer
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: 6, // Adjust the item count
                                itemBuilder: (_, __) => buildShimmerItemCard(),
                              ),
                            )
                          : TabBarView(
                              children: filteredCategories
                                  .map<Widget>((category) => ItemWidget(
                                        category: category,
                                        searchQuery: _searchController.text,
                                        isDarkMode: isDarkMode,
                                        toggleDarkMode: _toggleDarkMode,
                                        onItemAdded: _updateCartItemCount,
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: HomeNavBar(
                isDarkMode: isDarkMode,
                isSwitchOn: _isSwitchOn,
                toggleDarkMode: _toggleDarkMode,
                onSwitchChanged: _toggleSwitch,
              ),
              floatingActionButton: Stack(
                children: [
                  if (_subButtons) // Conditionally render the gesture detector
                    AnimatedOpacity(
                      opacity: _isSwitchOn ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _subButtons = false; // Close sub-buttons
                            _isSwitchOn = true;
                          });
                        },
                        child: Container(
                          color: Colors.black
                              .withOpacity(0.0), // Invisible backdrop
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Select table button
                        AnimatedOpacity(
                          opacity: _isSwitchOn ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: _isSwitchOn
                              ? FloatingActionButton(
                                  onPressed: () async {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    List<String>? cartItems =
                                        prefs.getStringList('cartItems');
                                    if (cartItems != null &&
                                        cartItems.length >= 1) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please settle your transactions first'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        _subButtons = !_subButtons;
                                        _isSwitchOn = !_isSwitchOn;
                                      });
                                    }
                                  },
                                  child: Icon(Icons.more_horiz),
                                  backgroundColor: isDarkMode
                                      ? Colors.grey.withOpacity(0.85)
                                      : Colors.orange.withOpacity(0.85),
                                  foregroundColor: Colors.white,
                                  elevation: 4.0,
                                )
                              : SizedBox(),
                        ),
                        // Sub-buttons
                        Visibility(
                          visible: _subButtons,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Opacity(
                                  opacity: _subButtons ? 1.0 : 0.0,
                                  child: AnimatedOpacity(
                                    opacity: _subButtons ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 500),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(-0.1, -0.4),
                                        end: Offset(-0.1, -0.4),
                                      ).animate(CurvedAnimation(
                                        parent: _animationController,
                                        curve: Curves.easeInOut,
                                      )),
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          
                  Navigator.pushNamed(context, "table");
                                        },
                                        child: Text('New Order'),
                                        backgroundColor: isDarkMode
                                            ? Colors.grey.withOpacity(0.85)
                                            : Color.fromARGB(255, 33, 155, 255)
                                                .withOpacity(0.85),
                                        foregroundColor: Colors.white,
                                        elevation: 4.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 100,
                                child: Opacity(
                                  opacity: _subButtons ? 1.0 : 0.0,
                                    child: AnimatedOpacity(
                                      opacity: _subButtons ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 500),
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                        begin: Offset(-0.1, -0.3),
                                        end: Offset(-0.1, -0.3),
                                        ).animate(CurvedAnimation(
                                          parent: _animationController,
                                          curve: Curves.easeInOut,
                                        )),
                                        child: FloatingActionButton(
                                          onPressed: () {
                                            // Implement the functionality for the "New Order" button
                                          },
                                          child: Text('Add Order'),
                                          backgroundColor: isDarkMode
                                              ? Colors.grey.withOpacity(0.85)
                                              : Colors.orange.withOpacity(0.85),
                                          foregroundColor: Colors.white,
                                          elevation: 4.0,
                                        ),
                                      ),
                                    ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 100,
                                child: Opacity(
                                  opacity: _subButtons ? 1.0 : 0.0,
                                  child: AnimatedOpacity(
                                    opacity: _subButtons ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 500),
                                    child: AnimatedOpacity(
                                      opacity: _subButtons ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 500),
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                        begin: Offset(-0.1, -0.2),
                                        end: Offset(-0.1, -0.2),
                                        ).animate(CurvedAnimation(
                                          parent: _animationController,
                                          curve: Curves.easeInOut,
                                        )),
                                        child: FloatingActionButton(
                                          onPressed: () {
                                            // Implement the functionality for the "New Order" button
                                          },
                                          child: Text('Bill Out'),
                                          backgroundColor: isDarkMode
                                              ? Colors.grey.withOpacity(0.85)
                                              : Color.fromARGB(255, 119, 204, 21).withOpacity(0.85),
                                          foregroundColor: Colors.white,
                                          elevation: 4.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  Widget buildShimmerItemCard() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4.0,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Container(
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  height: 16.0,
                  width: 100.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Container(
                  height: 16.0,
                  width: 80.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCartItemCount() {
    setState(() {
      // Refresh the state to update the item count in the HomeNavBar
    });
  }
}
