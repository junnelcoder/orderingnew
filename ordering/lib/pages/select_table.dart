
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ordering/pages/home_page.dart';
import 'package:ordering/pages/cart_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

enum TableStatus { AVAILABLE, OCCUPIED, RESERVED }

class SelectTablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackButtonPage(
      child: _SelectTablePage(),
    );
  }
}

class _SelectTablePage extends StatefulWidget {
  @override
  _SelectTablePageState createState() => _SelectTablePageState();
}

class _SelectTablePageState extends State<_SelectTablePage>
    with WidgetsBindingObserver {
  List<int> _selectedTables = [];
  List<String> _tempSelectedTables = [];
  Map<int, TableStatus> _tableStatus = Map();
  List<String> tableNumbersJson = [];
  List<String> tableNumbersArr = [];
  List<String> tableTransNumbArr = [];
  List<String> tableOccupiedArr = [];
  List<String> tableNotOccupiedArr = [];
  String alreadySelectedTable = "";
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchDataFromServer();
    selectedFromShared();
    _fetchThemeMode();
    // _loadAction();
  }

  @override
  void dispose() {
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

  Future<void> saveSelectedTables2(String table) async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedTables = prefs.getString('selectedTables2');
    if (selectedTables == null) {
      await prefs.setString('selectedTables2', table);
      selectedTables = "";
      List<int> retrievedIndexes = table.split(',').map(int.parse).toList();
      List<int> temp = [retrievedIndexes[0]];
      int action = 1;
      int change = 0;
      String? ipAddress = prefs.getString('ipAddress');
      var apiUrl =
          Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/occupy');
      var requestBody = jsonEncode({
        'previousIndex': selectedTables,
        'selectedIndex': temp,
        'action': action,
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
        print('Failed to occupy table. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } else {
      await prefs.setString('selectedTables2', table);
      List<int> retrievedIndexes = table.split(',').map(int.parse).toList();
      List<int> temp = [retrievedIndexes[0]];
      int action = 1;
      int change = 1;
      String? ipAddress = prefs.getString('ipAddress');
      var apiUrl =
          Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/occupy');
      var requestBody = jsonEncode({
        'previousIndex': selectedTables,
        'selectedIndex': temp,
        'action': action,
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

    String? currentPage = prefs.getString('currentPage');

    if (currentPage == "cartPage") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  Future<void> isOccupied(String tableNum) async {
    Fluttertoast.showToast(
      msg: '$tableNum is already occupied',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.greenAccent,
      textColor: Colors.white,
    );
  }

  Future<void> saveSelectedTables(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTables', table);
  }

  Future<void> selectedFromShared() async {
    final prefs = await SharedPreferences.getInstance();
    String? temp = prefs.getString('selectedTables');
    alreadySelectedTable = temp ?? '';
    _tempSelectedTables.add(alreadySelectedTable);
  }

  Future<void> removeFromShared(String table) async {
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

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  Future<void> fetchDataFromServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/tableno'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> occupied_0 = data['occupied_0'];
        final List<dynamic> occupied_1 = data['occupied_1'];
        List<Map<String, String>> tableNumbersJson = [];

        occupied_0.forEach((tableData) {
          final tableNum = tableData['table_no'].trim();
          final transNum = tableData['trans_no'];
          final occ = tableData['occupied'];
          tableNumbersJson
              .add({'tbl_no': tableNum, 'trans_no': transNum, 'occupied': occ});
          _tableStatus[int.parse(transNum)] = TableStatus.AVAILABLE;
        });

        occupied_1.forEach((tableData) {
          final tableNum = tableData['table_no'].trim();
          final transNum = tableData['trans_no'];
          final occ = tableData['occupied'];
          tableNumbersJson
              .add({'tbl_no': tableNum, 'trans_no': transNum, 'occupied': occ});
          _tableStatus[int.parse(transNum)] = TableStatus.RESERVED;
        });
        tableNumbersJson.sort((a, b) {
          final String? tblNoA = a['trans_no'];
          final String? tblNoB = b['trans_no'];
          if (tblNoA == null && tblNoB == null) {
            return 0;
          } else if (tblNoA == null) {
            return -1;
          } else if (tblNoB == null) {
            return 1;
          }

          final int? numA =
              int.tryParse(tblNoA.replaceAll(RegExp(r'[^0-9]'), ''));
          final int? numB =
              int.tryParse(tblNoB.replaceAll(RegExp(r'[^0-9]'), ''));

          if (numA == null && numB == null) {
            return 0;
          } else if (numA == null) {
            return -1;
          } else if (numB == null) {
            return 1;
          }

          return numA.compareTo(numB);
        });

        for (int i = 0; i < tableNumbersJson.length; i++) {
          tableNumbersArr.add(tableNumbersJson[i]['tbl_no']!);
          tableTransNumbArr.add(tableNumbersJson[i]['trans_no']!);
          tableOccupiedArr.add(tableNumbersJson[i]['occupied']!);
        }
        setState(() {});
      } else {
        print('Failed to fetch data. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = 4;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF222222) : Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(7.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a Table',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      color: Colors.red,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'OCCUPIED',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'AVAILABLE',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      color: Colors.black,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'SELECTED',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: tableNumbersArr.length,
                itemBuilder: (context, index) {
                  final tableNumber = tableNumbersArr[index];
                  final transNumber = tableTransNumbArr[index];
                  final ifOccupied = int.parse(tableOccupiedArr[index]);
                  final tableStatus = ifOccupied == 1
                      ? TableStatus.RESERVED
                      : TableStatus.AVAILABLE;
                  final isSelected = _tempSelectedTables.contains(tableNumber);
                  final isSelectedFromPrefs =
                      _selectedTables.contains(alreadySelectedTable);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (tableStatus != TableStatus.AVAILABLE) {
                          isOccupied(tableNumber);
                          return;
                        }
                        if (_tempSelectedTables.contains(tableNumber)) {
                          removeFromShared(transNumber);
                          _tempSelectedTables.remove(tableNumber);
                        } else {
                          _tempSelectedTables.clear();
                          saveSelectedTables(tableNumber);
                          saveSelectedTables2(transNumber);
                          _tempSelectedTables.add(tableNumber);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: tableStatus == TableStatus.AVAILABLE
                            ? (isSelected ? Colors.black : Colors.grey)
                            : Colors.red,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$tableNumber',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                         if (isSelected || isSelectedFromPrefs)
  GestureDetector(
    onTap: () {
      removeFromShared(transNumber);
      _tempSelectedTables.remove(tableNumber);
    },
    child: Container(
      color: Colors.black54.withOpacity(0.5),
      child: Center(
       
      ),
    ),
  ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: isDarkMode ? Color(0xFF222222) : Colors.white,
    );
  }
}

class BackButtonPage extends StatelessWidget {
  final Widget child;

  const BackButtonPage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Check if current page is HomePage, if not, navigate back to HomePage
        if (ModalRoute.of(context)?.settings.name != '/') {
          Navigator.pushReplacementNamed(context, '/');
          return false; // Prevent default back button behavior
        }
        return true; // Allow default back button behavior on HomePage
      },
      child: child,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SelectTablePage(),
  ));
}
