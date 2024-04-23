import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/ip_screen.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import '../pages/single_item_page.dart';
import '../pages/config.dart';
import 'dart:async';
import 'home_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemWidget extends StatefulWidget {
  final String category;
  final String searchQuery;
  final bool isDarkMode; // Add this parameter
  final VoidCallback toggleDarkMode; // Toggle function

  const ItemWidget({
    required this.category,
    required this.searchQuery,
    required this.isDarkMode, // Add this parameter
    required this.toggleDarkMode,
  });

  @override
  _ItemWidgetState createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  late List<Item> items = [];
  bool isLoading = true;
  bool isConnected = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    checkConnectivity();
  }

  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Call fetchItems whenever the search query changes
    if (widget.searchQuery != oldWidget.searchQuery) {
      fetchItems();
    }
  }

  Future<void> fetchItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    ;
    const Duration timeoutDuration = Duration(seconds: 5);
    String url = 'http://$ipAddress:8080/api/items';
    if (widget.category != 'ALL') {
      url += '?category=${Uri.encodeQueryComponent(widget.category)}';
    }
    try {
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((item) => Item.fromJson(item)).toList();
          if (widget.searchQuery.isNotEmpty) {
            items = items
                .where((item) => item.itemname
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase()))
                .toList();
          }
          isLoading = false;
        });
        final sellingPrices =
            data.map<int>((item) => item['sellingprice']).toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sellingPrices', json.encode(sellingPrices));
      } else {
        throw Exception('Failed to fetch items');
      }
    } catch (e) {
      print('Error fetching items: $e');
    }
    try {
      final response = await http
          .get(
            Uri.parse('http://$ipAddress:8080/api/allItems'),
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        // final Map<String, dynamic> data = json.decode(response.body);
        // String jsonData = json.encode(data);
      } else {
        print('Failed to connect to server');
      }
    } catch (e) {
      print('Error connecting to server: $e');
    }
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
        isLoading = false;
      });
    } else {
      fetchItems();
    }
  }

  void _myFunction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    if (ipAddress != "") {
      print('IP Address: $ipAddress');
      try {
        final response = await http
            .get(
              Uri.parse('http://$ipAddress:8080/api/ipConn'),
            )
            .timeout(Duration(seconds: 5));
        if (response.statusCode == 200) {
          String serverResponse = response.body;
          print('Server response: $serverResponse');
          AppConfig.serverIPAddress = ipAddress!;
        } else {
          print('Failed to connect to server');
        }
      } catch (e) {
        // print('Errorrrrr connecting to server: $e');
        // Fluttertoast.showToast(
        //   msg: "Server problem, Working offline",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   timeInSecForIosWeb: 3,
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IpScreen(),
          ),
        );
      }
    } else {
      print('IP Address not found in SharedPreferences');
    }
  }

  @override
  Widget build(BuildContext context) {
    _myFunction();
    return !isConnected
        ? _buildNoConnectionWidget()
        : isLoading
            ? _buildLoadingWidget()
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calculateCrossAxisCount(context),
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return buildItemCard(context, items[index]);
                },
              );
  }

  Widget _buildNoConnectionWidget() {
    return _buildLoadingWidget();
  }

  Widget _buildLoadingWidget() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(context),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          margin: EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 4.0,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!, // Dark base color
            highlightColor: Colors.grey[200]!, // Dark highlight color
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background color
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900], // Dark background color
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Container(
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[900], // Dark background color
                        borderRadius: BorderRadius.circular(
                            8.0), // Circular border radius
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      height: 16.0,
                      width: 100.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[900], // Dark background color
                        borderRadius: BorderRadius.circular(
                            8.0), // Circular border radius
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[900], // Dark background color
                            borderRadius: BorderRadius.circular(
                                8.0), // Circular border radius
                          ),
                        ),
                        Icon(
                          CupertinoIcons.plus,
                          size: 25,
                          color: Colors.white, // Icon color
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 3 : 2;
  }

  Widget buildItemCard(BuildContext context, Item item) {
    return Card(
      color: widget.isDarkMode ? Colors.grey.withOpacity(0.6) : Colors.white.withOpacity(0.85),
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SingleItemPage(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Image.network(
                _getImagePathForItem(item),
                width: 155,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.fastfood,
                    size: 120,
                    color: widget.isDarkMode ? Colors.white : Colors.black, // Use error color from the theme
                  );
                },

              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.itemname,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${item.itemcode}",
                style: TextStyle(
                  fontSize: 14.0,
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\₱${item.sellingprice.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.85),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.plus,
                    size: 25,
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.85),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      return 'http://$ipAddress:8080/api/image/$itemcode';
    }
  }
}

class Item {
  final String itemname;
  final String itemcode;
  final double sellingprice;

  final String category;
  final double unitPrice;
  final double markup;
  final String department;
  final String uom;
  final String vatable;
  final String section;
  final int close_status;
  final String picture_path;
  final String division;
  final String brand;
  final double total;
  final double subtotal;

  Item({
    required this.itemname,
    required this.itemcode,
    required this.sellingprice,
    this.category = '',
    this.unitPrice = 0.0,
    this.markup = 0.0,
    this.department = '',
    this.uom = '',
    this.vatable = '',
    this.section = '',
    this.close_status = 0,
    this.picture_path = '',
    this.division = '',
    this.brand = '',
    this.total = 0.0,
    this.subtotal = 0.0,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemname: json['itemname'] ?? '',
      itemcode: json['itemcode'] ?? '',
      sellingprice: json['sellingprice'] != null
          ? double.parse(json['sellingprice'].toString())
          : 0.0,
      category: json['category'] ?? '',
      unitPrice: json['unitprice'] != null
          ? double.parse(json['unitprice'].toString())
          : 0.0,
      markup: json['markup'] != null
          ? double.parse(json['markup'].toString())
          : 0.0,
      department: json['department'] ?? '',
      uom: json['uom'] ?? '',
      vatable: json['vatable'] ?? '',
      section: json['section'] ?? '',
      division: json['division'] ?? '',
      close_status: json['close_status'] != null
          ? int.parse(json['close_status'].toString())
          : 0,
      picture_path: json['picture_path'] ?? '',
      brand: json['brand'] ?? '',
      total:
          json['total'] != null ? double.parse(json['total'].toString()) : 0.0,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : 0.0,
    );
  }
}
