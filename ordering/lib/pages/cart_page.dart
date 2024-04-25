import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/cart_nav_bar.dart';
import 'config.dart';
import 'delete_cart_page.dart';
import 'home_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with WidgetsBindingObserver {
  bool isDarkMode = false; // Default to false for light mode
  List<Map<String, dynamic>> cartItems = [];
  Map<String, dynamic>? notesData;
  List<String> notesList = ['No notes added'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchThemeMode(); // Fetch theme mode from SharedPreferences
    _fetchCartItems();
    _fetchNotes();
    _storeCurrentPage('cartPage');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeMode = prefs.getString('isDarkMode');
    if (themeMode != null && themeMode == 'true') {
      setState(() {
        isDarkMode = true; // Enable dark mode if themeMode is true
      });
    }
  }

  Future<void> _storeCurrentPage(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentPage', pageName);
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

  Future<List<Map<String, dynamic>>> _saveToShared(unselected) async {
    String unselectedNotesJson = json.encode(unselected);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('unselectedNotes', unselectedNotesJson);
    return unselected;
  }

  Future<List<Map<String, dynamic>>> _fetchNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    var url = Uri.parse('http://$ipAddress:8080/api/get-notes');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          notes = data.cast<Map<String, dynamic>>();
        });
        return notes;
      } else {
        throw Exception('Failed to fetch note items');
      }
    } catch (e) {
      print('Error fetching note items: $e');
      throw Exception('Failed to fetch note items');
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

  Future<void> _updateCartItemQuantity(int index, int newQuantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      List<Map<String, dynamic>> updatedCartItems = [];
      for (int i = 0; i < cartItems.length; i++) {
        if (i == index) {
          // ignore: unused_local_variable
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

    if (newQuantity >= 0) {
      await _updateCartItemQuantity(index, newQuantity);
      if (newQuantity == 0) {
        _removeCartItem(index);
      }
    }
  }

  void _incrementQuantity(int index) async {
    int currentQuantity = int.parse(cartItems[index]['qty'].toString());
    int newQuantity = currentQuantity + 1;

    await _updateCartItemQuantity(index, newQuantity);
  }

  Future<void> _addNotes(String note, int index, String itemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      setState(() {
        if (cartItemsString.isNotEmpty) {
          Map<String, dynamic> lastCartItem = json.decode(cartItemsString.last);

          Map<String, dynamic> duplicatedItem = Map.from(lastCartItem);
          duplicatedItem['itemname'] = note;
          duplicatedItem['id'] = itemId;
          duplicatedItem['category'] = "notes";
          duplicatedItem['total'] = 0;
          cartItemsString.add(json.encode(duplicatedItem));
          prefs.setStringList('cartItems', cartItemsString);
          prefs.remove('unselectedNotes');
          _fetchCartItems();
        }
      });
    }
  }

  Future<void> _removeNotes(
      String cartItemId, int cartItemIndex, String note) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsString = prefs.getStringList('cartItems');

    if (cartItemsString != null) {
      List<Map<String, dynamic>> cartItems = cartItemsString
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();

      List<Map<String, dynamic>> updatedCartItems = [];
      for (int i = 0; i < cartItems.length; i++) {
        if (cartItems[i]['id'] == cartItemId) {
          if (cartItems[i]['category'] == 'notes' &&
              cartItems[i]['itemname'] == note) {
            continue;
          }
        }
        updatedCartItems.add(cartItems[i]);
      }
      await prefs.setStringList('cartItems',
          updatedCartItems.map((item) => json.encode(item)).toList());
      setState(() {
        cartItems = updatedCartItems;
      });

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Order List",
              style: TextStyle(
                fontSize: 30,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeleteCartPage()),
                );
              },
              child: Text(
                "Cancel Order",
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
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
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text(
                      'No orders yet',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> item = cartItems[index];
                      List<String> notesList = [];

                      for (int i = 0; i < cartItems.length; i++) {
                        if (cartItems[i]['category'] == 'notes' &&
                            cartItems[i]['id'] == item['id']) {
                          notesList.add(cartItems[i]['itemname']);
                        }
                      }

                      if (item['category'] != 'notes') {
                        List<String> availableNotes =
                            List<String>.from(notesList);
                        for (int i = 0; i < cartItems.length; i++) {
                          if (cartItems[i]['category'] == 'notes' &&
                              cartItems[i]['itemname'] != null) {
                            availableNotes.remove(cartItems[i]['itemname']);
                          }
                        }

                        List<Map<String, dynamic>> unselectedNotes = [];
                        for (int i = 0; i < notes.length; i++) {
                          bool isSelected = false;
                          String noteName = notes[i]['itemname'];
                          for (int j = 0; j < notesList.length; j++) {
                            if (notesList[j] == noteName) {
                              isSelected = true;
                              break;
                            }
                          }
                          if (!isSelected) {
                            Map<String, dynamic> noteWithId = {
                              ...notes[i],
                              'id': item['id']
                            };
                            unselectedNotes.add(noteWithId);
                          }
                        }
                        _saveToShared(unselectedNotes);

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
                                      Container(
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.015),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenWidth * 0.02,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Added notes:",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04 * 1.3,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        ...notesList.map(
                                          (note) => Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "- $note",
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
                                                  String cartItemId =
                                                      cartItems[index]['id'];
                                                  print("Clicked note: $note");
                                                  _removeNotes(
                                                    cartItemId,
                                                    index,
                                                    note,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        if (unselectedNotes.isNotEmpty)
                                          DropdownButton<String>(
                                            hint: Text(
                                              "Select a note",
                                              style: TextStyle(
                                                fontSize: 23,
                                                fontWeight: FontWeight
                                                    .bold, // Add fontWeight if desired
                                              ),
                                            ),
                                            value: null,
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                _addNotes(newValue, index,
                                                    item['id']);
                                              }
                                            },
                                            items: unselectedNotes
                                                .map<DropdownMenuItem<String>>(
                                                  (item) =>
                                                      DropdownMenuItem<String>(
                                                    value: item['itemname'],
                                                    child: Text(item['itemname']
                                                        .trim()),
                                                  ),
                                                )
                                                .toList(),
                                          )
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
          ),
        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? CartNavBar(
              cartItems: cartItems,
              updateCartItems: (_) {},
              isDarkMode: isDarkMode, // Pass isDarkMode to the bottom nav bar
            )
          : null,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
    );
  }
}
