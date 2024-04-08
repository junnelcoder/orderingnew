import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/home_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CartNavBar extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) updateCartItems;
  final VoidCallback fetchCartItems;

  const CartNavBar({
    Key? key,
    required this.cartItems,
    required this.updateCartItems,
    required this.fetchCartItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;

    if (cartItems.isNotEmpty) {
      totalAmount = cartItems
          .map((item) => double.parse(item['total'].toString()))
          .reduce((value, element) => value + element);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Price:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1),
              Text(
                "\₱${totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              _showConfirmationDialog(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Save Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                saveOrderToDatabase(cartItems, context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveOrderToDatabase(
      List<Map<String, dynamic>> cartItems, BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? ipAddress = prefs.getString('ipAddress');
      var apiUrl = Uri.parse('http://$ipAddress:8080/api/add-to-cart');

      var response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(cartItems.map((item) => jsonEncode(item)).toList()),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Order placed successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await prefs.remove('cartItems'); // Clear cartItems from local storage
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

  void _updateCartItems(List<Map<String, dynamic>> updatedItems) {
    setState(() {
      cartItems = updatedItems;
    });
  }

  Future<void> _fetchCartItems() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: Center(
        child: Text('Your cart items here'),
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? CartNavBar(
              cartItems: cartItems,
              updateCartItems: _updateCartItems,
              fetchCartItems: _fetchCartItems,
            )
          : null,
    );
  }
}
