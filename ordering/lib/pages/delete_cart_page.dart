import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DeleteCartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackButtonPage(
      child: _DeleteCartPage(),
    );
  }
}

class _DeleteCartPage extends StatefulWidget {
  @override
  _DeleteCartPageState createState() => _DeleteCartPageState();
}

class _DeleteCartPageState extends State<_DeleteCartPage>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> cartItems = [];
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    retrievePunched();
    _fetchThemeMode();
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

  void _clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    String? uname = prefs.getString('username');
    await prefs.clear();
    if (ipAddress != null && uname != null) {
      await prefs.setString('ipAddress', ipAddress);
      await prefs.setString('username', uname);
    }
  }

  void deleteOn(String trans_no, int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    final url = Uri.parse('http://$ipAddress:8080/api/delete-items');
    String? temp = prefs.getString('count');
    count = int.parse(temp!);
    print(count);
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'trans_no': trans_no,
          'count': count,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Deleted successfully');
        count--;
        if (count == 0) {
          Navigator.of(context).pop();
        } else if (count == 887) {
          Navigator.of(context).pop();
        }
        String countString = count.toString();
        await prefs.setString('count', countString);
        setState(() {});
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data: $e');
    }
  }

  void showModal(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    final url = Uri.parse('http://$ipAddress:8080/api/soDetailData');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<dynamic> filteredItem = data.where((item) {
          return item['so_number'] == id && item['category'] != 'notes';
        }).toList();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int count = filteredItem.length;
        String countString = count.toString();
        await prefs.setString('count', countString);
        print('Filtered item: $count');
        showCustomContainer(id);
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void showCustomContainer(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    final url = Uri.parse('http://$ipAddress:8080/api/soDetailData');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<dynamic> filteredItem = data.where((item) {
          return item['so_number'] == id && item['category'] != 'notes';
        }).toList();
        int count = filteredItem.length;
        String countString = count.toString();
        await prefs.setString('count', countString);
        print('Filtered item: $count');
        String transNoToDelete = '';

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Material(
              color: isDarkMode
                  ? Colors.grey
                  : Colors.white, // Set the background color to red
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItem.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> item = filteredItem[index];
                          return Dismissible(
                            key: UniqueKey(),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.red,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Confirm"),
                                    content: Text(
                                        "Are you sure you want to delete this item?"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                print(
                                    'Item swiped to the left: ${item['trans_no']}');
                                deleteOn(item['trans_no'], count);
                              }
                            },
                            child: ListTile(
                              title: Text('${item['itemname']}'),
                              subtitle: Text(
                                "Unit Price: ₱${double.parse(item['unitprice']?.toString() ?? '0').toStringAsFixed(2)}",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirm"),
                                  content: Text(
                                      "Are you sure you want to delete this whole transaction?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              for (var item in filteredItem) {
                                transNoToDelete = item['trans_no'];
                                print('All button clicked $transNoToDelete ff');
                                count = 888;
                                String countString = count.toString();
                                await prefs.setString('count', countString);
                                deleteOn(transNoToDelete, count);
                              }
                            }
                          },
                          child: Text(
                            'Delete Transaction',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors
                                    .black), // Adjust the font size as needed
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Close',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors
                                    .black), // Adjust the font size as needed
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ).then((_) {
          retrievePunched();
        });
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> retrievePunched() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    final url = Uri.parse('http://$ipAddress:8080/api/todaysTransactions');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        String? uname = prefs.getString('username');
        if (uname != null) {
          List<dynamic> filteredData = responseData
              .where((item) => item['pa_id'].trim() == uname)
              .toList();
          await prefs.setStringList('filteredData',
              filteredData.map((item) => json.encode(item)).toList());
          _fetchCartItems();
        } else {
          print('Username is null');
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<String?> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> _fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('filteredData');
    if (cartItemsString != null) {
      setState(() {
        cartItems = cartItemsString
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  void navigateToCartPage() {
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CartPage(),
    //   ),
    // );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF222222) : Colors.white,
        title: FutureBuilder<String?>(
          future: _getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Transactions of ...');
            } else {
              if (snapshot.hasData) {
                String username = snapshot.data!;
                return RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black, // Set default color for all text
                    ),
                    children: [
                      TextSpan(
                        text: "Transactions of ",
                      ),
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey
                              : Colors
                                  .blue, // Set the color for the username here
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Text('Transactions');
              }
            }
          },
        ),
        automaticallyImplyLeading: false,
        leading: InkWell(
          onTap: () {
            navigateToCartPage();
          },
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text(
                      'No items yet',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> item = cartItems[index];
                      return GestureDetector(
                        onTap: () {
                          showModal(item['so_number']);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.02,
                            horizontal: screenWidth * 0.05,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.withOpacity(
                                      0.4) // Black background for dark mode
                                  : Colors.white, // Default white background
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            // ignore: unnecessary_null_comparison
                                            "so_number: ${item['so_number']}" !=
                                                    null
                                                ? "so_number: ${item['so_number']}"
                                                    .toString()
                                                : '',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.07,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            // ignore: unnecessary_null_comparison
                                            "so_number: ${item['tran_time']}" !=
                                                    null
                                                ? "Customer Info: ${item['table_no']}"
                                                    .toString()
                                                : '',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.06,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "total: ₱${double.parse(item['total_amount']?.toString() ?? '0').toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.06,
                                              // fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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