import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/item_widget.dart';
import 'package:ordering/widgets/subitemwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/config.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class SubSingleItemPage extends StatefulWidget {
  final Item item;
  const SubSingleItemPage({required this.item});

  @override
  _SubSingleItemPageState createState() => _SubSingleItemPageState();
}

class _SubSingleItemPageState extends State<SubSingleItemPage>
    with WidgetsBindingObserver {
  bool isDarkMode = false;
  int quantity = 1;
  List<String> selectedNotes = [];

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchThemeMode();
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _clearSharedPreferences();
    }
  }

  Future<void> _fetchThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeMode = prefs.getString('isDarkMode');
    if (themeMode != null && themeMode == 'true') {
      setState(() {
        isDarkMode = true;
      });
    }
  }

  Future<void> removeTablesFromShared(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedTables');
    await prefs.remove('selectedTables2');

    List<int> retrievedIndexes = table.split(',').map(int.parse).toList();
    List<int> temp = [retrievedIndexes[0]];
    int action = 0;
    int change = 0;
    String? ipAddress = prefs.getString('ipAddress');
    var apiUrl =
        Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/occupy');
    var requestBody = jsonEncode({
      'selectedIndex': temp,
      'action': action, 
      'previousIndex': table,
        'changeSelected': change,
    });
    var response = await http.post(
      apiUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: requestBody,
    );
    if (response.statusCode == 200) {
    } else {
      print('Failed to occupy tables. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
  void _clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    String? uname = prefs.getString('username');
    String? temp = prefs.getString('selectedTables2');
    String? switchValue = prefs.getString('switchValue');
    removeTablesFromShared(temp!);
    await prefs.clear();
    if (ipAddress != null && uname != null) {
      await prefs.setString('ipAddress', ipAddress);
      await prefs.setString('username', uname);
      await prefs.setString('switchValue', switchValue!);
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void navigateToHomePage() {
    print(widget.item.subitem_tag);
    print("haha");
    Navigator.pop(context);
  }

  Future<List<Map<String, dynamic>>> fetchNoteItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    var url = Uri.parse('http://$ipAddress:${AppConfig.serverPort}/api/get-notes');

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
      String? terminalId = prefs.getString('terminalId');
      // Generate a unique identifier for the main item
      String mainItemId = UniqueKey().toString();
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
        'subitem_tag': (item.subitem_tag * quantity).toString(),
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
    Color _backgroundColor = isDarkMode ? Color(0xFF222222) : Colors.white;
    Color _textColor = isDarkMode ? Colors.white : Colors.black;
    // Color _buttonColor = isDarkMode ? Colors.white : Colors.black;
    // Color _buttonTextColor = isDarkMode ? Colors.black : Colors.white;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
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
                      color: _textColor,
                      size: 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Image.network(
                  _getImagePathForItem(widget.item),
                  height: MediaQuery.of(context).size.height / 2.5,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.fastfood,
                      size: 300,
                      color: isDarkMode
                              ? Colors.white
                              : Colors.black, // Use error color from the theme
                    );
                  },
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
                            color: _textColor,
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
                            color: _textColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            CupertinoIcons.minus,
                            color: _backgroundColor,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "$quantity",
                        style: TextStyle(
                          color: _textColor,
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
                            color: _textColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            CupertinoIcons.plus,
                            color: _backgroundColor,
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
                      color: _textColor,
                      fontSize: 18,
                    ),
                  ),
                 SizedBox(height: 10),
Text(
  '₱${widget.item.sellingprice.toStringAsFixed(2)}',
  style: TextStyle(
    color: _textColor,
    fontSize: 18,
  ),
),


                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      var selected = await showModalBottomSheet<List<String>>(
                        context: context,
                        builder: (BuildContext context) {
                          return Material(
                            // Wrap the Container with Material
                            color: isDarkMode
                                ? Colors.grey
                                : Colors
                                    .white, // Set the background color to red
                            child: Container(
                              height: MediaQuery.of(context).size.height / 1,
                              child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    'Select note(s)',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Expanded(
                                    child: FutureBuilder<
                                        List<Map<String, dynamic>>>(
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
                                          return Text(
                                              'Error: ${snapshot.error}');
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
                                                    value:
                                                        selectedNotes.contains(
                                                            noteItems[index]
                                                                ['itemname']),
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        if (value != null) {
                                                          if (value) {
                                                            selectedNotes.add(
                                                                noteItems[index]
                                                                    [
                                                                    'itemname']);
                                                          } else {
                                                            selectedNotes.remove(
                                                                noteItems[index]
                                                                    [
                                                                    'itemname']);
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
                                color: _textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.black, // Set the color to red
                          ),
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
      bottomNavigationBar: SubSingleItemPageNavBar(
        sellingPrice: widget.item.sellingprice,
        quantity: quantity,
        onAddToCart: addToCart,
        isDarkMode: isDarkMode,
      ),
    );
  }

  String _getImagePathForItem(Item item) {
    if (item.picture_path.trim().isNotEmpty) {
      return item.picture_path;
    } else {
      String itemcode = item.itemcode.trim().toUpperCase().replaceAll(' ', '_');
      String ipAddress = AppConfig.serverIPAddress;
      // Construct the URL to fetch the image dynamically from the server
      return 'http://$ipAddress:${AppConfig.serverPort}/api/image/$itemcode';
    }
  }
}

class SubSingleItemPageNavBar extends StatelessWidget {
  final double sellingPrice;
  final int quantity;
  final Function()? onAddToCart;
  final bool isDarkMode;

  const SubSingleItemPageNavBar({
    required this.sellingPrice,
    required this.quantity,
    this.onAddToCart,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    double total = sellingPrice * quantity;
    String formattedTotal = total.toStringAsFixed(2);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Color(0xFF222222)
            : Colors.white, // Apply dark mode color
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.grey.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
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
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Adjust text color for dark mode
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\₱$formattedTotal",
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Adjust text color for dark mode
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
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Apply dark mode color to button
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
                      color: isDarkMode
                          ? Colors.black
                          : Colors.white, // Adjust text color for dark mode
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(CupertinoIcons.plus,
                      color: isDarkMode ? Colors.black : Colors.white,
                      size: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
