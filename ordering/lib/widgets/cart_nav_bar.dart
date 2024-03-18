import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/config.dart';

class CartNavBar extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartNavBar({Key? key, required this.cartItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;

    // Compute the total amount by summing up the 'total' values of each cart item
    if (cartItems.isNotEmpty) {
      totalAmount = cartItems
          .map((item) => double.parse(item['total'].toString()))
          .reduce((value, element) => value + element);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      height: 80,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\₱${totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              saveOrderToDatabase(cartItems);
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

  Future<void> saveOrderToDatabase(List<Map<String, dynamic>> cartItems) async {
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
        print('Order saved successfully');
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
      print(cartItemsString); // Print the content of cartItemsString
      // Remove unnecessary characters and backslashes
      cartItemsString = cartItemsString.replaceAll('[', '');
      cartItemsString = cartItemsString.replaceAll(']', '');
      cartItemsString = cartItemsString.replaceAll('\\', '');

      // Parse the JSON string into a list of maps
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
      bottomNavigationBar:
          cartItems.isNotEmpty ? CartNavBar(cartItems: cartItems) : null,
    );
  }
}
