import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/cart_nav_bar.dart';
import 'dart:convert';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
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
        cartItems = cartItemsString.map((item) => json.decode(item) as Map<String, dynamic>).toList();
      });
    }
  }

  String _getImagePathForItem(Map<String, dynamic> item) {
    if (item['picture_path'] != null && item['picture_path'].trim().isNotEmpty) {
      return item['picture_path'];
    } else {
      String itemName = (item['itemname'] ?? '').trim().toUpperCase().replaceAll(' ', '_');

      List<String> imageFiles = [
        '25SL',
        '50SL',
        '75SL',
        '100SL',
        'BANGSILOG',
        'BLACKCOFFEE',
        'CAPPUCCINO',
        'CHICKSILOG',
        'CHOCOMT',
        'COKE1L',
        'COKEINCAN',
        'DEFAULT',
        'ESPRESSO',
        'HOTCHOCO',
        'HOTSILOG',
        'LESSICE',
        'MATCHAMT',
        'NOICE',
        'NOSUGAR',
        'OREOMT',
        'REDVELVETMT',
        'ROYALINCAN',
        'SISIG',
        'SPRITEINCAN',
        'TAPSILOG',
      ];

      for (String imageFileName in imageFiles) {
        if (itemName.contains(imageFileName)) {
          return 'images/${imageFileName.toUpperCase()}.png';
        }
      }

      return 'images/DEFAULT.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ListView.builder(
        itemCount: cartItems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.08),
                  Text(
                    "Order List",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                ],
              ),
            );
          } else {
            Map<String, dynamic> item = cartItems[index - 1];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02, horizontal: screenWidth * 0.05),
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
                child: Row(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      child: Image.asset(
                        _getImagePathForItem(item),
                        height: screenWidth * 0.22,
                        width: screenWidth * 0.35,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          if (item['category'] == 'notes' && item['notes'] != null)
                            Text(
                              "Added notes: ${item['notes']}",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            "\$${item['sellingprice']}",
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            CupertinoIcons.plus,
                            color: Colors.white,
                            size: screenWidth * 0.08,
                          ),
                          Text(
                            item['qty'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.minus,
                            color: Colors.white,
                            size: screenWidth * 0.08,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: CartNavBar(),
    );
  }
}
