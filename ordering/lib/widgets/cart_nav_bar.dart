import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/config.dart';
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
  bool operationCompleted = false;
  int setUp = 0;
  @override
  void initState() {
    _loadDarkModePreference();
    loadAuthorizedDeviceIdsJson();
    _saveTotalAmount(); // Save the total amount to SharedPreferences
    super.initState();
  }
void loadAuthorizedDeviceIdsJson() async {
    try {
      String data = await rootBundle.loadString('setup.json');

      Map<String, dynamic> jsonData = jsonDecode(data);
      setUp = jsonData['pos'];
    } catch (e) {
      print('Error loading authorized device IDs: $e');
    }
  }

  Future<void> _loadDarkModePreference() async {
    setState(() {
      _isDarkMode = widget.isDarkMode;
    });
  }

  Future<void> _saveTotalAmount() async {
    double totalAmount = widget.cartItems.isNotEmpty
        ? widget.cartItems
            .map((item) => double.parse(item['total'].toString()))
            .reduce((value, element) => value + element)
        : 0.0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalAmount', totalAmount);
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
    String? lastInvDigitsString = prefs.getString('lastInv');
    if (lastInvDigitsString == null) {
      var url = Uri.parse(
          'http://$ipAddress:${AppConfig.serverPort}/api/get-last_inv');
      try {
        var response = await http.get(url);
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            var lastInvDigits = data[0]['unique_number'];
            lastInvDigitsString = lastInvDigits.toString();
            setState(() {});
          }
        } else {
          throw Exception('Failed to fetch note items');
        }
      } catch (e) {
        print('Error fetching note items: $e');
        throw Exception('Failed to fetch note items');
      }
    }

    bool displayTextField = switchValue == 'QS'; // Check if switchValue is 'QS'
    if (displayTextField) {
      if(setUp != 0){
      _customerNameController.text = lastInvDigitsString!;
    }
      } else {
      _customerNameController.text = "";
    }
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
    var loadingDialog = AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Saving order...'),
        ],
      ),
    );
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
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();

                await prefs.setString('lastInv', lastInvDigitsString!);
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await prefs.remove('lastInv');
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => loadingDialog,
                );

                String customerName = _customerNameController.text.trim();
                if (displayTextField && customerName.isEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Please enter the customer name.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  Navigator.of(context).pop();
                  return;
                }
                Future.delayed(Duration(seconds: 10), () {
                  if (!operationCompleted) {
                    Fluttertoast.showToast(
                      msg: 'Server error. Please try again later.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                    Navigator.of(context).pop();
                  }
                });

                await saveOrderToDatabase(
                    widget.cartItems, context, _customerNameController.text);

                // Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveOrderToDatabase(List<Map<String, dynamic>> cartItems,
      BuildContext context, String custName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? ipAddress = prefs.getString('ipAddress');
      String? selectedTablesString = prefs.getString('selectedTables');
      String? selectedService = prefs.getString('selectedService');
      String serviceValue = '';
      if(selectedService !=""){
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
      }else{
        serviceValue='';
      }
      int add_order = prefs.getString('tablePageOperation') == 'add' ? 1 : 0;
      String? pa_id = prefs.getString('username');
      String? machine_id = prefs.getString('terminalId');
      double totalAmount = prefs.getDouble('totalAmount') ??
          0.0; // Retrieve total amount from SharedPreferences

      if (custName != "") {
        selectedTablesString = "QS-$custName";
        selectedTablesString = selectedTablesString.toUpperCase();
      }
      var apiUrl =
          Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/saveOrder');
      var c = jsonEncode({
        'content': cartItems,
        'summary': {
          'pa_id': pa_id,
          'machine_id': machine_id,
          'selectedTablesString': selectedTablesString,
          'switchValue': serviceValue,
        },
        'add_order': add_order,
      });
      print(c);
      var response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'content': cartItems,
          'summary': {
            'pa_id': pa_id,
            'machine_id': machine_id,
            'total': totalAmount, // Use total amount from SharedPreferences
            'table_no': selectedTablesString,
            'order_service': serviceValue,
          },
          'add_order': add_order,
        }),
      );

      if (response.statusCode == 300) {
        operationCompleted = true;
        Fluttertoast.showToast(
          msg: "Order placed successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await prefs.remove('cartItems');
        await prefs.remove('selectedService');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else if (response.statusCode == 200) {
        //  &&response.body.contains('no printer detected')
        operationCompleted = true;

        Fluttertoast.showToast(
          msg: "Order saved, but no printer detected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await prefs.remove('cartItems');
        await prefs.remove('selectedService');
        await prefs.remove('selectedTables2');
        await prefs.remove('selectedTables');
        await prefs.remove('add_order');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else {
        print('Failed to save order. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
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
