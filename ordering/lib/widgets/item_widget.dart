import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import '../pages/single_item_page.dart';
import '../pages/config.dart';
// import '../pages/config.dart';
class ItemWidget extends StatefulWidget {
  final String category;

  const ItemWidget({required this.category});

  @override
  _ItemWidgetState createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  late List<Item> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    String ipAddress = AppConfig.serverIPAddress; // Get the IP address from AppConfig
    String url = 'http://$ipAddress:8080/items'; 
    if (widget.category != 'ALL') {
      url += '?category=${Uri.encodeQueryComponent(widget.category)}';
    }

    final response = await http.get(Uri.parse(url));

    if (mounted) {
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((item) => Item.fromJson(item)).toList();
        });
      } else {
        throw Exception('Failed to fetch items');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return items.isNotEmpty
        ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(context),
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Adjust aspect ratio for better fitting
            ),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildItemCard(context, items[index]);
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Default value for smaller screens

    if (screenWidth > 600) {
      crossAxisCount = 3; // For larger screens, display more items per row
    }

    return crossAxisCount;
  }

  Widget buildItemCard(BuildContext context, Item item) {
    return Card(
      color: Colors.white,
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
              child: Image.asset(
                "images/pizza.jpg",
                width: 155,
                height: 120,
                // fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.itemname,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2, // Limit the number of lines
                overflow: TextOverflow.ellipsis, // Handle overflow by ellipsis
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${item.itemcode}",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${item.sellingprice}",
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.plus,
                    size: 25,
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

class Item {
  final String itemname;
  final String itemcode;
  final double sellingprice;

  // Additional properties with default values
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

  // New properties
  final double total;
  final double subtotal;

  Item({
    required this.itemname,
    required this.itemcode,
    required this.sellingprice,
    // Additional properties with default values
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
    // New properties with default values
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
      // Additional properties initialized from JSON
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
      // New properties initialized from JSON
      total:
          json['total'] != null ? double.parse(json['total'].toString()) : 0.0,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : 0.0,
    );
  }
}
