import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ordering/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'billlout_order.dart';
import 'config.dart';

enum TableStatus { AVAILABLE, OCCUPIED, RESERVED, BILLOUT }

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
  String operation = "";
  String operationLabel = "";
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchDataFromServer();
    selectedFromShared();
    _fetchThemeMode();
    _loadOperation();
  }

  @override
  void dispose() {
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

  Future<void> _loadOperation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? current = prefs.getString('tablePageOperation');
    String label = "";
    if (current == "select") {
      label = "New Order";
    } else if (current == "add") {
      label = "Add Order";
    } else {
      label = "Bill Out";
    }
    setState(() {
      operation = current!;
      operationLabel = label;
    });
  }

  Future<void> checkForBillOut(String tableNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ipAddress = prefs.getString('ipAddress');
      final Uri apiUrl = Uri.parse(
          'http://$ipAddress:${AppConfig.serverPort}/api/checkForBillout?tableno=$tableNumber');

      final http.Response response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final bool isValid = responseBody.isNotEmpty;
        if (isValid) {
          await prefs.setString('forBillOut', tableNumber);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BilllOutOrder(),
            ),
          );
        } else {
          await prefs.remove('selectedTables');
          await prefs.remove('selectedTables2');
          Fluttertoast.showToast(
            msg: 'No exing orders for $tableNumber',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.greenAccent,
            textColor: Colors.white,
          );
          return;
        }
      } else {
        print(
            'Failed to check for billout. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error checking for billout: $error');
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
      if (operation == "select") {
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

  Future<void> addOrder(String tableNum) async {
    Fluttertoast.showToast(
      msg: '$tableNum is already ',
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
    if (operation == "select") {
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
        final List<dynamic> result = data['result'];
        for (int i = 0; i < result.length; i++) {
          String tableMark = result[i]['table_mark'] ?? '';
          String tableNumber = result[i]['table_no'] ?? '';
          // Set the tableStatus based on the table_mark value
          TableStatus tableStatus;
          switch (tableMark) {
            case 'inuse':
              tableStatus = TableStatus.RESERVED;
              tableOccupiedArr.add("1");
              break;
            case 'billout':
              tableOccupiedArr.add("2");
              tableStatus = TableStatus.BILLOUT;
              break;
            case 'vacant':
              tableOccupiedArr.add("0");
              tableStatus = TableStatus.AVAILABLE;
              break;
            default:
              tableOccupiedArr.add("0");
              tableStatus = TableStatus.AVAILABLE;
              break;
          }

          tableNumbersArr.add(tableNumber);
          tableTransNumbArr.add(result[i]['trans_no'] ?? '');
          _tableStatus[i] = tableStatus;
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
              Navigator.pushNamed(context, "/");
            },
          ),
        ),
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Align items to the end (right)
          children: [
            Text(
              operationLabel,
              style: TextStyle(
                fontSize: 24.0,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Spacer(), // This pushes the text to the right
          ],
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
                        color: Color.fromARGB(255, 119, 204, 21)),
                    SizedBox(width: 5.0),
                    Text(
                      'BILL OUT',
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
                  final ifOccupied = tableOccupiedArr[index] == '1'
                      ? 1
                      : tableOccupiedArr[index] == '2'
                          ? 2
                          : 0;

                  final tableStatus = ifOccupied == 1
                      ? TableStatus.RESERVED
                      : ifOccupied == 2
                          ? TableStatus.BILLOUT
                          : TableStatus.AVAILABLE;

                  final isSelected = _tempSelectedTables.contains(tableNumber);
                  final isSelectedFromPrefs =
                      _selectedTables.contains(alreadySelectedTable);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (tableStatus != TableStatus.AVAILABLE) {
                          if (operation == "add") {
                            saveSelectedTables(tableNumber);
                            Fluttertoast.showToast(
                              msg: 'Adding new orders for $tableNumber',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.greenAccent,
                              textColor: Colors.white,
                            );
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          } else if (operation == "bill") {
                            checkForBillOut(tableNumber);
                          } else {
                            Fluttertoast.showToast(
                              msg: '$tableNumber is already occupied',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.greenAccent,
                              textColor: Colors.white,
                            );
                            return;
                          }
                        } else {
                          if (operation == "add" || operation == "bill") {
                            Fluttertoast.showToast(
                              msg: 'No, existing orders for $tableNumber',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.greenAccent,
                              textColor: Colors.white,
                            );
                            return;
                          } else {
                            saveSelectedTables(tableNumber);
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        }
                        if (operation == "select") {
                          if (_tempSelectedTables.contains(tableNumber)) {
                            removeFromShared(transNumber);
                            _tempSelectedTables.remove(tableNumber);
                          } else {
                            _tempSelectedTables.clear();
                            saveSelectedTables(tableNumber);
                            saveSelectedTables2(transNumber);
                            _tempSelectedTables.add(tableNumber);
                          }
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: tableStatus == TableStatus.AVAILABLE
                            ? (isSelected ? Colors.black : Colors.grey)
                            : tableStatus == TableStatus.BILLOUT
                                ? Colors
                                    .green // Set color to green when tableStatus is BILLOUT
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
                                child: Center(),
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


