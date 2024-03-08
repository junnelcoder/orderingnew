import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/item_widget.dart';
import 'config.dart';
import 'package:ordering/pages/home_page.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class SingleItemPage extends StatefulWidget {
  final Item item;

  const SingleItemPage({required this.item});

  @override
  _SingleItemPageState createState() => _SingleItemPageState();
}

class _SingleItemPageState extends State<SingleItemPage> {
  int quantity = 1;
  String dropdownValue = 'select a note...';
  List<String> selectedNotes = [];

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
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

  Future<List<String>> fetchNoteItems() async {
    var ipAddress = AppConfig.serverIPAddress;
    var url = Uri.parse('http://$ipAddress:8080/get-notes');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> notes =
          data.map<String>((item) => item.toString()).toList();
      print('Note items: $notes');
      return notes;
    } else {
      throw Exception('Failed to fetch note items');
    }
  }

  Future<void> addToCart() async {
    var ipAddress = AppConfig.serverIPAddress;
    var url = Uri.parse('http://$ipAddress:8080/add-to-cart');

    var itemDetails = {
      'pa_id': '1',
      'machine_id': '0001',
      'trans_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'itemcode': widget.item.itemcode,
      'itemname': widget.item.itemname,
      'category': widget.item.category,
      'qty': quantity.toString(),
      'unitprice': widget.item.unitPrice.toString(),
      'markup': widget.item.markup.toString(),
      'sellingprice': widget.item.sellingprice.toString(),
      'department': widget.item.department,
      'uom': widget.item.uom,
      'vatable': widget.item.vatable,
      'tran_time': DateFormat('HH:mm:ss').format(DateTime.now()),
      'division': widget.item.division,
      'section': widget.item.section,
      'close_status': widget.item.close_status.toString(),
      'picture_path': widget.item.picture_path,
      'brand': widget.item.brand,
      'subtotal': (widget.item.sellingprice * quantity).toString(),
      'total': (widget.item.sellingprice * quantity).toString(),
      'notes': selectedNotes.join(', '), // Join selected notes into a single string
    };
    print(itemDetails);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int terminator = 0;
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to add this order?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                var response = await http.post(
                  url,
                  body: json.encode(itemDetails),
                  headers: {'Content-Type': 'application/json'},
                );

                if (response.statusCode == 200) {
                  terminator = 1;
                  var responseBody = json.decode(response.body);
                  print('Item added to cart: $responseBody');
                } else {
                  print(
                      'Failed to add item to cart. Status code: ${response.statusCode}');
                }
                if (terminator == 1) {
                  Navigator.pop(context);
                  navigateToHomePage();
                  terminator = 0;
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
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
              Center(
                child: Image.asset(
                  _getImagePathForItem(widget.item),
                  height: MediaQuery.of(context).size.height / 2.5,
                ),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.itemname,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  SizedBox(height: 15),
                  Text(
                    widget.item.itemcode,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      var selected = await showModalBottomSheet<List<String>>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: MediaQuery.of(context).size.height / 3,
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'Select note(s)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: FutureBuilder<List<String>>(
  future: fetchNoteItems(),
  builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      List<String> noteItems = snapshot.data!;
      return ListView.builder(
        itemCount: noteItems.length,
        itemBuilder: (context, index) {
          return StatefulBuilder(
            builder: (context, setState) { // I-wrap ang CheckboxListTile sa StatefulBuilder
              return CheckboxListTile(
                title: Text(noteItems[index]),
                value: selectedNotes.contains(noteItems[index]),
                onChanged: (bool? value) {
                  setState(() { // Gumamit ng setState sa loob ng StatefulBuilder para mapansin ang pagbabago
                    if (value != null) {
                      if (value) {
                        selectedNotes.add(noteItems[index]);
                      } else {
                        selectedNotes.remove(noteItems[index]);
                      }
                    }
                  });
                },
                tristate: false,
              );
            },
          );
        },
      );
    }
  },
),

                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (selected != null) {
                        setState(() {
                          dropdownValue = selected.join(', ');
                        });
                      }
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
        onAddToCart: addToCart,
      ),
    );
  }

  String _getImagePathForItem(Item item) {
    if (item.picture_path.trim().isNotEmpty) {
      return item.picture_path;
    } else {
      String itemName =
          item.itemname.trim().toUpperCase().replaceAll(' ', '_');

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
    String formattedTotal = total.toStringAsFixed(2);
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\₱$formattedTotal",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onAddToCart,
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
