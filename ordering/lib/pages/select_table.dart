import 'package:flutter/material.dart';
import 'package:ordering/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum TableStatus { AVAILABLE, OCCUPIED, RESERVED }

class SelectTablePage extends StatefulWidget {
  @override
  _SelectTablePageState createState() => _SelectTablePageState();
}

class _SelectTablePageState extends State<SelectTablePage> {
  List<int> _selectedTables = [];
  List<int> _tempSelectedTables =
      []; // Temporary list to track selected tables after button press
  Map<int, TableStatus> _tableStatus = Map();
  List<String> tableNumbersJson = [];
  List<String> tableNumbersArr = [];
  List<String> tableOccupiedArr = [];
  List<String> tableNotOccupiedArr = [];

  @override
  void initState() {
    super.initState();
    fetchDataFromServer();
  }

  Future<void> sendSelectedIndexToServer(List<int> selectedIndexes) async {
    print("Print 1 $selectedIndexes");

    // Convert selectedIndexes to a string using a delimiter
    String temp = selectedIndexes.join(',');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedIndexes', temp);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedIndexesString = prefs.getString('selectedIndexes');

      if (selectedIndexesString != null) {
        List<int> retrievedIndexes =
            selectedIndexesString.split(',').map(int.parse).toList();
        String? ipAddress = prefs.getString('ipAddress');
        for (int i = 0; i < retrievedIndexes.length; i++) {
          List<int> temp = [];
          temp.add(retrievedIndexes[i]);
          var apiUrl = Uri.parse('http://$ipAddress:8080/api/occupy');

          print("Print 2 $temp");
          var response = await http.post(
            apiUrl,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(temp),
          );

          if (response.statusCode == 200) {
            print('Tables occupied successfully.');
            // Handle success as needed
          } else {
            print(
                'Failed to occupy tables. Status code: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        }
      } else {
        print('Selected indexes string is null.');
      }
    } catch (e) {
      print('Error occupying tables: $e');
    }
  }

  Future<void> fetchDataFromServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:8080/api/tableno'),
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
          tableNumbersArr.add(transNum);
          tableNotOccupiedArr.add(transNum);
          _tableStatus[int.parse(transNum)] = TableStatus.AVAILABLE;
        });

        occupied_1.forEach((tableData) {
          final tableNum = tableData['table_no'].trim();
          final transNum = tableData['trans_no'];
          final occ = tableData['occupied'];
          tableNumbersJson
              .add({'tbl_no': tableNum, 'trans_no': transNum, 'occupied': occ});
          tableNumbersArr.add(transNum);
          tableOccupiedArr.add(transNum);
          _tableStatus[int.parse(transNum)] = TableStatus.RESERVED;
        });

        // Sort tableNumbersArr ascendingly
        tableNumbersArr.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

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
    final crossAxisCount = MediaQuery.of(context).size.width ~/ 80;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a Table',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
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
                        color: Colors.black,
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
                        color: Colors.black,
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
                        color: Colors.black,
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
                  final tableStatus = _tableStatus[int.parse(tableNumber)];
                  final isSelected =
                      _tempSelectedTables.contains(int.parse(tableNumber));
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (tableStatus != TableStatus.AVAILABLE) {
                          return; // Do nothing if table is not available
                        }
                        if (isSelected) {
                          _tempSelectedTables.remove(int.parse(tableNumber));
                        } else {
                          _tempSelectedTables.add(int.parse(tableNumber));
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
                                'Table',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                          if (isSelected)
                            Container(
                              color: Colors.black54.withOpacity(0.5),
                              child: Center(
                                child: Text(
                                  'SELECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _tempSelectedTables.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Success'),
                          content: Container(
                            width: double.maxFinite,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 48,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Tables reserved successfully!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _tempSelectedTables.map((tableNumber) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Table $tableNumber',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                  ),
                                );
                              },
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      setState(() {
                        _tempSelectedTables.forEach((table) {
                          _tableStatus[table] = TableStatus.RESERVED;
                        });
                        sendSelectedIndexToServer(_tempSelectedTables);
                        _selectedTables.addAll(_tempSelectedTables);
                        _tempSelectedTables.clear();
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: Text(
                'Select Table',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SelectTablePage(),
  ));
}
