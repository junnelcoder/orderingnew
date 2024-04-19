import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'home_page.dart';

class DeleteCartPage extends StatefulWidget {
  @override
  _DeleteCartPageState createState() => _DeleteCartPageState();
}

class _DeleteCartPageState extends State<DeleteCartPage> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');
    if (cartItemsString != null) {
      setState(() {
        cartItems = cartItemsString
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();
      });

      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        print("Index $i: itemname: ${item['itemname']}, id: ${item['pa_id']}");
      }
    }
  }

  void navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(),
      ),
    );
  }

  Future<void> _removeCartItem(int index) async {
    String itemId = cartItems[index]['id'];
    cartItems.removeWhere((item) => item['id'] == itemId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'cartItems', cartItems.map((item) => json.encode(item)).toList());

    setState(() {});
  }

  String _getImagePathForItem(Map<String, dynamic> item) {
    if (item['picture_path'] != null &&
        item['picture_path'].trim().isNotEmpty) {
      return item['picture_path'];
    } else {
      String itemcode =
          item['itemcode'].trim().toUpperCase().replaceAll(' ', '_');
      String ipAddress = AppConfig.serverIPAddress;
      // Construct the URL to fetch the image dynamically from the server
      return 'http://$ipAddress:8080/api/image/$itemcode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TEST",
          style: TextStyle(
            fontSize: 30,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: InkWell(
          onTap: () {
            navigateToHomePage();
          },
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
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
                      'No orders yet',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> item = cartItems[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.02,
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
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
                                  Container(
                                    alignment: Alignment.center,
                                    width: screenWidth * 0.35,
                                    height: screenWidth * 0.35,
                                    child: Image.network(
                                      _getImagePathForItem(item),
                                      height: screenWidth * 0.22,
                                      width: screenWidth * 0.35,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'images/DEFAULT.png',
                                          width: 155,
                                          height: 120,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          item['itemname'],
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.06,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          item['category'],
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                        Text(
                                          "₱${double.parse(item['total']).toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.08,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
