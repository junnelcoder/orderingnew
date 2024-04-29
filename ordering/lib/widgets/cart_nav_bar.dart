import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/home_page.dart';
import 'package:ordering/pages/select_table.dart';

class CartNavBar extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) updateCartItems;
  final bool isDarkMode;

  CartNavBar({
    Key? key,
    required this.cartItems,
    required this.updateCartItems,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _CartNavBarState createState() => _CartNavBarState();
}

class _CartNavBarState extends State<CartNavBar> {
  bool _isDarkMode = false;

  @override
  void initState() {
    _loadDarkModePreference();
    super.initState();
  }

  Future<void> _loadDarkModePreference() async {
    setState(() {
      _isDarkMode = widget.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;

    if (widget.cartItems.isNotEmpty) {
      totalAmount = widget.cartItems
          .map((item) => double.parse(item['total'].toString()))
          .reduce((value, element) => value + element);
    }
    Color backgroundColor = _isDarkMode ? Color(0xFF222222) : Colors.white;
    Color textColor = _isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      height: 90,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.grey.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Price:",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    "\₱${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  String switchValue = await _loadSwitchValueFromStorage();
                  String label = await getActionButtonLabel();
                  if (switchValue == 'QS') {
                    label = "Save Order";
                    if (label == 'Save Order') {
                      _showConfirmationDialog(context);
                    }
                  } else if (switchValue == 'FNB') {
                    if (label == 'Save Order') {
                      _showConfirmationDialog(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectTablePage()),
                      );
                    }
                  } else {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => SelectTablePage()),
                    // );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.grey.withOpacity(0.5)
                        : Colors.black,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: FutureBuilder<String>(
                    future: getActionButtonLabel(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        String label = snapshot.data!;
                        return Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _loadSwitchValueFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('switchValue') ?? '';
  }

  Future<String> getActionButtonLabel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedTablesString = prefs.getString('selectedTables');
    String? temp = prefs.getString('switchValue') ?? '';
    if (selectedTablesString != null) {
      selectTableShared();
      return 'Save Order';
    } else if (selectedTablesString == null && temp == "QS") {
      selectTableShared();
      return 'Save Order';
    } else {
      return 'Select Table';
    }
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    TextEditingController _customerNameController = TextEditingController();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String switchValue = prefs.getString('switchValue') ?? '';
    String? ipAddress = prefs.getString('ipAddress');
    String lastInvDigitsString = "";
    var url = Uri.parse('http://$ipAddress:8080/api/get-last_inv');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          var lastInvDigits = data[0]['last_inv_digits'];
          lastInvDigitsString = lastInvDigits.toString();
          print(lastInvDigitsString);
          setState(() {});
        } else {
          throw Exception('No data received');
        }
      } else {
        throw Exception('Failed to fetch note items');
      }
    } catch (e) {
      print('Error fetching note items: $e');
      throw Exception('Failed to fetch note items');
    }

    bool displayTextField = switchValue == 'QS'; // Check if switchValue is 'QS'
    Widget textFieldWidget = displayTextField
        ? TextField(
            controller: _customerNameController,
            maxLength: 7,
            onTap: () {
              _customerNameController.clear();
            },
            decoration: InputDecoration(
              hintText: 'Enter Customer Name Here* ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            ),
          )
        : SizedBox();
    _customerNameController.text = lastInvDigitsString;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Confirm Order',
            style: TextStyle(
              fontSize: 30,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to place the order?',
                  style: TextStyle(fontSize: 23),
                ),
                SizedBox(height: 10),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 20),
                textFieldWidget, // Display the text field based on the switchValue
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String customerName = _customerNameController.text.trim();
                if (displayTextField && customerName.isEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Please enter the customer name.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  return;
                }
                // Navigator.of(context).pop();
                saveOrderToDatabase(
                    widget.cartItems, context, _customerNameController.text);
               
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSelectedIndexToServer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedIndexesString = prefs.getString('selectedTables2');

      if (selectedIndexesString != null) {
        List<int> retrievedIndexes =
            selectedIndexesString.split(',').map(int.parse).toList();
        String? ipAddress = prefs.getString('ipAddress');
        for (int i = 0; i < retrievedIndexes.length; i++) {
          List<int> temp = [];
          temp.add(retrievedIndexes[i]);
          var apiUrl = Uri.parse('http://$ipAddress:8080/api/occupy');
          var response = await http.post(
            apiUrl,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(temp),
          );

          if (response.statusCode == 200) {
            await prefs.remove('selectedTables2');
            await prefs.remove('selectedTables');
            Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
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

  Future<void> saveOrderToDatabase(List<Map<String, dynamic>> cartItems,
      BuildContext context, String custName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? ipAddress = prefs.getString('ipAddress');
      String? selectedTablesString = prefs.getString('selectedTables');
      String? selectedService = prefs.getString('selectedService');
      String serviceValue = '';
      switch (selectedService) {
        case 'Dine In':
          serviceValue = 'DI';
          break;
        case 'Take Out':
          serviceValue = 'TO';
          break;
        case 'Delivery':
          serviceValue = 'DE';
          break;
        case 'Pick Up':
          serviceValue = 'PU';
          break;
        default:
          serviceValue = 'DI';
      }
      if (custName != "") {
        selectedTablesString = "QS-" + custName;
        selectedTablesString = selectedTablesString.toUpperCase();
      }
      var apiUrl = Uri.parse('http://$ipAddress:8080/api/add-to-cart');

      var response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'cartItems': cartItems.map((item) => jsonEncode(item)).toList(),
          'selectedTablesString': selectedTablesString,
          'switchValue': serviceValue,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Order placed successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await prefs.remove('cartItems');
        await prefs.remove('selectedService');

        sendSelectedIndexToServer();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else {
        print('Failed to save order. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving order: $e');
    }
  }

  Future<void> selectTableShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTblBool', "true");
  }
}

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _getCartItems();
  }

  void _getCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartItemsString = prefs.getString('cartItems');
    if (cartItemsString != null) {
      cartItemsString = cartItemsString.replaceAll('[', '');
      cartItemsString = cartItemsString.replaceAll(']', '');
      cartItemsString = cartItemsString.replaceAll('\\', '');

      List<dynamic> parsedItems = jsonDecode('[$cartItemsString]');
      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
          parsedItems.map((item) => jsonDecode(item)));

      setState(() {
        cartItems = items;
      });
    }
  }

  void _updateCartItems(List<Map<String, dynamic>> updatedItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cartItems', jsonEncode(updatedItems));

    setState(() {
      cartItems = updatedItems;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cartItems.isNotEmpty
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(cartItems[index]['itemName']),
                        subtitle: Text(cartItems[index]['quantity']
                            .toString()), // Display quantity
                        trailing: Text(
                          '₱${cartItems[index]['total'].toString()}',
                        ),
                      );
                    },
                  ),
                ),
                CartNavBar(
                  cartItems: cartItems,
                  updateCartItems: _updateCartItems,
                  isDarkMode: false, // Set isDarkMode to false initially
                ),
              ],
            )
          : Center(
              child: Text('Your cart is empty.'),
            ),
    );
  }
}
