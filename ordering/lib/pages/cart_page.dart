import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_page.dart';
import '../widgets/cart_nav_bar.dart';

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
        cartItems = cartItemsString
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();
      });
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
    // Get the ID of the item to be removed
    String itemId = cartItems[index]['id'];

    // Remove all items with the same ID
    cartItems.removeWhere((item) => item['id'] == itemId);

    // Update the shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'cartItems', cartItems.map((item) => json.encode(item)).toList());

    // Check if cart is empty after deletion
    if (cartItems.isEmpty) {
      setState(() {}); // Trigger setState to update UI
    }
  }

  String _getImagePathForItem(Map<String, dynamic> item) {
    if (item['picture_path'] != null &&
        item['picture_path'].trim().isNotEmpty) {
      return item['picture_path'];
    } else {
      String itemName =
          (item['itemname'] ?? '').trim().toUpperCase().replaceAll(' ', '_');

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

  Future<void> _updateCartItemQuantity(int index, int newQuantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');
    int? value = prefs.getInt('newAmount');

    if (cartItemsString != null) {
      List<Map<String, dynamic>> updatedCartItems = [];
      for (int i = 0; i < cartItems.length; i++) {
        if (i == index) {
          cartItems[i]['qty'] = newQuantity.toString();
          cartItems[i]['total'] = value.toString();
        }
        updatedCartItems.add(cartItems[i]);
      }

      await prefs.setStringList('cartItems',
          updatedCartItems.map((item) => json.encode(item)).toList());
      setState(() {
        cartItems = updatedCartItems;
      });
    }
  }

  void _incrementQuantity(int index) async {
    int newQuantity = int.parse(cartItems[index]['qty']) + 1;
    final prefs = await SharedPreferences.getInstance();
    int newAmount = int.parse(cartItems[index]['sellingprice']) +
        int.parse(cartItems[index]['total']);
    await prefs.setInt('newAmount', newAmount);
    _updateCartItemQuantity(index, newQuantity);
  }

  Future<void> delete(int index) async {
    index++;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      List<Map<String, dynamic>> cartItems = cartItemsString
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
      cartItems.removeAt(index);

      // Convert the list of maps back to JSON strings
      List<String> updatedCartItems =
          cartItems.map((item) => json.encode(item)).toList();

      // Save the updated list back to SharedPreferences
      await prefs.setStringList('cartItems', updatedCartItems);
      setState(() {});
    }
  }

  void _decrementQuantity(int index) async {
    int newQuantity = int.parse(cartItems[index]['qty']) - 1;
    int newAmount = int.parse(cartItems[index]['total']) -
        int.parse(cartItems[index]['sellingprice']);
    if (newQuantity >= 1) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('newAmount', newAmount);
      _updateCartItemQuantity(index, newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Order List"),
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
      body: cartItems.isEmpty
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
                List<String> notesList = [];

                // Check if the following items have the category "notes"
                for (int i = index + 1; i < cartItems.length; i++) {
                  if (cartItems[i]['category'] == 'notes') {
                    notesList.add(cartItems[i]['itemname']);
                  } else {
                    break;
                  }
                }

                if (item['category'] != 'notes') {
                  return Dismissible(
                    key: Key(item.hashCode.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _removeCartItem(index);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.02,
                          horizontal: screenWidth * 0.05),
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
                                  if (notesList.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Added notes: ${notesList.join(', ')}",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors
                                                .red, // Set the color to red
                                          ),
                                          onPressed: () => delete(index),
                                        ),
                                      ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.plus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                    onPressed: () => _incrementQuantity(index),
                                  ),
                                  Text(
                                    item['qty'],
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.minus,
                                      color: Colors.white,
                                      size: screenWidth * 0.08,
                                    ),
                                    onPressed: () => _decrementQuantity(index),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox(); // Return an empty widget if the category is "notes"
                }
              },
            ),
      bottomNavigationBar: CartNavBar(),
    );
  }
}
