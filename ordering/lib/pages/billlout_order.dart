import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/home_page.dart';
import 'package:ordering/pages/select_table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'config.dart';

class BilllOutOrder extends StatefulWidget {
  @override
  _BilllOutOrderPageState createState() => _BilllOutOrderPageState();
}

class _BilllOutOrderPageState extends State<BilllOutOrder>
    with WidgetsBindingObserver {
  late TextEditingController _searchController;
  bool isDarkMode = false;
  String selectedService = 'Dine In';
  String alreadySelectedTable = "";
  DateTime? currentBackPressTime;
  String tableNumber = "";
  List<dynamic> items = [];
  Map<String, dynamic> summaryData = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    loadSelectedService();
    selectedFromShared();
    _fetchThemeMode();
    _loadForBillOut();
    currentBackPressTime = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  Future<void> _loadForBillOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? forBillOut = prefs.getString('forBillOut');
      if (forBillOut != null) {
        final String? ipAddress = prefs.getString('ipAddress');
        final Uri apiUrl = Uri.parse(
            'http://$ipAddress:${AppConfig.serverPort}/api/checkForBillout?tableno=$forBillOut');

        final http.Response response = await http.get(apiUrl);

        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          if (responseBody.containsKey('summary')) {
            final Map<String, dynamic> summary = responseBody['summary'];
            summary.forEach((key, value) {
              summaryData[key] = value;
            });
            setState(() {
              tableNumber = summary['table_no'];
              items = responseBody['detail'];
            });
          } else {
            print('Summary field not found in the response');
          }
        } else {
          print(
              'Failed to load for billout. Status code: ${response.statusCode}');
        }
      } else {
        print('No table number found for billout');
      }
    } catch (error) {
      print('Error loading for billout: $error');
    }
  }

  Future<void> _billOutTable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ipAddress = prefs.getString('ipAddress');
      final Uri apiUrl = Uri.parse(
          'http://$ipAddress:${AppConfig.serverPort}/api/billout?tableno=$tableNumber');

      final http.Response response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Bill out successful for table $tableNumber',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.greenAccent,
          textColor: Colors.white,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else {
        print('Failed to bill out table. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error billing out table: $error');
    }
  }

  Future<void> selectedFromShared() async {
    final prefs = await SharedPreferences.getInstance();
    String? temp = prefs.getString('selectedTables');
    alreadySelectedTable = temp ?? '';
  }

  Future<void> saveSwitchValueToShared(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('switchValue', newValue ? 'FNB' : 'QS');
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

  Widget billNavbar() {
    double screenWidth = MediaQuery.of(context).size.width;
    return BottomAppBar(
      color: isDarkMode
          ? Color.fromARGB(255, 20, 20, 20).withOpacity(0.0)
          : Colors.white,
      child: Container(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wrap the button with SizedBox to define its size
            SizedBox(
              width: screenWidth *
                  0.5, // Set desired width (e.g., half screen width)
              height: 60, // Set desired height
              child: ElevatedButton(
                onPressed: _billOutTable,
                child: Text('Bill Out',
                    style: TextStyle(
                        color: Colors.white, fontSize: screenWidth * 0.05)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: screenHeight * 0.2,
            backgroundColor: isDarkMode ? Color(0xFF222222) : Colors.white,
            leading: IconButton(
              // Customize back button
              icon: Icon(Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Color(0xFF222222)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectTablePage(),
                  ),
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Container(
                width: double.infinity,
                height: screenHeight * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: screenHeight * 0.07,
                      height: screenHeight * 0.07,
                      margin: EdgeInsets.only(
                          right: screenWidth * 0.08, top: screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Text(
                          tableNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Server: ${summaryData['cashierid']}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: screenHeight * 0.010,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sales Date: ${_formatSalesDate(summaryData['sales_date'])}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: screenHeight * 0.010,
                            ),
                          ),
                          Text(
                            'No. of Pax: ${summaryData['no_of_pax']}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: screenHeight * 0.010,
                            ),
                          ),
                          Text(
                            'Total: ₱${summaryData['subtotal']}',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: screenHeight * 0.02,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final item = items[index];
                return FutureBuilder<String>(
                  future: _getImagePathForItem(item['itemcode']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center();
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading image'),
                      );
                    } else {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: screenWidth * 0.2,
                              child: Image.network(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: screenHeight * 0.08,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '\n${item['itemname']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenHeight * 0.02,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '\n₱ ${item['selling_price']}  x  ${item['qty']}',
                                          style: TextStyle(
                                            fontSize: screenHeight * 0.02,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: SizedBox(
                                              width: screenWidth * 0.02),
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Text(
                                            '  ',
                                            style: TextStyle(
                                              fontSize: screenHeight * 0.02,
                                            ),
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                left: screenWidth * 0.3),
                                            child: Text(
                                              ' ₱${item['subtotal']}',
                                              style: TextStyle(
                                                fontSize: screenHeight * 0.025,
                                                fontWeight: FontWeight.w900,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < items.length - 1) ...[
                                    SizedBox(height: screenHeight * 0.015),
                                    Divider(),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
              childCount: items.length,
            ),
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF222222) : Colors.white,
      bottomNavigationBar:
          summaryData['billout_tag'] == '0' ? billNavbar() : null,
    );
  }

  String _formatSalesDate(String? dateString) {
    if (dateString != null) {
      DateTime date = DateTime.tryParse(dateString) ?? DateTime.now();
      String formattedDate = DateFormat.yMMMMd().format(date);
      return formattedDate;
    } else {
      return 'Date not available';
    }
  }

  Future<String> _getImagePathForItem(String itemCode) async {
    String ipAddress = AppConfig.serverIPAddress;
    String imagePath =
        'http://$ipAddress:${AppConfig.serverPort}/api/image/$itemCode';
    return imagePath;
  }
}
