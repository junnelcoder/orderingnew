import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering/pages/ip_screen.dart';
import 'package:ordering/pages/subPage.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import '../pages/single_item_page.dart';
import '../pages/config.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SubItemWidget extends StatefulWidget {
  final String itemcode;
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;
  final VoidCallback onItemAdded;

  const SubItemWidget({
    required this.itemcode,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.onItemAdded,
  });

  @override
  _SubItemWidgetState createState() => _SubItemWidgetState();
}

class _SubItemWidgetState extends State<SubItemWidget> {
  late List<SubItem> items = [];
  bool isLoading = true;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    checkConnectivity();
  }

  Future<void> fetchItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ipAddress = prefs.getString('ipAddress');
    const Duration timeoutDuration = Duration(seconds: 5);
    String url = 'http://$ipAddress:${AppConfig.serverPort}/api/subitems?itemcode=${Uri.encodeQueryComponent(widget.itemcode)}';

    try {
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((item) => SubItem.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch items');
      }
    } catch (e) {
      print('Error fetching items: $e');
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

  @override
  Widget build(BuildContext context) {
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
    return Center(
      child: Text(
        'No Internet Connection',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
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
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[200]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
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
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      height: 16.0,
                      width: 100.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.plus,
                          size: 25,
                          color: Colors.white,
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

  Widget buildItemCard(BuildContext context, SubItem item) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.grey[800]
              : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.0,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                child: Image.network(
                  item.picture_path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 50,
                        color: widget.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemname,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Price: ${item.sellingprice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code: ${item.itemcode}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.plus,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () {
                      // Add your item to cart logic here
                      widget.onItemAdded();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SubItem {
  final String itemname;
  final String itemcode;
  final double sellingprice;
  final int subitem_tag;

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

  SubItem({
    required this.itemname,
    required this.itemcode,
    required this.sellingprice,
    required this.subitem_tag,
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

  factory SubItem.fromJson(Map<String, dynamic> json) {
    return SubItem(
      itemname: json['itemname'] ?? '',
      itemcode: json['itemcode'] ?? '',
      sellingprice: json['sellingprice'] != null
          ? double.parse(json['sellingprice'].toString())
          : 0.0,
      subitem_tag: json['subitem_tag'] != null
          ? int.parse(json['subitem_tag'].toString())
          : 0,
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
      total: json['total'] != null
          ? double.parse(json['total'].toString())
          : 0.0,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : 0.0,
    );
  }
}
