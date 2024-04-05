import 'package:flutter/material.dart';
import 'package:ordering/pages/home_page.dart';

enum TableStatus { AVAILABLE, OCCUPIED, RESERVED }

class SelectTablePage extends StatefulWidget {
  @override
  _SelectTablePageState createState() => _SelectTablePageState();
}

class _SelectTablePageState extends State<SelectTablePage> {
  List<int> _selectedTables = [];
  List<int> _tempSelectedTables = []; // Temporary list to track selected tables after button press
  Map<int, TableStatus> _tableStatus = Map();

  @override
  void initState() {
    super.initState();
    _tableStatus = Map.fromIterable(
      List.generate(50, (index) => index + 1),
      key: (index) => index,
      value: (index) => TableStatus.AVAILABLE, // By default, all tables are available
    );
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
                itemCount: 50,
                itemBuilder: (context, index) {
                  final tableNumber = index + 1;
                  final tableStatus = _tableStatus[tableNumber];
                  final isSelected = _tempSelectedTables.contains(tableNumber);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (tableStatus != TableStatus.AVAILABLE) {
                          return; // Do nothing if table is not available
                        }
                        if (isSelected) {
                          _tempSelectedTables.remove(tableNumber);
                        } else {
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
                                  children: _tempSelectedTables.map((tableNumber) {
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
                                  MaterialPageRoute(builder: (context) => HomePage()),
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
