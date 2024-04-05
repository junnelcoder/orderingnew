import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/item_widget.dart';
import 'package:ordering/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class SingleItemPage extends StatefulWidget {
  final Item item;

  const SingleItemPage({required this.item});

  @override
  _SingleItemPageState createState() => _SingleItemPageState();
}

class _SingleItemPageState extends State<SingleItemPage> {
  int quantity = 1;
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

  Future<List<Map<String, dynamic>>> fetchNoteItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    var url = Uri.parse('http://$ipAddress:8080/api/get-notes');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> notes =
            List<Map<String, dynamic>>.from(data);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String dataStringToSave = json.encode(data);
        await prefs.setString('notes', dataStringToSave);
        return notes;
      } else {
        throw Exception('Failed to fetch note items');
      }
    } catch (e) {
      print('Error fetching note items: $e');
      throw Exception('Failed to fetch note items');
    }
  }

  Future<void> addToCart() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Confirm",
            style: TextStyle(
              fontSize: 30,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to add this order?',
            style: TextStyle(
              fontSize: 23,
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _addItemToCart(selectedNotes);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchTerminalId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    var url = Uri.parse('http://$ipAddress:8080/api/getTerminalId');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['terminalId'];
      } else {
        throw Exception('Failed to fetch terminal ID');
      }
    } catch (e) {
      print('Error fetching terminal ID: $e');
      throw Exception('Failed to fetch terminal ID');
    }
  }

  Future<void> _addItemToCart(List<String> selectedNotes) async {
    try {
      await _saveItemToLocal(widget.item, quantity, selectedNotes);
      navigateToHomePage();
      Fluttertoast.showToast(
        msg: 'Item successfully added to orders tab',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.greenAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error adding item to cart: $e');
    }
  }

  Future<void> _saveItemToLocal(
      Item item, int quantity, List<String> selectedNotes) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? cartItems = prefs.getStringList('cartItems') ?? [];
      String? storedUsername = prefs.getString('username');
      // Generate a unique identifier for the main item
      String mainItemId = UniqueKey().toString();
      String terminalId = await _fetchTerminalId();
      var mainItemDetails = {
        'id': mainItemId,
        'pa_id': storedUsername,
        'machine_id': terminalId.toString(),
        'trans_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'itemcode': item.itemcode,
        'itemname': item.itemname,
        'category': item.category,
        'qty': quantity.toString(),
        'unitprice': item.unitPrice.toString(),
        'markup': item.markup.toString(),
        'sellingprice': item.sellingprice.toString(),
        'department': item.department,
        'uom': item.uom,
        'vatable': item.vatable,
        'tran_time': DateFormat('HH:mm:ss').format(DateTime.now()),
        'division': item.division,
        'section': item.section,
        'close_status': item.close_status.toString(),
        'picture_path': item.picture_path,
        'brand': item.brand,
        'subtotal': (item.sellingprice * quantity).toString(),
        'total': (item.sellingprice * quantity).toString(),
      };

      cartItems.add(json.encode(mainItemDetails));

      List<Map<String, dynamic>> noteItems = await fetchNoteItems();

      for (Map<String, dynamic> noteItem in noteItems) {
        if (selectedNotes.contains(noteItem['itemname'])) {
          // Use the same identifier for the main item and its associated notes
          var noteItemDetails = {
            'id': mainItemId,
            'pa_id': storedUsername,
            'machine_id': terminalId,
            'trans_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'itemcode': noteItem['itemcode'],
            'itemname': noteItem['itemname'],
            'category': 'notes',
            'qty': '0',
            'unitprice': noteItem['unitPrice'].toString(),
            'markup': noteItem['markup'].toString(),
            'sellingprice': noteItem['sellingprice'].toString(),
            'department': noteItem['department'],
            'uom': noteItem['uom'],
            'vatable': noteItem['vatable'],
            'tran_time': DateFormat('HH:mm:ss').format(DateTime.now()),
            'division': noteItem['division'],
            'section': noteItem['section'],
            'close_status': noteItem['close_status'].toString(),
            'picture_path': noteItem['picture_path'],
            'brand': noteItem['brand'],
            'subtotal': (noteItem['sellingprice'] * quantity)
                .toString(), // Assuming quantity is always 1
            'total': (noteItem['sellingprice'] * quantity)
                .toString(), // Assuming quantity is always 1
          };
          cartItems.add(json.encode(noteItemDetails));
        }
      }

      await prefs.setStringList('cartItems', cartItems);
      print('Cart Items: $cartItems');
    } catch (e) {
      print('Error saving item to local storage: $e');
      throw Exception('Failed to save item to local storage');
    }
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
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                    future: fetchNoteItems(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<
                                                List<Map<String, dynamic>>>
                                            snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        List<Map<String, dynamic>> noteItems =
                                            snapshot.data!;
                                        return ListView.builder(
                                          itemCount: noteItems.length,
                                          itemBuilder: (context, index) {
                                            return StatefulBuilder(
                                              builder: (context, setState) {
                                                return CheckboxListTile(
                                                  title: Text(noteItems[index]
                                                      ['itemname']),
                                                  value: selectedNotes.contains(
                                                      noteItems[index]
                                                          ['itemname']),
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      if (value != null) {
                                                        if (value) {
                                                          selectedNotes.add(
                                                              noteItems[index]
                                                                  ['itemname']);
                                                        } else {
                                                          selectedNotes.remove(
                                                              noteItems[index]
                                                                  ['itemname']);
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
                          selectedNotes = selected;
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
                              selectedNotes.isEmpty
                                  ? 'Select a note...'
                                  : selectedNotes.join(', '),
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
      String itemName = item.itemname.trim().toUpperCase().replaceAll(' ', '_');

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
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\₱$formattedTotal",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
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
