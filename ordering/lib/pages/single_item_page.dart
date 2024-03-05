import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/item_widget.dart'; // Import your Item model

class SingleItemPage extends StatefulWidget {
  final Item item; // Declare a variable to hold the item data

  const SingleItemPage({required this.item}); // Constructor to receive the item data

  @override
  _SingleItemPageState createState() => _SingleItemPageState();
}

class _SingleItemPageState extends State<SingleItemPage> {
  int quantity = 1; // Initialize quantity to 1
  String dropdownValue = 'Add a note...';

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decrementQuantity() {
    if (quantity > 1) {
      // Check if quantity is greater than 1 before decrementing
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> addToCart() async {
    // Define the URL of your API endpoint
    var url = Uri.parse('http://192.168.5.100:8080/add-to-cart');

    // Define the item details to be saved
    var itemDetails = {
      'pa_id': '1',
      'machine_id': '0001',
      'trans_date': DateTime.now().toString(),
      'itemcode': widget.item.itemcode,
      'itemname': widget.item.itemname,
      'category': widget.item.category,
      'qty': quantity.toString(),
      'unitprice': widget.item.unitPrice.toString(),
      'markup': widget.item.markup.toString(),
      'sellingprice': widget.item.sellingprice.toString(),
      // Add other item details as needed
    };

    // Send a POST request to your API endpoint with the item details
    var response = await http.post(
      url,
      body: json.encode(itemDetails),
      headers: {'Content-Type': 'application/json'},
    );

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // Parse the response body if needed
      var responseBody = json.decode(response.body);
      print('Item added to cart: $responseBody');
      // Perform any additional actions after adding the item to the cart
    } else {
      // Handle the error if the request was not successful
      print('Failed to add item to cart. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 25, left: 15, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Image.asset(
                  "images/burger.png",
                  height: MediaQuery.of(context).size.height / 2.5,
                ),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.itemname, // Use the item's data
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines:
                                2, // Allow the item name to wrap to the next line if needed
                            overflow: TextOverflow
                                .ellipsis, // Display ellipsis (...) if the text overflows
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: decrementQuantity,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              CupertinoIcons.minus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "$quantity",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: incrementQuantity,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    widget.item.itemcode, // Use the item's data
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 15),
                  // Dropdown for adding a note
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: MediaQuery.of(context).size.height / 3,
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'Select a note',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      _buildDropdownItem('Note 1'),
                                      _buildDropdownItem('Note 2'),
                                      _buildDropdownItem('Note 3'),
                                      // Add more options as needed
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              dropdownValue,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SingleItemNavBar(
        sellingPrice: widget.item.sellingprice,
        quantity: quantity,
        onAddToCart: addToCart, // Pass the addToCart function
      ),
    );
  }

  Widget _buildDropdownItem(String value) {
    return ListTile(
      title: Text(value),
      onTap: () {
        setState(() {
          dropdownValue = value;
        });
        Navigator.pop(context); // Close the bottom sheet when an option is selected
      },
    );
  }
}

class SingleItemNavBar extends StatelessWidget {
  final double sellingPrice;
  final int quantity;
  final Function()? onAddToCart;

  const SingleItemNavBar({
    required this.sellingPrice,
    required this.quantity,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    double total = sellingPrice * quantity;
    String formattedTotal =
        total.toStringAsFixed(2); // Format total to display with two decimal places
    return Container(
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
      padding: EdgeInsets.symmetric(horizontal: 15),
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
                  fontSize: 15, // smaller font size
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                  height:
                      4), // Adjust the space between "Total Price:" and the price value
              Text(
                "\₱$formattedTotal", // Display the formatted total
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18, // smaller font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onAddToCart, // Call the addToCart function when tapped
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
                    "Add Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(CupertinoIcons.plus, color: Colors.white, size: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
