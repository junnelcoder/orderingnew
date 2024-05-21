import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/item_widget.dart';
import '../widgets/subitemwidget.dart';
import 'config.dart';

class BilllOutOrder extends StatefulWidget {
 
  @override
  _BillOutOrderPageState createState() => _BillOutOrderPageState();
}

String _getImagePathForItem(Item item) {
  if (item.picture_path.trim().isNotEmpty) {
    return item.picture_path;
  } else {
    String itemcode = item.itemcode.trim().toUpperCase().replaceAll(' ', '_');
    String ipAddress = AppConfig.serverIPAddress;
    // Construct the URL to fetch the image dynamically from the server
    return 'http://$ipAddress:${AppConfig.serverPort}/api/image/$itemcode';
  }
}

class _BillOutOrderPageState extends State<BilllOutOrder> with WidgetsBindingObserver {
  late TextEditingController _searchController;
  bool isDarkMode = false;
  String selectedService = 'Dine In';
  String alreadySelectedTable = "";
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    loadSelectedService();
    selectedFromShared();
    _storeCurrentPage('subPage');
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

  Future<void> _storeCurrentPage(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentPage', pageName);
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
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        // Check if 'table_no' field is present in the response
        if (responseBody.containsKey('table_no')) {
          String? tableNumber = responseBody['table_no'];
           Fluttertoast.showToast(
            msg: '$tableNumber',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.greenAccent,
            textColor: Colors.white,
          );
            // Do further processing with the table number if needed
         
        } else {
          print('Table number field not found in the response');
        }
      } else {
        print('Failed to load for billout. Status code: ${response.statusCode}');
      }
    } else {
      // Handle case where 'forBillOut' value is not set
      print('No table number found for billout');
    }
  } catch (error) {
    // Handle any errors that occur during the process
    print('Error loading for billout: $error');
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

@override
Widget build(BuildContext context){
  return Scaffold(
    body: CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          floating: true,
          expandedHeight: 160.0,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('haha'))
        ),
        SliverList(delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index){
            return ListTile(
              title: Text('Item ${1 + index}'),
              );

          }
        ))
      ]
    )
  );

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
 
}
