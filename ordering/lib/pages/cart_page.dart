import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/cart_nav_bar.dart';
import 'config.dart';
import 'home_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  Map<String, dynamic>? notesData;
  // List<String> notesList = [];

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

  Future<void> _fetchNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? notesDataString = prefs.getString('notes');
    if (notesDataString != null) {
      setState(() {
        List<dynamic> notesDataList = json.decode(notesDataString);
        List<Map<String, dynamic>> notes =
            notesDataList.cast<Map<String, dynamic>>();
      });
      print('Notes fetched successfully');
    } else {
      print('No notes found');
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

    if (cartItems.isEmpty) {
      setState(() {});
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

    if (cartItemsString != null) {
      List<Map<String, dynamic>> updatedCartItems = [];
      for (int i = 0; i < cartItems.length; i++) {
        if (i == index) {
          int qty = int.parse(cartItems[i]['qty'].toString());
          double sellingPrice =
              double.parse(cartItems[i]['sellingprice'].toString());

          cartItems[i]['qty'] = newQuantity.toString();
          cartItems[i]['total'] = (newQuantity * sellingPrice).toString();
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

  void _decrementQuantity(int index) async {
    int currentQuantity = int.parse(cartItems[index]['qty'].toString());
    int newQuantity = currentQuantity - 1;

    if (newQuantity >= 1) {
      await _updateCartItemQuantity(index, newQuantity);
    }
  }

  void _incrementQuantity(int index) async {
    int currentQuantity = int.parse(cartItems[index]['qty'].toString());
    int newQuantity = currentQuantity + 1;

    await _updateCartItemQuantity(index, newQuantity);
  }

  Future<void> _addNotes(String notes, int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      cartItems[index]['notes'] = notes;
      await prefs.setStringList(
          'cartItems', cartItems.map((item) => json.encode(item)).toList());
      setState(() {});
    }
  }

  Future<void> _removeNotes(
      String cartItemId, int cartItemIndex, String note) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      // Convert JSON strings to Map objects
      List<Map<String, dynamic>> cartItems = cartItemsString
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();

      // Initialize an empty list to hold updated cart items
      List<Map<String, dynamic>> updatedCartItems = [];

      // Iterate through cart items
      for (int i = 0; i < cartItems.length; i++) {
        // If the current item has the specified cartItemId
        if (cartItems[i]['id'] == cartItemId) {
          // Check if the item is a note category and matches the note to be removed
          if (cartItems[i]['category'] == 'notes' &&
              cartItems[i]['itemname'] == note) {
            // Skip this note, effectively removing it
            continue;
          }
        }
        // Add the current item to the updated cart items list
        updatedCartItems.add(cartItems[i]);
      }

      // Update the cartItems in SharedPreferences
      await prefs.setStringList('cartItems',
          updatedCartItems.map((item) => json.encode(item)).toList());

      // Update the state to reflect changes
      setState(() {
        cartItems = updatedCartItems;
      });

      // Fetch updated cart items to reflect changes immediately
      await _fetchCartItems();
    } else {
      print('Error: SharedPreferences cartItemsString is null');
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

                for (int i = index + 1; i < cartItems.length; i++) {
                  if (cartItems[i]['category'] == 'notes') {
                    notesList.add(cartItems[i]['itemname']);
                  } else {
                    break;
                  }
                }

                if (item['category'] != 'notes') {
                  List<String> availableNotes = List<String>.from(notesList);

                  // Remove notes already associated with items
                  // print(cartItems[3]);
                  for (int i = 0; i < cartItems.length; i++) {
                    if (cartItems[i]['category'] == 'notes' &&
                        cartItems[i]['itemname'] != null) {
                      availableNotes.remove(cartItems[i]['itemname']);
                    }
                  }

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
                                  child: Image.asset(
                                    _getImagePathForItem(item),
                                    height: screenWidth * 0.22,
                                    width: screenWidth * 0.35,
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
                                      // if (item['notes'] == null)
                                      //   DropdownButton<String>(
                                      //     hint: Text("Add Notes"),
                                      //     value: null,
                                      //     onChanged: (String? newValue) {
                                      //       _addNotes(newValue!, index);
                                      //     },
                                      //     items: availableNotes.map<DropdownMenuItem<String>>(
                                      //       (value) => DropdownMenuItem<String>(
                                      //         value: value,
                                      //         child: Text(value),
                                      //       ),
                                      //     ).toList(),
                                      //   ),
                                      Text(
                                        "₱${double.parse(item['total']).toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.06,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
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
                                        onPressed: () =>
                                            _incrementQuantity(index),
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
                                        onPressed: () =>
                                            _decrementQuantity(index),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (notesList.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                    vertical: screenWidth * 0.02),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Added notes:",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    ...notesList.asMap().entries.map(
                                          (entry) => Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "- ${entry.value}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  String note = entry.value;
                                                  String cartItemId = cartItems[
                                                          index][
                                                      'id']; // Get the id of the current item
                                                  print(
                                                      "Clicked note at index ${entry.key}: $note");
                                                  _removeNotes(
                                                      cartItemId,
                                                      entry.key,
                                                      note); // Pass the id to the _removeNotes function
                                                },
                                              ),
                                            ],
                                          ),
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
                  return SizedBox();
                }
              },
            ),
      bottomNavigationBar:
          cartItems.isNotEmpty ? CartNavBar(cartItems: cartItems) : null,
    );
  }
}
