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
  List<String> _tempSelectedTables = [];
  Map<int, TableStatus> _tableStatus = Map();
  List<String> tableNumbersJson = [];
  List<String> tableNumbersArr = [];
  List<String> tableTransNumbArr = [];
  List<String> tableOccupiedArr = [];
  List<String> tableNotOccupiedArr = [];
  String alreadySelectedTable = "";

  @override
  void initState() {
    super.initState();
    fetchDataFromServer();
    selectedFromShared();
  }
Future<void> saveSelectedTables2(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTables2', table);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
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

  Future<void> removeFromShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedTables');
    await prefs.remove('selectedTables2');
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
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
          // tableNumbersArr.add(tableNum);
          // tableNotOccupiedArr.add(transNum);
          _tableStatus[int.parse(transNum)] = TableStatus.AVAILABLE;
        });

        occupied_1.forEach((tableData) {
          final tableNum = tableData['table_no'].trim();
          final transNum = tableData['trans_no'];
          final occ = tableData['occupied'];
          tableNumbersJson
              .add({'tbl_no': tableNum, 'trans_no': transNum, 'occupied': occ});
          // tableNumbersArr.add(tableNum);
          // tableOccupiedArr.add(transNum);
          _tableStatus[int.parse(transNum)] = TableStatus.RESERVED;
        });
        tableNumbersJson.sort((a, b) {
  final String? tblNoA = a['tbl_no'];
  final String? tblNoB = b['tbl_no'];
  if (tblNoA == null && tblNoB == null) {
    return 0;
  } else if (tblNoA == null) {
    return -1; 
  } else if (tblNoB == null) {
    return 1; 
  }

  final int? numA = int.tryParse(tblNoA.replaceAll(RegExp(r'[^0-9]'), ''));
  final int? numB = int.tryParse(tblNoB.replaceAll(RegExp(r'[^0-9]'), ''));

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
                  final transNumber = tableTransNumbArr[index];
                 final ifOccupied = int.parse(tableOccupiedArr[index]);
final tableStatus = ifOccupied == 1 ? TableStatus.RESERVED : TableStatus.AVAILABLE;
                  final isSelected =
                      _tempSelectedTables.contains(tableNumber);
                  final isSelectedFromPrefs =
                      _selectedTables.contains(alreadySelectedTable);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                       
                        if (tableStatus != TableStatus.AVAILABLE) {
                          return;
                        }
                        if (_tempSelectedTables
                            .contains(tableNumber)) {
                          removeFromShared();
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
                          //
                          if (isSelected || isSelectedFromPrefs)
                            Container(
                              color: Colors.black54.withOpacity(0.5),
                              child: Center(
                               
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
